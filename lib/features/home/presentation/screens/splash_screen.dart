import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPrimaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.accentGold, size: 56),
            SizedBox(height: 16),
            Text('TickBell', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
            ),
          ],
        ),
      ),
    );
  }
}
