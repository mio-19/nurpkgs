/*
 * ArchiveTune (2026)
 * © Rukamori — github.com/rukamori
 * GPL-3.0 License | Contributors: see git history
 * Do not remove or alter this notice. - Per GPL-3.0 Section 4 & Section 5
 */

@file:OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalMaterial3Api::class)

package moe.rukamori.archivetune.ui.screens.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.net.toUri
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import moe.rukamori.archivetune.LocalPlayerAwareWindowInsets
import moe.rukamori.archivetune.R
import moe.rukamori.archivetune.constants.*
import moe.rukamori.archivetune.innertube.YouTube
import moe.rukamori.archivetune.ui.component.EditTextPreference
import moe.rukamori.archivetune.ui.component.IconButton
import moe.rukamori.archivetune.ui.component.ListPreference
import moe.rukamori.archivetune.ui.component.PreferenceEntry
import moe.rukamori.archivetune.ui.component.PreferenceGroup
import moe.rukamori.archivetune.ui.component.SwitchPreference
import moe.rukamori.archivetune.ui.utils.backToMain
import moe.rukamori.archivetune.utils.rememberEnumPreference
import moe.rukamori.archivetune.utils.rememberPreference
import moe.rukamori.archivetune.utils.setAppLocale
import moe.rukamori.archivetune.viewmodels.AiContentFilterSettingsEffect
import moe.rukamori.archivetune.viewmodels.AiContentFilterSettingsState
import moe.rukamori.archivetune.viewmodels.ContentSettingsViewModel
import java.util.Locale

@Composable
fun ContentSettings(
    navController: NavController,
    viewModel: ContentSettingsViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val aiContentFilterState by viewModel.aiContentFilterState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(viewModel, context) {
        viewModel.aiContentFilterEffects.collect { effect ->
            when (effect) {
                is AiContentFilterSettingsEffect.ShowMessage -> {
                    snackbarHostState.showSnackbar(context.getString(effect.messageResId))
                }

                is AiContentFilterSettingsEffect.OpenUrl -> {
                    context.startActivity(Intent(Intent.ACTION_VIEW, effect.url.toUri()))
                }
            }
        }
    }

    val (useSystemLanguage, onUseSystemLanguageChange) = rememberPreference(key = UseSystemLanguageKey, defaultValue = true)

    val (contentLanguage, onContentLanguageChange) = rememberPreference(key = ContentLanguageKey, defaultValue = "system")
    val (contentCountry, onContentCountryChange) = rememberPreference(key = ContentCountryKey, defaultValue = "system")
    val (playlistSuggestionSource, onPlaylistSuggestionSourceChange) =
        rememberEnumPreference(
            key = PlaylistSuggestionSourceKey,
            defaultValue = PlaylistSuggestionSource.BOTH,
        )
    val (hideExplicit, onHideExplicitChange) = rememberPreference(key = HideExplicitKey, defaultValue = false)
    val (hideVideo, onHideVideoChange) = rememberPreference(key = HideVideoKey, defaultValue = false)
    val (lengthTop, onLengthTopChange) = rememberPreference(key = TopSize, defaultValue = "50")
    val (quickPicks, onQuickPicksChange) = rememberEnumPreference(key = QuickPicksKey, defaultValue = QuickPicks.QUICK_PICKS)

    Column(
        Modifier
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current)
            .verticalScroll(rememberScrollState())
            .padding(bottom = SettingsDimensions.ScreenBottomPadding),
    ) {
        PreferenceGroup(title = "general") {
            item {
                ListPreference(
                    title = { Text("content_language") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    selectedValue = contentLanguage,
                    values = listOf(SYSTEM_DEFAULT) + LanguageCodeToName.keys.toList(),
                    valueText = {
                        LanguageCodeToName.getOrElse(it) { "system_default" }
                    },
                    onValueSelected = { newValue ->
                        val locale = Locale.getDefault()
                        val languageTag = locale.toLanguageTag().replace("-Hant", "")

                        YouTube.locale =
                            YouTube.locale.copy(
                                hl =
                                    newValue.takeIf { it != SYSTEM_DEFAULT }
                                        ?: locale.language.takeIf { it in LanguageCodeToName }
                                        ?: languageTag.takeIf { it in LanguageCodeToName }
                                        ?: "en",
                            )

                        onContentLanguageChange(newValue)
                    },
                )
            }

            item {
                ListPreference(
                    title = { Text("content_country") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    selectedValue = contentCountry,
                    values = listOf(SYSTEM_DEFAULT) + CountryCodeToName.keys.toList(),
                    valueText = {
                        CountryCodeToName.getOrElse(it) { "system_default" }
                    },
                    onValueSelected = { newValue ->
                        val locale = Locale.getDefault()

                        YouTube.locale =
                            YouTube.locale.copy(
                                gl =
                                    newValue.takeIf { it != SYSTEM_DEFAULT }
                                        ?: locale.country.takeIf { it in CountryCodeToName }
                                        ?: "US",
                            )

                        onContentCountryChange(newValue)
                    },
                )
            }

            item {
                ListPreference(
                    title = { Text("you_might_like_source") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    selectedValue = playlistSuggestionSource,
                    values =
                        listOf(
                            PlaylistSuggestionSource.PLAYLIST_TITLE,
                            PlaylistSuggestionSource.PLAYLIST_CONTENT,
                            PlaylistSuggestionSource.BOTH,
                        ),
                    valueText = {
                        when (it) {
                            PlaylistSuggestionSource.PLAYLIST_TITLE -> "playlist_suggestion_source_title"
                            PlaylistSuggestionSource.PLAYLIST_CONTENT -> "playlist_suggestion_source_content"
                            PlaylistSuggestionSource.BOTH -> "playlist_suggestion_source_both"
                        }
                    },
                    onValueSelected = onPlaylistSuggestionSourceChange,
                )
            }

            item {
                SwitchPreference(
                    title = { Text("hide_explicit") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    checked = hideExplicit,
                    onCheckedChange = onHideExplicitChange,
                )
            }

            item {
                SwitchPreference(
                    title = { Text("hide_video") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    checked = hideVideo,
                    onCheckedChange = onHideVideoChange,
                )
            }
        }

        AiContentFilterPreferences(
            state = aiContentFilterState,
            onEnabledChange = viewModel::setAiContentFilterEnabled,
            onIncludeModerateChange = viewModel::setAiContentFilterIncludeModerate,
            onRefresh = viewModel::refreshAiContentFilter,
            onOpenSource = viewModel::openAiContentFilterSource,
        )

        PreferenceGroup(title = "app_language") {
            item {
                SwitchPreference(
                    title = { Text("use_system_language") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    checked = useSystemLanguage,
                    onCheckedChange = { checked ->
                        onUseSystemLanguageChange(checked)
                        val newLocale = if (checked) Locale.getDefault() else Locale.ENGLISH
                        setAppLocale(context, newLocale)
                        (context as? android.app.Activity)?.recreate()
                    },
                )
            }
        }

        PreferenceGroup(title = "misc") {
            item {
                EditTextPreference(
                    title = { Text("top_length") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    value = lengthTop,
                    isInputValid = { it.toIntOrNull()?.let { num -> num > 0 } == true },
                    onValueChange = onLengthTopChange,
                )
            }

            item {
                ListPreference(
                    title = { Text("set_quick_picks") },
                    icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                    selectedValue = quickPicks,
                    values = listOf(QuickPicks.QUICK_PICKS, QuickPicks.LAST_LISTEN, QuickPicks.DONT_SHOW),
                    valueText = {
                        when (it) {
                            QuickPicks.QUICK_PICKS -> "quick_picks"
                            QuickPicks.LAST_LISTEN -> "last_song_listened"
                            QuickPicks.DONT_SHOW -> "dont_show"
                        }
                    },
                    onValueSelected = onQuickPicksChange,
                )
            }
        }
    }

    TopAppBar(
        title = { Text("content") },
        navigationIcon = {
            IconButton(
                onClick = navController::navigateUp,
                onLongClick = navController::backToMain,
            ) {
                Icon(
                    androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent),
                    contentDescription = null,
                )
            }
        },
    )

    Box(Modifier.fillMaxSize()) {
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

@Composable
private fun AiContentFilterPreferences(
    state: AiContentFilterSettingsState,
    onEnabledChange: (Boolean) -> Unit,
    onIncludeModerateChange: (Boolean) -> Unit,
    onRefresh: () -> Unit,
    onOpenSource: () -> Unit,
) {
    PreferenceGroup(title = "ai_content_filter") {
        when (state) {
            AiContentFilterSettingsState.Loading -> {
                item {
                    PreferenceEntry(
                        title = { Text("ai_content_filter") },
                        description = "loading",
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        isEnabled = false,
                    )
                }
            }

            AiContentFilterSettingsState.Empty -> {
                Unit
            }

            is AiContentFilterSettingsState.Error -> {
                item {
                    PreferenceEntry(
                        title = { Text("ai_content_filter") },
                        description = stringResource(state.messageResId),
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        onClick = onRefresh,
                    )
                }
            }

            is AiContentFilterSettingsState.Success -> {
                val model = state.model
                item {
                    SwitchPreference(
                        title = { Text("ai_content_filter_hide") },
                        description = "ai_content_filter_hide_summary",
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        checked = model.enabled,
                        onCheckedChange = onEnabledChange,
                    )
                }
                item {
                    SwitchPreference(
                        title = { Text("ai_content_filter_moderate") },
                        description = "ai_content_filter_moderate_summary",
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        checked = model.includeModerateConfidence,
                        onCheckedChange = onIncludeModerateChange,
                        isEnabled = model.enabled,
                    )
                }
                item {
                    PreferenceEntry(
                        title = { Text("ai_content_filter_update") },
                        description =
                            if (model.refreshing) {
                                "loading"
                            } else {
                                stringResource(
                                    R.string.ai_content_filter_list_counts,
                                    model.blocklistCount,
                                    model.warnlistCount,
                                )
                            },
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        onClick = onRefresh,
                        isEnabled = !model.refreshing,
                    )
                }
                item {
                    PreferenceEntry(
                        title = { Text("ai_content_filter_source") },
                        description = "ai_content_filter_source_summary",
                        icon = { Icon(androidx.compose.ui.graphics.painter.ColorPainter(androidx.compose.ui.graphics.Color.Transparent), null) },
                        onClick = onOpenSource,
                    )
                }
            }
        }
    }
}
