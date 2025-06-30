import 'dart:io';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';

bool forceStopToLoadAds = false;

class TestAdsIdManager extends AdsIdManager {
  const TestAdsIdManager();

  @override
  List<AppAdIds> get appAdIds => [
        AppAdIds(
          adNetwork: AdNetwork.admob,
          appId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544~3347511713'
              : 'ca-app-pub-3940256099942544~1458002511',
          appOpenId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/3419835294'
              : 'ca-app-pub-3940256099942544/5575463023',
          bannerId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716',
          interstitialId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/1033173712'
              : 'ca-app-pub-3940256099942544/4411468910',
          rewardedId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/5224354917'
              : 'ca-app-pub-3940256099942544/1712485313',
          nativeId: Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/2247696110'
              : 'ca-app-pub-3940256099942544/3986624511',
        ),
      ];
}
