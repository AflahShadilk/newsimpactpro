// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../data/models/news_event_model.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

class NewsCard extends StatelessWidget {
  final NewsEvent event;

  const NewsCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM d');
    // Convert UTC time to device local time for display
    final localTime = event.time.toLocal();
    final isReleased = event.status == NewsStatus.released;

    return Container(
      decoration: AppTheme.glassDecoration(opacity: isReleased ? 0.02 : 0.05),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.toNamed('/detail', arguments: event),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Time Column
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeFormat.format(localTime),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isReleased
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(localTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical divider
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: AppColors.textMuted.withOpacity(0.25),
                  ),

                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Currency + impact badge row
                        Row(
                          children: [
                            _buildImpactBadge(event.impact),
                            const SizedBox(width: 8),
                            Text(
                              event.currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(event),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Event name
                        Text(
                          event.eventName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Forecast / Previous data row
                        Row(
                          children: [
                            if (event.forecastRaw != null || event.forecast != null)
                              _buildDataPill(
                                'F',
                                event.forecastRaw ?? event.forecast.toString(),
                                AppColors.accentBlue.withOpacity(0.15),
                                AppColors.accentBlue,
                              ),
                            if (event.previousRaw != null || event.previous != null) ...[
                              const SizedBox(width: 6),
                              _buildDataPill(
                                'P',
                                event.previousRaw ?? event.previous.toString(),
                                AppColors.textMuted.withOpacity(0.15),
                                AppColors.textSecondary,
                              ),
                            ],
                            if (isReleased &&
                                (event.actualRaw != null || event.actual != null)) ...[
                              const SizedBox(width: 6),
                              _buildDataPill(
                                'A',
                                event.actualRaw ?? event.actual.toString(),
                                AppColors.accentOrange.withOpacity(0.15),
                                AppColors.accentOrange,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataPill(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(NewsEvent event) {
    if (event.status == NewsStatus.released) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('RELEASED',
            style: TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
      );
    }

    // Show countdown for upcoming events
    final now = DateTime.now();
    final diff = event.time.toLocal().difference(now);
    if (diff.isNegative) return const SizedBox.shrink();

    String countdownText;
    if (diff.inDays > 0) {
      countdownText = '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      countdownText = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } else {
      countdownText = '${diff.inMinutes}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getImpactColor(event.impact).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'in $countdownText',
        style: TextStyle(
          fontSize: 9,
          color: _getImpactColor(event.impact),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImpactBadge(String impact) {
    final color = _getImpactColor(impact);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1),
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
