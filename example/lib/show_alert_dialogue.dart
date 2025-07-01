import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Helper function for showing an adaptive alert dialog
/// Returns:
/// - true if the default action was selected
/// - false if the cancel action was selected
/// - null if the dialog was dismissed
Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? cancelActionText,
  required String defaultActionText,
  bool barrierDismissible = true,
  bool isDestructive = false,
}) {
  return showAdaptiveDialog<bool?>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        if (cancelActionText != null)
          _adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelActionText),
          ),
        _adaptiveAction(
          context: context,
          isDestructive: isDestructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(defaultActionText),
        ),
      ],
    ),
  );
}

/// Helper function for showing an adaptive action
/// Returns:
/// - TextButton if the platform is not iOS or macOS
/// - CupertinoDialogAction if the platform is iOS or macOS
Widget _adaptiveAction({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
  bool isDestructive = false,
}) {
  final platform = Theme.of(context).platform;
  if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
    return TextButton(onPressed: onPressed, child: child);
  } else {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructive,
      child: child,
    );
  }
}

/// Shows information about the new max retries functionality
void showMaxRetriesInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Max Retries Feature'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Feature: Zero Height After Max Retries'),
            SizedBox(height: 8),
            Text(
                '• Banner and Native ads now automatically reduce height to 0 after max retry attempts'),
            Text(
                '• This prevents empty ad spaces from taking up screen real estate'),
            Text(
                '• Use the maxRetriesReached getter to check if max retries were reached'),
            Text('• Call retry() method to manually reset and try again'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
