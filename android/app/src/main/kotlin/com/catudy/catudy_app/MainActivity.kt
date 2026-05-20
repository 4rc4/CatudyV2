package com.catudy.catudy_app

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "catudy/app_lock"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listInstalledApps" -> result.success(listInstalledApps())
                "getPermissionStatus" -> result.success(permissionStatus())
                "openUsageAccessSettings" -> {
                    openSettings(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    openSettings(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                    )
                    result.success(null)
                }
                "openLocationSettings" -> {
                    openSettings(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")
                        )
                    )
                    result.success(null)
                }
                "syncLockRules" -> {
                    AppLockRuleStore.save(this, call.arguments)
                    result.success(null)
                }
                "startLockService" -> {
                    startAppLockService()
                    result.success(null)
                }
                "stopLockService" -> {
                    stopService(Intent(this, CatudyAppLockService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun listInstalledApps(): List<Map<String, String>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                launcherIntent,
                PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }
        return resolved
            .mapNotNull { info ->
                val activityInfo = info.activityInfo ?: return@mapNotNull null
                val appPackage = activityInfo.packageName ?: return@mapNotNull null
                if (appPackage == packageName) {
                    return@mapNotNull null
                }
                mapOf(
                    "packageName" to appPackage,
                    "appName" to info.loadLabel(packageManager).toString()
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { it["appName"]?.lowercase() }
    }

    private fun permissionStatus(): Map<String, Boolean> {
        val locationGranted = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) ||
            hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        val backgroundGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            hasPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        } else {
            locationGranted
        }
        return mapOf(
            "usageAccess" to hasUsageAccess(),
            "overlay" to Settings.canDrawOverlays(this),
            "location" to locationGranted,
            "backgroundLocation" to backgroundGranted
        )
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasPermission(permission: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        return checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun openSettings(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun startAppLockService() {
        val intent = Intent(this, CatudyAppLockService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
