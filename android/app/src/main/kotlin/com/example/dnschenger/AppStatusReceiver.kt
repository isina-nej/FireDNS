package com.example.dnschenger

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

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
                if (!MyVpnService.isRunning) {
                    context.startService(vpnServiceIntent)
                }
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d("AppStatusReceiver", "ACTION_USER_PRESENT received, checking VPN status")
                if (!MyVpnService.isRunning) {
                    context.startService(vpnServiceIntent)
                }
            }
        }
    }
}
