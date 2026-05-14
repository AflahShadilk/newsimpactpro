// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/news_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sync_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final newsController = Get.find<NewsController>();
    final syncService = Get.find<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Profile Section
            _buildSectionHeader('Account'),
            Obx(() {
              final user = authController.userModel.value;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(opacity: 0.05),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl) : null,
                      backgroundColor: AppColors.cardBg,
                      child: user?.photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Trader',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSettingTile(
              title: 'Enable Alerts',
              subtitle: 'Receive notifications before events',
              trailing: Obx(() => Switch(
                    value: authController.userModel.value?.notificationsEnabled ?? true,
                    onChanged: (val) => authController.updateUser({'notifications_enabled': val}),
                    activeColor: AppColors.accentBlue,
                  )),
            ),
            _buildSettingTile(
              title: 'Alert Time',
              subtitle: 'How many minutes before the event',
              trailing: Obx(() => Text(
                    '${authController.userModel.value?.alertTime ?? 15}m',
                    style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold),
                  )),
              onTap: () => _showNumberPicker(context, authController),
            ),

            const SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildSettingTile(
              title: 'Currencies',
              subtitle: 'Managed currencies for news',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showMultiSelect(
                context,
                title: 'Select Currencies',
                options: ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'NZD'],
                selected: authController.userModel.value?.currencies ?? [],
                onSave: (val) => authController.updateUser({'currencies': val}),
              ),
            ),
            _buildSettingTile(
              title: 'Impact Levels',
              subtitle: 'Minimum impact to show',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showMultiSelect(
                context,
                title: 'Select Impact',
                options: ['high', 'medium', 'low'],
                selected: authController.userModel.value?.impact ?? [],
                onSave: (val) => authController.updateUser({'impact': val}),
              ),
            ),
            _buildSettingTile(
              title: 'Sync Live Data',
              subtitle: 'Fetch latest news from Forex Factory',
              trailing: const Icon(Icons.sync_rounded, color: AppColors.accentBlue),
              onTap: () => syncService.syncLiveNewsData(),
            ),

            const SizedBox(height: 48),

            // Logout Button
            ElevatedButton(
              onPressed: () => _showLogoutConfirmation(context, authController),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed.withOpacity(0.1),
                foregroundColor: AppColors.accentRed,
                side: const BorderSide(color: AppColors.accentRed, width: 1),
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'NewsImpact Pro v1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.03),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showNumberPicker(BuildContext context, AuthController controller) {
    // Simple implementation for demo
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alert Timing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [5, 10, 15, 30, 60].map((mins) {
                return InkWell(
                  onTap: () {
                    controller.updateUser({'alert_time': mins});
                    Get.back();
                  },
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: controller.userModel.value?.alertTime == mins
                          ? AppColors.accentBlue
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$mins\nmins', textAlign: TextAlign.center),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showMultiSelect(
    BuildContext context, {
    required String title,
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onSave,
  }) {
    final RxList<String> tempSelected = RxList<String>.from(selected);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: options.map((opt) {
                return Obx(() {
                  final isSelected = tempSelected.contains(opt);
                  return FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        tempSelected.add(opt);
                      } else {
                        tempSelected.remove(opt);
                      }
                    },
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                onSave(tempSelected.toList());
                Get.back();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }
}
