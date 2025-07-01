import 'dart:async';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

/// Widget for displaying native ads in sequence with configurable retry and loading behavior.
class ApslSequenceNativeAd extends StatefulWidget {
  /// List of ad networks to try in order
  final List<AdNetwork> orderOfAdNetworks;

  /// Optional template style for the native ad
  final NativeTemplateStyle? nativeTemplateStyle;

  /// The type of template to use (small, medium, or custom)
  final TemplateType templateType;

  /// Optional color for the native ad border
  final Color? nativeAdBorderColor;

  /// Optional border radius for the native ad
  final double? nativeAdBorderRadius;

  /// Optional configuration for retry, loading, and placeholder behavior
  final NativeAdConfig? config;

  const ApslSequenceNativeAd({
    super.key,
    this.orderOfAdNetworks = const [
      AdNetwork.admob,
    ],
    this.nativeTemplateStyle,
    this.templateType = TemplateType.medium,
    this.nativeAdBorderColor,
    this.nativeAdBorderRadius,
    this.config,
  });

  @override
  State<ApslSequenceNativeAd> createState() => _ApslSequenceNativeAdState();
}

class _ApslSequenceNativeAdState extends State<ApslSequenceNativeAd> {
  int _currentADNetworkIndex = 0;
  StreamSubscription? _streamSubscription;

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.orderOfAdNetworks.length;
    if (_currentADNetworkIndex >= length) {
      _currentADNetworkIndex = 0;
    }

    while (_currentADNetworkIndex < length) {
      if (_isNativeIdAvailable(
          widget.orderOfAdNetworks[_currentADNetworkIndex])) {
        return _showNativeAd(widget.orderOfAdNetworks[_currentADNetworkIndex]);
      }

      _currentADNetworkIndex++;
    }
    return const SizedBox();
  }

  void _subscribeToAdEvent(AdNetwork priorityAdNetwork) {
    _cancelStream();
    _streamSubscription = ApslAds.instance.onEvent.listen((event) {
      if (event.adNetwork == priorityAdNetwork &&
          event.adUnitType == AdUnitType.native &&
          (event.type == AdEventType.adFailedToLoad ||
              event.type == AdEventType.adFailedToShow)) {
        _cancelStream();
        _currentADNetworkIndex++;
        setState(() {});
      } else if (event.adNetwork == priorityAdNetwork &&
          event.adUnitType == AdUnitType.native &&
          (event.type == AdEventType.adShowed ||
              event.type == AdEventType.adLoaded)) {
        _cancelStream();
      }
    });
  }

  bool _isNativeIdAvailable(AdNetwork adNetwork) {
    final adIdManager = ApslAds.instance.adIdManager;
    return adIdManager.appAdIds.any(
      (adIds) =>
          adIds.adNetwork == adNetwork &&
          adIds.nativeId != null &&
          adIds.nativeId!.isNotEmpty,
    );
  }

  Widget _showNativeAd(AdNetwork priorityAdNetwork) {
    _subscribeToAdEvent(priorityAdNetwork);
    return ApslNativeAd(
      adNetwork: priorityAdNetwork,
      nativeTemplateStyle: widget.nativeTemplateStyle,
      templateType: widget.templateType,
      nativeAdBorderColor: widget.nativeAdBorderColor,
      nativeAdBorderRadius: widget.nativeAdBorderRadius,
      config: widget.config,
    );
  }

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
