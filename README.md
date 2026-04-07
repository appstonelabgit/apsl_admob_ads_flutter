# Apsl AdMob Ads Flutter

> **⚠️ v2.0.0 BREAKING CHANGES** — this release is a deep audit pass focused on **ad fill, load latency, and reliability**. Single-field callbacks (`ad.onAdLoaded = …`) have been replaced with a multicast listener API (`ad.addOnAdLoaded(…)`), `ApslAds.initialize()` no longer accepts `preloadRewardedAds` (use `RewardedAdConfig` instead), and `loadAndShowRewardedAd` now returns `Future<bool>`. See the full migration notes in `CHANGELOG.md`.

Seamlessly integrate Google AdMob ads into your Flutter app using the `apsl_admob_ads_flutter` package. Provides exponential-backoff retries, error-code-based classification, network-aware reload, and configurable ad management for all AdMob ad types.

🌟 If this package benefits you, show your support by giving it a star on GitHub!

## 🚀 What's in 2.0.0

- **Exponential backoff retries** (2s → 4s → 8s … capped 64s) replacing the old fixed 30 s delay
- **Default `maxRetries` raised from 1 → 5** — single biggest fill-rate fix
- **Error-code-based classification** using `LoadAdError.code` instead of fragile substring matching
- **Network- and lifecycle-aware load resumer** powered by `connectivity_plus` — ads automatically recover when the device comes back online or the app returns to the foreground
- **Cold-start preloads run in parallel** — `initialize()` no longer blocks on three sequential network round-trips
- **Multicast listener model** so the event stream and widget callbacks coexist without clobbering each other
- **Rewarded ads default to preloaded** for instant show on tap
- **App Open ads pre-warm after dismiss** so the next foreground is instant
- **Race-free**: load generation tokens discard stale callbacks from cancelled loads

## 🎯 Features

- **Google AdMob Integration**:
  - Banner Ads with configurable retry and loading widgets
  - Native Ads with template customization and retry logic
  - Interstitial Ads with advanced error handling
  - Rewarded Ads with configurable preloading
  - App Open Ads with lifecycle management
- **Configurable retry policy** per ad type (`BannerAdConfig`, `NativeAdConfig`, `InterstitialAdConfig`, `RewardedAdConfig`)
- **Detailed error categorization** via `AdErrorType`
- **Load timeout handling** with sane defaults
- **Comprehensive event streaming** via `ApslAds.instance.onEvent`
- **Multicast per-ad listeners** via `addOn*` methods

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  apsl_admob_ads_flutter: ^2.0.0
```

```bash
flutter pub get
```

## 📱 AdMob Mediation

The plugin offers comprehensive AdMob mediation support. See:

- [AdMob Mediation Guide](https://developers.google.com/admob/flutter/mediation/get-started)

Remember to configure the native platform settings for AdMob mediation.

## 🛠 Platform-Specific Setup

### iOS

#### 📝 Update your Info.plist

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_SDK_KEY</string>
```

Additionally, add `SKAdNetworkItems` for all networks. You can find and copy the `SKAdNetworkItems` from the example [info.plist](https://github.com/appstonelabgit/apsl_admob_ads_flutter/blob/main/example/ios/Runner/Info.plist).

### Android

#### 📝 Update AndroidManifest.xml

```xml
<manifest>
    <application>
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
    </application>
</manifest>
```

## 🧩 Initialize Ad IDs

```dart
import 'dart:io';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';

class MyAdsIdManager extends AdsIdManager {
  const MyAdsIdManager();

  @override
  List<AppAdIds> get appAdIds => [
        AppAdIds(
          adNetwork: AdNetwork.admob,
          appId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx~zzzzzzzzzz',
          appOpenId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx/aaaaaaaaaa'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx/bbbbbbbbbb',
          bannerId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx/cccccccccc'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx/dddddddddd',
          interstitialId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx/eeeeeeeeee'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx/ffffffffff',
          rewardedId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx/gggggggggg'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx/hhhhhhhhhh',
          nativeId: Platform.isAndroid
              ? 'ca-app-pub-xxxxxxxxxxxxxxxx/iiiiiiiiii'
              : 'ca-app-pub-xxxxxxxxxxxxxxxx/jjjjjjjjjj',
        ),
      ];
}
```

## 🚀 SDK Initialization

```dart
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

const AdsIdManager adIdManager = MyAdsIdManager();

await ApslAds.instance.initialize(
  adIdManager,
  adMobAdRequest: const AdRequest(),
  admobConfiguration: RequestConfiguration(testDeviceIds: []),
  // Tune retry / timeout / immersive mode for the highest-revenue formats:
  interstitialAdConfig: const InterstitialAdConfig(
    maxRetries: 5,
    loadTimeout: Duration(seconds: 20),
    immersiveModeEnabled: true,
  ),
  rewardedAdConfig: const RewardedAdConfig(
    maxRetries: 5,
    preLoadRewardedAds: true, // instant show on first tap
    autoReloadAfterShow: true, // next tap is also instant
  ),
);
```

`initialize()` returns as soon as the AdMob SDK is ready — preloads run in the background in parallel and do **not** block your `runApp` call.

## 🎥 Interstitial Ads

```dart
// Show the next interstitial in the round-robin
ApslAds.instance.showAd(AdUnitType.interstitial);

// With a loader dialog while we wait
ApslAds.instance.showAd(
  AdUnitType.interstitial,
  shouldShowLoader: true,
  context: context,
);
```

Interstitials are auto-reloaded after dismiss (or after a show failure) so the next call is ready immediately.

## 🎁 Rewarded Ads

The recommended pattern is `await`-ing the new `Future<bool>` return value so you can branch on success/failure:

```dart
final shown = await ApslAds.instance.loadAndShowRewardedAd(
  context: context,
  adNetwork: AdNetwork.admob,
  // Hard timeout — if the load doesn't complete in this window, the
  // loader dialog dismisses and the call returns false.
  waitTimeout: const Duration(seconds: 10),
);

if (shown) {
  // Subscribe to onEvent / earnedReward to credit the user.
}
```

- **Cache hit fast path** — if the rewarded ad is already loaded, it's shown instantly with no loader dialog.
- **Hard wait timeout** — never spins forever on a hung load.
- **Always reloads after dismiss** so the next tap is also instant.

Use `ApslAds.instance.onEvent` to react to `earnedReward`:

```dart
ApslAds.instance.onEvent.listen((event) {
  if (event.adUnitType == AdUnitType.rewarded &&
      event.type == AdEventType.earnedReward) {
    // event.data == { rewardType, rewardAmount }
  }
});
```

## 🎨 Banner Ads

```dart
const ApslBannerAd(
  adNetwork: AdNetwork.admob,
  adSize: AdSize.banner,
)
```

With a custom retry policy:

```dart
const ApslBannerAd(
  adNetwork: AdNetwork.admob,
  adSize: AdSize.banner,
  config: BannerAdConfig(
    maxRetries: 5,
    retryDelay: Duration(seconds: 2), // base delay for backoff
    maxRetryDelay: Duration(seconds: 64), // backoff cap
    useExponentialBackoff: true,
    loadTimeout: Duration(seconds: 20),
    loadingWidget: Center(child: CircularProgressIndicator()),
  ),
)
```

> 💡 `BannerAdConfig` (and the other three configs) have value-based `==`/`hashCode`. A parent rebuild that constructs an inline `const` config does **not** destroy the in-flight ad.

## 🎯 Native Ads

```dart
const ApslNativeAd(
  adNetwork: AdNetwork.admob,
  templateType: TemplateType.medium,
)
```

With a custom height and config:

```dart
const ApslNativeAd(
  adNetwork: AdNetwork.admob,
  templateType: TemplateType.small,
  customHeight: 120,
  config: NativeAdConfig(
    maxRetries: 5,
    loadTimeout: Duration(seconds: 20),
    loadingWidget: Center(child: CircularProgressIndicator()),
  ),
)
```

The `onAdShowed` analytics callback fires **exactly once per loaded ad** via the SDK's `onAdImpression` listener — independent of how many times the parent rebuilds.

## 📊 Per-ad listener API

`ApslAdBase` exposes a multicast listener model. Multiple subscribers can attach to the same ad without clobbering each other:

```dart
final ad = ApslAds.instance.createBanner(
  adNetwork: AdNetwork.admob,
  adSize: AdSize.banner,
);

ad?.addOnAdLoaded((network, unit, data, {errorMessage, rewardType, rewardAmount}) {
  // analytics: impression
});

ad?.addOnAdFailedToLoad((network, unit, data, {errorMessage, rewardType, rewardAmount}) {
  // analytics: failure
});

ad?.addOnAdShowed((network, unit, data, {errorMessage, rewardType, rewardAmount}) {
  // analytics: shown
});
```

Available registration methods:

- `addOnAdLoaded`
- `addOnAdShowed`
- `addOnAdClicked`
- `addOnAdFailedToLoad`
- `addOnAdFailedToShow`
- `addOnAdDismissed`
- `addOnEarnedReward`
- `addOnBannerAdReadyForSetState`
- `addOnNativeAdReadyForSetState`

Call `ad.clearListeners()` (already done by `dispose()`) to release closure references.

## 🌐 Network-aware retry

The package automatically re-arms ad loads on two signals:

1. **Connectivity restored** — offline → online transition (via `connectivity_plus`)
2. **App returned to the foreground** — `AppLifecycleState.resumed`

So an ad that exhausted its retry budget on a flaky network is automatically revived without the user having to restart your app. No additional configuration required.

## 🛑 Disabling ads (e.g. for premium users)

```dart
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';

// Set BEFORE calling ApslAds.instance.initialize() for the strongest effect.
// In-flight loads are NOT cancelled — only future load() calls are skipped.
forceStopToLoadAds = true;
```

## ♻️ Cleanup

```dart
// Disposes every ad managed by the singleton plus the lifecycle reactor
// and the connectivity-aware load resumer. Safe to call multiple times.
ApslAds.instance.destroyAds();
```

## 📋 Migration from 1.x → 2.0

| Before (1.x) | After (2.0) |
|---|---|
| `ApslAds.initialize(manager, preloadRewardedAds: true)` | `ApslAds.initialize(manager, rewardedAdConfig: RewardedAdConfig(preLoadRewardedAds: true))` |
| `ad.onAdLoaded = cb;` | `ad.addOnAdLoaded(cb);` |
| `ad.onAdShowed = cb;` | `ad.addOnAdShowed(cb);` |
| `bool shown = ApslAds.instance.loadAndShowRewardedAd(context: c);` | `bool shown = await ApslAds.instance.loadAndShowRewardedAd(context: c);` |
| `BannerAdConfig(retryDelay: Duration(seconds: 30), maxRetries: 1)` | Defaults are now exponential backoff with `maxRetries: 5`. Override via the new `useExponentialBackoff`, `maxRetryDelay`, etc. fields. |

The full set of breaking changes and the rationale for each is documented in `CHANGELOG.md`.
