/// Configuration class for rewarded ad settings
class RewardedAdConfig {
  /// Default retry delay duration
  static const Duration defaultRetryDelay = Duration(seconds: 5);

  /// Maximum number of retry attempts
  static const int defaultMaxRetries = 3;

  /// Retry delay duration for failed ad loads
  final Duration retryDelay;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Whether to enable automatic retry on failure
  final bool enableAutoRetry;

  /// Timeout duration for ad loading
  final Duration? loadTimeout;

  /// Whether to enable immersive mode for the ad
  final bool immersiveModeEnabled;

  /// Whether to preload rewarded ads automatically
  final bool preLoadRewardedAds;

  /// Whether to auto-reload after the ad is shown
  final bool autoReloadAfterShow;

  /// Creates a new [RewardedAdConfig] instance
  const RewardedAdConfig({
    this.retryDelay = defaultRetryDelay,
    this.maxRetries = defaultMaxRetries,
    this.enableAutoRetry = true,
    this.loadTimeout,
    this.immersiveModeEnabled = true,
    this.preLoadRewardedAds = false,
    this.autoReloadAfterShow = true,
  });

  /// Creates a copy of this config with the given fields replaced
  RewardedAdConfig copyWith({
    Duration? retryDelay,
    int? maxRetries,
    bool? enableAutoRetry,
    Duration? loadTimeout,
    bool? immersiveModeEnabled,
    bool? preLoadRewardedAds,
    bool? autoReloadAfterShow,
  }) {
    return RewardedAdConfig(
      retryDelay: retryDelay ?? this.retryDelay,
      maxRetries: maxRetries ?? this.maxRetries,
      enableAutoRetry: enableAutoRetry ?? this.enableAutoRetry,
      loadTimeout: loadTimeout ?? this.loadTimeout,
      immersiveModeEnabled: immersiveModeEnabled ?? this.immersiveModeEnabled,
      preLoadRewardedAds: preLoadRewardedAds ?? this.preLoadRewardedAds,
      autoReloadAfterShow: autoReloadAfterShow ?? this.autoReloadAfterShow,
    );
  }
}
