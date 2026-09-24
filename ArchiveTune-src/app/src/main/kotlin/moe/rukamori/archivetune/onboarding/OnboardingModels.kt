/*
 * ArchiveTune (2026)
 * © Rukamori — github.com/rukamori
 * GPL-3.0 License | Contributors: see git history
 * Do not remove or alter this notice. - Per GPL-3.0 Section 4 & Section 5
 */

package moe.rukamori.archivetune.onboarding

import androidx.compose.runtime.Immutable
import com.google.common.collect.ImmutableList

sealed interface OnboardingScreenState {
    data object Loading : OnboardingScreenState

    data class Success(
        val uiState: OnboardingUiState,
    ) : OnboardingScreenState

    data object Empty : OnboardingScreenState

    data class Error(
        val messageResId: Int,
    ) : OnboardingScreenState
}

@Immutable
data class OnboardingUiState(
    val shouldShowOnboarding: Boolean,
    val currentPage: Int,
    val variantLabelResId: Int,
    val versionName: String,
    val pages: ImmutableList<OnboardingPageUiModel>,
    val permissions: ImmutableList<OnboardingPermissionUiModel>,
    val loginBenefits: ImmutableList<OnboardingLoginBenefitUiModel>,
    val communityActions: ImmutableList<OnboardingCommunityActionUiModel>,
)

@Immutable
data class OnboardingPageUiModel(
    val id: OnboardingPageId,
    val titleResId: Int,
    val subtitleResId: Int,
    val iconResId: Int,
)

enum class OnboardingPageId {
    WELCOME,
    PERMISSIONS,
    LOGIN,
    COMMUNITY,
}

@Immutable
data class OnboardingLoginBenefitUiModel(
    val id: String,
    val titleResId: Int,
    val descriptionResId: Int,
    val iconResId: Int,
)

@Immutable
data class OnboardingPermissionUiModel(
    val id: OnboardingPermissionId,
    val titleResId: Int,
    val descriptionResId: Int,
    val iconResId: Int,
    val status: OnboardingPermissionStatus,
    val action: OnboardingPermissionAction?,
)

data class OnboardingPermissionData(
    val id: OnboardingPermissionId,
    val status: OnboardingPermissionStatus,
    val action: OnboardingPermissionAction?,
)

enum class OnboardingPermissionId {
    NOTIFICATIONS,
    LOCAL_AUDIO,
    MICROPHONE,
    DEVICE_AUDIO_CAPTURE,
    BLUETOOTH_CONNECT,
    NETWORK,
    PLAYBACK_SERVICE,
    AUDIO_SETTINGS,
    APP_INSTALLATION,
    BLUETOOTH_SCAN,
}

enum class OnboardingPermissionStatus {
    ALLOWED,
    NEEDS_ACTION,
    ALLOWED_BY_INSTALL,
    UNAVAILABLE,
}

sealed interface OnboardingPermissionAction {
    data class RequestRuntimePermission(
        val permission: String,
    ) : OnboardingPermissionAction

    data object OpenInstallPackagesSettings : OnboardingPermissionAction
}

@Immutable
data class OnboardingCommunityActionUiModel(
    val id: String,
    val titleResId: Int,
    val descriptionResId: Int,
    val iconResId: Int,
    val url: String,
)

data class OnboardingData(
    val shouldShowOnboarding: Boolean,
    val permissions: ImmutableList<OnboardingPermissionData>,
)

sealed interface OnboardingEvent {
    data class RequestPermission(
        val permission: String,
    ) : OnboardingEvent

    data object OpenInstallPackagesSettings : OnboardingEvent

    data object OpenLogin : OnboardingEvent

    data class OpenUri(
        val url: String,
    ) : OnboardingEvent
}
