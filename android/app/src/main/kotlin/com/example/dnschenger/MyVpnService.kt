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
        
        // تنظیمات پایه VPN
        private const val DNS_VPN_CONNECTION_NAME = "FireDNS VPN"
        // آدرس داخلی غیر رایج برای جلوگیری از تداخل با شبکه‌های محلی
        private const val VPN_ADDRESS = "10.88.229.2"
        
        // سرورهای DNS پیش‌فرض گوگل
        const val DEFAULT_PRIMARY_DNS = "8.8.8.8"      // Google DNS Primary
        const val DEFAULT_SECONDARY_DNS = "8.8.4.4"    // Google DNS Secondary
        // متغیر برای تشخیص خاموش شدن دستی توسط کاربر
        var userStoppedService: Boolean = false
    }

    // رابط VPN که برای اتصال استفاده می‌شود
    private var vpnInterface: ParcelFileDescriptor? = null

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
     * تست اتصال اینترنت و عملکرد DNS
     * این تابع سه تست انجام می‌دهد:
     * 1. تست اتصال پایه با پینگ به 8.8.8.8
     * 2. تست اتصال به گوگل
     * 3. تست عملکرد DNS با nslookup
     */
    private fun testInternetConnectivity() {
        try {
            Log.d("FireDNS", "Testing internet connectivity after VPN setup...")
            
            // تست اتصال پایه با پینگ
            val pingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 8.8.8.8")
            val pingExitCode = pingProcess.waitFor()
            if (pingExitCode == 0) {
                Log.d("FireDNS", "✅ Basic internet connectivity test PASSED")
            } else {
                Log.e("FireDNS", "❌ Basic internet connectivity test FAILED")
            }
            
            // تست اتصال به گوگل برای اطمینان از کارکرد DNS
            Log.d("FireDNS", "Testing Google connectivity...")
            val googlePingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 google.com")
            val googleExitCode = googlePingProcess.waitFor()
            if (googleExitCode == 0) {
                Log.d("FireDNS", "✅ Google connectivity test PASSED")
            } else {
                Log.e("FireDNS", "❌ Google connectivity test FAILED - DNS resolution issue")
            }
            
            // تست مستقیم عملکرد DNS
            Log.d("FireDNS", "Testing DNS resolution...")
            val nslookupProcess = Runtime.getRuntime().exec("nslookup google.com")
            val nslookupExitCode = nslookupProcess.waitFor()
            if (nslookupExitCode == 0) {
                Log.d("FireDNS", "✅ DNS resolution test PASSED")
            } else {
                Log.e("FireDNS", "❌ DNS resolution test FAILED")
            }
            
        } catch (e: Exception) {
            Log.e("FireDNS", "Connectivity test failed with exception: ${e.message}")
        }
    }



    /**
     * توقف اجباری سرویس VPN
     * این تابع تمام منابع را آزاد کرده و سرویس را متوقف می‌کند
     */
    private fun forceStop() {
        try {
            // ثبت شروع عملیات توقف
            Log.d("FireDNS", "Force stopping VPN service...")
            
            // بستن رابط VPN
            vpnInterface?.close()
            vpnInterface = null
            
            // به‌روزرسانی وضعیت
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            
            // حذف نوتیفیکیشن با توجه به نسخه اندروید
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            
            // توقف کامل سرویس
            stopSelf()
            Log.d("FireDNS", "VPN service force stopped successfully")
        } catch (e: Exception) {
            // مدیریت خطاها در زمان توقف سرویس
            Log.e("FireDNS", "Error in force stop: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            stopSelf()
        }

            // ثبت خاموش شدن دستی توسط کاربر
            userStoppedService = true
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
            userStoppedService = true

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
        // اگر سرویس به صورت خودکار استارت شده، مقدار userStoppedService را false کن
        userStoppedService = false
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
                statusListener?.invoke("VPN_STARTED")
                testInternetConnectivity() // Test internet connectivity after VPN setup
                return START_STICKY
            } else {
                Log.e("FireDNS", "Failed to establish VPN interface")
                isRunning = false
                statusListener?.invoke("DNS_STOPPED")
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
        
        // حذف نوتیفیکیشن
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.cancel(NOTIFICATION_ID)
        
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
        statusListener?.invoke("DNS_STOPPED")

        // حذف ثبت خاموش شدن دستی اگر سرویس destroy شد (مثلاً توسط سیستم)
        if (!userStoppedService) {
            userStoppedService = false
        }

        // حذف ثبت BroadcastReceiver
        try {
            unregisterReceiver(networkReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
    override fun onCreate() {
        super.onCreate()
        // ثبت BroadcastReceiver برای تغییرات شبکه
        val filter = android.content.IntentFilter(android.net.ConnectivityManager.CONNECTIVITY_ACTION)
        registerReceiver(networkReceiver, filter)
    }
}