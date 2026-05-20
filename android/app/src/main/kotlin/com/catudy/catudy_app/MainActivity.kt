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
    @Volatile
    private var installedAppsCache: List<Map<String, String>>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "catudy/app_lock"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listInstalledApps" -> loadInstalledApps(result)
                "getLastKnownLocation" -> {
                    if (hasLocationPermission()) {
                        val location = lastKnownLocation()
                        if (location != null) {
                            result.success(mapOf(
                                "latitude" to location.latitude,
                                "longitude" to location.longitude
                            ))
                        } else {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
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

    private fun loadInstalledApps(result: MethodChannel.Result) {
        installedAppsCache?.let {
            result.success(it)
            return
        }
        Thread {
            val apps = runCatching { listInstalledApps() }
                .getOrElse { emptyList<Map<String, String>>() }
            installedAppsCache = apps
            runOnUiThread { result.success(apps) }
        }.start()
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
                val appName = info.loadLabel(packageManager).toString()
                val iconBase64 = try {
                    val drawable = info.loadIcon(packageManager)
                    val bitmap = drawableToBitmap(drawable)
                    val scaled = android.graphics.Bitmap.createScaledBitmap(
                        bitmap,
                        APP_ICON_SIZE_PX,
                        APP_ICON_SIZE_PX,
                        true
                    )
                    val stream = java.io.ByteArrayOutputStream()
                    scaled.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                    android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.NO_WRAP)
                } catch (e: Exception) {
                    ""
                }
                mapOf(
                    "packageName" to appPackage,
                    "appName" to appName,
                    "appIconBase64" to iconBase64
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { it["appName"]?.lowercase() }
    }

    private fun drawableToBitmap(drawable: android.graphics.drawable.Drawable): android.graphics.Bitmap {
        if (drawable is android.graphics.drawable.BitmapDrawable) {
            if (drawable.bitmap != null) {
                return drawable.bitmap
            }
        }
        val width = if (drawable.intrinsicWidth <= 0) 96 else drawable.intrinsicWidth
        val height = if (drawable.intrinsicHeight <= 0) 96 else drawable.intrinsicHeight
        val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun lastKnownLocation(): android.location.Location? {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
        return runCatching {
            locationManager.getProviders(true)
                .mapNotNull { provider ->
                    runCatching { locationManager.getLastKnownLocation(provider) }.getOrNull()
                }
                .maxByOrNull { it.time }
        }.getOrNull()
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

    private fun hasLocationPermission(): Boolean {
        return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) ||
            hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
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

    companion object {
        private const val APP_ICON_SIZE_PX = 64
    }
}
