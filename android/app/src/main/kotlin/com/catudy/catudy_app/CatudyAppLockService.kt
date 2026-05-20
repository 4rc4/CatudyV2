package com.catudy.catudy_app

import android.Manifest
import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class CatudyAppLockService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var overlayPackageName: String? = null
    private var rules = AppLockRules()

    private val monitorRunnable = object : Runnable {
        override fun run() {
            rules = AppLockRuleStore.load(this@CatudyAppLockService)
            evaluateForegroundApp()
            handler.postDelayed(this, 1500)
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildNotification())
        handler.post(monitorRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        rules = AppLockRuleStore.load(this)
        handler.removeCallbacks(monitorRunnable)
        handler.post(monitorRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(monitorRunnable)
        hideOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun evaluateForegroundApp() {
        if (!rules.enabled || !hasUsageAccess()) {
            hideOverlay()
            return
        }
        val foregroundPackage = currentForegroundPackage()
        if (foregroundPackage == null || foregroundPackage == packageName) {
            hideOverlay()
            return
        }
        val rule = rules.lockedApps.firstOrNull {
            it.enabled && it.packageName == foregroundPackage
        }
        if (rule == null) {
            hideOverlay()
            return
        }
        val strictLocationActive = rules.strictLocationLocksEnabled &&
            isInsideActiveLockLocation()
        val now = System.currentTimeMillis()
        val unlocked = rule.unlockedUntilMillis?.let { it > now } == true
        if (!strictLocationActive && unlocked) {
            hideOverlay()
            return
        }
        showOverlay(rule, strictLocationActive)
    }

    private fun currentForegroundPackage(): String? {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(end - 10000, end)
        val event = UsageEvents.Event()
        var latestPackage: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val isForeground = event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    event.eventType == UsageEvents.Event.ACTIVITY_RESUMED)
            if (isForeground) {
                latestPackage = event.packageName
            }
        }
        return latestPackage
    }

    private fun showOverlay(rule: LockedAppRule, strictLocationActive: Boolean) {
        if (!Settings.canDrawOverlays(this)) {
            return
        }
        if (overlayView != null && overlayPackageName == rule.packageName) {
            return
        }
        hideOverlay()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(56, 56, 56, 56)
            setBackgroundColor(Color.rgb(250, 247, 255))
        }
        root.addView(lockTitle(if (isTurkish()) "Bu uygulama kilitli" else "This app is locked"))
        root.addView(lockBody(rule, strictLocationActive))
        root.addView(lockButton(
            if (isTurkish()) "Catudy'de odak başlat" else "Start focus in Catudy"
        ) {
            hideOverlay()
            launchCatudy("catudy:///focus/start?unlockApp=${Uri.encode(rule.packageName)}")
        })
        root.addView(lockButton(
            if (isTurkish()) "Kilit ayarlarına git" else "Open lock settings"
        ) {
            hideOverlay()
            launchCatudy("catudy:///app-lock")
        })

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            android.graphics.PixelFormat.OPAQUE
        )
        params.gravity = Gravity.CENTER
        runCatching {
            windowManager.addView(root, params)
            overlayView = root
            overlayPackageName = rule.packageName
        }
    }

    private fun lockTitle(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.rgb(43, 39, 59))
            textSize = 28f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
    }

    private fun lockBody(rule: LockedAppRule, strictLocationActive: Boolean): TextView {
        val body = if (strictLocationActive) {
            if (isTurkish()) {
                "${rule.appName} konum kilidi nedeniyle kapalı. Açmak için Catudy'den konum kuralını kaldır."
            } else {
                "${rule.appName} is blocked by a location rule. Remove that location rule in Catudy to unlock."
            }
        } else {
            if (isTurkish()) {
                "${rule.requiredFocusMinutes} dk odak tamamlayınca bugün açılacak."
            } else {
                "Complete ${rule.requiredFocusMinutes} min focus to unlock it for today."
            }
        }
        return TextView(this).apply {
            text = body
            setTextColor(Color.rgb(86, 80, 110))
            textSize = 17f
            gravity = Gravity.CENTER
            setPadding(0, 18, 0, 28)
        }
    }

    private fun lockButton(text: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            this.text = text
            isAllCaps = false
            setOnClickListener { onClick() }
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            params.setMargins(0, 8, 0, 8)
            layoutParams = params
        }
    }

    private fun hideOverlay() {
        val view = overlayView ?: return
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        runCatching { windowManager.removeView(view) }
        overlayView = null
        overlayPackageName = null
    }

    private fun launchCatudy(uri: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val fallback = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { startActivity(intent) }
            .onFailure {
                if (fallback != null) {
                    startActivity(fallback)
                }
            }
    }

    private fun isInsideActiveLockLocation(): Boolean {
        val activeLocations = rules.lockLocations.filter { it.active }
        if (activeLocations.isEmpty() || !hasLocationPermission()) {
            return false
        }
        val current = lastKnownLocation() ?: return false
        return activeLocations.any { location ->
            distanceMeters(
                current.latitude,
                current.longitude,
                location.latitude,
                location.longitude
            ) <= location.radiusMeters
        }
    }

    private fun lastKnownLocation(): Location? {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return runCatching {
            locationManager.getProviders(true)
                .mapNotNull { provider ->
                    runCatching { locationManager.getLastKnownLocation(provider) }.getOrNull()
                }
                .maxByOrNull { it.time }
        }.getOrNull()
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

    private fun hasLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun buildNotification(): Notification {
        createNotificationChannel()
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("catudy:///app-lock"))
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle(if (isTurkish()) "Catudy kilit izliyor" else "Catudy app lock is active")
            .setContentText(if (isTurkish()) "Kilitli uygulamalar ve konumlar izleniyor." else "Watching locked apps and locations.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Catudy App Lock",
            NotificationManager.IMPORTANCE_LOW
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun isTurkish(): Boolean {
        val locale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            resources.configuration.locales[0]
        } else {
            @Suppress("DEPRECATION")
            resources.configuration.locale
        }
        return locale.language == "tr"
    }

    private fun distanceMeters(
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double
    ): Double {
        val earthRadiusMeters = 6371000.0
        val dLat = Math.toRadians(endLatitude - startLatitude)
        val dLon = Math.toRadians(endLongitude - startLongitude)
        val lat1 = Math.toRadians(startLatitude)
        val lat2 = Math.toRadians(endLatitude)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    companion object {
        private const val CHANNEL_ID = "catudy_app_lock"
        private const val NOTIFICATION_ID = 9051
    }
}
