package com.example.firedns

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.util.Log

/**
 * دریافت‌کننده وضعیت برنامه
 * این کلاس رویدادهای سیستمی مانند خاموش شدن دستگاه، روشن شدن صفحه و تغییر وضعیت شبکه را مدیریت می‌کند
 */
class AppStatusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val vpnServiceIntent = Intent(context, MyVpnService::class.java)
        
        when (intent.action) {
            Intent.ACTION_SHUTDOWN -> {
                Log.d("AppStatusReceiver", "ACTION_SHUTDOWN received, stopping VPN service")
                context.stopService(vpnServiceIntent)
            }
            Intent.ACTION_SCREEN_ON -> {
                Log.d("AppStatusReceiver", "ACTION_SCREEN_ON received, checking VPN status")
                // بررسی وضعیت سرویس و اینکه آیا کاربر آن را خاموش کرده است
                if (!MyVpnService.isRunning && !MyVpnService.userStoppedService) {
                    startVpnServiceIfNeeded(context, vpnServiceIntent)
                }
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d("AppStatusReceiver", "ACTION_USER_PRESENT received, checking VPN status")
                // بررسی وضعیت سرویس و اینکه آیا کاربر آن را خاموش کرده است
                if (!MyVpnService.isRunning && !MyVpnService.userStoppedService) {
                    startVpnServiceIfNeeded(context, vpnServiceIntent)
                }
            }
            ConnectivityManager.CONNECTIVITY_ACTION -> {
                Log.d("AppStatusReceiver", "CONNECTIVITY_ACTION received, checking network status")
                val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val activeNetwork = cm.activeNetworkInfo
                val isConnected = activeNetwork?.isConnectedOrConnecting == true
                
                if (isConnected && !MyVpnService.isRunning && !MyVpnService.userStoppedService) {
                    Log.d("AppStatusReceiver", "Network connected, restarting VPN service")
                    startVpnServiceIfNeeded(context, vpnServiceIntent)
                }
            }
            Intent.ACTION_POWER_CONNECTED -> {
                Log.d("AppStatusReceiver", "Power connected, checking VPN status")
                // وقتی شارژر وصل می‌شود، می‌توانیم سرویس را با تنظیمات کامل راه‌اندازی کنیم
                if (!MyVpnService.isRunning && !MyVpnService.userStoppedService) {
                    startVpnServiceIfNeeded(context, vpnServiceIntent)
                }
            }
        }
    }
    
    /**
     * راه‌اندازی سرویس VPN با بررسی شرایط لازم
     * @param context زمینه برنامه
     * @param intent قصد برای راه‌اندازی سرویس
     */
    private fun startVpnServiceIfNeeded(context: Context, intent: Intent) {
        try {
            // بررسی وضعیت باتری قبل از راه‌اندازی سرویس
            val batteryStatus = context.registerReceiver(
                null, 
                IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            )
            
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            val batteryPct = level * 100 / scale
            
            // در صورتی که باتری کمتر از 15% است، سرویس را با تنظیمات کم‌مصرف راه‌اندازی کنیم
            if (batteryPct < 15) {
                intent.putExtra("low_power_mode", true)
            }
            
            // بازیابی تنظیمات DNS از SharedPreferences
            val sharedPreferences = context.getSharedPreferences("DNSPreferences", Context.MODE_PRIVATE)
            val dns1 = sharedPreferences.getString("dns1", MyVpnService.DEFAULT_PRIMARY_DNS)
            val dns2 = sharedPreferences.getString("dns2", MyVpnService.DEFAULT_SECONDARY_DNS)
            
            // اضافه کردن DNS ها به intent
            intent.putExtra("dns1", dns1)
            intent.putExtra("dns2", dns2)
            intent.putExtra("auto_reconnect", true)
            
            // راه‌اندازی سرویس با توجه به نسخه اندروید
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            
            Log.d("AppStatusReceiver", "VPN service started successfully with DNS: $dns1, $dns2")
        } catch (e: Exception) {
            Log.e("AppStatusReceiver", "Error starting VPN service: ${e.message}", e)
        }
    }
    
    companion object {
        /**
         * ثبت BroadcastReceiver برای دریافت رویدادهای سیستمی
         * @param context زمینه برنامه
         * @return نمونه ثبت شده از AppStatusReceiver
         */
        fun register(context: Context): AppStatusReceiver {
            val receiver = AppStatusReceiver()
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SHUTDOWN)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(ConnectivityManager.CONNECTIVITY_ACTION)
                addAction(Intent.ACTION_POWER_CONNECTED)
            }
            context.registerReceiver(receiver, filter)
            return receiver
        }
    }
}
