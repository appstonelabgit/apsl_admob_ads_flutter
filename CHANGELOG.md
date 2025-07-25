# 📋 Changelog

All notable changes to the `apsl_admob_ads_flutter` package will be documented in this file.

---

## 🚨 Version 1.3.0 - NativeAd API Simplification

**Release Date:** Jul 2, 2025  
**Package:** `apsl_admob_ads_flutter`

### ⚠️ Breaking Changes

- **NativeAd API Simplified:** Removed previous options from the NativeAd constructor. Now only the following options are supported:
  - `adUnitId`
  - `adRequest`
  - `nativeTemplateStyle`
  - `templateType`
  - `config`
  - `customHeight`

Update your usage accordingly. See the README for new usage examples.

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
