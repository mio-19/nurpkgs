/*
 * ArchiveTune (2026)
 * © Rukamori — github.com/rukamori
 * GPL-3.0 License | Contributors: see git history
 * Do not remove or alter this notice. - Per GPL-3.0 Section 4 & Section 5
 */

package moe.rukamori.archivetune.ui.screens.settings

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.navigation.NavController
import moe.rukamori.archivetune.BuildConfig
import moe.rukamori.archivetune.R

@Composable
fun buildSettingsGroups(
    navController: NavController,
    isAndroid12OrLater: Boolean,
    hasUpdate: Boolean,
    context: Context,
): List<SettingsGroup> {
    val account =
        SettingsItem(
            key = "account",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "account",
            subtitle = "settings_account_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("settings/account") },
        )
    val stats =
        SettingsItem(
            key = "stats",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "settings_stats_title",
            subtitle = "settings_stats_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("stats") },
        )
    val appearance =
        SettingsItem(
            key = "appearance",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "appearance",
            subtitle = "settings_appearance_subtitle",
            accentColor = MaterialTheme.colorScheme.secondary,
            onClick = { navController.navigate("settings/appearance") },
        )
    val playback =
        SettingsItem(
            key = "playback",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "settings_playback_title",
            subtitle = "settings_playback_subtitle",
            accentColor = MaterialTheme.colorScheme.tertiary,
            onClick = { navController.navigate("settings/player") },
        )
    val canvas =
        SettingsItem(
            key = "canvas",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "archivetune_canvas",
            subtitle = "canvas_settings_subtitle",
            accentColor = MaterialTheme.colorScheme.tertiary,
            onClick = { navController.navigate("settings/canvas") },
        )
    val lyrics =
        SettingsItem(
            key = "lyrics",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "lyrics",
            subtitle = "settings_lyrics_subtitle",
            accentColor = MaterialTheme.colorScheme.secondary,
            onClick = { navController.navigate("settings/lyrics") },
        )
    val content =
        SettingsItem(
            key = "content",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "content",
            subtitle = "settings_content_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("settings/content") },
        )
    val behavior =
        SettingsItem(
            key = "behavior",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "settings_behavior_title",
            subtitle = "settings_behavior_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("settings/privacy") },
        )
    val integration =
        SettingsItem(
            key = "integration",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "integration",
            subtitle = "settings_integration_subtitle",
            accentColor = MaterialTheme.colorScheme.secondary,
            onClick = { navController.navigate("settings/integration") },
        )
    val aiIntegration =
        SettingsItem(
            key = "ai_integration",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "ai_integration",
            subtitle = "ai_integration_desc",
            accentColor = MaterialTheme.colorScheme.secondary,
            onClick = { navController.navigate("settings/ai_integration") },
        )
    val internet =
        SettingsItem(
            key = "internet",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "internet",
            subtitle = "settings_internet_subtitle",
            accentColor = MaterialTheme.colorScheme.tertiary,
            onClick = { navController.navigate("settings/internet") },
        )
    val storage =
        SettingsItem(
            key = "storage",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "storage",
            subtitle = "settings_storage_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("settings/storage") },
        )
    val backupRestore =
        SettingsItem(
            key = "backup_restore",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "backup_restore",
            subtitle = "settings_backup_restore_subtitle",
            accentColor = MaterialTheme.colorScheme.primary,
            onClick = { navController.navigate("settings/backup_restore") },
        )
    val developerOptions =
        SettingsItem(
            key = "developer_options",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "settings_developer_options_title",
            subtitle = "settings_developer_options_subtitle",
            accentColor = MaterialTheme.colorScheme.tertiary,
            onClick = { navController.navigate("settings/misc") },
        )
    val defaultLinks =
        if (isAndroid12OrLater) {
            SettingsItem(
                key = "default_links",
                icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
                title = "default_links",
                subtitle = "open_supported_links",
                accentColor = MaterialTheme.colorScheme.secondary,
                onClick = {
                    try {
                        val intent =
                            Intent(
                                Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS,
                                Uri.parse("package:${context.packageName}"),
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        context.startActivity(intent)
                    } catch (e: Exception) {
                        when (e) {
                            is ActivityNotFoundException,
                            is SecurityException,
                            -> {
                                Toast
                                    .makeText(
                                        context,
                                        R.string.open_app_settings_error,
                                        Toast.LENGTH_LONG,
                                    ).show()
                            }

                            else -> {
                                Toast
                                    .makeText(
                                        context,
                                        R.string.open_app_settings_error,
                                        Toast.LENGTH_LONG,
                                    ).show()
                            }
                        }
                    }
                },
            )
        } else {
            null
        }
    val updates =
        if (BuildConfig.UPDATER_AVAILABLE) {
            SettingsItem(
                key = "updates",
                icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
                title = "updates",
                subtitle =
                    if (hasUpdate) {
                        "new_version_available"
                    } else {
                        "settings_updates_subtitle"
                    },
                showUpdateIndicator = hasUpdate,
                accentColor =
                    if (hasUpdate) {
                        MaterialTheme.colorScheme.tertiary
                    } else {
                        MaterialTheme.colorScheme.primary
                    },
                badge = if (hasUpdate) "v${BuildConfig.VERSION_NAME}" else BuildConfig.VERSION_NAME,
                onClick = { navController.navigate("settings/update") },
            )
        } else {
            null
        }
    val about =
        SettingsItem(
            key = "about",
            icon = androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
            title = "about",
            subtitle = "settings_about_subtitle",
            accentColor = MaterialTheme.colorScheme.secondary,
            onClick = { navController.navigate("settings/about") },
        )

    return listOf(
        SettingsGroup(
            title = "settings",
            items = listOf(account, stats),
        ),
        SettingsGroup(
            title = "settings_section_player_content",
            items = listOf(appearance, playback, canvas, lyrics, content, behavior),
        ),
        SettingsGroup(
            title = "integration",
            items = listOf(integration, aiIntegration, internet),
        ),
        SettingsGroup(
            title = "storage",
            items = listOf(storage, backupRestore),
        ),
        SettingsGroup(
            title = "about",
            items =
                buildList {
                    add(developerOptions)
                    defaultLinks?.let(::add)
                    updates?.let(::add)
                    add(about)
                },
        ),
    )
}
