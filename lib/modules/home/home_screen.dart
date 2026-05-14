// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/news_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/news_card.dart';
import '../../widgets/news_card_skeleton.dart';
import '../../widgets/history_card.dart';
import '../../services/sync_service.dart';

class HomeScreen extends GetView<NewsController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final syncService = Get.find<SyncService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NewsImpact Pro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed('/settings'),
            ),
            Obx(() => authController.userModel.value != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(authController.userModel.value!.photoUrl),
                    backgroundColor: AppColors.cardBg,
                  )
                : const Icon(Icons.account_circle)),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
            indicatorColor: AppColors.accentBlue,
            labelColor: AppColors.accentBlue,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: Column(
          children: [
            // Filter Section
            _buildFilters(),
            
            Expanded(
              child: TabBarView(
                children: [
                  // Upcoming News Tab
                  _buildNewsList(context, syncService),
                  
                  // History Tab
                  _buildHistoryList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList(BuildContext context, SyncService syncService) {
    return Obx(() {
      if (controller.isLoading.value) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppConstants.horizontalPadding),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => const NewsCardSkeleton(),
        );
      }

      final events = controller.filteredEvents;

      if (events.isEmpty) {
        return _buildEmptyState(context, 'No upcoming events found');
      }

      return RefreshIndicator(
        onRefresh: () => syncService.syncLiveNewsData(),
        color: AppColors.accentBlue,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppConstants.horizontalPadding),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return NewsCard(event: events[index]);
          },
        ),
      );
    });
  }

  Widget _buildHistoryList(BuildContext context) {
    return Obx(() {
      if (controller.isHistoryLoading.value) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppConstants.horizontalPadding),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => const NewsCardSkeleton(),
        );
      }

      final history = controller.filteredHistory;

      if (history.isEmpty) {
        return _buildEmptyState(context, 'No historical data found');
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchHistory(),
        color: AppColors.accentBlue,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppConstants.horizontalPadding),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return HistoryCard(history: history[index]);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('USD'),
          _filterChip('EUR'),
          _filterChip('GBP'),
          const VerticalDivider(width: 32, indent: 16, endIndent: 16),
          _impactChip('high', AppColors.accentRed),
          _impactChip('medium', AppColors.accentOrange),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Obx(() {
      final isSelected = controller.selectedCurrencies.contains(label);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => controller.toggleCurrency(label),
          selectedColor: AppColors.accentBlue.withOpacity(0.2),
          checkmarkColor: AppColors.accentBlue,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    });
  }

  Widget _impactChip(String label, Color color) {
    return Obx(() {
      final isSelected = controller.selectedImpacts.contains(label);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label.toUpperCase()),
          selected: isSelected,
          onSelected: (_) => controller.toggleImpact(label),
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    });
  }
}
