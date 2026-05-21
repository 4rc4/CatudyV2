package com.catudy.catudy_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CatudyPetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_pet_widget).apply {
                val petName = widgetData.getString("petName", "Mochi") ?: "Mochi"
                val petMood = widgetData.getInt("petMood", 100)
                val petHunger = widgetData.getInt("petHunger", 100)
                val petEnergy = widgetData.getInt("petEnergy", 100)
                val streakDays = widgetData.getInt("streakDays", 0)

                setTextViewText(R.id.widget_pet_name, petName)
                
                setTextViewText(R.id.widget_pet_mood_val, petMood.toString())
                setProgressBar(R.id.widget_pet_mood_bar, 100, petMood, false)

                setTextViewText(R.id.widget_pet_hunger_val, petHunger.toString())
                setProgressBar(R.id.widget_pet_hunger_bar, 100, petHunger, false)

                setTextViewText(R.id.widget_pet_energy_val, petEnergy.toString())
                setProgressBar(R.id.widget_pet_energy_bar, 100, petEnergy, false)

                setTextViewText(R.id.widget_pet_streak, "$streakDays Gün Serisi")

                // Pending Intent to open app in pet room
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///pet-room")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 100, intent,
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
                val dailyGoalMinutes = widgetData.getInt("dailyGoalMinutes", 45)
                val dailyGoalCompletedMinutes = widgetData.getInt("dailyGoalCompletedMinutes", 0)
                
                val percent = if (dailyGoalMinutes > 0) {
                    (dailyGoalCompletedMinutes * 100) / dailyGoalMinutes
                } else {
                    0
                }

                setTextViewText(R.id.widget_progress_value, "$dailyGoalCompletedMinutes/$dailyGoalMinutes dk")
                setProgressBar(R.id.widget_progress_bar, 100, percent.coerceAtMost(100), false)
                
                if (percent >= 100) {
                    setTextViewText(R.id.widget_progress_label, "Hedef Tamamlandı! 🎉")
                } else {
                    setTextViewText(R.id.widget_progress_label, "%$percent Tamamlandı")
                }

                // Pending Intent to open app in stats
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///stats")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 101, intent,
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
                val categoryId = widgetData.getString("widgetShortcutCategoryId", "study") ?: "study"
                val categoryName = when (categoryId) {
                    "study" -> "Ders"
                    "work" -> "İş"
                    "reading" -> "Okuma"
                    "math" -> "Matematik"
                    else -> "Ders"
                }

                val activeSessionCategory = widgetData.getString("activeSessionCategory", "") ?: ""
                val activeSessionMinutesLeft = widgetData.getInt("activeSessionMinutesLeft", 0)

                setTextViewText(R.id.widget_shortcut_title, categoryName)

                if (activeSessionCategory.isNotEmpty()) {
                    setTextViewText(R.id.widget_shortcut_status, "$activeSessionMinutesLeft dk kaldı")
                } else {
                    setTextViewText(R.id.widget_shortcut_status, "Hazır")
                }

                // Pending Intent to start focus in app
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///focus/start?category=$categoryId")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 102, intent,
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
                val streakDays = widgetData.getInt("streakDays", 0)
                val completed = widgetData.getInt("dailyGoalCompletedMinutes", 0)
                val goal = widgetData.getInt("dailyGoalMinutes", 45)
                val percent = if (goal > 0) ((completed * 100) / goal).coerceAtMost(100) else 0

                setTextViewText(R.id.widget_streak_days, streakDays.toString())
                setTextViewText(R.id.widget_streak_goal, "$completed/$goal dk")
                setProgressBar(R.id.widget_streak_progress, 100, percent, false)

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///stats")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 103, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_streak_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class CatudyWalletWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.layout_catudy_wallet_widget).apply {
                val coins = widgetData.getInt("gold", 0)
                val points = widgetData.getInt("focusPoints", 0)
                val shards = widgetData.getInt("shards", 0)

                setTextViewText(R.id.widget_wallet_coin, "$coins coin")
                setTextViewText(R.id.widget_wallet_points, "$points puan")
                setTextViewText(R.id.widget_wallet_shards, "$shards shard")

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("catudy:///shop")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 104, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_wallet_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
