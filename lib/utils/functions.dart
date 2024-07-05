import 'package:flutter/material.dart';

Future<void> navigateToScreen(BuildContext context, Widget screen) async {
  // if (context == null || !context.mounted) {
  //   return; // Ensure the context is valid and widget is mounted
  // }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    bool isCurrentScreen = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrentScreen) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    }
  });
  // await Navigator.of(context)
  // .push(MaterialPageRoute(builder: (context) => screen));
}
