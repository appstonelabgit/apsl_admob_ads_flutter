import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a native ad with configurable retry and loading behavior.
class ApslNativeAd extends StatefulWidget {
  /// The ad network to use (defaults to AdMob)
  final AdNetwork adNetwork;

  /// Optional template style for the native ad
  final NativeTemplateStyle? nativeTemplateStyle;

  /// The type of template to use (small, medium, or custom)
  final TemplateType? templateType;

  /// Optional color for the native ad border
  final Color? nativeAdBorderColor;

  /// Optional border radius for the native ad
  final double? nativeAdBorderRadius;

  /// Optional configuration for retry, loading, and placeholder behavior
  final NativeAdConfig? config;

  const ApslNativeAd({
    this.adNetwork = AdNetwork.admob,
    this.nativeTemplateStyle,
    this.templateType,
    this.nativeAdBorderColor,
    this.nativeAdBorderRadius,
    this.config,
    super.key,
  });

  @override
  State<ApslNativeAd> createState() => _ApslNativeAdState();
}

class _ApslNativeAdState extends State<ApslNativeAd> {
  ApslAdBase? _nativeAd;
  late AdNetwork _currentNetwork;
  late TemplateType _currentTemplateType;
  NativeAdConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentNetwork = widget.adNetwork;
    _currentTemplateType = widget.templateType ?? TemplateType.small;
    _currentConfig = widget.config;
    _initNative();
  }

  @override
  void didUpdateWidget(covariant ApslNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    final updatedTemplate = widget.templateType ?? TemplateType.small;

    if (widget.adNetwork != _currentNetwork ||
        updatedTemplate != _currentTemplateType ||
        widget.config != _currentConfig) {
      _currentNetwork = widget.adNetwork;
      _currentTemplateType = updatedTemplate;
      _currentConfig = widget.config;
      _initNative();
    }
  }

  /// Initializes the native ad with the current configuration
  void _initNative() {
    _nativeAd?.dispose();

    _nativeAd = ApslAds.instance.createNative(
      adNetwork: _currentNetwork,
      nativeTemplateStyle: widget.nativeTemplateStyle,
      templateType: _currentTemplateType,
      nativeAdBorderColor: widget.nativeAdBorderColor,
      nativeAdBorderRadius: widget.nativeAdBorderRadius,
      config: _currentConfig,
    );

    _nativeAd?.onAdLoaded = _onNativeAdReady;
    _nativeAd?.onNativeAdReadyForSetState = _onNativeAdReady;

    _nativeAd?.load();
  }

  void _onNativeAdReady(
    AdNetwork adNetwork,
    AdUnitType adUnitType,
    Object? data, {
    String? errorMessage,
    String? rewardType,
    num? rewardAmount,
  }) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the ad widget from the native ad instance
    // The show() method always returns a widget:
    // - Loading widget (custom or default) when loading
    // - Actual ad widget when loaded
    // - SizedBox.shrink() when max retries reached
    return _nativeAd?.show() ?? const SizedBox.shrink();
  }
}
