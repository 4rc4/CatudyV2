package com.catudy.catudy_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AppLockBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val rules = AppLockRuleStore.load(context)
        if (!rules.enabled) {
            return
        }
        val serviceIntent = Intent(context, CatudyAppLockService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
