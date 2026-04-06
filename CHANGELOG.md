# 📋 Changelog

All notable changes to the `apsl_admob_ads_flutter` package will be documented in this file.

## 🚀 Version 2.0.0 - Reliability, Revenue, and Retry Overhaul

**Release Date:** Apr 6, 2026
**Package:** `apsl_admob_ads_flutter`

This release is a deep audit pass focused on ad fill, load latency, and
reliability. It contains breaking API changes — see migration notes below.

### 💰 Revenue & fill improvements

- **Exponential backoff retries** (2s → 4s → 8s → … capped at 64s) replace
  the old fixed 30-second retry. Single biggest fill-rate win.
- **Default `maxRetries` raised from 1 to 5** across all four ad configs.
  Previously a single failed retry left the slot dead for the rest of
  the session.
- **Error-code-based classification** using the SDK's stable
  `LoadAdError.code` constants instead of fragile substring matching.
  Non-recoverable errors (invalid ad unit / missing app id) now stop
  retrying instead of hammering the network forever.
- **Rewarded ads default to preloaded** (`preLoadRewardedAds: true`) and
  always reload after dismiss — the next user tap is instant.
- **Network- and lifecycle-aware load resumer**: any ad that exhausted
  its retry budget on a flaky network is automatically re-armed when
  connectivity returns or the app comes back to the foreground (powered
  by `connectivity_plus`).
- **Sensible default `loadTimeout` of 20 seconds** for every ad type.
- Banner/Native configs now have value-based `==`/`hashCode`, so a
  parent rebuild that constructs an inline config no longer destroys
  the in-flight ad.
- App Open ads pre-warm immediately after dismiss so the next foreground
  is instant. Expired cached ads are detected by `isAdLoaded` and
  refreshed proactively.

### ⚡ Cold start

- `ApslAds.initialize()` no longer blocks on three sequential ad loads.
  Preloads run in parallel, in the background, after the SDK init
  completes — typically saves 2–5 seconds on time-to-`runApp`.
- App Open ads no longer auto-show on the first preload at app start
  (they used to pop over the splash screen).

### 🛠 Reliability fixes

- **Multicast callback model**: replaced single-field `onAdLoaded` etc.
  with `addOnAdLoaded(cb)` / `clearListeners()`. Previously, when both
  the event controller and a widget tried to attach to the same ad,
  one silently overwrote the other — breaking
  `ApslAds.instance.onEvent` for banner/native ads and rendering
  sequence ads non-functional.
- `createBanner` and `createNative` actually wire up the
  `onAdFailedToLoad` / `onAdShowed` parameters now (they were silently
  dropped before).
- `createNative` now calls `setupEvents`, fixing the bug where native
  ad events never reached the broadcast stream at all.
- `loadAndShowRewardedAd` rewritten: instant show on cache hit, hard
  wait timeout, properly returns `Future<bool>`, scoped subscription,
  filtered by ad network.
- Native ad's `onAdShowed` now fires exactly once per loaded ad via
  the SDK's `onAdImpression` listener — previously it fired on every
  widget rebuild, inflating impression analytics.
- Load generation tokens discard stale callbacks from a load that was
  already cancelled by a timeout, fixing a race that could clobber a
  freshly-loaded ad.
- App Open retry timer is now cancellable and bounded with
  exponential backoff. The previous `Future.delayed`-based retry could
  fire on a disposed instance and stack unbounded retries on a flaky
  network.
- Banner load timeout path consolidated into a single
  `_handleLoadFailure` so the timeout case correctly fires
  `onBannerAdReadyForSetState` (previously the widget would spin forever
  on timeout).
- `destroyAds()` now disposes the lifecycle reactor and load resumer
  in addition to the ads, fixing duplicate-listener leaks across
  destroy + re-initialize cycles.
- Sequence banner / native widgets no longer reset their cursor to 0
  and infinite-loop when all configured networks fail.

### 🔧 API changes (breaking)

- `ApslAds.initialize()` no longer accepts `preloadRewardedAds`,
  `blockAppOpenAd`, `onAdFailedToLoad`, or `onAdShowed`. Configure
  preloading via `RewardedAdConfig.preLoadRewardedAds`, and use the
  per-ad listener API for callbacks.
- `ApslAds.initialize()` now accepts `interstitialAdConfig` and
  `rewardedAdConfig` parameters. Use them to tune retry policy,
  timeouts, and immersive mode for the two highest-revenue formats —
  these were previously hardcoded with no way to override.
- `ApslAdBase` no longer exposes single-field callback slots
  (`onAdLoaded`, `onAdShowed`, `onAdFailedToLoad`, etc.). Replace
  `ad.onAdLoaded = cb` with `ad.addOnAdLoaded(cb)`. Multiple subscribers
  can now coexist on the same ad.
- `loadAndShowRewardedAd` now returns `Future<bool>` instead of `bool`
  and accepts a `waitTimeout` parameter (default 10 s).
- `BannerAdConfig` / `NativeAdConfig` / `InterstitialAdConfig` /
  `RewardedAdConfig` gained `useExponentialBackoff` and `maxRetryDelay`
  parameters; the meaning of `retryDelay` changed from "fixed delay"
  to "base delay for backoff". The default value also dropped from
  30 s to 2 s.
- The unused `shared_preferences` dependency has been removed.
- Added `connectivity_plus` as a new dependency.

### 🧹 Internal cleanup

- Removed four duplicate copies of fragile error-string matching in
  favor of a single shared `mapLoadAdError` helper.
- Moved the `forceStopToLoadAds` global out of the test ID manager into
  its own `ad_loading_gate.dart`. The barrel file re-exports it, so
  existing imports keep working.
- `_appLifecycleReactor` is now nullable instead of `late final`.

---

## 🚀 Version 1.6.0 - Updated Package Versions

**Release Date:** Jan 29, 2026
**Package:** `apsl_admob_ads_flutter`

### 🛠 Improvements

- Updated Package Versions: Upgraded internal and external dependencies to their latest stable versions for improved compatibility and reliability.

- Improved Stability: Includes upstream fixes and performance improvements from updated libraries, resulting in smoother ad loading and lifecycle handling.

- Maintenance Release: No breaking API changes. This release focuses on keeping the package modern, secure, and stable.

---

## 🚀 Version 1.5.0 - Analytics Event Callbacks

**Release Date:** Jul 23, 2025  
**Package:** `apsl_admob_ads_flutter`

### ✨ What's New

- **Analytics Event Callbacks:** All ad types (Banner, Native, Interstitial, Rewarded, App Open) now support `onAdShowed` and `onAdFailedToShow` callbacks for robust analytics and logging integration.
- **Docs:** Added usage examples and guidance for integrating analytics/logging with ad events.

**This is a recommended update for anyone who wants to track ad impressions and failures in their app.**

---

## 🚨 Version 1.3.0 - NativeAd API Simplification & Stability

**Release Date:** Jul 2, 2025  
**Package:** `apsl_admob_ads_flutter`

### ⚠️ Breaking Changes

- **NativeAd API Simplified:** The NativeAd constructor has been streamlined for clarity and maintainability. Deprecated and legacy options have been removed. Now only the following options are supported:
  - `adUnitId`
  - `adRequest`
  - `nativeTemplateStyle`
  - `templateType`
  - `config`
  - `customHeight`

### 🛠 Improvements

- Improved documentation and usage examples for the new API.
- Internal code cleanup for better stability and maintainability.
- Unified ad event callbacks (`onAdShowed`, `onAdFailedToShow`) for all ad types, enabling robust analytics and logging from your app.

**This is a stable and recommended update for all users.**

---

## 🚀 Version 1.2.0 - Native Ad Custom Height

**Release Date:** Jul 2, 2025  
**Package:** `apsl_admob_ads_flutter`

### ✨ What's New

- **Custom Height for Native Ads**: Added a `customHeight` parameter to the native ad widget, allowing developers to specify the height of native ads for more flexible UI layouts.

---

## 🚀 Version 1.1.0 - Navigation Ad Improvements

**Release Date:** Dec 19, 2024  
**Package:** `apsl_admob_ads_flutter`

### 🎯 What's New

Enhanced navigation ad functionality with improved `showAdOnNavigation` method for better user experience and ad management.

### ✨ Features & Improvements

#### 🔄 **Enhanced Navigation Ad Management**

- **Improved `showAdOnNavigation` Method** - Better logic for showing interstitial ads during navigation
- **Configurable Navigation Count** - More flexible control over when ads are shown during navigation
- **Enhanced User Experience** - Smoother integration of ads into navigation flow

### 🛠️ Technical Improvements

- **Better Navigation Tracking** - Improved internal navigation counter management
- **Optimized Ad Display Logic** - More efficient ad showing during navigation events
- **Enhanced Error Handling** - Better error management for navigation-based ad displays

### 📚 Documentation Updates

- Updated method documentation for `showAdOnNavigation`
- Enhanced usage examples for navigation ad integration

---

## 🚀 Version 1.0.0 - Initial Release

**Release Date:** Jul 1, 2025  
**Package:** `apsl_admob_ads_flutter`

### 🎉 What's New

Welcome to **Apsl AdMob Ads Flutter** - A comprehensive, production-ready Flutter package for seamless Google AdMob integration! This is a completely new package built from the ground up with modern Flutter practices and advanced features.

---

## ✨ Features

### 🎯 **Complete AdMob Integration**

- **Banner Ads** - Responsive, configurable banner ads with smart retry logic
- **Native Ads** - Customizable native ad templates with advanced styling
- **Interstitial Ads** - Full-screen ads with intelligent loading and error handling
- **Rewarded Ads** - User-engaged rewarded video ads with preloading support
- **App Open Ads** - Lifecycle-aware app open ads with automatic management

### ⚙️ **Advanced Configuration System**

- **`BannerAdConfig`** - Fine-tune banner ad behavior and appearance
- **`NativeAdConfig`** - Customize native ad templates and loading behavior
- **`InterstitialAdConfig`** - Configure interstitial ad loading and display logic
- **`RewardedAdConfig`** - Manage rewarded ad preloading and user experience

### 🛡️ **Robust Error Handling**

- **`AdErrorType`** - Detailed error categorization for better debugging
- **Smart Retry Logic** - Configurable retry attempts with exponential backoff
- **Load Timeout Handling** - Prevent hanging requests with timeout management
- **Comprehensive Error Reporting** - Detailed error messages and stack traces

### 🎨 **Enhanced User Experience**

- **Custom Loading Widgets** - Beautiful placeholder widgets during ad loading
- **Automatic Lifecycle Management** - Seamless ad lifecycle handling
- **Event Streaming** - Real-time ad event notifications
- **Manual Retry Methods** - Developer control over retry behavior

### 🛠️ **Developer-Friendly Features**

- **Comprehensive Documentation** - Complete API documentation with examples
- **Type-Safe Configuration** - Strongly typed configuration classes
- **Backward Compatibility** - Smooth migration from existing implementations
- **Extensive Examples** - Complete example app demonstrating all features

---

## 🔧 Technical Highlights

### **Performance Optimizations**

- Configurable retry delay and max attempts for all ad types
- Proper timer management and cleanup to prevent memory leaks
- Enhanced disposal logic for better resource management
- Improved error mapping from Google Mobile Ads SDK
- Consistent API design across all ad types

### **Code Quality**

- **100% Dart/Flutter** - No platform-specific code dependencies
- **Null Safety** - Full null safety support throughout
- **Modern Flutter** - Built with latest Flutter best practices
- **Clean Architecture** - Well-structured, maintainable codebase

---

## 📚 Documentation & Examples

### **Complete Documentation**

- 📖 [Installation Guide](https://github.com/appstonelabgit/apsl_admob_ads_flutter#installation)
- 🚀 [Quick Start Guide](https://github.com/appstonelabgit/apsl_admob_ads_flutter#quick-start)
- 📋 [API Reference](https://github.com/appstonelabgit/apsl_admob_ads_flutter#api-reference)
- 🎯 [Configuration Guide](https://github.com/appstonelabgit/apsl_admob_ads_flutter#configuration)

### **Example Applications**

- 📱 [Complete Example App](https://github.com/appstonelabgit/apsl_admob_ads_flutter/tree/main/example)
- 🎨 [UI Examples](https://github.com/appstonelabgit/apsl_admob_ads_flutter/tree/main/example/lib)
- ⚙️ [Configuration Examples](https://github.com/appstonelabgit/apsl_admob_ads_flutter/tree/main/example/lib)

---

## 🎯 Package Focus

### **AdMob-Only Approach**

- **Streamlined** - Focused solely on Google AdMob for optimal performance
- **Production Ready** - Robust error handling and retry logic
- **Developer Experience** - Easy to use with comprehensive configuration options
- **Performance** - Optimized loading and lifecycle management

### **Why This Package?**

- 🚀 **Fast Integration** - Get up and running in minutes
- 🛡️ **Reliable** - Built-in error handling and retry mechanisms
- 🎨 **Flexible** - Highly configurable for any use case
- 📚 **Well Documented** - Comprehensive guides and examples
- 🔧 **Maintained** - Active development and support

---

## 📦 Installation

```yaml
dependencies:
  apsl_admob_ads_flutter: ^1.0.0
```

## 🚀 Quick Start

```dart
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';

// Initialize the package
await ApslAds.instance.initialize(
  TestAdsIdManager(), // Your ads ID manager
  showAdBadge: true,
);

// Create and show a banner ad
final bannerAd = ApslAds.instance.createBanner(
  adNetwork: AdNetwork.admob,
  adSize: AdSize.banner,
);
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ by the Apsl Team**
