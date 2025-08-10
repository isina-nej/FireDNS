package com.example.firedns

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*

/**
 * سرویس VPN برای تغییر DNS سیستم
 * این کلاس مسئول مدیریت اتصال VPN و تنظیم DNS های سفارشی است
 */
class MyVpnService : VpnService() {
    companion object {
        // متغیر نشان‌دهنده وضعیت اجرای سرویس
        var isRunning: Boolean = false
        
        // شنونده برای اطلاع‌رسانی تغییرات وضعیت سرویس
        var statusListener: ((String) -> Unit)? = null
        
        // ثابت‌های مربوط به نوتیفیکیشن
        private const val NOTIFICATION_CHANNEL_ID = "FireDNS_VPN"
        private const val NOTIFICATION_ID = 1
        private const val ERROR_NOTIFICATION_ID = 2
        private const val RECONNECT_NOTIFICATION_ID = 3
        
        // تنظیمات پایه VPN
        private const val DNS_VPN_CONNECTION_NAME = "FireDNS VPN"
        // آدرس داخلی غیر رایج برای جلوگیری از تداخل با شبکه‌های محلی
        private const val VPN_ADDRESS = "10.88.229.2"
        
        // سرورهای DNS پیش‌فرض گوگل
        const val DEFAULT_PRIMARY_DNS = "8.8.8.8"      // Google DNS Primary
        const val DEFAULT_SECONDARY_DNS = "8.8.4.4"    // Google DNS Secondary
        // متغیر برای تشخیص خاموش شدن دستی توسط کاربر
        var userStoppedService: Boolean = false
        
        // دلایل قطع شدن اتصال
        enum class ConnectionLostReason {
            NONE,                   // بدون قطعی
            INTERNET_DISCONNECTED,  // قطعی اینترنت
            DNS_UNREACHABLE,        // عدم دسترسی به سرور DNS
            DNS_NOT_WORKING,        // عدم کارکرد صحیح DNS
            UNKNOWN_ERROR           // خطای ناشناخته
        }
    }

    // رابط VPN که برای اتصال استفاده می‌شود
    private var vpnInterface: ParcelFileDescriptor? = null
    
    // دلیل قطع شدن اتصال فعلی
    private var connectionLostReason: ConnectionLostReason = ConnectionLostReason.NONE
    
    // زمان آخرین تلاش برای اتصال مجدد
    private var lastReconnectAttempt: Long = 0
    
    // متغیرهای مدیریت مصرف منابع
    private var lastNetworkType: Int = -1
    private var lastBatteryLevel: Int = -1
    private var isLowPowerMode: Boolean = false
    private var dataUsageBytes: Long = 0
    private var lastDataUsageUpdate: Long = 0

    // BroadcastReceiver برای تشخیص وصل شدن اینترنت
    private val networkReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: android.content.Context?, intent: Intent?) {
            val cm = context?.getSystemService(android.content.Context.CONNECTIVITY_SERVICE) as? android.net.ConnectivityManager
            val activeNetwork = cm?.activeNetworkInfo
            val isConnected = activeNetwork?.isConnectedOrConnecting == true
            if (isConnected && !isRunning && !userStoppedService) {
                Log.d("FireDNS", "Network connected, restarting VPN service...")
                val restartIntent = Intent(context, MyVpnService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context?.startForegroundService(restartIntent)
                } else {
                    context?.startService(restartIntent)
                }
            }
        }
    }
    
    // BroadcastReceiver برای نظارت بر وضعیت باتری
    private val batteryReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: android.content.Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                val level = intent.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1)
                val batteryPct = level * 100 / scale
                
                // بررسی تغییر قابل توجه در سطح باتری
                if (lastBatteryLevel != -1 && Math.abs(batteryPct - lastBatteryLevel) >= 10) {
                    Log.d("FireDNS", "Battery level changed significantly: $lastBatteryLevel -> $batteryPct")
                    adjustServiceBasedOnBattery(batteryPct)
                }
                
                lastBatteryLevel = batteryPct
            } else if (intent?.action == android.os.PowerManager.ACTION_POWER_SAVE_MODE_CHANGED) {
                val powerManager = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                isLowPowerMode = powerManager.isPowerSaveMode
                Log.d("FireDNS", "Power save mode changed: $isLowPowerMode")
                adjustServiceBasedOnPowerMode(isLowPowerMode)
            }
        }
    }

    /**
     * بررسی معتبر بودن آدرس IP
     * @param ip آدرس IP برای بررسی
     * @return true اگر آدرس IP معتبر باشد، false در غیر این صورت
     */
    private fun isValidIpAddress(ip: String): Boolean {
        return try {
            // بررسی آدرس 0.0.0.0
            if (ip == "0.0.0.0") return false
            
            // تقسیم آدرس به بخش‌های جداگانه
            val parts = ip.split(".")
            if (parts.size != 4) return false
            
            // بررسی محدوده اعداد در هر بخش (0-255)
            parts.all { part ->
                part.toInt() in 0..255
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * تست اتصال اینترنت و عملکرد DNS به صورت غیرمسدودکننده
     * این تابع همچنین وضعیت اتصال را بررسی می‌کند و در صورت قطعی، نوتیفیکیشن مناسب نمایش می‌دهد
     */
    private fun testInternetConnectivity() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d("FireDNS", "Testing internet connectivity after VPN setup...")
                
                // تست اتصال پایه با پینگ (غیرمسدودکننده)
                val pingResult = async {
                    try {
                        val pingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 8.8.8.8")
                        val exitCode = pingProcess.waitFor()
                        exitCode == 0
                    } catch (e: Exception) {
                        Log.e("FireDNS", "Basic connectivity test failed with exception", e)
                        false
                    }
                }
                
                // تست اتصال به گوگل (غیرمسدودکننده)
                val googleResult = async {
                    try {
                        val googlePingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 google.com")
                        val exitCode = googlePingProcess.waitFor()
                        exitCode == 0
                    } catch (e: Exception) {
                        Log.e("FireDNS", "Google connectivity test failed with exception", e)
                        false
                    }
                }
                
                // تست مستقیم عملکرد DNS (غیرمسدودکننده)
                val dnsResult = async {
                    try {
                        // Use InetAddress instead of nslookup command to avoid permission issues
                        val inetAddress = java.net.InetAddress.getByName("google.com")
                        val isReachable = inetAddress != null
                        Log.d("FireDNS", "DNS resolution test using InetAddress: ${inetAddress?.hostAddress}")
                        isReachable
                    } catch (e: Exception) {
                        Log.e("FireDNS", "DNS resolution test failed with exception", e)
                        false
                    }
                }
                
                // انتظار برای تکمیل تمام تست‌ها با timeout
                val basicConnectivity = withTimeoutOrNull(5000) { pingResult.await() } ?: false
                val googleConnectivity = withTimeoutOrNull(5000) { googleResult.await() } ?: false
                val dnsResolution = withTimeoutOrNull(5000) { dnsResult.await() } ?: false
                
                // گزارش نتایج
                if (basicConnectivity) {
                    Log.d("FireDNS", "✅ Basic internet connectivity test PASSED")
                } else {
                    Log.e("FireDNS", "❌ Basic internet connectivity test FAILED")
                    // Switch to main thread for UI operations
                    withContext(Dispatchers.Main) {
                        // نمایش نوتیفیکیشن برای قطعی اینترنت
                        showDisconnectionNotification("قطعی اینترنت", "اتصال اینترنت قطع شده است. به محض برقراری اتصال، سرویس VPN مجدداً راه‌اندازی خواهد شد.")
                        // تنظیم وضعیت برای اتصال مجدد خودکار
                        connectionLostReason = ConnectionLostReason.INTERNET_DISCONNECTED
                        stopVpnButKeepNotification()
                    }
                    return@launch
                }
                
                if (googleConnectivity) {
                    Log.d("FireDNS", "✅ Google connectivity test PASSED")
                } else {
                    Log.e("FireDNS", "❌ Google connectivity test FAILED - DNS resolution issue")
                    if (basicConnectivity) {
                        // Switch to main thread for UI operations
                        withContext(Dispatchers.Main) {
                            // نمایش نوتیفیکیشن برای مشکل DNS
                            showDisconnectionNotification("مشکل در سرور DNS", "سرور DNS در دسترس نیست. در حال تلاش برای اتصال مجدد...")
                            // تنظیم وضعیت برای اتصال مجدد خودکار
                            connectionLostReason = ConnectionLostReason.DNS_UNREACHABLE
                            stopVpnButKeepNotification()
                        }
                        return@launch
                    }
                }
                
                if (dnsResolution) {
                    Log.d("FireDNS", "✅ DNS resolution test PASSED")
                } else {
                    Log.e("FireDNS", "❌ DNS resolution test FAILED")
                    if (basicConnectivity) {
                        // Switch to main thread for UI operations
                        withContext(Dispatchers.Main) {
                            // نمایش نوتیفیکیشن برای مشکل DNS
                            showDisconnectionNotification("مشکل در عملکرد DNS", "سیستم DNS به درستی کار نمی‌کند. در حال تلاش برای اتصال مجدد...")
                            // تنظیم وضعیت برای اتصال مجدد خودکار
                            connectionLostReason = ConnectionLostReason.DNS_NOT_WORKING
                            stopVpnButKeepNotification()
                        }
                        return@launch
                    }
                }
                
                // اطلاع‌رسانی نتیجه کلی تست‌ها
                val overallSuccess = basicConnectivity && (googleConnectivity || dnsResolution)
                
                // Switch to main thread for UI operations
                withContext(Dispatchers.Main) {
                    if (overallSuccess) {
                        statusListener?.invoke("DNS_TEST_SUCCESS")
                        // اگر قبلاً قطعی داشتیم و الان وصل شده، نوتیفیکیشن را به‌روز کنیم
                        if (connectionLostReason != ConnectionLostReason.NONE) {
                            showReconnectionNotification()
                            connectionLostReason = ConnectionLostReason.NONE
                        }
                    } else {
                        statusListener?.invoke("DNS_TEST_PARTIAL")
                    }
                }
                
            } catch (e: Exception) {
                Log.e("FireDNS", "Connectivity test failed with exception: ${e.message}")
                
                // Switch to main thread for UI operations
                withContext(Dispatchers.Main) {
                    statusListener?.invoke("DNS_TEST_FAILED")
                    // نمایش نوتیفیکیشن برای خطای ناشناخته
                    showDisconnectionNotification("خطای ناشناخته", "خطایی در سرویس VPN رخ داده است: ${e.message}")
                    connectionLostReason = ConnectionLostReason.UNKNOWN_ERROR
                    stopVpnButKeepNotification()
                }
            }
        }
    }

    /**
     * توقف اجباری سرویس VPN
     * این تابع تمام منابع را آزاد کرده و سرویس را متوقف می‌کند
     */
    private fun forceStop() {
        try {
            // ثبت خاموش شدن دستی توسط کاربر - این خط باید در ابتدای تابع باشد
            userStoppedService = true
            
            // ثبت شروع عملیات توقف
            Log.d("FireDNS", "Force stopping VPN service...")
            
            // بستن رابط VPN
            vpnInterface?.close()
            vpnInterface = null
            
            // به‌روزرسانی وضعیت
            isRunning = false
            
            // Notify status change on main thread
            CoroutineScope(Dispatchers.Main).launch {
                statusListener?.invoke("DNS_STOPPED")
                Log.d("FireDNS", "Status listener notified: DNS_STOPPED (force stop)")
            }
            
            // حذف تمام نوتیفیکیشن‌ها
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            notificationManager?.cancel(ERROR_NOTIFICATION_ID)
            notificationManager?.cancel(RECONNECT_NOTIFICATION_ID)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            
            // ریست کردن وضعیت قطعی
            connectionLostReason = ConnectionLostReason.NONE
            
            // توقف کامل سرویس
            stopSelf()
            Log.d("FireDNS", "VPN service force stopped successfully")
        } catch (e: Exception) {
            // مدیریت خطاها در زمان توقف سرویس
            Log.e("FireDNS", "Error in force stop: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            
            // حذف تمام نوتیفیکیشن‌ها در صورت خطا
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            notificationManager?.cancel(ERROR_NOTIFICATION_ID)
            notificationManager?.cancel(RECONNECT_NOTIFICATION_ID)
            
            stopSelf()
        }
    }

    /**
     * شروع سرویس VPN
     * این تابع مسئول راه‌اندازی سرویس VPN و تنظیم DNS های سفارشی است
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // بررسی درخواست توقف اجباری
        if (intent?.action == "FORCE_STOP") {
            Log.d("FireDNS", "Force stop requested")
            forceStop()
            return START_NOT_STICKY
        }
        
        // دریافت آدرس‌های DNS از intent
        var dns1 = intent?.getStringExtra("dns1") ?: DEFAULT_PRIMARY_DNS
        var dns2 = intent?.getStringExtra("dns2") ?: DEFAULT_SECONDARY_DNS
        
        // اگر سرویس به صورت خودکار استارت شده، مقدار userStoppedService را false کن
        userStoppedService = false

        // اعتبارسنجی DNS ها
        if (!isValidIpAddress(dns1)) {
            Log.e("FireDNS", "Invalid primary DNS: $dns1, stopping service")
            isRunning = false
            statusListener?.invoke("DNS_ERROR_INVALID_PRIMARY")
            return START_NOT_STICKY
        }
        if (!isValidIpAddress(dns2)) {
            Log.e("FireDNS", "Invalid secondary DNS: $dns2, stopping service")
            isRunning = false
            statusListener?.invoke("DNS_ERROR_INVALID_SECONDARY")
            return START_NOT_STICKY
        }

        Log.d("FireDNS", "MyVpnService onStartCommand: dns1=$dns1, dns2=$dns2")

        // ساخت notification برای سرویس foreground
        val notificationId = 1
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(notificationId, notification)
        }

        try {
            // ایجاد VPN با تنظیمات ساده مانند NetShift
            Log.d("FireDNS", "Setting up VPN configuration (NetShift style)")
            val builder = Builder()
                .setSession("FireDNSVPN")
                .addAddress("10.0.0.2", 24)
                .setConfigureIntent(android.app.PendingIntent.getActivity(
                    this, 0,
                    Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                    android.app.PendingIntent.FLAG_IMMUTABLE
                ))

            // تنظیم DNS سرورها (مانند NetShift)
            Log.d("FireDNS", "Setting DNS servers: $dns1, $dns2")
            builder.addDnsServer(dns1)
            if (dns2.isNotEmpty()) {
                builder.addDnsServer(dns2)
            }

            // فقط خود برنامه را از VPN جدا می‌کنیم
            builder.addDisallowedApplication(packageName)
            Log.d("FireDNS", "Excluding self app from VPN: $packageName")

            // راه‌اندازی VPN
            Log.d("FireDNS", "Establishing VPN connection...")
            vpnInterface = builder.establish()

            if (vpnInterface != null) {
                Log.d("FireDNS", "VPN interface established successfully")
                Log.d("FireDNS", "DNS servers active: $dns1, $dns2")
                isRunning = true
                
                // Notify status change with delay to ensure MainActivity is ready
                CoroutineScope(Dispatchers.Main).launch {
                    delay(100) // Small delay to ensure listener is connected
                    statusListener?.invoke("VPN_STARTED")
                    Log.d("FireDNS", "Status listener notified: VPN_STARTED")
                }
                
                testInternetConnectivity() // Test internet connectivity after VPN setup
                return START_STICKY
            } else {
                Log.e("FireDNS", "Failed to establish VPN interface")
                isRunning = false
                
                // Notify status change
                CoroutineScope(Dispatchers.Main).launch {
                    statusListener?.invoke("DNS_STOPPED")
                    Log.d("FireDNS", "Status listener notified: DNS_STOPPED")
                }
                
                return START_NOT_STICKY
            }

        } catch (e: Exception) {
            Log.e("FireDNS", "Error setting up VPN: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            return START_NOT_STICKY
        }
    }

    private fun createNotification(): Notification {
        // آیکون برنامه باید در پوشه res/drawable/ic_launcher.png قرار داشته باشد
        val iconRes = resources.getIdentifier("ic_launcher", "drawable", packageName)
        val smallIcon = if (iconRes != 0) iconRes else android.R.drawable.ic_menu_manage
        val title = "فایر دی‌ان‌اس فعال است"
        val text = "سرویس DNS در حال اجراست"

        // Intent برای باز کردن برنامه
        val mainIntent = Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val mainPendingIntent = android.app.PendingIntent.getActivity(
            this, 0, mainIntent, android.app.PendingIntent.FLAG_IMMUTABLE
        )

        // Intent برای خاموش کردن VPN
        val stopIntent = Intent(this, MyVpnService::class.java).apply { action = "FORCE_STOP" }
        val stopPendingIntent = android.app.PendingIntent.getService(
            this, 1, stopIntent, android.app.PendingIntent.FLAG_IMMUTABLE
        )

        val actionIcon = android.R.drawable.ic_menu_close_clear_cancel
        val actionTitle = "خاموش کردن VPN"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fire_dns_vpn"
            val channelName = "Fire DNS VPN"
            val manager = getSystemService(NotificationManager::class.java)
            if (manager?.getNotificationChannel(channelId) == null) {
                val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
                manager.createNotificationChannel(channel)
            }
            Notification.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(smallIcon)
                .setOngoing(true)
                .setContentIntent(mainPendingIntent)
                .addAction(actionIcon, actionTitle, stopPendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(smallIcon)
                .setOngoing(true)
                .setContentIntent(mainPendingIntent)
                .addAction(actionIcon, actionTitle, stopPendingIntent)
                .build()
        }
    }

    override fun onDestroy() {
        // آزادسازی منابع
        // بستن اتصال VPN
        // متوقف کردن سرویس foreground
        // اعلام وضعیت توقف
        Log.d("FireDNS", "MyVpnService onDestroy called")
        Log.d("FireDNS", "Stopping VPN service, releasing resources.")
        
        // حذف تمام نوتیفیکیشن‌ها
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.cancel(NOTIFICATION_ID)
        notificationManager?.cancel(ERROR_NOTIFICATION_ID)
        notificationManager?.cancel(RECONNECT_NOTIFICATION_ID)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        try {
            vpnInterface?.close()
            Log.d("FireDNS", "vpnInterface closed successfully.")
        } catch (e: Exception) {
            Log.e("FireDNS", "Error closing vpnInterface: ${e.message}")
        }
        vpnInterface = null
        isRunning = false
        
        // Notify status change on main thread
        CoroutineScope(Dispatchers.Main).launch {
            statusListener?.invoke("DNS_STOPPED")
            Log.d("FireDNS", "Status listener notified: DNS_STOPPED (onDestroy)")
        }

        // حذف ثبت خاموش شدن دستی اگر سرویس destroy شد (مثلاً توسط سیستم)
        if (!userStoppedService) {
            userStoppedService = false
        }

        // حذف ثبت BroadcastReceiver
        try {
            unregisterReceiver(networkReceiver)
            unregisterReceiver(batteryReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
    
    override fun onCreate() {
        super.onCreate()
        // ثبت BroadcastReceiver برای تغییرات شبکه
        val networkFilter = android.content.IntentFilter(android.net.ConnectivityManager.CONNECTIVITY_ACTION)
        registerReceiver(networkReceiver, networkFilter)
        
        // ثبت BroadcastReceiver برای تغییرات باتری
        val batteryFilter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(android.os.PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        }
        registerReceiver(batteryReceiver, batteryFilter)
        
        // راه‌اندازی سرویس بررسی دوره‌ای اتصال
        // Start connection monitoring in a coroutine
        CoroutineScope(Dispatchers.Default).launch {
            startConnectionMonitoring()
        }
    }
    
    // تنظیم سرویس بر اساس سطح باتری
    private fun adjustServiceBasedOnBattery(batteryLevel: Int) {
        when {
            batteryLevel <= 15 -> {
                // حالت صرفه‌جویی شدید
                Log.d("FireDNS", "Entering extreme battery saving mode")
                // کاهش فرکانس به‌روزرسانی‌ها و عملیات‌های پس‌زمینه
            }
            batteryLevel <= 30 -> {
                // حالت صرفه‌جویی متوسط
                Log.d("FireDNS", "Entering moderate battery saving mode")
            }
        }
    }
    
    // تنظیم سرویس بر اساس حالت صرفه‌جویی انرژی
    private fun adjustServiceBasedOnPowerMode(isLowPowerMode: Boolean) {
        if (isLowPowerMode) {
            Log.d("FireDNS", "Device is in power save mode, adjusting service")
            // کاهش عملیات‌های پس‌زمینه
        } else {
            Log.d("FireDNS", "Device exited power save mode, restoring normal operation")
            // بازگشت به حالت عادی
        }
    }
    
    /**
     * نمایش نوتیفیکیشن برای قطعی اتصال
     * @param title عنوان نوتیفیکیشن
     * @param message پیام نوتیفیکیشن
     */
    private fun showDisconnectionNotification(title: String, message: String) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fire_dns_error"
            val channelName = "Fire DNS Errors"
            if (notificationManager?.getNotificationChannel(channelId) == null) {
                val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
                notificationManager.createNotificationChannel(channel)
            }
            Notification.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setOngoing(true)
                .build()
        }
        
        notificationManager?.notify(ERROR_NOTIFICATION_ID, notification)
    }
    
    /**
     * نمایش نوتیفیکیشن برای اتصال مجدد
     */
    private fun showReconnectionNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fire_dns_reconnect"
            val channelName = "Fire DNS Reconnection"
            if (notificationManager?.getNotificationChannel(channelId) == null) {
                val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
                notificationManager.createNotificationChannel(channel)
            }
            Notification.Builder(this, channelId)
                .setContentTitle("اتصال مجدد برقرار شد")
                .setContentText("سرویس VPN با موفقیت مجدداً راه‌اندازی شد.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setTimeoutAfter(5000) // نوتیفیکیشن بعد از 5 ثانیه ناپدید می‌شود
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("اتصال مجدد برقرار شد")
                .setContentText("سرویس VPN با موفقیت مجدداً راه‌اندازی شد.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()
        }
        
        notificationManager?.notify(RECONNECT_NOTIFICATION_ID, notification)
    }
    
    /**
     * توقف VPN بدون حذف نوتیفیکیشن
     * این تابع VPN را متوقف می‌کند اما نوتیفیکیشن را حفظ می‌کند تا کاربر بتواند وضعیت را ببیند
     */
    private fun stopVpnButKeepNotification() {
        try {
            Log.d("FireDNS", "Stopping VPN but keeping notification...")
            
            // بستن رابط VPN
            vpnInterface?.close()
            vpnInterface = null
            
            // به‌روزرسانی وضعیت
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            
            // حذف نوتیفیکیشن اصلی اما حفظ نوتیفیکیشن خطا
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            
            // توقف سرویس foreground بدون حذف نوتیفیکیشن
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                stopForeground(STOP_FOREGROUND_DETACH)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(false)
            }
            
            Log.d("FireDNS", "VPN stopped but notification kept")
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in stopVpnButKeepNotification: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
        }
    }
    
    /**
     * راه‌اندازی سیستم نظارت بر اتصال
     * این تابع یک کوروتین راه‌اندازی می‌کند که به صورت دوره‌ای اتصال را بررسی می‌کند
     */
    private fun startConnectionMonitoring() {
        CoroutineScope(Dispatchers.Default).launch {
            try {
                Log.d("FireDNS", "Starting connection monitoring service")
                while (true) {
                    // بررسی وضعیت اتصال هر 30 ثانیه
                    delay(30000)
                    
                    // اگر سرویس در حال اجرا نیست، نیازی به بررسی نیست
                    if (!isRunning) continue
                    
                    // بررسی اتصال اینترنت
                    Log.d("FireDNS", "Checking connection status...")
                    val connectivityManager = getSystemService(android.content.Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                    val activeNetwork = connectivityManager.activeNetworkInfo
                    val isConnected = activeNetwork?.isConnectedOrConnecting == true
                    
                    if (!isConnected) {
                        Log.e("FireDNS", "Network connection lost")
                        connectionLostReason = ConnectionLostReason.INTERNET_DISCONNECTED
                        
                        // Switch to main thread for UI operations
                        withContext(Dispatchers.Main) {
                            showDisconnectionNotification("قطعی اینترنت", "اتصال اینترنت قطع شده است. به محض برقراری اتصال، سرویس VPN مجدداً راه‌اندازی خواهد شد.")
                            stopVpnButKeepNotification()
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("FireDNS", "Error in connection monitoring: ${e.message}")
            }
        }
    }
}