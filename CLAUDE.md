# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`apsl_admob_ads_flutter` is a published Flutter package (pub.dev) wrapping `google_mobile_ads` to provide a unified API over Banner, Native, Interstitial, Rewarded, and App Open ads with retry/error/timeout handling. The `example/` directory is a separate Flutter app that consumes the package locally and is the primary way to manually test changes.

## Common commands

```bash
# Package-level (run from repo root)
flutter pub get
flutter analyze            # uses flutter_lints
flutter test               # runs test/apsl_ads_test.dart
flutter test test/apsl_ads_test.dart -n "test name"   # single test

# Example app (run from ./example)
cd example && flutter pub get
flutter run                # on a connected device/emulator
```

There is no separate build step — this is a Dart/Flutter library, not an app. Publishing is done via `flutter pub publish` (maintainer-only); `version` in `pubspec.yaml` and `CHANGELOG.md` must be bumped together.

## Architecture

The package is a thin orchestration layer over `google_mobile_ads`. The key abstractions live in `lib/src/`:

- **`ApslAds` (singleton, `apsl_ads.dart`)** is the entry point. `ApslAds.instance.initialize(adIdManager, …)` is called once at app startup. It walks the user-supplied `AdsIdManager.appAdIds`, initializes the Mobile Ads SDK exactly once (`_isMobileAdNetworkInitialized`), and eagerly constructs interstitial / rewarded / app-open ad instances per configured ad unit, storing them in `_interstitialAds`, `_rewardedAds`, `_appOpenAds`. Each list is round-robin indexed (`_interstitialAdIndex`, etc.) by `_updateAdIndex` after a successful `showAd`.

- **`ApslAdBase` (`apsl_ad_base.dart`)** is the abstract contract every ad type implements: `load()`, `show()`, `dispose()`, `isAdLoaded`, plus a multicast listener API — `addOnAdLoaded(cb)`, `addOnAdShowed(cb)`, `addOnAdFailedToLoad(cb)`, `addOnAdFailedToShow(cb)`, `addOnAdDismissed(cb)`, `addOnEarnedReward(cb)`, `addOnBannerAdReadyForSetState(cb)`, `addOnNativeAdReadyForSetState(cb)`, plus `clearListeners()`. Subclasses dispatch via protected `fireAdLoaded(...)`/`fireAdFailedToLoad(...)`/etc. helpers that fan out to every registered listener. The pre-2.0 design used single-field callback slots that silently overwrote each other when both the event controller and a widget tried to attach.

- **AdMob implementations (`lib/src/apsl_admob/`)** — one file per ad format (`apsl_admob_banner_ad.dart`, `apsl_admob_native_ad.dart`, `apsl_admob_interstitial_ad.dart`, `apsl_admob_rewarded_ad.dart`, `apsl_admob_app_open_ad.dart`). Each wraps the corresponding `google_mobile_ads` class and applies retry/timeout logic from its config object. `app_lifecycle_reactor.dart` uses `WidgetsBindingObserver` to show app-open ads on resume; it is wired up only when `initialize(isShowAppOpenOnAppStateChange: true)`.

- **Configs (`lib/src/config/`)** — `BannerAdConfig`, `NativeAdConfig`, `InterstitialAdConfig`, `RewardedAdConfig`. They carry `retryDelay` (base for backoff), `maxRetryDelay` (cap), `maxRetries`, `useExponentialBackoff`, `loadTimeout`, `loadingWidget`, `immersiveModeEnabled`, etc. All four implement value-based `==`/`hashCode`. Banner/Native are passed via the widget constructors; Interstitial/Rewarded are passed via `ApslAds.initialize(interstitialAdConfig:, rewardedAdConfig:)`. Retry policy uses the shared `retry_policy.dart` (truncated exponential backoff) and error classification uses `ad_error_mapper.dart` (numeric `LoadAdError.code` constants).

- **Widgets (`lib/src/utils/apsl_banner_ad.dart`, `apsl_native_ad.dart`)** — `ApslBannerAd` and `ApslNativeAd` are `StatefulWidget`s users embed in their tree. They internally call `ApslAds.instance.createBanner` / `createNative`, listen for the "ready for setState" callback, and render the loading widget / placeholder until the ad is bound.

- **Sequence ads (`lib/src/apsl_sequence_ads/`)** — `ApslSequenceBanner` / `ApslSequenceNative` cycle through multiple ad networks in order (currently only `admob` is implemented in the switch statements; `AdNetwork.any` is a placeholder for future networks).

- **Events (`lib/src/utils/apsl_event_controller.dart`, `ad_event.dart`, `enums/apsl_event_type.dart`)** — every ad created through `ApslAds` is registered with `_eventController.setupEvents(ad)`, which forwards lifecycle callbacks into a single `Stream<AdEvent>` exposed as `ApslAds.instance.onEvent`. `loadAndShowRewardedAd` subscribes to this stream to coordinate the loader dialog with `adLoaded` / `adFailedToLoad` events. When adding new ad types, you must call `_eventController.setupEvents(ad)` after construction or events will silently drop.

- **`AdsIdManager` (`lib/src/utils/ads_id_manager.dart`)** is an abstract class the consuming app subclasses to declare its `AppAdIds` per platform. `TestAdsIdManager` provides Google's test IDs.

- **Public surface** — `lib/apsl_admob_ads_flutter.dart` is the barrel file. Anything not exported here is private to the package. It also re-exports `package:google_mobile_ads/google_mobile_ads.dart` so consumers don't need to add it as a direct dep.

### Key invariants when modifying

- The single `ApslAds` instance keeps three parallel lists (`_interstitialAds`, `_rewardedAds`, `_appOpenAds`) plus per-list round-robin indices. Any code that adds/removes ads must keep the index `< list.length` (see `_updateAdIndex`'s modulo) and call `dispose()` on removed entries.
- `_initAdmob` uses `doesNotContain(adNetwork, adUnitType, adUnitId)` (in `utils/extensions.dart`) to dedupe — re-calling `initialize` with the same IDs is a no-op for existing ads.
- `forceStopToLoadAds` (referenced in `_initAdmob`) is a global kill switch from `extensions.dart` for blocking all ad loads (e.g. for premium users).
- `onAdShowed` / `onAdFailedToShow` are guaranteed to fire **exactly once** per show attempt — when adding new ad types, preserve this contract (it's documented in the README and is what analytics consumers rely on).
- The `AdNetwork` enum currently has `admob` and `any`. Switch statements deliberately fall through `default` to `null` so future networks can be added without breaking existing call sites.
