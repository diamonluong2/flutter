import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(AppStrings.notifications, style: AppTextStyles.headline3),
      ),
      body: const Center(
        child: Text('Notifications coming soon!', style: AppTextStyles.body1),
      ),
    );
  }
}
