import 'package:apsl_admob_ads_flutter/src/enums/ad_network.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_unit_type.dart';

abstract class ApslAdBase {
  final String adUnitId;

  /// This will be called for initialization when we don't have to wait for the initialization
  ApslAdBase(this.adUnitId);

  AdNetwork get adNetwork;
  AdUnitType get adUnitType;
  bool get isAdLoaded;

  void dispose();

  /// This will load ad, It will only load the ad if isAdLoaded is false
  Future<void> load();
  dynamic show();

  ApslAdCallback? onAdLoaded;
  ApslAdCallback? onAdShowed;
  ApslAdCallback? onAdClicked;
  ApslAdCallback? onAdFailedToLoad;
  ApslAdCallback? onAdFailedToShow;
  ApslAdCallback? onAdDismissed;
  ApslAdCallback? onBannerAdReadyForSetState;
  ApslAdCallback? onNativeAdReadyForSetState;
  ApslAdCallback? onEarnedReward;
}

typedef ApslAdNetworkInitialized = void Function(
    AdNetwork adNetwork, bool isInitialized, Object? data);
typedef ApslAdCallback = void Function(
  AdNetwork adNetwork,
  AdUnitType adUnitType,
  Object? data, {
  String? errorMessage,
  String? rewardType,
  num? rewardAmount,
});

// typedef ApslAdFailedCallback = void Function(AdNetwork adNetwork,
//     AdUnitType adUnitType, Object? data, String errorMessage);
// typedef ApslAdEarnedReward = void Function(AdNetwork adNetwork,
//     AdUnitType adUnitType, String? rewardType, num? rewardAmount);
