// MyVpnService.kt
package com.example.firedns

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*
import android.os.BatteryManager
import android.os.PowerManager
import android.net.ConnectivityManager
import java.net.InetAddress
import java.lang.Math

class MyVpnService : VpnService() {
    companion object {
        var isRunning: Boolean = false
        
        var statusListener: ((String) -> Unit)? = null
        
        private const val NOTIFICATION_CHANNEL_ID = "FireDNS_VPN"
        private const val NOTIFICATION_ID = 1
        private const val ERROR_NOTIFICATION_ID = 2
        private const val RECONNECT_NOTIFICATION_ID = 3
        
        private const val VPN_ADDRESS = "10.88.229.2"
        
        const val DEFAULT_PRIMARY_DNS = "8.8.8.8"
        const val DEFAULT_SECONDARY_DNS = "8.8.4.4"
        var userStoppedService: Boolean = false
        
        enum class ConnectionLostReason {
            NONE,
            INTERNET_DISCONNECTED,
            DNS_UNREACHABLE,
            DNS_NOT_WORKING,
            UNKNOWN_ERROR
        }
    }
    
    private var vpnInterface: ParcelFileDescriptor? = null
    
    private var connectionLostReason: ConnectionLostReason = ConnectionLostReason.NONE
    
    private var lastReconnectAttempt: Long = 0
    
    private var lastNetworkType: Int = -1
    private var lastBatteryLevel: Int = -1
    private var isLowPowerMode: Boolean = false
    private var dataUsageBytes: Long = 0
    private var lastDataUsageUpdate: Long = 0
    
    private val networkReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val cm = context?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
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
    
    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val batteryPct = level * 100 / scale
                
                if (lastBatteryLevel != -1 && Math.abs(batteryPct - lastBatteryLevel) >= 10) {
                    Log.d("FireDNS", "Battery level changed significantly: $lastBatteryLevel -> $batteryPct")
                    adjustServiceBasedOnBattery(batteryPct)
                }
                
                lastBatteryLevel = batteryPct
            } else if (intent?.action == PowerManager.ACTION_POWER_SAVE_MODE_CHANGED) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                isLowPowerMode = powerManager.isPowerSaveMode
                Log.d("FireDNS", "Power save mode changed: $isLowPowerMode")
                adjustServiceBasedOnPowerMode(isLowPowerMode)
            }
        }
    }
    
    private fun isValidIpAddress(ip: String): Boolean {
        return try {
            if (ip == "0.0.0.0") return false
            
            val parts = ip.split(".")
            if (parts.size != 4) return false
            
            parts.all { part ->
                part.toInt() in 0..255
            }
        } catch (e: Exception) {
            false
        }
    }
    
    private fun testInternetConnectivity() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d("FireDNS", "Testing internet connectivity after VPN setup...")
                
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
                
                val dnsResult = async {
                    try {
                        val inetAddress = InetAddress.getByName("google.com")
                        val isReachable = inetAddress != null
                        Log.d("FireDNS", "DNS resolution test using InetAddress: ${inetAddress?.hostAddress}")
                        isReachable
                    } catch (e: Exception) {
                        Log.e("FireDNS", "DNS resolution test failed with exception", e)
                        false
                    }
                }
                
                val basicConnectivity = withTimeoutOrNull(5000) { pingResult.await() } ?: false
                val googleConnectivity = withTimeoutOrNull(5000) { googleResult.await() } ?: false
                val dnsResolution = withTimeoutOrNull(5000) { dnsResult.await() } ?: false
                
                if (basicConnectivity) {
                    Log.d("FireDNS", "Basic internet connectivity test PASSED")
                } else {
                    Log.e("FireDNS", "Basic internet connectivity test FAILED")
                    withContext(Dispatchers.Main) {
                        showDisconnectionNotification("قطعی اینترنت", "اتصال اینترنت قطع شده است. به محض برقراری اتصال، سرویس VPN مجدداً راه‌اندازی خواهد شد.")
                        stopVpnButKeepNotification()
                    }
                    return@launch
                }
                
                if (googleConnectivity) {
                    Log.d("FireDNS", "Google connectivity test PASSED")
                } else {
                    Log.e("FireDNS", "Google connectivity test FAILED - DNS resolution issue")
                    if (basicConnectivity) {
                        withContext(Dispatchers.Main) {
                            showDisconnectionNotification("مشکل در سرور DNS", "سرور DNS در دسترس نیست. در حال تلاش برای اتصال مجدد...")
                            stopVpnButKeepNotification()
                        }
                        return@launch
                    }
                }
                
                if (dnsResolution) {
                    Log.d("FireDNS", "DNS resolution test PASSED")
                } else {
                    Log.e("FireDNS", "DNS resolution test FAILED")
                    if (basicConnectivity) {
                        withContext(Dispatchers.Main) {
                            showDisconnectionNotification("مشکل در عملکرد DNS", "سیستم DNS به درستی کار نمی‌کند. در حال تلاش برای اتصال مجدد...")
                            stopVpnButKeepNotification()
                        }
                        return@launch
                    }
                }
                
                val overallSuccess = basicConnectivity && (googleConnectivity || dnsResolution)
                
                withContext(Dispatchers.Main) {
                    if (overallSuccess) {
                        statusListener?.invoke("DNS_TEST_SUCCESS")
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
                
                withContext(Dispatchers.Main) {
                    statusListener?.invoke("DNS_TEST_FAILED")
                    showDisconnectionNotification("خطای ناشناخته", "خطایی در سرویس VPN رخ داده است: ${e.message}")
                    connectionLostReason = ConnectionLostReason.UNKNOWN_ERROR
                    stopVpnButKeepNotification()
                }
            }
        }
    }
    
    private fun forceStop() {
        try {
            userStoppedService = true
            
            Log.d("FireDNS", "Force stopping VPN service...")
            
            vpnInterface?.close()
            vpnInterface = null
            
            isRunning = false
            
            CoroutineScope(Dispatchers.Main).launch {
                statusListener?.invoke("DNS_STOPPED")
                Log.d("FireDNS", "Status listener notified: DNS_STOPPED (force stop)")
            }
            
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
            
            connectionLostReason = ConnectionLostReason.NONE
            
            stopSelf()
            Log.d("FireDNS", "VPN service force stopped successfully")
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in force stop: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            notificationManager?.cancel(ERROR_NOTIFICATION_ID)
            notificationManager?.cancel(RECONNECT_NOTIFICATION_ID)
            
            stopSelf()
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "FORCE_STOP") {
            Log.d("FireDNS", "Force stop requested")
            forceStop()
            return START_NOT_STICKY
        }
        
        var dns1 = intent?.getStringExtra("dns1") ?: DEFAULT_PRIMARY_DNS
        var dns2 = intent?.getStringExtra("dns2") ?: DEFAULT_SECONDARY_DNS
        
        userStoppedService = false
        
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
        val notificationId = 1
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(notificationId, notification)
        }
        try {
            Log.d("FireDNS", "Setting up VPN configuration (NetShift style)")
            val builder = Builder()
                .setSession("FireDNSVPN")
                .addAddress("10.0.0.2", 24)
                .setConfigureIntent(android.app.PendingIntent.getActivity(
                    this, 0,
                    Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                    android.app.PendingIntent.FLAG_IMMUTABLE
                ))
            Log.d("FireDNS", "Setting DNS servers: $dns1, $dns2")
            builder.addDnsServer(dns1)
            if (dns2.isNotEmpty()) {
                builder.addDnsServer(dns2)
            }
            builder.addDisallowedApplication(packageName)
            Log.d("FireDNS", "Excluding self app from VPN: $packageName")
            Log.d("FireDNS", "Establishing VPN connection...")
            vpnInterface = builder.establish()
            if (vpnInterface != null) {
                Log.d("FireDNS", "VPN interface established successfully")
                Log.d("FireDNS", "DNS servers active: $dns1, $dns2")
                isRunning = true
                
                CoroutineScope(Dispatchers.Main).launch {
                    delay(100)
                    statusListener?.invoke("VPN_STARTED")
                    Log.d("FireDNS", "Status listener notified: VPN_STARTED")
                }
                
                testInternetConnectivity()
                return START_STICKY
            } else {
                Log.e("FireDNS", "Failed to establish VPN interface")
                isRunning = false
                
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
        val iconRes = resources.getIdentifier("ic_launcher", "drawable", packageName)
        val smallIcon = if (iconRes != 0) iconRes else android.R.drawable.ic_menu_manage
        val title = "فایر دی‌ان‌اس فعال است"
        val text = "سرویس DNS در حال اجراست"
        val mainIntent = Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val mainPendingIntent = android.app.PendingIntent.getActivity(
            this, 0, mainIntent, android.app.PendingIntent.FLAG_IMMUTABLE
        )
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
        Log.d("FireDNS", "MyVpnService onDestroy called")
        Log.d("FireDNS", "Stopping VPN service, releasing resources.")
        
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
        
        CoroutineScope(Dispatchers.Main).launch {
            statusListener?.invoke("DNS_STOPPED")
            Log.d("FireDNS", "Status listener notified: DNS_STOPPED (onDestroy)")
        }
        if (!userStoppedService) {
            userStoppedService = false
        }
        try {
            unregisterReceiver(networkReceiver)
            unregisterReceiver(batteryReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
    
    private fun adjustServiceBasedOnBattery(batteryLevel: Int) {
        when {
            batteryLevel <= 15 -> {
                Log.d("FireDNS", "Entering extreme battery saving mode: $batteryLevel")
            }
            batteryLevel <= 30 -> {
                Log.d("FireDNS", "Entering moderate battery saving mode: $batteryLevel")
            }
        }
    }
    
    private fun adjustServiceBasedOnPowerMode(isLowPowerMode: Boolean) {
        if (isLowPowerMode) {
            Log.d("FireDNS", "Device is in power save mode, adjusting service")
        } else {
            Log.d("FireDNS", "Device exited power save mode, restoring normal operation")
        }
    }
    
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
                .setContentText("سرویس سرویس با موفقیت مجدداً راه‌اندازی شد.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setTimeoutAfter(5000)
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
    
    private fun stopVpnButKeepNotification() {
        try {
            Log.d("FireDNS", "Stopping VPN but keeping notification...")
            
            vpnInterface?.close()
            vpnInterface = null
            
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.cancel(NOTIFICATION_ID)
            
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
    
    private fun startConnectionMonitoring() {
        CoroutineScope(Dispatchers.Default).launch {
            try {
                Log.d("FireDNS", "Starting connection monitoring service")
                while (true) {
                    delay(15000) // هر 15 ثانیه
                    
                    if (!isRunning) continue
                    
                    Log.d("FireDNS", "Checking connection status...")
                    val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val activeNetwork = connectivityManager.activeNetworkInfo
                    val isConnected = activeNetwork?.isConnectedOrConnecting == true
                    
                    if (!isConnected) {
                        Log.e("FireDNS", "Network connection lost")
                        connectionLostReason = ConnectionLostReason.INTERNET_DISCONNECTED
                        
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