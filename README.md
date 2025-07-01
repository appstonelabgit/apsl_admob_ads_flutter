# Apsl AdMob Ads Flutter

Seamlessly integrate Google AdMob ads into your Flutter app using the `Apsl AdMob Ads Flutter` package. This comprehensive package provides advanced retry logic, configurable error handling, and robust ad management for all AdMob ad types.

🌟 If this package benefits you, show your support by giving it a star on GitHub!

## 🚀 Features

- **Google AdMob Integration**:
  - Banner Ads with configurable retry and loading widgets
  - Native Ads with template customization and retry logic
  - Interstitial Ads with advanced error handling
  - Rewarded Ads with configurable preloading
  - App Open Ads with lifecycle management

- **Advanced Features**:
  - Configurable retry logic for all ad types
  - Detailed error categorization with `AdErrorType`
  - Load timeout handling
  - Custom loading/placeholder widgets
  - Automatic ad lifecycle management
  - Comprehensive event streaming

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apsl_admob_ads_flutter: ^1.0.0
```

You can install packages from the command line:

```bash
flutter pub get
```

## 📱 AdMob Mediation

The plugin offers comprehensive AdMob mediation support. Delve deeper into mediation details:

- [AdMob Mediation Guide](https://developers.google.com/admob/flutter/mediation/get-started)
- Remember to configure the native platform settings for AdMob mediation.

## 🛠 Platform-Specific Setup

### iOS

#### 📝 Update your Info.plist

For Google Ads, certain keys are essential. Update your `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_SDK_KEY</string>
```

Additionally, add `SKAdNetworkItems` for all networks provided by `Apsl AdMob Ads Flutter`. You can find and copy the `SKAdNetworkItems` from the provided [info.plist](https://github.com/appstonelabgit/apsl_admob_ads_flutter/blob/main/example/ios/Runner/Info.plist) to your project.

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

This is how you can define and manage your ad IDs for AdMob:

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

Before displaying ads, ensure you initialize the Mobile Ads SDK with `ApslAds.instance.initialize()`. It's a one-time setup, ideally done just before your app starts.

```dart
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

const AdsIdManager adIdManager = MyAdsIdManager();

ApslAds.instance.initialize(
    adIdManager,
    adMobAdRequest: const AdRequest(),
    admobConfiguration: RequestConfiguration(testDeviceIds: []),
  );
```

## 🎥 Interstitial/Rewarded Ads

### 🔋 Load an ad

By default, an ad loads after being displayed or when you call `initialize` for the first time.
As a precaution, use the following method to load both rewarded and interstitial ads:

```dart
ApslAds.instance.loadAd();
```

### 📺 Display Interstitial or Rewarded Ad

```dart
// Show Interstitial Ad
ApslAds.instance.showAd(AdUnitType.interstitial);

// Show Rewarded Ad
ApslAds.instance.showAd(AdUnitType.rewarded);

// Show with loading dialog
ApslAds.instance.showAd(
  AdUnitType.interstitial,
  shouldShowLoader: true,
  context: context,
);

// Load and show rewarded ad with custom config
ApslAds.instance.loadAndShowRewardedAd(
  context: context,
  adNetwork: AdNetwork.admob,
);
```

## 🎨 Banner Ads

### Basic Banner

```dart
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: YourContent(),
          ),
          const ApslBannerAd(
            adNetwork: AdNetwork.admob,
            adSize: AdSize.banner,
          ),
        ],
      ),
    );
  }
}
```

### Banner with Custom Config

```dart
const ApslBannerAd(
  adNetwork: AdNetwork.admob,
  adSize: AdSize.banner,
  config: BannerAdConfig(
    retryDelay: Duration(seconds: 10),
    maxRetries: 5,
    loadingWidget: Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Loading Banner...'),
        ],
      ),
    ),
    loadTimeout: Duration(seconds: 30),
  ),
)
```

## 🎯 Native Ads

### Basic Native Ad

```dart
const ApslNativeAd(
  adNetwork: AdNetwork.admob,
  templateType: TemplateType.medium,
)
```

### Native Ad with Custom Config

```dart
const ApslNativeAd(
  adNetwork: AdNetwork.admob,
  templateType: TemplateType.medium,
  config: NativeAdConfig(
    retryDelay: Duration(seconds: 3),
    maxRetries: 2,
    loadingWidget: Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Loading Native Ad...'),
        ],
      ),
    ),
  ),
)
```

## 📊 Event Handling

Listen to ad events for better user experience:

```dart
StreamSubscription? _streamSubscription;

@override
void initState() {
  super.initState();
  _streamSubscription = ApslAds.instance.onEvent.listen((event) {
    switch (event.type) {
      case AdEventType.adLoaded:
        print('Ad loaded: ${event.adUnitType}');
        break;
      case AdEventType.adFailedToLoad:
        print('Ad failed to load: ${event.adUnitType}');
        break;
      case AdEventType.adShowed:
        print('Ad showed: ${event.adUnitType}');
        break;
      case AdEventType.earnedReward:
        print('Reward earned: ${event.data}');
        break;
    }
  });
}

@override
void dispose() {
  _streamSubscription?.cancel();
  super.dispose();
}
```

## 🔧 Advanced Configuration

### Interstitial Ad Config

```dart
const InterstitialAdConfig(
  retryDelay: Duration(seconds: 5),
  maxRetries: 3,
  enableAutoRetry: true,
  loadTimeout: Duration(seconds: 15),
  immersiveModeEnabled: true,
  autoReloadAfterShow: true,
)
```

### Rewarded Ad Config

```dart
const RewardedAdConfig(
  retryDelay: Duration(seconds: 5),
  maxRetries: 3,
  enableAutoRetry: true,
  loadTimeout: Duration(seconds: 15),
  immersiveModeEnabled: true,
  preLoadRewardedAds: true,
  autoReloadAfterShow: true,
)
```

## 🎯 Error Handling

The package provides detailed error categorization:

```dart
enum AdErrorType {
  networkError,    // Network connectivity issues
  invalidAdUnit,   // Invalid or malformed ad unit ID
  timeout,         // Ad request timeout
  noFill,          // No ad available to serve
  internalError,   // Internal SDK error
  unknown,         // Unknown or unspecified error
}
```

## 📱 Example

Check out the [example](https://github.com/appstonelabgit/apsl_admob_ads_flutter/tree/main/example) directory for a complete working example.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google AdMob team for the excellent Flutter plugin
- Flutter community for the amazing framework
