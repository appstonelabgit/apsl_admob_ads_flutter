import 'dart:async';

import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'show_alert_dialogue.dart';

/// Test ad IDs manager for demonstration purposes.
/// In a real app, you would use your own ad IDs.
const AdsIdManager adIdManager = TestAdsIdManager();

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Apsl Ads SDK with test configuration
  try {
    await ApslAds.instance.initialize(
      isShowAppOpenOnAppStateChange: true,
      adIdManager,
      adMobAdRequest: const AdRequest(),
      admobConfiguration: RequestConfiguration(testDeviceIds: []),
      showAdBadge: false,
      preloadRewardedAds: false,
    );
  } catch (e) {
    debugPrint('Failed to initialize ads: $e');
    // In a real app, you might want to handle this error differently
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Apsl Ads Example',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Stream subscription for ad events
  StreamSubscription? _streamSubscription;

  @override
  void dispose() {
    // Clean up stream subscription when the widget is disposed
    _streamSubscription?.cancel();
    super.dispose();
  }

  // Builds the UI of the home screen, including the list of ad options.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List of Ads"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () async {
                    ApslAds.instance.destroyAds();

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text("Destroy")),
              _sectionTitleWidget(context, title: 'App Open'),
              AdListTile(
                networkName: 'AdMob AppOpen',
                onTap: () =>
                    _showAd(AdUnitType.appOpen, adNetwork: AdNetwork.admob),
              ),
              const ApslSequenceNativeAd(
                templateType: TemplateType.small,
              ),
              const Divider(thickness: 2),
              // Native Ads Section
              _sectionTitleWidget(context, title: 'Native Ads'),
              const ApslNativeAd(
                templateType: TemplateType.medium,
                config: NativeAdConfig(
                  retryDelay: Duration(seconds: 3),
                  maxRetries: 2,
                  loadingWidget: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Loading Native Ad...'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const ApslSequenceNativeAd(
                templateType: TemplateType.small,
                config: NativeAdConfig(
                  retryDelay: Duration(seconds: 5),
                  maxRetries: 3,
                  loadTimeout: Duration(seconds: 15),
                ),
              ),
              const Divider(thickness: 2),
              // Interstitial Ads Section
              _sectionTitleWidget(context, title: 'Interstitial'),
              AdListTile(
                networkName: 'AdMob Interstitial',
                onTap: () => _showAd(AdUnitType.interstitial,
                    adNetwork: AdNetwork.admob),
              ),

              AdListTile(
                networkName: 'Show Interstitial one by one',
                onTap: () => _showAd(AdUnitType.interstitial),
              ),
              AdListTile(
                networkName: 'Show on Navigation',
                onTap: () => _showAd(AdUnitType.interstitial, navigate: true),
              ),
              const Divider(thickness: 2),
              // Rewarded Ads Section
              _sectionTitleWidget(context, title: 'Rewarded'),
              AdListTile(
                networkName: 'AdMob Rewarded',
                onTap: () =>
                    _loadAndShowRewardedAds(adNetwork: AdNetwork.admob),
              ),

              AdListTile(
                networkName: 'Show Rewarded one by one',
                onTap: () => _loadAndShowRewardedAds(adNetwork: AdNetwork.any),
              ),
              const Divider(thickness: 2),
              // Banner Ads Section
              _sectionTitleWidget(context, title: 'Banner Ads'),
              const ApslSequenceBannerAd(
                orderOfAdNetworks: [
                  AdNetwork.admob,
                ],
              ),
              const SizedBox(height: 16),
              const ApslBannerAd(
                adNetwork: AdNetwork.admob,
                adSize: AdSize.banner,
                config: BannerAdConfig(
                  retryDelay: Duration(seconds: 4),
                  maxRetries: 2,
                  loadingWidget: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 4),
                        Text('Loading Banner...'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Creates a ListTile widget with a title indicating the section of ads.
  Widget _sectionTitleWidget(BuildContext context, {String title = ""}) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall!
            .copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Shows an ad of the specified type and network.
  ///
  /// Parameters:
  /// * [adUnitType] - The type of ad to show (interstitial, rewarded, etc.)
  /// * [adNetwork] - The ad network to use (AdMob)
  /// * [navigate] - Whether to navigate to the next screen after showing the ad
  void _showAd(
    AdUnitType adUnitType, {
    AdNetwork adNetwork = AdNetwork.any,
    bool navigate = false,
  }) {
    try {
      if (ApslAds.instance.showAd(adUnitType, adNetwork: adNetwork)) {
        if (navigate) {
          // Cancel any existing subscription
          _streamSubscription?.cancel();

          // Listen for ad events
          _streamSubscription = ApslAds.instance.onEvent.listen(
            (event) {
              if (event.adUnitType == adUnitType) {
                _streamSubscription?.cancel();
                _goToNextScreen(adNetwork: adNetwork);
              }
            },
            onError: (error) {
              debugPrint('Error showing ad: $error');
              if (navigate) _goToNextScreen(adNetwork: adNetwork);
            },
          );
        }
      } else {
        if (navigate) _goToNextScreen(adNetwork: adNetwork);
      }
    } catch (e) {
      debugPrint('Error in _showAd: $e');
      if (navigate) _goToNextScreen(adNetwork: adNetwork);
    }
  }

  /// Loads and shows a rewarded ad from the specified network.
  ///
  /// Parameters:
  /// * [adNetwork] - The ad network to use for the rewarded ad
  void _loadAndShowRewardedAds({required AdNetwork adNetwork}) {
    try {
      ApslAds.instance.loadAndShowRewardedAd(
        context: context,
        adNetwork: adNetwork,
      );

      _streamSubscription?.cancel();
      _streamSubscription = ApslAds.instance.onEvent.listen(
        (event) {
          if (event.adUnitType == AdUnitType.rewarded) {
            if (event.type == AdEventType.adDismissed) {
              // Ad was dismissed
            } else if (event.type == AdEventType.adFailedToShow) {
              if (mounted) {
                _showCustomDialog(
                  context,
                  title: "Ads not available",
                  description: "Please try again later.",
                );
              }
            } else if (event.type == AdEventType.earnedReward) {
              if (mounted) {
                _showCustomDialog(
                  context,
                  title: "Congratulations",
                  description: "You earned rewards",
                );
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Error in rewarded ad: $error');
          if (mounted) {
            _showCustomDialog(
              context,
              title: "Error",
              description: "Failed to show rewarded ad. Please try again.",
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _loadAndShowRewardedAds: $e');
      if (mounted) {
        _showCustomDialog(
          context,
          title: "Error",
          description: "Failed to load rewarded ad. Please try again.",
        );
      }
    }
  }

  void _goToNextScreen({AdNetwork? adNetwork}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(adNetwork: adNetwork),
      ),
    );
  }

  void _showCustomDialog(BuildContext context,
      {required String title, required String description}) {
    showAlertDialog(
      context: context,
      title: title,
      content: description,
      defaultActionText: "Close",
    );
  }
}

class DetailScreen extends StatefulWidget {
  final AdNetwork? adNetwork;
  const DetailScreen({super.key, this.adNetwork = AdNetwork.admob});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://flutter.dev'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Screen'),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}

class AdListTile extends StatelessWidget {
  final String networkName;
  final VoidCallback onTap;

  const AdListTile({
    super.key,
    required this.networkName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(networkName),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
