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

  /// Optional onAdShowed callback
  final ApslAdCallback? onAdShowed;

  /// Optional onAdFailedToLoad callback
  final ApslAdCallback? onAdFailedToLoad;

  /// Optional configuration for retry, loading, and placeholder behavior
  final NativeAdConfig? config;

  const ApslSequenceNativeAd({
    super.key,
    this.orderOfAdNetworks = const [
      AdNetwork.admob,
    ],
    this.nativeTemplateStyle,
    this.templateType = TemplateType.medium,
    this.config,
    this.onAdShowed,
    this.onAdFailedToLoad,
  });

  @override
  State<ApslSequenceNativeAd> createState() => _ApslSequenceNativeAdState();
}

class _ApslSequenceNativeAdState extends State<ApslSequenceNativeAd> {
  int _currentADNetworkIndex = 0;
  bool _exhausted = false;
  StreamSubscription? _streamSubscription;

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_exhausted) return const SizedBox();

    final length = widget.orderOfAdNetworks.length;

    while (_currentADNetworkIndex < length) {
      if (_isNativeIdAvailable(
          widget.orderOfAdNetworks[_currentADNetworkIndex])) {
        return _showNativeAd(widget.orderOfAdNetworks[_currentADNetworkIndex]);
      }

      _currentADNetworkIndex++;
    }

    // No remaining configured networks have a native id — give up
    // permanently for this widget instance instead of looping back to 0
    // and re-rendering the same dud network forever.
    _exhausted = true;
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
      config: widget.config,
      onAdShowed: widget.onAdShowed,
      onAdFailedToLoad: widget.onAdFailedToLoad,
    );
  }

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
