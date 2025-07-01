import 'dart:async';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

/// A class encapsulating the logic for AdMob's Native Ads.
class ApslAdmobNativeAd extends ApslAdBase {
  final AdRequest _adRequest;
  final NativeTemplateStyle? nativeTemplateStyle;
  final TemplateType _templateType;
  final Color? nativeAdBorderColor;
  final double? nativeAdBorderRadius;
  final NativeAdConfig _config;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  int _retryCount = 0;
  bool _maxRetriesReached = false;
  Timer? _retryTimer;
  Timer? _loadTimeoutTimer;

  /// Creates a new [ApslAdmobNativeAd] instance
  ///
  /// [adUnitId] - The AdMob ad unit ID for the native ad
  /// [adRequest] - Optional custom ad request configuration
  /// [nativeTemplateStyle] - Optional template style for the native ad
  /// [templateType] - The type of template to use (small, medium, or custom)
  /// [nativeAdBorderColor] - Optional color for the native ad border
  /// [nativeAdBorderRadius] - Optional border radius for the native ad
  /// [config] - Optional configuration for retry behavior and loading settings
  ApslAdmobNativeAd(
    super.adUnitId, {
    AdRequest? adRequest,
    this.nativeTemplateStyle,
    TemplateType? templateType,
    this.nativeAdBorderColor,
    this.nativeAdBorderRadius,
    NativeAdConfig? config,
  })  : _adRequest = adRequest ?? const AdRequest(),
        _templateType = templateType ?? TemplateType.medium,
        _config = config ?? const NativeAdConfig();

  @override
  AdUnitType get adUnitType => AdUnitType.native;

  @override
  AdNetwork get adNetwork => AdNetwork.admob;

  @override
  bool get isAdLoaded => _isAdLoaded;

  /// Gets the current retry count
  int get retryCount => _retryCount;

  /// Gets whether max retries have been reached
  bool get maxRetriesReached => _maxRetriesReached;

  @override
  void dispose() {
    _isAdLoaded = false;
    _isLoading = false;
    _retryTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    _retryCount = 0;
    _maxRetriesReached = false;
    if (_nativeAd != null) {
      _nativeAd!.dispose();
      _nativeAd = null;
    }
  }

  /// Loads the native ad with retry and timeout logic.
  @override
  Future<void> load() async {
    if (_isLoading || _isAdLoaded) return;
    _isLoading = true;
    _loadTimeoutTimer?.cancel();
    _retryTimer?.cancel();

    if (_nativeAd != null) {
      await _nativeAd!.dispose();
      _nativeAd = null;
    }
    _isAdLoaded = false;

    // Setup timeout if configured
    if (_config.loadTimeout != null) {
      _loadTimeoutTimer = Timer(_config.loadTimeout!, () {
        if (!_isAdLoaded) {
          _isLoading = false;
          _handleError(AdErrorType.timeout,
              errorMessage: 'Native ad load timed out');
        }
      });
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) async {
          _isAdLoaded = true;
          _isLoading = false;
          _retryCount = 0;
          _maxRetriesReached = false;
          _loadTimeoutTimer?.cancel();
          _nativeAd = ad as NativeAd?;
          onAdLoaded?.call(adNetwork, adUnitType, ad);
          onNativeAdReadyForSetState?.call(adNetwork, adUnitType, ad);
        },
        onAdFailedToLoad: (ad, error) {
          _isAdLoaded = false;
          _isLoading = false;
          _nativeAd = null;
          ad.dispose();
          _loadTimeoutTimer?.cancel();
          final errorType = _mapErrorToType(error);
          _handleError(errorType, errorMessage: error.toString(), ad: ad);
        },
      ),
      nativeTemplateStyle: nativeTemplateStyle ?? getTemplate(),
      request: _adRequest,
    )..load();
  }

  /// Maps the Mobile Ads error to [AdErrorType]
  AdErrorType _mapErrorToType(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network')) return AdErrorType.networkError;
    if (errorStr.contains('timeout')) return AdErrorType.timeout;
    if (errorStr.contains('no fill')) return AdErrorType.noFill;
    if (errorStr.contains('internal')) return AdErrorType.internalError;
    if (errorStr.contains('invalid')) return AdErrorType.invalidAdUnit;
    return AdErrorType.unknown;
  }

  /// Handles ad load errors, retrying if enabled and under max retries
  void _handleError(AdErrorType errorType, {String? errorMessage, Object? ad}) {
    onAdFailedToLoad?.call(
      adNetwork,
      adUnitType,
      ad,
      errorMessage: errorMessage ?? errorType.message,
    );
    if (_config.enableAutoRetry && _retryCount < _config.maxRetries) {
      _retryCount++;
      _retryTimer = Timer(_config.retryDelay, () {
        if (!_isAdLoaded) load();
      });
    } else {
      // Max retries reached - set flag and reset retry count
      _maxRetriesReached = true;
      _retryCount = 0;
      // Notify widget to rebuild
      onNativeAdReadyForSetState?.call(adNetwork, adUnitType, ad);
    }
  }

  /// Returns the template style for the native ad
  NativeTemplateStyle getTemplate() {
    return NativeTemplateStyle(
      templateType: _templateType,
      mainBackgroundColor: Colors.transparent,
      cornerRadius: 10.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: Colors.blue,
        style: NativeTemplateFontStyle.normal,
        size: 16.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.blue,
        style: NativeTemplateFontStyle.normal,
        size: 16.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black,
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.brown,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 16.0,
      ),
    );
  }

  /// Displays the loaded native ad, or a loading/placeholder widget if not ready.
  @override
  Widget show() {
    // If max retries have been reached, return zero-height widget
    if (_maxRetriesReached) {
      return const SizedBox.shrink();
    }

    if (_nativeAd == null || !_isAdLoaded) {
      load();
      // Show loading widget if provided, otherwise show 0-height box
      return _config.loadingWidget ?? const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 320,
        maxWidth: 400,
        minHeight: _templateType == TemplateType.small ? 90 : 320,
        maxHeight: _templateType == TemplateType.small ? 200 : 400,
      ),
      child: Center(
        child: Stack(
          children: [
            if ((nativeAdBorderRadius ?? 0.0) > 0.0)
              ClipRRect(
                borderRadius: BorderRadius.circular(nativeAdBorderRadius!),
                child: AdWidget(ad: _nativeAd!),
              )
            else
              AdWidget(ad: _nativeAd!),
            if ((nativeAdBorderRadius ?? 0.0) > 0.0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(nativeAdBorderRadius!),
                    border: Border.all(
                      color: nativeAdBorderColor ?? Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Manually triggers a retry of the ad load
  ///
  /// This method can be called to manually retry loading the ad,
  /// useful for implementing custom retry logic in the UI.
  Future<void> retry() async {
    _retryCount = 0;
    _maxRetriesReached = false;
    await load();
  }

  /// Gets the current configuration
  NativeAdConfig get config => _config;
}
