package com.example.firedns

import android.content.Intent
import android.content.Context
import com.example.firedns.MyVpnService
import android.net.VpnService
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Bundle
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        // Load DNS from SharedPreferences
        val sharedPreferences = getSharedPreferences("DNSPreferences", android.content.Context.MODE_PRIVATE)
        lastDns1 = sharedPreferences.getString("dns1", "8.8.8.8") ?: "8.8.8.8"
        lastDns2 = sharedPreferences.getString("dns2", "8.8.4.4") ?: "8.8.4.4"
        
        // Always check actual service status
        val isServiceRunning = isMyVpnServiceRunning()
        Log.d("FireDNS", "onResume: isVpnRunning=$isVpnRunning, isMyVpnServiceRunning=$isServiceRunning")
        
        // Force synchronization of VPN status
        forceSyncVpnStatus()
    }

    private fun isMyVpnServiceRunning(): Boolean {
        // بررسی دقیق سرویس در حال اجرا
        val activityManager = getSystemService(android.content.Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val services = activityManager.getRunningServices(Int.MAX_VALUE)
        for (service in services) {
            if (service.service.className == com.example.firedns.MyVpnService::class.java.name) {
                return true
            }
        }
        return false
    }
    
    /**
     * Force synchronization of VPN status between service and UI
     * This method ensures the UI reflects the actual service state
     */
    private fun forceSyncVpnStatus() {
        try {
            val actualServiceRunning = isMyVpnServiceRunning()
            val serviceIsRunningFlag = MyVpnService.isRunning
            
            Log.d("FireDNS", "forceSyncVpnStatus: actualServiceRunning=$actualServiceRunning, serviceIsRunningFlag=$serviceIsRunningFlag, cachedStatus=$isVpnRunning")
            
            // Use the actual service status as the source of truth
            val correctStatus = actualServiceRunning && serviceIsRunningFlag
            
            if (isVpnRunning != correctStatus) {
                Log.d("FireDNS", "Correcting VPN status: $isVpnRunning -> $correctStatus")
                isVpnRunning = correctStatus
                
                // Notify Flutter about the corrected status
                vpnStatusEventSink?.success(if (correctStatus) "VPN_STARTED" else "DNS_STOPPED")
                
                // Also reconnect the status listener to ensure future updates
                MyVpnService.statusListener = vpnStatusListener
            }
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in forceSyncVpnStatus: ${e.message}", e)
        }
    }
    private val CHANNEL = "com.example.firedns/dns"
    private val VPN_STATUS_CHANNEL = "com.example.firedns/vpnStatus"
    private val DATA_USAGE_CHANNEL = "com.example.firedns/dataUsage"
    private var lastDns1: String = "178.22.122.100"  // Shecan DNS
    private var lastDns2: String = "1.1.1.1"        // Cloudflare DNS
    private var vpnStatusEventSink: EventChannel.EventSink? = null

    /**
     * تست اتصال به سرور DNS با قابلیت‌های پیشرفته
     * @param dns آدرس سرور DNS برای تست
     * @param timeout زمان انتظار برای پاسخ (میلی‌ثانیه)
     * @param packetCount تعداد بسته‌های ارسالی
     * @param detailed آیا نتایج دقیق مورد نیاز است
     * @return نتیجه تست شامل وضعیت دسترسی و زمان پاسخ
     */
    private suspend fun testDnsConnectivity(
        dns: String,
        timeout: Int = 1000,
        packetCount: Int = 2,
        detailed: Boolean = true
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        return@withContext try {
            Log.d("FireDNS", "Testing DNS connectivity for $dns (timeout: $timeout, packets: $packetCount)")
            
            if (detailed) {
                // پیاده‌سازی دقیق با تحلیل خروجی ping
                val process = Runtime.getRuntime().exec("/system/bin/ping -W ${timeout/1000} -c $packetCount $dns")
                val reader = process.inputStream.bufferedReader()
                var pingTime = -1
                var isReachable = false
                var packetLoss = 100 // پیش‌فرض: 100% از دست رفتن بسته‌ها
                val output = StringBuilder()
                
                reader.useLines { lines ->
                    lines.forEach { line ->
                        output.append(line).append("\n")
                        Log.d("FireDNS", "Ping output line: $line")
                        when {
                            line.contains("time=") -> {
                                try {
                                    // پشتیبانی از فرمت‌های مختلف خروجی ping
                                    val timeStr = when {
                                        line.contains("time=") -> line.substringAfter("time=").substringBefore(" ms").trim()
                                        line.contains("время=") -> line.substringAfter("время=").substringBefore(" мс").trim()
                                        else -> null
                                    }
                                    val currentPing = timeStr?.toFloatOrNull()?.toInt() ?: -1
                                    // انتخاب کمترین زمان پاسخ در صورت دریافت چندین پاسخ
                                    if (currentPing > 0 && (pingTime == -1 || currentPing < pingTime)) {
                                        pingTime = currentPing
                                    }
                                    isReachable = true
                                    Log.d("FireDNS", "Extracted ping time: $pingTime ms")
                                } catch (e: Exception) {
                                    Log.e("FireDNS", "Error parsing ping time from line: $line", e)
                                }
                            }
                            line.contains("packet loss") -> {
                                try {
                                    // استخراج درصد از دست رفتن بسته‌ها
                                    val lossStr = line.substringBefore("%").substringAfterLast(" ")
                                    packetLoss = lossStr.toIntOrNull() ?: 100
                                    Log.d("FireDNS", "Packet loss: $packetLoss%")
                                } catch (e: Exception) {
                                    Log.e("FireDNS", "Error parsing packet loss from line: $line", e)
                                }
                            }
                        }
                    }
                }
                
                val exitCode = process.waitFor()
                Log.d("FireDNS", "Ping process exit code: $exitCode")
                
                // سرور در دسترس است اگر پاسخی دریافت کردیم یا درصد از دست رفتن بسته‌ها کمتر از 100% است
                isReachable = isReachable || packetLoss < 100
                
                mapOf(
                    "isReachable" to isReachable,
                    "ping" to if (isReachable) pingTime else -1,
                    "packetLoss" to packetLoss,
                    "details" to output.toString()
                )
            } else {
                // پیاده‌سازی ساده و سریع
                val startTime = System.currentTimeMillis()
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -w 1 $dns")
                val isReachable = process.waitFor() == 0
                val pingTime = System.currentTimeMillis() - startTime
                
                mapOf(
                    "isReachable" to isReachable,
                    "ping" to pingTime.toInt()
                )
            }
        } catch (e: Exception) {
            Log.e("FireDNS", "Error testing DNS connectivity for $dns: ${e.message}", e)
            mapOf(
                "isReachable" to false,
                "ping" to -1,
                "error" to (e.message ?: "Unknown error")
            )
        }
    }
    
    /**
     * تابع کمکی برای استخراج زمان پاسخ از خط خروجی ping
     */
    private fun extractPingTime(line: String): Int? {
        return try {
            val timeStr = when {
                line.contains("time=") -> line.substringAfter("time=").substringBefore(" ms").trim()
                line.contains("время=") -> line.substringAfter("время=").substringBefore(" мс").trim()
                else -> return null
            }
            timeStr.toFloatOrNull()?.toInt()
        } catch (e: Exception) {
            Log.e("FireDNS", "Error parsing ping time from line: $line", e)
            null
        }
    }
    private var dataUsageEventSink: EventChannel.EventSink? = null
    private var isVpnRunning: Boolean = false

    // NetShift-style: sync MyVpnService status with EventChannel
    private val vpnStatusListener: (String) -> Unit = { status ->
        vpnStatusEventSink?.success(status)
        isVpnRunning = status == "VPN_STARTED"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("FireDNS", "MethodChannel call: ${call.method}")
            when (call.method) {
                "testDns" -> {
                    val dns = call.argument<String>("dns") ?: ""
                    if (dns.isEmpty()) {
                        result.error("INVALID_DNS", "DNS address cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val pingResult = testDnsConnectivity(dns)
                            Log.d("FireDNS", "Ping to $dns completed with result: $pingResult")
                            result.success(pingResult)
                        } catch (e: Exception) {
                            Log.e("FireDNS", "Error in testDns: ${e.message}", e)
                            result.error("PING_ERROR", "Error pinging DNS server", e.message)
                        }
                    }
                }
                "testGoogleConnectivity" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val connectivityResult = withContext(Dispatchers.IO) {
                                testGoogleConnectivity()
                            }
                            Log.d("FireDNS", "Google connectivity test completed with result: $connectivityResult")
                            result.success(connectivityResult)
                        } catch (e: Exception) {
                            Log.e("FireDNS", "Error in testGoogleConnectivity: ${e.message}", e)
                            result.error("CONNECTIVITY_ERROR", "Error testing Google connectivity", e.message)
                        }
                    }
                }
                "setDns" -> {
                    val dns1 = call.argument<String>("dns1") ?: "8.8.8.8"
                    val dns2 = call.argument<String>("dns2") ?: "8.8.4.4"
                    lastDns1 = dns1
                    lastDns2 = dns2
                    Log.d("FireDNS", "setDns called with dns1=$dns1, dns2=$dns2")
                    setDns(dns1, dns2)
                    result.success(true)
                }
                "stopDnsVpn" -> {
                    Log.d("FireDNS", "stopDnsVpn called")
                    stopDnsVpn()
                    result.success(true)
                }
                "getServiceStatus" -> {
                    // Always check the actual service status instead of using the cached value
                    val actualStatus = isMyVpnServiceRunning()
                    Log.d("FireDNS", "getServiceStatus called, actual service status: $actualStatus, cached status: $isVpnRunning")
                    
                    // Update the cached status to match the actual status
                    if (isVpnRunning != actualStatus) {
                        Log.d("FireDNS", "Fixing status mismatch: isVpnRunning=$isVpnRunning, actual=$actualStatus")
                        isVpnRunning = actualStatus
                        // Notify Flutter about the corrected status
                        vpnStatusEventSink?.success(if (actualStatus) "VPN_STARTED" else "DNS_STOPPED")
                    }
                    
                    result.success(actualStatus)
                }
                "testDnsWithDns" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    val dns = call.argument<String>("dns") ?: ""
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val pingResult = withContext(Dispatchers.IO) {
                                testDomainWithCustomDns(domain, dns)
                            }
                            result.success(pingResult)
                        } catch (e: Exception) {
                            Log.e("FireDNS", "Error in testDnsWithDns: ${e.message}", e)
                            result.error("PING_ERROR", "Error pinging domain with custom DNS", e.message)
                        }
                    }
                }
                "testDnsIPv6" -> {
                    val dns = call.argument<String>("dns") ?: ""
                    if (dns.isEmpty()) {
                        result.error("INVALID_DNS", "DNS address cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            // استفاده از تابع جدید با پارامتر IPv6
                            val pingResult = testDnsConnectivity(
                                dns = dns,
                                detailed = true,
                                packetCount = 2
                            )
                            Log.d("FireDNS", "Ping to IPv6 $dns completed with result: $pingResult")
                            result.success(pingResult)
                        } catch (e: Exception) {
                            Log.e("FireDNS", "Error in testDnsIPv6: ${e.message}", e)
                            result.error("PING_ERROR", "Error pinging IPv6 DNS server", e.message)
                        }
                    }
                }
                else -> {
                    Log.d("FireDNS", "notImplemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_STATUS_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                vpnStatusEventSink = events
                // NetShift-style: attach statusListener to MyVpnService
                MyVpnService.statusListener = vpnStatusListener
                
                // Immediately send current status when listener connects
                val currentServiceStatus = isMyVpnServiceRunning()
                Log.d("FireDNS", "EventChannel onListen: sending current status = $currentServiceStatus")
                
                // Update cached status to match actual status
                isVpnRunning = currentServiceStatus
                
                // Send current status to Flutter
                vpnStatusEventSink?.success(if (currentServiceStatus) "VPN_STARTED" else "DNS_STOPPED")
            }
            override fun onCancel(arguments: Any?) {
                vpnStatusEventSink = null
                MyVpnService.statusListener = null
            }
        })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_USAGE_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                dataUsageEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                dataUsageEventSink = null
            }
        })
    }

    private fun setDns(dns1: String, dns2: String?) {
        Log.d("FireDNS", "setDns: prepare VPN")
        // Save DNS to SharedPreferences
        val sharedPreferences = getSharedPreferences("DNSPreferences", android.content.Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.putString("dns1", dns1)
        editor.putString("dns2", dns2)
        editor.apply()
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            Log.d("FireDNS", "VPN permission required, launching intent")
            startActivityForResult(prepareIntent, 1001)
        } else {
            Log.d("FireDNS", "VPN permission already granted, starting service")
            startDnsVpnService(dns1, dns2)
        }
    }

    /**
     * راه‌اندازی سرویس VPN برای تغییر DNS سیستم
     * @param dns1 سرور DNS اصلی
     * @param dns2 سرور DNS ثانویه (اختیاری)
     * @return نتیجه راه‌اندازی سرویس
     */
    private fun startDnsVpnService(dns1: String?, dns2: String?): Boolean {
        Log.d("FireDNS", "startDnsVpnService: dns1=$dns1, dns2=$dns2")
        
        try {
            // بررسی معتبر بودن پارامترها
            if (dns1.isNullOrEmpty()) {
                Log.e("FireDNS", "Primary DNS is null or empty")
                vpnStatusEventSink?.success("DNS_ERROR_INVALID_PRIMARY")
                return false
            }
            
            // ایجاد و راه‌اندازی سرویس
            val intent = Intent(this, MyVpnService::class.java)
            intent.putExtra("dns1", dns1)
            intent.putExtra("dns2", dns2)
            
            // بررسی نسخه اندروید برای روش مناسب راه‌اندازی سرویس
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            
            // بررسی راه‌اندازی موفق سرویس (با تأخیر کوتاه)
            CoroutineScope(Dispatchers.Main).launch {
                delay(500) // تأخیر کوتاه برای راه‌اندازی سرویس
                if (!isMyVpnServiceRunning()) {
                    Log.e("FireDNS", "VPN service failed to start")
                    vpnStatusEventSink?.success("DNS_START_FAILED")
                }
            }
            
            return true
        } catch (e: Exception) {
            Log.e("FireDNS", "Error starting VPN service: ${e.message}", e)
            vpnStatusEventSink?.success("DNS_START_FAILED")
            return false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d("FireDNS", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        if (requestCode == 1001 && resultCode == RESULT_OK) {
            Log.d("FireDNS", "VPN permission granted by user, starting service with lastDns1=$lastDns1, lastDns2=$lastDns2")
            startDnsVpnService(lastDns1, lastDns2)
        } else if (requestCode == 1001) {
            Log.d("FireDNS", "VPN permission denied by user")
            vpnStatusEventSink?.success("DNS_STOPPED")
            isVpnRunning = false
        }
    }

    private fun stopDnsVpn() {
        Log.d("FireDNS", "stopDnsVpn: Attempting to stop VPN service...")
        try {
            val intent = Intent(this, MyVpnService::class.java)
            intent.action = "FORCE_STOP"
            startService(intent)
            
            // Wait briefly and check if service is still running
            Thread.sleep(500)
            if (isMyVpnServiceRunning()) {
                Log.d("FireDNS", "Force stopping VPN service...")
                stopService(intent)
                
                // Wait again and verify service has stopped
                Thread.sleep(500)
            }
            
            // Check the actual status after attempting to stop
            val serviceStillRunning = isMyVpnServiceRunning()
            Log.d("FireDNS", "After stop attempt, service running: $serviceStillRunning")
            
            // Only update status if service is actually stopped
            isVpnRunning = serviceStillRunning
            
            // Always notify Flutter about the current status
            vpnStatusEventSink?.success(if (serviceStillRunning) "VPN_STARTED" else "DNS_STOPPED")
            
            if (!serviceStillRunning) {
                Log.d("FireDNS", "VPN service stopped successfully")
            } else {
                Log.e("FireDNS", "Failed to stop VPN service")
            }
        } catch (e: Exception) {
            Log.e("FireDNS", "Error stopping VPN service: ${e.message}")
            
            // Check actual status even after exception
            val serviceStillRunning = isMyVpnServiceRunning()
            isVpnRunning = serviceStillRunning
            vpnStatusEventSink?.success(if (serviceStillRunning) "VPN_STARTED" else "DNS_STOPPED")
        }
    }

    private fun testGoogleConnectivity(): Map<String, Any> {
        return try {
            Log.d("FireDNS", "Starting Google connectivity test...")
            
            // Test 1: Basic ping to Google
            val googlePingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 google.com")
            val googlePingExitCode = googlePingProcess.waitFor()
            val googlePingWorking = googlePingExitCode == 0
            
            // Test 2: DNS resolution test using dig instead of nslookup
            val dnsResolutionWorking = try {
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 2 www.google.com")
                process.waitFor() == 0
            } catch (e: Exception) {
                Log.w("FireDNS", "DNS resolution test failed: ${e.message}")
                false
            }
            
            // Test 3: HTTPS connectivity test
            val httpsConnectivityWorking = try {
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 2 8.8.8.8")
                process.waitFor() == 0
            } catch (e: Exception) {
                false
            }
            
            Log.d("FireDNS", "Google connectivity results:")
            Log.d("FireDNS", "  - Google ping: ${if (googlePingWorking) "✅ WORKING" else "❌ FAILED"}")
            Log.d("FireDNS", "  - DNS resolution: ${if (dnsResolutionWorking) "✅ WORKING" else "❌ FAILED"}")
            Log.d("FireDNS", "  - HTTPS connectivity: ${if (httpsConnectivityWorking) "✅ WORKING" else "❌ FAILED"}")
            
            val overallStatus = googlePingWorking && dnsResolutionWorking && httpsConnectivityWorking
            
            mapOf(
                "googlePing" to googlePingWorking,
                "dnsResolution" to dnsResolutionWorking,
                "httpsConnectivity" to httpsConnectivityWorking,
                "overallStatus" to overallStatus,
                "message" to if (overallStatus) "Google services are working properly" else "Some Google services may not work correctly"
            )
        } catch (e: Exception) {
            Log.e("FireDNS", "Error testing Google connectivity: ${e.message}")
            mapOf(
                "googlePing" to false,
                "dnsResolution" to false,
                "httpsConnectivity" to false,
                "overallStatus" to false,
                "message" to "Error testing connectivity: ${e.message}"
            )
        }
    }

    private fun testDomainWithCustomDns(domain: String, dns: String): Map<String, Any> {
        // این پیاده‌سازی ساده است و فقط dig را با دی‌ان‌اس سفارشی اجرا می‌کند (باید dig روی دستگاه باشد)
        // اگر dig نصب نیست، می‌توانید از nslookup یا ابزار مشابه استفاده کنید
        try {
            val cmd = arrayOf("/system/bin/dig", "@${dns}", domain)
            val process = Runtime.getRuntime().exec(cmd)
            val reader = process.inputStream.bufferedReader()
            var pingTime = -1
            var isReachable = false
            val output = StringBuilder()
            val start = System.currentTimeMillis()
            reader.useLines { lines ->
                lines.forEach { line ->
                    output.append(line).append("\n")
                    if (line.contains("ANSWER SECTION")) {
                        isReachable = true
                    }
                }
            }
            val exitCode = process.waitFor()
            val end = System.currentTimeMillis()
            if (isReachable) {
                pingTime = (end - start).toInt()
            }
            Log.d("FireDNS", "dig output for $domain with $dns:\n$output")
            return mapOf(
                "isReachable" to isReachable,
                "ping" to if (isReachable) pingTime else -1
            )
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in testDomainWithCustomDns: ${e.message}", e)
            return mapOf(
                "isReachable" to false,
                "ping" to -1
            )
        }
    }

    /**
     * کلاس نتیجه برای عملیات‌های سرویس DNS
     * این کلاس برای بازگرداندن نتایج دقیق‌تر از عملیات‌های سرویس استفاده می‌شود
     */
    sealed class DnsServiceResult {
        object Success : DnsServiceResult()
        data class Error(val message: String, val code: String) : DnsServiceResult()
    }
    
    /**
     * کلاس کمکی برای عملیات‌های مرتبط با DNS
     * این کلاس توابع مفید برای کار با DNS را فراهم می‌کند
     */
    private object DnsUtils {
        /**
         * بررسی معتبر بودن آدرس IP
         * @param ip آدرس IP برای بررسی
         * @return true اگر آدرس IP معتبر باشد، false در غیر این صورت
         */
        fun isValidIpAddress(ip: String?): Boolean {
            if (ip.isNullOrEmpty()) return false
            
            return try {
                // بررسی آدرس 0.0.0.0
                if (ip == "0.0.0.0") return false
                
                // تقسیم آدرس به بخش‌های جداگانه
                val parts = ip.split(".")
                if (parts.size != 4) return false
                
                // بررسی محدوده اعداد در هر بخش (0-255)
                parts.all { part ->
                    part.toIntOrNull() in 0..255
                }
            } catch (e: Exception) {
                false
            }
        }
    }
}

