import 'dart:async';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:apsl_admob_ads_flutter/src/apsl_admob/apsl_admob_interstitial_ad.dart';
import 'package:apsl_admob_ads_flutter/src/apsl_admob/apsl_admob_native_ad.dart';
import 'package:apsl_admob_ads_flutter/src/apsl_admob/apsl_admob_rewarded_ad.dart';
import 'package:apsl_admob_ads_flutter/src/utils/apsl_event_controller.dart';
import 'package:apsl_admob_ads_flutter/src/utils/apsl_logger.dart';
import 'package:apsl_admob_ads_flutter/src/utils/auto_hiding_loader_dialogue.dart';
import 'package:apsl_admob_ads_flutter/src/utils/extensions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class ApslAds {
  ApslAds._apslAds();
  static final ApslAds instance = ApslAds._apslAds();

  /// Google admob's ad request
  AdRequest _adRequest = const AdRequest();
  late final AdsIdManager adIdManager;
  late AppLifecycleReactor _appLifecycleReactor;

  final _eventController = ApslEventController();
  Stream<AdEvent> get onEvent => _eventController.onEvent;

  List<ApslAdBase> get _allAds =>
      [..._interstitialAds, ..._rewardedAds, ..._appOpenAds];

  /// All the App Open Ads ads will be stored in it
  final List<ApslAdBase> _appOpenAds = [];

  /// All the Interstitial ads will be stored in it
  final List<ApslAdBase> _interstitialAds = [];

  /// All the Rewarded ads will be stored in it
  final List<ApslAdBase> _rewardedAds = [];

  /// [_logger] is used to show Ad logs in the console
  final ApslLogger _logger = ApslLogger();

  /// On banner, ad badge will appear
  bool get showAdBadge => _showAdBadge;
  bool _showAdBadge = false;

  bool _preLoadRewardedAds = false;

  int _interstitialAdIndex = 0;
  int _rewardedAdIndex = 0;
  int _appOpenAdIndex = 0;

  int _navigationCount = 0;
  int _showNavigationAdAfterCount = 1;

  /// [_isMobileAdNetworkInitialized] is used to check if admob is initialized or not
  bool _isMobileAdNetworkInitialized = false;

  StreamSubscription? _streamSubscription;

  /// Initializes the Google Mobile Ads SDK.
  ///
  /// Call this method as early as possible after the app launches
  /// [adMobAdRequest] will be used in all the admob requests. By default empty request will be used if nothing passed here.
  Future<void> initialize(
    AdsIdManager manager, {
    bool isShowAppOpenOnAppStateChange = false,
    AdRequest? adMobAdRequest,
    RequestConfiguration? admobConfiguration,
    bool enableLogger = true,
    bool showAdBadge = false,
    int showNavigationAdAfterCount = 1,
    bool preloadRewardedAds = false,
    bool blockAppOpenAd = false,
  }) async {
    _showAdBadge = showAdBadge;
    _showNavigationAdAfterCount = showNavigationAdAfterCount;
    _preLoadRewardedAds = preloadRewardedAds;
    if (enableLogger) _logger.enable(enableLogger);
    adIdManager = manager;
    if (adMobAdRequest != null) {
      _adRequest = adMobAdRequest;
    }

    if (admobConfiguration != null) {
      MobileAds.instance.updateRequestConfiguration(admobConfiguration);
    }

    for (var appAdId in manager.appAdIds) {
      if (appAdId.appId.isNotEmpty) {
        final adNetworkName = getAdNetworkFromString(appAdId.adNetwork.name);
        switch (adNetworkName) {
          case AdNetwork.admob:
            // Initializing Mobile Ads SDK
            if (!_isMobileAdNetworkInitialized) {
              final response = await MobileAds.instance.initialize();
              final status = response.adapterStatuses.values.firstOrNull?.state;

              response.adapterStatuses.forEach((key, value) {
                _logger.logInfo(
                    'Google-mobile-ads Adapter status for $key: ${value.description}');
              });

              _eventController.fireNetworkInitializedEvent(
                  AdNetwork.admob, status == AdapterInitializationState.ready);

              _isMobileAdNetworkInitialized = true;
            }

            // Initializing admob Ads
            await ApslAds.instance._initAdmob(
              appOpenAdUnitId: appAdId.appOpenId,
              interstitialAdUnitId: appAdId.interstitialId,
              rewardedAdUnitId: appAdId.rewardedId,
              isShowAppOpenOnAppStateChange: isShowAppOpenOnAppStateChange,
            );
            break;

          case AdNetwork.any:
            break;
        }
      }
    }
  }

  /// Creates a banner ad for the specified ad network.
  ///
  /// This method creates and returns a banner ad instance based on the provided [adNetwork].
  /// The banner ad can be customized using the following parameters:
  ///
  /// * [adSize] - The size of the banner ad (defaults to standard banner)
  /// * [config] - Optional configuration for retry behavior, loading settings, and placeholders
  ///
  /// Currently supported networks:
  /// * AdMob - Full support with all customization options
  ///
  /// Returns null if the ad network is not supported or if the banner ad ID is not configured.
  ///
  /// Example:
  /// ```dart
  /// final bannerAd = ApslAds.instance.createBanner(
  ///   adNetwork: AdNetwork.admob,
  ///   adSize: AdSize.banner,
  ///   config: BannerAdConfig(
  ///     retryDelay: Duration(seconds: 10),
  ///     maxRetries: 5,
  ///     loadingWidget: CircularProgressIndicator(),
  ///     loadTimeout: Duration(seconds: 30),
  ///   ),
  /// );
  /// ```
  ApslAdBase? createBanner({
    required AdNetwork adNetwork,
    AdSize adSize = AdSize.banner,
    BannerAdConfig? config,
  }) {
    ApslAdBase? ad;
    final bannerId = adIdManager.getAppIds(adNetwork).bannerId;

    switch (adNetwork) {
      case AdNetwork.admob:
        assert(bannerId != null,
            'You are trying to create a banner and Admob Banner id is null in ad id manager');
        if (bannerId != null) {
          ad = ApslAdmobBannerAd(
            bannerId,
            adSize: adSize,
            adRequest: _adRequest,
            config: config,
          );
          _eventController.setupEvents(ad);
        }
        break;

      default:
        ad = null;
    }
    return ad;
  }

  /// Creates a native ad for the specified ad network.
  ///
  /// This method creates and returns a native ad instance based on the provided [adNetwork].
  /// The native ad can be customized using the following parameters:
  ///
  /// * [nativeTemplateStyle] - Optional styling for the native ad template
  /// * [templateType] - The type of template to use (small, medium, or custom)
  /// * [nativeAdBorderColor] - Optional color for the native ad border
  /// * [nativeAdBorderRadius] - Optional border radius for the native ad
  /// * [config] - Optional configuration for retry, loading, and placeholder behavior
  ///
  /// Currently supported networks:
  /// * AdMob - Full support with all customization options
  ///
  /// Returns null if the ad network is not supported or if the native ad ID is not configured.
  ///
  /// Example:
  /// ```dart
  /// final nativeAd = ApslAds.instance.createNative(
  ///   adNetwork: AdNetwork.admob,
  ///   templateType: TemplateType.medium,
  ///   nativeAdBorderColor: Colors.blue,
  ///   nativeAdBorderRadius: 8.0,
  ///   config: NativeAdConfig(
  ///     retryDelay: Duration(seconds: 10),
  ///     maxRetries: 5,
  ///     loadingWidget: CircularProgressIndicator(),
  ///     loadTimeout: Duration(seconds: 30),
  ///   ),
  /// );
  /// ```
  ApslAdBase? createNative({
    required AdNetwork adNetwork,
    NativeTemplateStyle? nativeTemplateStyle,
    TemplateType? templateType,
    Color? nativeAdBorderColor,
    double? nativeAdBorderRadius,
    NativeAdConfig? config,
  }) {
    ApslAdBase? ad;
    final nativeId = adIdManager.getAppIds(adNetwork).nativeId;

    switch (adNetwork) {
      case AdNetwork.admob:
        assert(nativeId != null,
            'You are trying to create a native ad and Admob Native id is null in ad id manager');
        if (nativeId != null) {
          ad = ApslAdmobNativeAd(
            nativeId,
            nativeTemplateStyle: nativeTemplateStyle,
            templateType: templateType,
            config: config,
          );
        }
        break;
      default:
        ad = null;
    }
    return ad;
  }

  Future<void> _initAdmob({
    String? appOpenAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
    bool immersiveModeEnabled = true,
    bool isShowAppOpenOnAppStateChange = true,
  }) async {
    // init interstitial ads
    ApslLogger().logInfo("InterstitialAdUnitId $interstitialAdUnitId");
    if (interstitialAdUnitId != null &&
        _interstitialAds.doesNotContain(
          AdNetwork.admob,
          AdUnitType.interstitial,
          interstitialAdUnitId,
        )) {
      final ad = ApslAdmobInterstitialAd(
        interstitialAdUnitId,
        adRequest: _adRequest,
        config: InterstitialAdConfig(
          immersiveModeEnabled: immersiveModeEnabled,
        ),
      );
      _interstitialAds.add(ad);
      _eventController.setupEvents(ad);

      await ad.load();
    }

    // init rewarded ads
    if (rewardedAdUnitId != null &&
        _rewardedAds.doesNotContain(
          AdNetwork.admob,
          AdUnitType.rewarded,
          rewardedAdUnitId,
        )) {
      final ad = ApslAdmobRewardedAd(
        adUnitId: rewardedAdUnitId,
        adRequest: _adRequest,
        config: RewardedAdConfig(
          immersiveModeEnabled: immersiveModeEnabled,
          preLoadRewardedAds: _preLoadRewardedAds,
        ),
      );
      _rewardedAds.add(ad);
      _eventController.setupEvents(ad);

      if (_preLoadRewardedAds) {
        await ad.load();
      }
    }

    if (!forceStopToLoadAds &&
        appOpenAdUnitId != null &&
        _appOpenAds.doesNotContain(
          AdNetwork.admob,
          AdUnitType.appOpen,
          appOpenAdUnitId,
        )) {
      final appOpenAdManager = ApslAdmobAppOpenAd(
        appOpenAdUnitId,
        _adRequest,
      );

      if (_appOpenAds.isEmpty) {
        await appOpenAdManager.load();
      }

      if (isShowAppOpenOnAppStateChange) {
        _appLifecycleReactor =
            AppLifecycleReactor(appOpenAdManager: appOpenAdManager);
        _appLifecycleReactor.listenToAppStateChanges();
      }
      _appOpenAds.add(appOpenAdManager);
      _eventController.setupEvents(appOpenAdManager);
    }
  }

  /// Displays [adUnitType] ad from [adNetwork]. It will check if first ad it found from list is loaded,
  /// it will be displayed if [adNetwork] is not mentioned otherwise it will load the ad.
  ///
  /// Returns bool indicating whether ad has been successfully displayed or not
  ///
  /// [adUnitType] should be mentioned here, only interstitial or rewarded should be mentioned here
  /// if [adNetwork] is provided, only that network's ad would be displayed
  /// if [shouldShowLoader] before interstitial. If it's true, you have to provide build context.
  bool showAd(
    AdUnitType adUnitType, {
    AdNetwork adNetwork = AdNetwork.any,
    bool shouldShowLoader = false,
    BuildContext? context,
  }) {
    try {
      final ad = _fetchAdByTypeAndNetwork(adUnitType, adNetwork);
      if (ad == null) {
        _logger.logInfo("No ad found for $adUnitType from $adNetwork");
        return false;
      }

      if (ad.isAdLoaded) {
        if (shouldShowLoader && context != null) {
          showLoaderDialog(context);
        }
        ad.show();
        _updateAdIndex(adUnitType);
        return true;
      } else {
        _logger.logInfo("Ad not loaded for $adUnitType from $adNetwork");
        ad.load();
        return false;
      }
    } catch (e) {
      _logger.logInfo("Error in showing ad: $e");
      return false;
    }
  }

  /// Loads and shows a rewarded ad with a loading dialog.
  ///
  /// This method will show a loading dialog while the ad is being loaded,
  /// and then display the ad once it's ready.
  ///
  /// Parameters:
  /// * [context] - The build context for showing the loading dialog
  /// * [adNetwork] - The ad network to use (defaults to AdNetwork.any)
  ///
  /// Returns true if the ad loading process was initiated successfully.
  bool loadAndShowRewardedAd({
    required BuildContext context,
    AdNetwork adNetwork = AdNetwork.any,
  }) {
    try {
      final ad = _fetchAdByTypeAndNetwork(AdUnitType.rewarded, adNetwork);
      ad?.load();

      showLoaderDialog(context);

      _streamSubscription?.cancel();
      _streamSubscription = ApslAds.instance.onEvent.listen((event) {
        if (event.adUnitType == AdUnitType.rewarded) {
          _logger.logInfo(
              "message: ${event.adNetwork} ${event.adUnitType} $event");

          if (event.type == AdEventType.adLoaded) {
            _updateAdIndex(AdUnitType.rewarded);
            hideLoaderDialog();
            ad?.show();
          } else if (event.type == AdEventType.adFailedToLoad) {
            _updateAdIndex(AdUnitType.rewarded);
            hideLoaderDialog();
          }
        }
      });
    } catch (e) {
      _logger.logInfo("Error in showing rewarded ad: $e");
      return false;
    }
    return false;
  }

  ApslAdBase? _fetchAdByTypeAndNetwork(
      AdUnitType adUnitType, AdNetwork adNetwork) {
    final mapForAds = {
      AdUnitType.rewarded: _rewardedAds,
      AdUnitType.interstitial: _interstitialAds,
      AdUnitType.appOpen: _appOpenAds,
    };
    final mapForIndexes = {
      AdUnitType.rewarded: _rewardedAdIndex,
      AdUnitType.interstitial: _interstitialAdIndex,
      AdUnitType.appOpen: _appOpenAdIndex,
    };

    final ads = mapForAds[adUnitType];
    final index = mapForIndexes[adUnitType];

    return adNetwork != AdNetwork.any
        ? ads?.firstWhereOrNull((e) => adNetwork == e.adNetwork)
        : ads != null && ads.isNotEmpty
            ? ads[index!]
            : null;
  }

  /// This will load both rewarded and interstitial ads.
  /// If a particular ad is already loaded, it will not load it again.
  /// Also you do not have to call this method everytime. Ad is automatically loaded after being displayed.
  ///
  /// if [adNetwork] is provided, only that network's ad will be loaded
  void loadAd({AdNetwork? adNetwork}) {
    if (adNetwork != null) {
      _loadAdsForNetwork(adNetwork);
    } else {
      _loadAdsForNetwork(AdNetwork.admob);
    }
  }

  void _loadAdsForNetwork(AdNetwork adNetwork) {
    for (var ad in _allAds) {
      if (ad.adNetwork == adNetwork && !ad.isAdLoaded) {
        ad.load();
      }
    }
  }

  void _updateAdIndex(AdUnitType adUnitType) {
    switch (adUnitType) {
      case AdUnitType.interstitial:
        _interstitialAdIndex =
            (_interstitialAdIndex + 1) % _interstitialAds.length;
        break;
      case AdUnitType.rewarded:
        _rewardedAdIndex = (_rewardedAdIndex + 1) % _rewardedAds.length;
        break;
      case AdUnitType.appOpen:
        _appOpenAdIndex = (_appOpenAdIndex + 1) % _appOpenAds.length;
        break;
      default:
        break;
    }
  }

  /// This will destroy all the ads and clear the lists
  void destroyAds() {
    for (var ad in _allAds) {
      ad.dispose();
    }
    _interstitialAds.clear();
    _rewardedAds.clear();
    _appOpenAds.clear();
    _interstitialAdIndex = 0;
    _rewardedAdIndex = 0;
    _appOpenAdIndex = 0;
  }

  /// This method is used to show navigation ad after every [showNavigationAdAfterCount] navigation
  /// if [showNavigationAdAfterCount] is not provided, it will show ad after every 1 navigation
  /// This will only show interstitial ad
  bool showAdOnNavigation() {
    if ((_navigationCount % (_showNavigationAdAfterCount) == 0) &&
        _navigationCount > 0) {
      _navigationCount++;
      return showAd(AdUnitType.interstitial);
    } else {
      _navigationCount++;
      return false;
    }
  }
}
