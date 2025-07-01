import 'package:apsl_admob_ads_flutter/src/apsl_ad_base.dart';
import 'package:apsl_admob_ads_flutter/src/config/interstitial_ad_config.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_error_type.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_network.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_unit_type.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// A class that encapsulates the logic for AdMob's Interstitial Ads.
///
/// This class handles the creation, loading, and display of AdMob interstitial ads.
/// It includes configurable retry logic, enhanced error handling, and timeout support.
class ApslAdmobInterstitialAd extends ApslAdBase {
  final AdRequest _adRequest;
  final InterstitialAdConfig _config;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _loadTimeoutTimer;

  /// Creates a new [ApslAdmobInterstitialAd] instance
  ///
  /// [adUnitId] - The AdMob ad unit ID for the interstitial ad
  /// [adRequest] - Optional custom ad request configuration
  /// [config] - Optional configuration for retry behavior and loading settings
  ApslAdmobInterstitialAd(
    super.adUnitId, {
    AdRequest? adRequest,
    InterstitialAdConfig? config,
  })  : _adRequest = adRequest ?? const AdRequest(),
        _config = config ?? const InterstitialAdConfig();

  @override
  AdNetwork get adNetwork => AdNetwork.admob;

  @override
  AdUnitType get adUnitType => AdUnitType.interstitial;

  @override
  bool get isAdLoaded => _isAdLoaded;

  /// Gets the current retry count
  int get retryCount => _retryCount;

  @override
  void dispose() {
    _isAdLoaded = false;
    _isLoading = false;
    _retryTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    _retryCount = 0;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  @override
  Future<void> load() async {
    if (_isAdLoaded || _isLoading) return;

    _isLoading = true;
    _loadTimeoutTimer?.cancel();
    _retryTimer?.cancel();

    // Setup timeout if configured
    if (_config.loadTimeout != null) {
      _loadTimeoutTimer = Timer(_config.loadTimeout!, () {
        if (!_isAdLoaded) {
          _isLoading = false;
          _handleError(AdErrorType.timeout,
              errorMessage: 'Interstitial ad load timed out');
        }
      });
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd?.dispose(); // Clean up previous instance
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
          _retryCount = 0;
          _loadTimeoutTimer?.cancel();
          onAdLoaded?.call(adNetwork, adUnitType, ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isAdLoaded = false;
          _isLoading = false;
          _loadTimeoutTimer?.cancel();
          final errorType = _mapErrorToType(error);
          _handleError(errorType, errorMessage: error.toString());
        },
      ),
    );
  }

  /// Maps the Mobile Ads error to [AdErrorType]
  AdErrorType _mapErrorToType(LoadAdError error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network')) return AdErrorType.networkError;
    if (errorStr.contains('timeout')) return AdErrorType.timeout;
    if (errorStr.contains('no fill')) return AdErrorType.noFill;
    if (errorStr.contains('internal')) return AdErrorType.internalError;
    if (errorStr.contains('invalid')) return AdErrorType.invalidAdUnit;
    return AdErrorType.unknown;
  }

  /// Handles ad load errors, retrying if enabled and under max retries
  void _handleError(AdErrorType errorType, {String? errorMessage}) {
    onAdFailedToLoad?.call(
      adNetwork,
      adUnitType,
      null,
      errorMessage: errorMessage ?? errorType.message,
    );
    if (_config.enableAutoRetry && _retryCount < _config.maxRetries) {
      _retryCount++;
      _retryTimer = Timer(_config.retryDelay, () {
        if (!_isAdLoaded) load();
      });
    }
  }

  @override
  void show() {
    final ad = _interstitialAd;
    if (ad == null || !_isAdLoaded) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        onAdShowed?.call(adNetwork, adUnitType, ad);
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        onAdDismissed?.call(adNetwork, adUnitType, ad);
        _cleanAndReload(ad);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        onAdFailedToShow?.call(
          adNetwork,
          adUnitType,
          ad,
          errorMessage: error.toString(),
        );
        _cleanAndReload(ad);
      },
    );

    ad.setImmersiveMode(_config.immersiveModeEnabled);
    ad.show();

    _interstitialAd = null;
    _isAdLoaded = false;
  }

  /// Cleans up the ad and optionally reloads for next use
  void _cleanAndReload(InterstitialAd ad) {
    ad.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isLoading = false;

    if (_config.autoReloadAfterShow) {
      load(); // Preload next ad
    }
  }

  /// Manually triggers a retry of the ad load
  ///
  /// This method can be called to manually retry loading the ad,
  /// useful for implementing custom retry logic in the UI.
  Future<void> retry() async {
    _retryCount = 0;
    await load();
  }

  /// Gets the current configuration
  InterstitialAdConfig get config => _config;
}
