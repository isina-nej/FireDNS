package com.example.dnschenger

import android.content.Intent
import android.content.Context
import com.example.dnschenger.MyVpnService
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
        val isServiceRunning = isMyVpnServiceRunning()
        Log.d("DNSChanger", "onResume: isVpnRunning=$isVpnRunning, isMyVpnServiceRunning=$isServiceRunning")
        if (!isServiceRunning) {
            Log.d("DNSChanger", "VPN service is not running, restarting VPN service...")
            startDnsVpnService(lastDns1, lastDns2)
        }
    }

    private fun isMyVpnServiceRunning(): Boolean {
        // بررسی دقیق سرویس در حال اجرا
        val activityManager = getSystemService(android.content.Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val services = activityManager.getRunningServices(Int.MAX_VALUE)
        for (service in services) {
            if (service.service.className == com.example.dnschenger.MyVpnService::class.java.name) {
                return true
            }
        }
        return false
    }
    private val CHANNEL = "com.example.dnschanger/dns"
    private val VPN_STATUS_CHANNEL = "com.example.dnschanger/vpnStatus"
    private val DATA_USAGE_CHANNEL = "com.example.dnschanger/dataUsage"
    private var lastDns1: String = "178.22.122.100"  // Shecan DNS
    private var lastDns2: String = "1.1.1.1"        // Cloudflare DNS
    private var vpnStatusEventSink: EventChannel.EventSink? = null

    private fun pingDns(dns: String): Map<String, Any> {
        return try {
            Log.d("DNSChanger", "Starting ping test for DNS: $dns")
            // Use -W 1 to set the timeout to 1 second per packet
            // Use -c 2 to send 2 packets (in case one is lost)
            val process = Runtime.getRuntime().exec("/system/bin/ping -W 1 -c 2 $dns")
            val reader = process.inputStream.bufferedReader()
            var pingTime = -1
            var isReachable = false
            var packetLoss = 100 // Default to 100% loss
            val output = StringBuilder()
            
            reader.useLines { lines ->
                lines.forEach { line ->
                    output.append(line).append("\n")
                    Log.d("DNSChanger", "Ping output line: $line")
                    
                    when {
                        line.contains("time=") -> {
                            try {
                                // Handle different ping output formats
                                val timeStr = when {
                                    line.contains("time=") -> line.substringAfter("time=").substringBefore(" ms").trim()
                                    line.contains("время=") -> line.substringAfter("время=").substringBefore(" мс").trim()
                                    else -> null
                                }
                                val currentPing = timeStr?.toFloatOrNull()?.toInt() ?: -1
                                // Take the minimum ping time if we receive multiple responses
                                if (currentPing > 0 && (pingTime == -1 || currentPing < pingTime)) {
                                    pingTime = currentPing
                                }
                                isReachable = true
                                Log.d("DNSChanger", "Extracted ping time: $pingTime ms")
                            } catch (e: Exception) {
                                Log.e("DNSChanger", "Error parsing ping time from line: $line", e)
                            }
                        }
                        line.contains("packet loss") -> {
                            try {
                                // Parse packet loss percentage
                                val lossStr = line.substringBefore("%").substringAfterLast(" ")
                                packetLoss = lossStr.toIntOrNull() ?: 100
                                Log.d("DNSChanger", "Packet loss: $packetLoss%")
                            } catch (e: Exception) {
                                Log.e("DNSChanger", "Error parsing packet loss from line: $line", e)
                            }
                        }
                    }
                }
            }
            
            val exitCode = process.waitFor()
            Log.d("DNSChanger", "Ping process exit code: $exitCode")
            Log.d("DNSChanger", "Full ping output:\n$output")
            
            // Consider the server reachable if we got any response or if packet loss is less than 100%
            isReachable = isReachable || packetLoss < 100
            
            val result = mapOf(
                "isReachable" to isReachable,
                "ping" to if (isReachable) pingTime else -1
            )
            Log.d("DNSChanger", "Final ping result for $dns: $result")
            result
        } catch (e: Exception) {
            Log.e("DNSChanger", "Error pinging $dns: ${e.message}", e)
            mapOf(
                "isReachable" to false,
                "ping" to -1
            )
        }
    }

    private suspend fun checkDnsAsync(dns: String): Deferred<Map<String, Any>> = 
        kotlinx.coroutines.GlobalScope.async(Dispatchers.IO) {
            val startTime = System.currentTimeMillis()
            val isReachable = try {
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -w 1 $dns")
                process.waitFor() == 0
            } catch (e: Exception) {
                false
            }
            val pingTime = System.currentTimeMillis() - startTime
            
            mapOf(
                "isReachable" to isReachable,
                "ping" to pingTime.toInt()
            )
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
            Log.d("DNSChanger", "MethodChannel call: ${call.method}")
            when (call.method) {
                "testDns" -> {
                    val dns = call.argument<String>("dns") ?: ""
                    if (dns.isEmpty()) {
                        result.error("INVALID_DNS", "DNS address cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val pingResult = withContext(Dispatchers.IO) {
                                pingDns(dns)
                            }
                            Log.d("DNSChanger", "Ping to $dns completed with result: $pingResult")
                            result.success(pingResult)
                        } catch (e: Exception) {
                            Log.e("DNSChanger", "Error in testDns: ${e.message}", e)
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
                            Log.d("DNSChanger", "Google connectivity test completed with result: $connectivityResult")
                            result.success(connectivityResult)
                        } catch (e: Exception) {
                            Log.e("DNSChanger", "Error in testGoogleConnectivity: ${e.message}", e)
                            result.error("CONNECTIVITY_ERROR", "Error testing Google connectivity", e.message)
                        }
                    }
                }
                "setDns" -> {
                    val dns1 = call.argument<String>("dns1") ?: "8.8.8.8"
                    val dns2 = call.argument<String>("dns2") ?: "8.8.4.4"
                    lastDns1 = dns1
                    lastDns2 = dns2
                    Log.d("DNSChanger", "setDns called with dns1=$dns1, dns2=$dns2")
                    setDns(dns1, dns2)
                    result.success(true)
                }
                "stopDnsVpn" -> {
                    Log.d("DNSChanger", "stopDnsVpn called")
                    stopDnsVpn()
                    result.success(true)
                }
                "getServiceStatus" -> {
                    result.success(isVpnRunning)
                }
                else -> {
                    Log.d("DNSChanger", "notImplemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_STATUS_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                vpnStatusEventSink = events
                // NetShift-style: attach statusListener to MyVpnService
                MyVpnService.statusListener = vpnStatusListener
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
        Log.d("DNSChanger", "setDns: prepare VPN")
        // Save DNS to SharedPreferences
        val sharedPreferences = getSharedPreferences("DNSPreferences", android.content.Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.putString("dns1", dns1)
        editor.putString("dns2", dns2)
        editor.apply()
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            Log.d("DNSChanger", "VPN permission required, launching intent")
            startActivityForResult(prepareIntent, 1001)
        } else {
            Log.d("DNSChanger", "VPN permission already granted, starting service")
            startDnsVpnService(dns1, dns2)
        }
    }

    private fun startDnsVpnService(dns1: String?, dns2: String?) {
        Log.d("DNSChanger", "startDnsVpnService: dns1=$dns1, dns2=$dns2")
        val intent = Intent(this, MyVpnService::class.java)
        intent.putExtra("dns1", dns1)
        intent.putExtra("dns2", dns2)
        startService(intent)
        // isVpnRunning and status sync will be handled by statusListener
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d("DNSChanger", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        if (requestCode == 1001 && resultCode == RESULT_OK) {
            Log.d("DNSChanger", "VPN permission granted by user, starting service with lastDns1=$lastDns1, lastDns2=$lastDns2")
            startDnsVpnService(lastDns1, lastDns2)
        } else if (requestCode == 1001) {
            Log.d("DNSChanger", "VPN permission denied by user")
            vpnStatusEventSink?.success("DNS_STOPPED")
            isVpnRunning = false
        }
    }

    private fun stopDnsVpn() {
        Log.d("DNSChanger", "stopDnsVpn: Attempting to stop VPN service...")
        try {
            val intent = Intent(this, MyVpnService::class.java)
            intent.action = "FORCE_STOP"
            startService(intent)
            
            // Wait briefly and check if service is still running
            Thread.sleep(500)
            if (isMyVpnServiceRunning()) {
                Log.d("DNSChanger", "Force stopping VPN service...")
                stopService(intent)
            }
            
            isVpnRunning = false
            vpnStatusEventSink?.success("DNS_STOPPED")
            Log.d("DNSChanger", "VPN service stopped successfully")
        } catch (e: Exception) {
            Log.e("DNSChanger", "Error stopping VPN service: ${e.message}")
            isVpnRunning = false
            vpnStatusEventSink?.success("DNS_STOPPED")
        }
    }

    private fun testGoogleConnectivity(): Map<String, Any> {
        return try {
            Log.d("DNSChanger", "Starting Google connectivity test...")
            
            // Test 1: Basic ping to Google
            val googlePingProcess = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 google.com")
            val googlePingExitCode = googlePingProcess.waitFor()
            val googlePingWorking = googlePingExitCode == 0
            
            // Test 2: DNS resolution test using dig instead of nslookup
            val dnsResolutionWorking = try {
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 2 www.google.com")
                process.waitFor() == 0
            } catch (e: Exception) {
                Log.w("DNSChanger", "DNS resolution test failed: ${e.message}")
                false
            }
            
            // Test 3: HTTPS connectivity test
            val httpsConnectivityWorking = try {
                val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 2 8.8.8.8")
                process.waitFor() == 0
            } catch (e: Exception) {
                false
            }
            
            Log.d("DNSChanger", "Google connectivity results:")
            Log.d("DNSChanger", "  - Google ping: ${if (googlePingWorking) "✅ WORKING" else "❌ FAILED"}")
            Log.d("DNSChanger", "  - DNS resolution: ${if (dnsResolutionWorking) "✅ WORKING" else "❌ FAILED"}")
            Log.d("DNSChanger", "  - HTTPS connectivity: ${if (httpsConnectivityWorking) "✅ WORKING" else "❌ FAILED"}")
            
            val overallStatus = googlePingWorking && dnsResolutionWorking && httpsConnectivityWorking
            
            mapOf(
                "googlePing" to googlePingWorking,
                "dnsResolution" to dnsResolutionWorking,
                "httpsConnectivity" to httpsConnectivityWorking,
                "overallStatus" to overallStatus,
                "message" to if (overallStatus) "Google services are working properly" else "Some Google services may not work correctly"
            )
        } catch (e: Exception) {
            Log.e("DNSChanger", "Error testing Google connectivity: ${e.message}")
            mapOf(
                "googlePing" to false,
                "dnsResolution" to false,
                "httpsConnectivity" to false,
                "overallStatus" to false,
                "message" to "Error testing connectivity: ${e.message}"
            )
        }
    }
}

