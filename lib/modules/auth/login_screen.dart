import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  Color(0xFF1A1A1A),
                  Color(0xFF0D0D0D),
                ],
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                
                // Logo or Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: AppTheme.glassDecoration(opacity: 0.1),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.accentBlue,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'NewsImpact\nPro',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Your directional edge in the\nforex market.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const Spacer(),
                
                // Login Button
                Obx(() => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
                  : ElevatedButton.icon(
                      onPressed: () => controller.signInWithGoogle(),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                      ),
                      label: const Text('Sign in with Google'),
                    ),
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: Text(
                    'By signing in, you agree to our Terms and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
