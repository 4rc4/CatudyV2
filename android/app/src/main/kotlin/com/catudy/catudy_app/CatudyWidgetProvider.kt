package com.catudy.catudy_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

private fun SharedPreferences.catudyLanguageCode(): String {
    return getString("languageCode", "tr")?.lowercase() ?: "tr"
}

private fun isEnglish(languageCode: String): Boolean = languageCode == "en"

private fun label(languageCode: String, tr: String, en: String): String {
    return if (isEnglish(languageCode)) en else tr
}

private fun minuteUnit(languageCode: String): String {
    return if (isEnglish(languageCode)) "min" else "dk"
}

private fun shortcutCategoryName(
    widgetData: SharedPreferences,
    categoryId: String,
    languageCode: String
): String {
    val syncedName = widgetData.getString("widgetShortcutCategoryName", null)
    if (!syncedName.isNullOrBlank()) {
        return syncedName
    }
    return when (categoryId) {
        "study" -> label(languageCode, "Ders", "Study")
        "work" -> label(languageCode, "\u0130\u015f", "Work")
        "read", "reading" -> label(languageCode, "Okuma", "Reading")
        "math" -> label(languageCode, "Matematik", "Math")
        else -> label(languageCode, "Ders", "Study")
    }
}

class CatudyPetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_pet_widget).apply {
                val languageCode = widgetData.catudyLanguageCode()
                val petName = widgetData.getString("petName", "Mochi") ?: "Mochi"
                val petMood = widgetData.getInt("petMood", 100)
                val petHunger = widgetData.getInt("petHunger", 100)
                val petEnergy = widgetData.getInt("petEnergy", 100)
                val streakDays = widgetData.getInt("streakDays", 0)

                setTextViewText(R.id.widget_pet_name, petName)
                setTextViewText(R.id.widget_pet_mood_label, label(languageCode, "Mod", "Mood"))
                setTextViewText(
                    R.id.widget_pet_hunger_label,
                    label(languageCode, "A\u00e7l\u0131k", "Hunger")
                )
                setTextViewText(R.id.widget_pet_energy_label, label(languageCode, "Enerji", "Energy"))

                setTextViewText(R.id.widget_pet_mood_val, petMood.toString())
                setProgressBar(R.id.widget_pet_mood_bar, 100, petMood, false)

                setTextViewText(R.id.widget_pet_hunger_val, petHunger.toString())
                setProgressBar(R.id.widget_pet_hunger_bar, 100, petHunger, false)

                setTextViewText(R.id.widget_pet_energy_val, petEnergy.toString())
                setProgressBar(R.id.widget_pet_energy_bar, 100, petEnergy, false)

                setTextViewText(
                    R.id.widget_pet_streak,
                    "$streakDays ${label(languageCode, "G\u00fcn Serisi", "Day Streak")}"
                )

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///pet-room")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_pet_avatar, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class CatudyProgressWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_progress_widget).apply {
                val languageCode = widgetData.catudyLanguageCode()
                val dailyGoalMinutes = widgetData.getInt("dailyGoalMinutes", 45)
                val dailyGoalCompletedMinutes = widgetData.getInt("dailyGoalCompletedMinutes", 0)
                val percent = (if (dailyGoalMinutes > 0) {
                    (dailyGoalCompletedMinutes * 100) / dailyGoalMinutes
                } else {
                    0
                }).coerceAtMost(100)

                setTextViewText(
                    R.id.widget_progress_title,
                    label(languageCode, "G\u00fcnl\u00fck Hedef", "Daily Goal")
                )
                setTextViewText(
                    R.id.widget_progress_value,
                    "$dailyGoalCompletedMinutes/$dailyGoalMinutes ${minuteUnit(languageCode)}"
                )
                setProgressBar(R.id.widget_progress_bar, 100, percent, false)

                val progressLabel = if (percent >= 100) {
                    label(languageCode, "Hedef tamam!", "Goal done!")
                } else if (isEnglish(languageCode)) {
                    "$percent% done"
                } else {
                    "%$percent tamam"
                }
                setTextViewText(R.id.widget_progress_label, progressLabel)

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///stats")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    101,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_progress_value, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class CatudyShortcutWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_shortcut_widget).apply {
                val languageCode = widgetData.catudyLanguageCode()
                val categoryId = widgetData.getString("widgetShortcutCategoryId", "study") ?: "study"
                val categoryName = shortcutCategoryName(widgetData, categoryId, languageCode)
                val activeSessionCategory = widgetData.getString("activeSessionCategory", "") ?: ""
                val activeSessionMinutesLeft = widgetData.getInt("activeSessionMinutesLeft", 0)

                setTextViewText(R.id.widget_shortcut_title, categoryName)
                setTextViewText(
                    R.id.widget_shortcut_subtitle,
                    label(languageCode, "H\u0131zl\u0131 odak", "Quick focus")
                )

                if (activeSessionCategory.isNotEmpty()) {
                    val suffix = label(languageCode, "kald\u0131", "left")
                    setTextViewText(
                        R.id.widget_shortcut_status,
                        "$activeSessionMinutesLeft ${minuteUnit(languageCode)} $suffix"
                    )
                } else {
                    setTextViewText(
                        R.id.widget_shortcut_status,
                        label(languageCode, "Haz\u0131r", "Ready")
                    )
                }

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///focus/start?category=$categoryId")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    102,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_shortcut_action_btn, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class CatudyStreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_streak_widget).apply {
                val languageCode = widgetData.catudyLanguageCode()
                val streakDays = widgetData.getInt("streakDays", 0)
                val completed = widgetData.getInt("dailyGoalCompletedMinutes", 0)
                val goal = widgetData.getInt("dailyGoalMinutes", 45)
                val percent = if (goal > 0) ((completed * 100) / goal).coerceAtMost(100) else 0

                setTextViewText(R.id.widget_streak_title, label(languageCode, "Seri", "Streak"))
                setTextViewText(R.id.widget_streak_days, streakDays.toString())
                setTextViewText(
                    R.id.widget_streak_goal,
                    "$completed/$goal ${minuteUnit(languageCode)}"
                )
                setProgressBar(R.id.widget_streak_progress, 100, percent, false)

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///stats")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    103,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_streak_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
