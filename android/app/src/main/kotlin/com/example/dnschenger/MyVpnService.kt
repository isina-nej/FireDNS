package com.example.dnschenger

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

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
        try {
            Log.d("FireDNS", "Testing internet connectivity after VPN setup...")
            
            // Test basic connectivity
            val pingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 8.8.8.8")
            val pingExitCode = pingProcess.waitFor()
            if (pingExitCode == 0) {
                Log.d("FireDNS", "✅ Basic internet connectivity test PASSED")
            } else {
                Log.e("FireDNS", "❌ Basic internet connectivity test FAILED")
            }
            
            // Test Google connectivity specifically
            Log.d("FireDNS", "Testing Google connectivity...")
            val googlePingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 google.com")
            val googleExitCode = googlePingProcess.waitFor()
            if (googleExitCode == 0) {
                Log.d("FireDNS", "✅ Google connectivity test PASSED")
            } else {
                Log.e("FireDNS", "❌ Google connectivity test FAILED - DNS resolution issue")
            }
            
            // Test DNS resolution specifically
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

    companion object {
        var isRunning: Boolean = false
        var statusListener: ((String) -> Unit)? = null
        
        // DNS servers
        const val DEFAULT_PRIMARY_DNS = "178.22.122.100"    // Shecan
        const val DEFAULT_SECONDARY_DNS = "1.1.1.1"         // Cloudflare
    }

    private fun forceStop() {
        try {
            Log.d("FireDNS", "Force stopping VPN service...")
            vpnInterface?.close()
            vpnInterface = null
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            Log.d("FireDNS", "VPN service force stopped successfully")
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in force stop: ${e.message}")
            isRunning = false
            statusListener?.invoke("DNS_STOPPED")
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

        // اعتبارسنجی DNS ها
        if (!isValidIpAddress(dns1)) {
            Log.w("FireDNS", "Invalid primary DNS: $dns1, using default")
            dns1 = DEFAULT_PRIMARY_DNS
        }
        if (!isValidIpAddress(dns2)) {
            Log.w("FireDNS", "Invalid secondary DNS: $dns2, using default")
            dns2 = DEFAULT_SECONDARY_DNS
        }

        Log.d("FireDNS", "MyVpnService onStartCommand: dns1=$dns1, dns2=$dns2")

        // ساخت notification برای سرویس foreground
        val notificationId = 1
        val notification = createNotification()
        startForeground(notificationId, notification)

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
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fire_dns_vpn"
            val channelName = "Fire DNS VPN"
            val manager = getSystemService(NotificationManager::class.java)
            if (manager?.getNotificationChannel(channelId) == null) {
                val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
                manager.createNotificationChannel(channel)
            }
            Notification.Builder(this, channelId)
                .setContentTitle("Fire DNS Active")
                .setContentText("DNS VPN Service is running")
                .setSmallIcon(android.R.drawable.ic_menu_manage)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Fire DNS Active")
                .setContentText("DNS VPN Service is running")
                .setSmallIcon(android.R.drawable.ic_menu_manage)
                .build()
        }
    }

    override fun onDestroy() {
        Log.d("FireDNS", "MyVpnService onDestroy called")
        Log.d("FireDNS", "Stopping VPN service, releasing resources.")
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
        super.onDestroy()
    }
}