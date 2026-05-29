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
import android.graphics.drawable.GradientDrawable
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
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.atan2
import kotlin.math.ceil
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
        if (foregroundPackage == null) {
            return
        }
        if (foregroundPackage == packageName) {
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
        val locationLockActive = rule.locationLockEnabled &&
            rules.strictLocationLocksEnabled &&
            isInsideActiveLockLocation()
        val now = System.currentTimeMillis()
        val unlocked = rule.unlockedUntilMillis?.let { it > now } == true
        val focusLockActive = rule.focusLockEnabled && !unlocked
        if (!locationLockActive && !focusLockActive) {
            hideOverlay()
            return
        }
        showOverlay(rule, locationLockActive, focusLockActive)
    }

    private fun currentForegroundPackage(): String? {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(end - FOREGROUND_LOOKBACK_MS, end)
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

    private fun showOverlay(
        rule: LockedAppRule,
        locationLockActive: Boolean,
        focusLockActive: Boolean
    ) {
        if (!Settings.canDrawOverlays(this)) {
            return
        }
        val activeProgressVisible = rules.activeUnlock?.packageName == rule.packageName
        if (overlayView != null && overlayPackageName == rule.packageName && !activeProgressVisible) {
            return
        }
        hideOverlay()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.rgb(21, 17, 42))
        }
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(24), dp(24), dp(22))
            background = rounded(Color.rgb(255, 250, 247), 28)
        }
        root.addView(
            card,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
                leftMargin = dp(22)
                rightMargin = dp(22)
            }
        )
        card.addView(lockBadge())
        card.addView(lockTitle(if (isTurkish()) "Bu uygulama kilitli" else "This app is locked"))
        card.addView(lockAppName(rule.appName))
        card.addView(lockBody(rule, locationLockActive))
        card.addView(lockProgress(rule, locationLockActive))
        if (focusLockActive && !locationLockActive) {
            card.addView(lockButton(
                if (isTurkish()) "Catudy'de odak ba\u015Flat" else "Start focus in Catudy"
            ) {
                hideOverlay()
                launchCatudy("catudy:///focus/start?unlockApp=${Uri.encode(rule.packageName)}")
            })
        }
        card.addView(lockButton(
            if (isTurkish()) "Kilit ayarlar\u0131" else "Lock settings"
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

    private fun lockBadge(): TextView {
        return TextView(this).apply {
            text = "CATUDY"
            setTextColor(Color.rgb(45, 143, 136))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(6), dp(12), dp(6))
            background = rounded(
                Color.rgb(234, 223, 255),
                999,
                Color.rgb(216, 200, 255),
                1
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(12)
            }
        }
    }

    private fun lockTitle(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.rgb(20, 57, 133))
            textSize = 30f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            includeFontPadding = false
        }
    }

    private fun lockAppName(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.rgb(117, 97, 200))
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, dp(10), 0, 0)
        }
    }

    private fun lockBody(rule: LockedAppRule, locationLockActive: Boolean): TextView {
        val body = if (locationLockActive) {
            if (isTurkish()) {
                "${rule.appName} se\u00E7ili konumdayken kapal\u0131 kal\u0131r. Konum kural\u0131n\u0131 Catudy'den kapatabilirsin."
            } else {
                "${rule.appName} stays closed inside the selected location. Turn off that location rule in Catudy to open it."
            }
        } else {
            if (isTurkish()) {
                "Uygulamay\u0131 a\u00E7mak i\u00E7in Catudy'de odak hedefini tamamla."
            } else {
                "Complete the focus target in Catudy to open this app."
            }
        }
        return TextView(this).apply {
            text = body
            setTextColor(Color.rgb(102, 91, 134))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, dp(14), 0, dp(18))
            setLineSpacing(0f, 1.0f)
        }
    }

    private fun lockProgress(rule: LockedAppRule, locationLockActive: Boolean): LinearLayout {
        val progress = progressFor(rule, locationLockActive)
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = rounded(
                Color.rgb(234, 223, 255),
                20,
                Color.rgb(216, 200, 255),
                1
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(16)
            }
            addView(LinearLayout(this@CatudyAppLockService).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                addView(TextView(this@CatudyAppLockService).apply {
                    text = if (locationLockActive) {
                        if (isTurkish()) "Konum kural\u0131" else "Location rule"
                    } else {
                        if (isTurkish()) "Kalan odak" else "Remaining focus"
                    }
                    setTextColor(Color.rgb(20, 57, 133))
                    textSize = 14f
                    typeface = Typeface.DEFAULT_BOLD
                    layoutParams = LinearLayout.LayoutParams(
                        0,
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        1f
                    )
                })
                addView(TextView(this@CatudyAppLockService).apply {
                    text = progress.label
                    setTextColor(Color.rgb(117, 97, 200))
                    textSize = 14f
                    typeface = Typeface.DEFAULT_BOLD
                })
            })
            addView(progressTrack(progress.value))
        }
    }

    private fun progressTrack(value: Double): FrameLayout {
        val track = FrameLayout(this).apply {
            background = rounded(Color.rgb(255, 250, 247), 999)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(12)
            ).apply {
                topMargin = dp(10)
            }
        }
        val fill = View(this).apply {
            background = rounded(Color.rgb(91, 200, 188), 999)
        }
        track.addView(
            fill,
            FrameLayout.LayoutParams(0, FrameLayout.LayoutParams.MATCH_PARENT)
        )
        track.post {
            fill.layoutParams = FrameLayout.LayoutParams(
                (track.width * value.coerceIn(0.0, 1.0)).toInt(),
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        return track
    }

    private fun progressFor(
        rule: LockedAppRule,
        locationLockActive: Boolean
    ): LockProgress {
        if (locationLockActive) {
            return LockProgress(
                label = if (isTurkish()) "Aktif" else "Active",
                value = 0.0
            )
        }
        val active = rules.activeUnlock
        val requiredMinutes = rule.requiredFocusMinutes.coerceAtLeast(1)
        if (active != null && active.packageName == rule.packageName) {
            val totalMillis = active.durationMinutes.coerceAtLeast(1) * 60_000L
            val elapsedMillis = (System.currentTimeMillis() - active.startedAtMillis)
                .coerceIn(0L, totalMillis)
            val remainingMillis = (totalMillis - elapsedMillis).coerceAtLeast(0L)
            val remainingMinutes = ceil(remainingMillis / 60000.0)
                .toInt()
                .coerceAtLeast(0)
            return LockProgress(
                label = if (isTurkish()) "$remainingMinutes dk" else "$remainingMinutes min",
                value = elapsedMillis.toDouble() / totalMillis.toDouble()
            )
        }
        return LockProgress(
            label = if (isTurkish()) "$requiredMinutes dk" else "$requiredMinutes min",
            value = 0.0
        )
    }

    private fun lockButton(text: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            val primary = !text.contains("settings", ignoreCase = true) &&
                !text.contains("ayar", ignoreCase = true)
            this.text = text
            isAllCaps = false
            typeface = Typeface.DEFAULT_BOLD
            textSize = 16f
            setTextColor(if (primary) Color.WHITE else Color.rgb(117, 97, 200))
            background = rounded(
                if (primary) Color.rgb(117, 97, 200) else Color.rgb(255, 250, 247),
                18,
                if (primary) Color.rgb(117, 97, 200) else Color.rgb(216, 200, 255),
                1
            )
            setOnClickListener { onClick() }
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(52)
            )
            params.setMargins(0, if (primary) 0 else dp(8), 0, 0)
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

    private fun rounded(
        color: Int,
        radiusDp: Int,
        strokeColor: Int? = null,
        strokeWidthDp: Int = 0
    ): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
            if (strokeColor != null && strokeWidthDp > 0) {
                setStroke(dp(strokeWidthDp), strokeColor)
            }
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private data class LockProgress(
        val label: String,
        val value: Double,
    )

    companion object {
        private const val CHANNEL_ID = "catudy_app_lock"
        private const val NOTIFICATION_ID = 9051
        private const val FOREGROUND_LOOKBACK_MS = 120_000L
    }
}
