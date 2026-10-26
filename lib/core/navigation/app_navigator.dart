import 'package:flutter/material.dart';

import '../router/app_routes.dart';

abstract final class AppNavigator {
  static void goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  static Future<void> openLogin(BuildContext context) {
    return Navigator.pushNamed(context, AppRoutes.login);
  }
}
