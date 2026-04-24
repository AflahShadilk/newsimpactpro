import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/news_event_model.dart';
import '../../controllers/news_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NewsEvent event = Get.arguments;
    final newsController = Get.find<NewsController>();
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    // Fetch history for this specific event
    newsController.fetchEventHistory(event.eventName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(opacity: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildImpactBadge(event.impact),
                      const SizedBox(width: 12),
                      Text(
                        event.impact.toUpperCase(),
                        style: TextStyle(
                          color: _getImpactColor(event.impact),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.currency,
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    event.eventName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${timeFormat.format(event.time)} GMT',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(event.time),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Section
            Text(
              'Economic Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Actual', event.actual?.toString() ?? 'TBD', AppColors.accentBlue),
                const SizedBox(width: 12),
                _buildStatCard('Forecast', event.forecast?.toString() ?? '--', AppColors.textPrimary),
                const SizedBox(width: 12),
                _buildStatCard('Previous', event.previous?.toString() ?? '--', AppColors.textSecondary),
              ],
            ),
            
            const SizedBox(height: 32),

            // Historical Performance Section
            Text(
              'Historical Impact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Obx(() {
              final history = newsController.specificEventHistory;
              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(opacity: 0.02),
                  child: const Center(
                    child: Text('No historical data available for this event.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              
              return Column(
                children: history.map((h) => _buildHistoryRow(h)).toList(),
              );
            }),

            const SizedBox(height: 32),
            
            // Market Insight
            Text(
              'Market Insight',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(opacity: 0.03),
              child: Text(
                'This event typically causes ${event.impact} volatility in the ${event.currency} pairs. Traders should watch for deviations from the forecast of ${event.forecast ?? "N/A"}. A higher than expected reading is generally positive/bullish for the ${event.currency}, while a lower than expected reading is negative/bearish.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Set Alert Button
            ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Alert Set',
                  'You will be notified 15 minutes before ${event.eventName}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.surface,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(dynamic h) {
    final dateFormat = DateFormat('MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(opacity: 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateFormat.format(h.date), style: const TextStyle(fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${h.pipsMoved15m > 0 ? '+' : ''}${h.pipsMoved15m} pips',
                style: TextStyle(
                  color: h.pipsMoved15m >= 0 ? AppColors.accentBlue : AppColors.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Dev: ${h.deviation > 0 ? '+' : ''}${h.deviation}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: AppTheme.glassDecoration(opacity: 0.05),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBadge(String impact) {
    Color color = _getImpactColor(impact);

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return AppColors.accentRed;
      case 'medium':
        return AppColors.accentOrange;
      default:
        return AppColors.textSecondary;
    }
  }
}
