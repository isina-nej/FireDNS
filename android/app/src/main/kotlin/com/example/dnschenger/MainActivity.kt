package com.example.firedns

import android.content.Intent
import android.content.Context
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import android.app.ActivityManager
import android.os.Build
import java.lang.Runtime
import java.io.BufferedReader
import java.io.InputStreamReader
import android.os.Handler
import android.os.Looper
import android.content.pm.ServiceInfo
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        val sharedPreferences = getSharedPreferences("DNSPreferences", Context.MODE_PRIVATE)
        lastDns1 = sharedPreferences.getString("dns1", "8.8.8.8") ?: "8.8.8.8"
        lastDns2 = sharedPreferences.getString("dns2", "8.8.4.4") ?: "8.8.4.4"
        
        val isServiceRunning = isMyVpnServiceRunning()
        Log.d("FireDNS", "onResume: isVpnRunning=$isVpnRunning, isMyVpnServiceRunning=$isServiceRunning")
        
        forceSyncVpnStatus()
    }

    private fun isMyVpnServiceRunning(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val services = activityManager.getRunningServices(Int.MAX_VALUE)
        for (service in services) {
            if (service.service.className == MyVpnService::class.java.name) {
                return true
            }
        }
        return false
    }
    
    private fun forceSyncVpnStatus() {
        try {
            val actualServiceRunning = isMyVpnServiceRunning()
            val serviceIsRunningFlag = MyVpnService.isRunning
            
            Log.d("FireDNS", "forceSyncVpnStatus: actualServiceRunning=$actualServiceRunning, serviceIsRunningFlag=$serviceIsRunningFlag, cachedStatus=$isVpnRunning")
            
            val correctStatus = actualServiceRunning && serviceIsRunningFlag
            
            if (isVpnRunning != correctStatus) {
                Log.d("FireDNS", "Correcting VPN status: $isVpnRunning -> $correctStatus")
                isVpnRunning = correctStatus
                
                vpnStatusEventSink?.success(if (correctStatus) "VPN_STARTED" else "DNS_STOPPED")
                
                MyVpnService.statusListener = vpnStatusListener
            }
        } catch (e: Exception) {
            Log.e("FireDNS", "Error in forceSyncVpnStatus: ${e.message}", e)
        }
    }

    private val CHANNEL = "com.example.firedns/dns"
    private val VPN_STATUS_CHANNEL = "com.example.firedns/vpnStatus"
    private val DATA_USAGE_CHANNEL = "com.example.firedns/dataUsage"
    private var lastDns1: String = "178.22.122.100"
    private var lastDns2: String = "1.1.1.1"
    private var vpnStatusEventSink: EventChannel.EventSink? = null
    
    private suspend fun testDnsConnectivity(
        dns: String,
        timeout: Int = 1000,
        packetCount: Int = 1,
        detailed: Boolean = true
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        return@withContext try {
            Log.d("FireDNS", "Testing DNS connectivity for $dns (timeout: $timeout, packets: $packetCount)")
            
            if (detailed) {
                val address = InetAddress.getByName(dns)
                val startTime = System.currentTimeMillis()
                val isReachable = address.isReachable(timeout)
                val pingTime = if (isReachable) (System.currentTimeMillis() - startTime).toInt() else -1
                
                if (isReachable) {
                    mapOf(
                        "isReachable" to true,
                        "ping" to pingTime
                    )
                } else {
                    val socket = Socket()
                    val socketAddress = InetSocketAddress(dns, 53)
                    val socketStart = System.currentTimeMillis()
                    socket.connect(socketAddress, timeout)
                    socket.close()
                    val socketPing = (System.currentTimeMillis() - socketStart).toInt()
                    
                    mapOf(
                        "isReachable" to true,
                        "ping" to socketPing
                    )
                }
            } else {
                val socket = Socket()
                val socketAddress = InetSocketAddress(dns, 53)
                val startTime = System.currentTimeMillis()
                socket.connect(socketAddress, timeout)
                socket.close()
                val pingTime = (System.currentTimeMillis() - startTime).toInt()
                
                mapOf(
                    "isReachable" to true,
                    "ping" to pingTime
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

    private var dataUsageEventSink: EventChannel.EventSink? = null
    private var isVpnRunning: Boolean = false
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
                "ping" -> {
                    val ip = call.argument<String>("ip")
                    if (ip != null) {
                        thread {
                            try {
                                val address = InetAddress.getByName(ip)
                                val startTime = System.currentTimeMillis()
                                val isReachable = address.isReachable(1000)
                                val pingTime = if (isReachable) {
                                    (System.currentTimeMillis() - startTime).toInt()
                                } else {
                                    -1
                                }
                                result.success(pingTime)
                            } catch (e: Exception) {
                                result.success(-1)
                            }
                        }
                    } else {
                        result.success(-1)
                    }
                    return@setMethodCallHandler
                }
                "testGoogleConnectivity" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val connectivityResult = withContext(Dispatchers.IO) {
                                testGoogleConnectivity()
                            }
                            Log.d("FireDNS", "Google connectivity result: $connectivityResult")
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
                    val actualStatus = isMyVpnServiceRunning()
                    Log.d("FireDNS", "getServiceStatus called, actual service status: $actualStatus, cached status: $isVpnRunning")
                    
                    if (isVpnRunning != actualStatus) {
                        Log.d("FireDNS", "Fixing status mismatch: isVpnRunning=$isVpnRunning, actual=$actualStatus")
                        isVpnRunning = actualStatus
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
                MyVpnService.statusListener = vpnStatusListener
                
                val currentServiceStatus = isMyVpnServiceRunning()
                Log.d("FireDNS", "EventChannel onListen: sending current status = $currentServiceStatus")
                
                isVpnRunning = currentServiceStatus
                
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
        val sharedPreferences = getSharedPreferences("DNSPreferences", Context.MODE_PRIVATE)
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

    private fun startDnsVpnService(dns1: String?, dns2: String?): Boolean {
        Log.d("FireDNS", "startDnsVpnService: dns1=$dns1, dns2=$dns2")
        
        try {
            if (dns1.isNullOrEmpty()) {
                Log.e("FireDNS", "Primary DNS is null or empty")
                vpnStatusEventSink?.success("DNS_ERROR_INVALID_PRIMARY")
                return false
            }
            
            val intent = Intent(this, MyVpnService::class.java)
            intent.putExtra("dns1", dns1)
            intent.putExtra("dns2", dns2)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            
            CoroutineScope(Dispatchers.Main).launch {
                delay(500)
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
            
            Handler(Looper.getMainLooper()).postDelayed({
                if (isMyVpnServiceRunning()) {
                    Log.d("FireDNS", "Force stopping VPN service...")
                    stopService(intent)
                }
                
                val serviceStillRunning = isMyVpnServiceRunning()
                Log.d("FireDNS", "After stop attempt, service running: $serviceStillRunning")
                
                isVpnRunning = serviceStillRunning
                
                vpnStatusEventSink?.success(if (serviceStillRunning) "VPN_STARTED" else "DNS_STOPPED")
                
                if (!serviceStillRunning) {
                    Log.d("FireDNS", "VPN service stopped successfully")
                } else {
                    Log.e("FireDNS", "Failed to stop VPN service")
                }
            }, 500)
        } catch (e: Exception) {
            Log.e("FireDNS", "Error stopping VPN service: ${e.message}")
            
            val serviceStillRunning = isMyVpnServiceRunning()
            isVpnRunning = serviceStillRunning
            vpnStatusEventSink?.success(if (serviceStillRunning) "VPN_STARTED" else "DNS_STOPPED")
        }
    }

    private fun testGoogleConnectivity(): Map<String, Any> {
        return try {
            Log.d("FireDNS", "Starting Google connectivity test...")
            
            val basicConnectivity = runBlocking { testConnectivity("8.8.8.8") }
            val googleConnectivity = runBlocking { testConnectivity("google.com") }
            val dnsResolution = runBlocking { testDnsResolution("google.com") }
            
            Log.d("FireDNS", "Google connectivity results:")
            Log.d("FireDNS", "  - Basic ping: " + if (basicConnectivity) "WORKING" else "FAILED")
            Log.d("FireDNS", "  - Google ping: " + if (googleConnectivity) "WORKING" else "FAILED")
            Log.d("FireDNS", "  - DNS resolution: " + if (dnsResolution) "WORKING" else "FAILED")
            
            val overallStatus = basicConnectivity && googleConnectivity && dnsResolution
            
            mapOf(
                "googlePing" to googleConnectivity,
                "dnsResolution" to dnsResolution,
                "httpsConnectivity" to basicConnectivity,
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
    
    private suspend fun testConnectivity(host: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val process = Runtime.getRuntime().exec("/system/bin/ping -c 1 -W 3 $host")
            process.waitFor() == 0
        } catch (e: Exception) {
            false
        }
    }
    
    private suspend fun testDnsResolution(host: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val inetAddress = InetAddress.getByName(host)
            inetAddress != null
        } catch (e: Exception) {
            false
        }
    }

    private fun testDomainWithCustomDns(domain: String, dns: String): Map<String, Any> {
        try {
            val process = Runtime.getRuntime().exec("/system/bin/dig @$dns $domain")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var pingTime = -1
            var isReachable = false
            val start = System.currentTimeMillis()
            val output = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                output.append(line).append("\n")
                if (line!!.contains("ANSWER SECTION")) {
                    isReachable = true
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

    sealed class DnsServiceResult {
        object Success : DnsServiceResult()
        data class Error(val message: String, val code: String) : DnsServiceResult()
    }
    
    private object DnsUtils {
        fun isValidIpAddress(ip: String?): Boolean {
            if (ip.isNullOrEmpty()) return false
            
            return try {
                if (ip == "0.0.0.0") return false
                
                val parts = ip.split(".")
                if (parts.size != 4) return false
                
                parts.all { part ->
                    part.toIntOrNull() in 0..255
                }
            } catch (e: Exception) {
                false
            }
        }
    }
}