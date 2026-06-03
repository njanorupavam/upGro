import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInWebButton({
  required bool darkMode,
  required bool isRegister,
}) {
  return google_web.renderButton(
    configuration: GSIButtonConfiguration(
      theme: darkMode ? GSIButtonTheme.filledBlack : GSIButtonTheme.outline,
      text: isRegister ? GSIButtonText.signupWith : GSIButtonText.signinWith,
      size: GSIButtonSize.large,
      shape: GSIButtonShape.pill,
      type: GSIButtonType.standard,
      minimumWidth: 320,
    ),
  );
}
