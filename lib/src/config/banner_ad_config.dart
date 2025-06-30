import 'package:flutter/material.dart';

/// Configuration class for banner ad settings
class BannerAdConfig {
  /// Default retry delay duration
  static const Duration defaultRetryDelay = Duration(seconds: 5);

  /// Maximum number of retry attempts
  static const int defaultMaxRetries = 3;

  /// Default loading placeholder widget
  static const Widget defaultLoadingWidget = SizedBox(
    height: 50,
    width: 320,
    child: Center(
      child: CircularProgressIndicator(),
    ),
  );

  /// Retry delay duration for failed ad loads
  final Duration retryDelay;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Widget to show while ad is loading
  final Widget? loadingWidget;

  /// Whether to enable automatic retry on failure
  final bool enableAutoRetry;

  /// Timeout duration for ad loading
  final Duration? loadTimeout;

  /// Creates a new [BannerAdConfig] instance
  const BannerAdConfig({
    this.retryDelay = defaultRetryDelay,
    this.maxRetries = defaultMaxRetries,
    this.loadingWidget,
    this.enableAutoRetry = true,
    this.loadTimeout,
  });

  /// Creates a copy of this config with the given fields replaced
  BannerAdConfig copyWith({
    Duration? retryDelay,
    int? maxRetries,
    Widget? loadingWidget,
    bool? enableAutoRetry,
    Duration? loadTimeout,
  }) {
    return BannerAdConfig(
      retryDelay: retryDelay ?? this.retryDelay,
      maxRetries: maxRetries ?? this.maxRetries,
      loadingWidget: loadingWidget ?? this.loadingWidget,
      enableAutoRetry: enableAutoRetry ?? this.enableAutoRetry,
      loadTimeout: loadTimeout ?? this.loadTimeout,
    );
  }
}
