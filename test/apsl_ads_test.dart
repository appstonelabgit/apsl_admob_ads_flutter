import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:apsl_admob_ads_flutter/src/apsl_admob/apsl_admob_native_ad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApslAds', () {
    setUp(() {
      // Reset the instance before each test
      ApslAds.instance.destroyAds();
    });

    test('instance is singleton', () {
      expect(ApslAds.instance, equals(ApslAds.instance));
    });

    test('initialize sets correct properties', () async {
      const testManager = TestAdsIdManager();
      await ApslAds.instance.initialize(
        testManager,
        showAdBadge: true,
      );

      // Verify initialization properties
      expect(ApslAds.instance.showAdBadge, isTrue);
    });

    test('createBanner returns correct ad type for AdMob', () {
      // Test AdMob banner
      final admobBanner = ApslAds.instance.createBanner(
        adNetwork: AdNetwork.admob,
        adSize: AdSize.banner,
      );
      expect(admobBanner, isA<ApslAdmobBannerAd>());
    });

    test('createNative returns correct ad type for AdMob', () {
      final nativeAd = ApslAds.instance.createNative(
        adNetwork: AdNetwork.admob,
        templateType: TemplateType.medium,
      );
      expect(nativeAd, isA<ApslAdmobNativeAd>());
    });
  });
}
