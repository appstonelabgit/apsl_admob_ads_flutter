import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

class BadgedBanner extends StatelessWidget {
  final Widget? child;
  final AdSize adSize;
  const BadgedBanner({this.child, this.adSize = AdSize.banner, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: adSize.height.toDouble(),
      width: double.infinity,
      alignment: Alignment.center,
      child: Badge(
        label: const Text('Ad'),
        backgroundColor: Theme.of(context).primaryColor,
        alignment: AlignmentDirectional.topStart,
        child: Container(
          height: adSize.height.toDouble(),
          color: Theme.of(context).primaryColor.withValues(
                alpha: (0.05 * 255).round().toDouble(),
                red: Theme.of(context).primaryColor.r,
                green: Theme.of(context).primaryColor.g,
                blue: Theme.of(context).primaryColor.b,
              ),
          child: child,
        ),
      ),
    );
  }
}
