package com.catudy.catudy_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

object AppLockRuleStore {
    private const val PREFS_NAME = "catudy_app_lock_rules"
    private const val KEY_PAYLOAD = "payload"

    fun save(context: Context, payload: Any?) {
        val json = toJsonValue(payload) as? JSONObject ?: JSONObject()
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PAYLOAD, json.toString())
            .apply()
    }

    fun load(context: Context): AppLockRules {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_PAYLOAD, null) ?: return AppLockRules()
        return runCatching {
            val json = JSONObject(raw)
            val settings = json.optJSONObject("settings")
            val apps = json.optJSONArray("lockedApps") ?: JSONArray()
            val locations = json.optJSONArray("lockLocations") ?: JSONArray()
            AppLockRules(
                enabled = settings?.optBoolean("enabled", false) ?: false,
                strictLocationLocksEnabled = settings
                    ?.optBoolean("strictLocationLocksEnabled", true) ?: true,
                lockedApps = (0 until apps.length()).mapNotNull { index ->
                    val app = apps.optJSONObject(index) ?: return@mapNotNull null
                    val packageName = app.optString("packageName")
                    if (packageName.isBlank()) {
                        return@mapNotNull null
                    }
                    LockedAppRule(
                        packageName = packageName,
                        appName = app.optString("appName", packageName),
                        requiredFocusMinutes = app.optInt("requiredFocusMinutes", 25),
                        enabled = app.optBoolean("enabled", true),
                        unlockedUntilMillis = parseInstantMillis(
                            app.optString("unlockedUntil", "")
                        )
                    )
                },
                lockLocations = (0 until locations.length()).mapNotNull { index ->
                    val location = locations.optJSONObject(index) ?: return@mapNotNull null
                    val id = location.optString("id")
                    if (id.isBlank()) {
                        return@mapNotNull null
                    }
                    LockLocationRule(
                        id = id,
                        name = location.optString("name", "Focus area"),
                        latitude = location.optDouble("latitude", 0.0),
                        longitude = location.optDouble("longitude", 0.0),
                        radiusMeters = location.optDouble("radiusMeters", 150.0),
                        active = location.optBoolean("active", true)
                    )
                }
            )
        }.getOrDefault(AppLockRules())
    }

    private fun toJsonValue(value: Any?): Any {
        return when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> JSONObject().apply {
                value.forEach { (key, item) ->
                    if (key != null) {
                        put(key.toString(), toJsonValue(item))
                    }
                }
            }
            is Iterable<*> -> JSONArray().apply {
                value.forEach { put(toJsonValue(it)) }
            }
            is Array<*> -> JSONArray().apply {
                value.forEach { put(toJsonValue(it)) }
            }
            else -> value
        }
    }

    private fun parseInstantMillis(value: String): Long? {
        if (value.isBlank() || value == "null") {
            return null
        }
        return runCatching { Instant.parse(value).toEpochMilli() }.getOrNull()
    }
}

data class AppLockRules(
    val enabled: Boolean = false,
    val strictLocationLocksEnabled: Boolean = true,
    val lockedApps: List<LockedAppRule> = emptyList(),
    val lockLocations: List<LockLocationRule> = emptyList(),
)

data class LockedAppRule(
    val packageName: String,
    val appName: String,
    val requiredFocusMinutes: Int,
    val enabled: Boolean,
    val unlockedUntilMillis: Long?,
)

data class LockLocationRule(
    val id: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val radiusMeters: Double,
    val active: Boolean,
)
