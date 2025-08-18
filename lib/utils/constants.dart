import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1DA1F2);
  static const Color secondary = Color(0xFF14171A);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F9FA);
  static const Color textPrimary = Color(0xFF14171A);
  static const Color textSecondary = Color(0xFF657786);
  static const Color textLight = Color(0xFFAAB8C2);
  static const Color border = Color(0xFFE1E8ED);
  static const Color like = Color(0xFFE0245E);
  static const Color retweet = Color(0xFF17BF63);
  static const Color reply = Color(0xFF1DA1F2);
}

class AppSizes {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
}

class AppStrings {
  static const String appName = 'SocialApp';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String username = 'Username';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String home = 'Home';
  static const String search = 'Search';
  static const String notifications = 'Notifications';
  static const String profile = 'Profile';
  static const String createPost = 'Create Post';
  static const String whatHappening = "What's happening?";
  static const String post = 'Post';
  static const String cancel = 'Cancel';
  static const String like = 'Like';
  static const String comment = 'Comment';
  static const String share = 'Share';
  static const String followers = 'Followers';
  static const String following = 'Following';
  static const String posts = 'Posts';
  static const String editProfile = 'Edit Profile';
  static const String logout = 'Logout';
  static const String settings = 'Settings';
  static const String about = 'About';
  static const String help = 'Help';
  static const String privacy = 'Privacy';
  static const String terms = 'Terms';
}
