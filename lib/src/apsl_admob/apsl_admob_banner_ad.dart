import 'package:apsl_admob_ads_flutter/src/apsl_ad_base.dart';
import 'package:apsl_admob_ads_flutter/src/config/banner_ad_config.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_error_type.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_network.dart';
import 'package:apsl_admob_ads_flutter/src/enums/ad_unit_type.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// AdMob implementation of banner ads
///
/// This class handles the creation, loading, and display of AdMob banner ads.
/// It includes configurable retry logic, enhanced error handling, and support
/// for loading placeholders.
class ApslAdmobBannerAd extends ApslAdBase {
  final AdRequest _adRequest;
  final AdSize adSize;
  final BannerAdConfig _config;

  /// The banner ad instance
  BannerAd? _bannerAd;

  /// Whether the ad is currently loaded
  bool _isAdLoaded = false;

  /// Whether the ad is currently loading
  bool _isLoading = false;

  /// Number of retry attempts made
  int _retryCount = 0;

  /// Timer for retry delay
  Timer? _retryTimer;

  /// Timer for load timeout
  Timer? _loadTimeoutTimer;

  /// Creates a new [ApslAdmobBannerAd] instance
  ///
  /// [adUnitId] - The AdMob ad unit ID for the banner ad
  /// [adRequest] - Optional custom ad request configuration
  /// [adSize] - The size of the banner ad (defaults to standard banner)
  /// [config] - Optional configuration for retry behavior and loading settings
  ApslAdmobBannerAd(
    super.adUnitId, {
    AdRequest? adRequest,
    this.adSize = AdSize.banner,
    BannerAdConfig? config,
  })  : _adRequest = adRequest ?? const AdRequest(),
        _config = config ?? const BannerAdConfig();

  @override
  AdUnitType get adUnitType => AdUnitType.banner;

  @override
  AdNetwork get adNetwork => AdNetwork.admob;

  @override
  bool get isAdLoaded => _isAdLoaded;

  /// Gets the current retry count
  int get retryCount => _retryCount;

  /// Gets whether the ad is currently loading
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _cancelTimers();
    _isAdLoaded = false;
    _isLoading = false;
    _retryCount = 0;
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// Cancels any active timers
  void _cancelTimers() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = null;
  }

  /// Determines the error type from a LoadAdError message
  AdErrorType _getErrorType(LoadAdError error) {
    final errorMessage = error.message.toLowerCase();

    if (errorMessage.contains('network') || errorMessage.contains('connect')) {
      return AdErrorType.networkError;
    } else if (errorMessage.contains('invalid') ||
        errorMessage.contains('request')) {
      return AdErrorType.invalidAdUnit;
    } else if (errorMessage.contains('timeout')) {
      return AdErrorType.timeout;
    } else if (errorMessage.contains('no fill') ||
        errorMessage.contains('no ad')) {
      return AdErrorType.noFill;
    } else if (errorMessage.contains('internal')) {
      return AdErrorType.internalError;
    } else {
      return AdErrorType.unknown;
    }
  }

  /// Handles ad loading failure with retry logic
  void _handleLoadFailure(Ad ad, LoadAdError error) {
    _isAdLoaded = false;
    _isLoading = false;
    _cancelTimers();

    final errorType = _getErrorType(error);

    // Call the failure callback with detailed error information
    onAdFailedToLoad?.call(
      adNetwork,
      adUnitType,
      ad,
      errorMessage: '${errorType.message} (${error.message})',
    );

    ad.dispose();

    // Retry logic
    if (_config.enableAutoRetry && _retryCount < _config.maxRetries) {
      _retryCount++;
      _retryTimer = Timer(_config.retryDelay, () {
        if (!_isAdLoaded && !_isLoading) {
          load();
        }
      });
    } else {
      // Reset retry count after max retries reached
      _retryCount = 0;
    }
  }

  @override
  Future<void> load() async {
    // Prevent redundant calls
    if (_isLoading) {
      return;
    }

    // If already loaded, don't reload unless explicitly requested
    if (_isAdLoaded && _bannerAd != null) {
      return;
    }

    _isLoading = true;
    _cancelTimers();

    // Dispose existing ad if any
    await _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;

    // Set up load timeout if configured
    if (_config.loadTimeout != null) {
      _loadTimeoutTimer = Timer(_config.loadTimeout!, () {
        if (_isLoading) {
          // Handle timeout by calling failure callback directly
          onAdFailedToLoad?.call(
            adNetwork,
            adUnitType,
            _bannerAd,
            errorMessage:
                'Ad load timeout after ${_config.loadTimeout!.inSeconds} seconds',
          );
          _isAdLoaded = false;
          _isLoading = false;
          _cancelTimers();

          // Retry logic for timeout
          if (_config.enableAutoRetry && _retryCount < _config.maxRetries) {
            _retryCount++;
            _retryTimer = Timer(_config.retryDelay, () {
              if (!_isAdLoaded && !_isLoading) {
                load();
              }
            });
          } else {
            _retryCount = 0;
          }
        }
      });
    }

    _bannerAd = BannerAd(
      size: adSize,
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _cancelTimers();
          _bannerAd = ad as BannerAd;
          _isAdLoaded = true;
          _isLoading = false;
          _retryCount = 0; // Reset retry count on successful load

          onAdLoaded?.call(adNetwork, adUnitType, ad);
          onBannerAdReadyForSetState?.call(adNetwork, adUnitType, ad);
        },
        onAdFailedToLoad: _handleLoadFailure,
        onAdOpened: (Ad ad) => onAdClicked?.call(adNetwork, adUnitType, ad),
        onAdClosed: (Ad ad) => onAdDismissed?.call(adNetwork, adUnitType, ad),
        onAdImpression: (Ad ad) => onAdShowed?.call(adNetwork, adUnitType, ad),
      ),
      request: _adRequest,
    )..load();
  }

  @override
  Widget show() {
    // If ad is not loaded, trigger load and show loading widget
    if (_bannerAd == null || !_isAdLoaded) {
      // Only load if not already loading to prevent redundant calls
      if (!_isLoading) {
        load();
      }

      // Return loading widget or default placeholder
      return _config.loadingWidget ??
          SizedBox(
            height: adSize.height.toDouble(),
            width: adSize.width.toDouble(),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    // Return the loaded ad widget
    return Container(
      alignment: Alignment.center,
      height: adSize.height.toDouble(),
      width: adSize.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
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
  BannerAdConfig get config => _config;
}
