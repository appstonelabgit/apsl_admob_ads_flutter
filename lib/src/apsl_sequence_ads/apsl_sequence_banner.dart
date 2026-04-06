import 'dart:async';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

class ApslSequenceBannerAd extends StatefulWidget {
  final List<AdNetwork> orderOfAdNetworks;
  final AdSize adSize;

  final ApslAdCallback? onAdFailedToLoad;
  final ApslAdCallback? onAdShowed;

  const ApslSequenceBannerAd({
    super.key,
    this.orderOfAdNetworks = const [
      AdNetwork.admob,
    ],
    this.adSize = AdSize.banner,
    this.onAdFailedToLoad,
    this.onAdShowed,
  });

  @override
  State<ApslSequenceBannerAd> createState() => _ApslSequenceBannerAdState();
}

class _ApslSequenceBannerAdState extends State<ApslSequenceBannerAd> {
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
      if (_isBannerIdAvailable(
          widget.orderOfAdNetworks[_currentADNetworkIndex])) {
        return _showBannerAd(widget.orderOfAdNetworks[_currentADNetworkIndex]);
      }

      _currentADNetworkIndex++;
    }

    // No remaining configured networks have a banner id — give up
    // permanently for this widget instance instead of looping back to 0
    // and re-rendering the same dud network forever.
    _exhausted = true;
    return const SizedBox();
  }

  void _subscribeToAdEvent(AdNetwork priorityAdNetwork) {
    _cancelStream();
    _streamSubscription = ApslAds.instance.onEvent.listen((event) {
      if (event.adNetwork == priorityAdNetwork &&
          event.adUnitType == AdUnitType.banner &&
          (event.type == AdEventType.adFailedToLoad ||
              event.type == AdEventType.adFailedToShow)) {
        _cancelStream();
        _currentADNetworkIndex++;
        setState(() {});
      } else if (event.adNetwork == priorityAdNetwork &&
          event.adUnitType == AdUnitType.banner &&
          (event.type == AdEventType.adShowed ||
              event.type == AdEventType.adLoaded)) {
        _cancelStream();
      }
    });
  }

  bool _isBannerIdAvailable(AdNetwork adNetwork) {
    final adIdManager = ApslAds.instance.adIdManager;
    return adIdManager.appAdIds.any(
      (adIds) =>
          adIds.adNetwork == adNetwork &&
          adIds.bannerId != null &&
          adIds.bannerId!.isNotEmpty,
    );
  }

  Widget _showBannerAd(AdNetwork priorityAdNetwork) {
    _subscribeToAdEvent(priorityAdNetwork);
    return ApslBannerAd(
      adNetwork: priorityAdNetwork,
      adSize: widget.adSize,
      onAdFailedToLoad: widget.onAdFailedToLoad,
      onAdShowed: widget.onAdShowed,
    );
  }

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
