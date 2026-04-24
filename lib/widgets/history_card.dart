import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/news_history_model.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

class HistoryCard extends StatelessWidget {
  final NewsHistory history;

  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM d');

    return Container(
      decoration: AppTheme.glassDecoration(opacity: 0.05),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // History detail if needed, or just show impact info
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Date Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(history.date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeFormat.format(history.date),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Divider
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildImpactBadge(history.impact),
                            const SizedBox(width: 8),
                            Text(
                              history.currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          history.eventName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildValueInfo('Act: ', history.actual.toString(), AppColors.accentBlue),
                            const SizedBox(width: 12),
                            _buildValueInfo('Dev: ', history.deviation.toString(), _getDeviationColor(history.deviation)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Pips Move
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${history.pipsMoved15m > 0 ? '+' : ''}${history.pipsMoved15m}',
                        style: TextStyle(
                          color: history.pipsMoved15m >= 0 ? AppColors.accentBlue : AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'pips',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueInfo(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildImpactBadge(String impact) {
    Color color;
    switch (impact.toLowerCase()) {
      case 'high':
        color = AppColors.accentRed;
        break;
      case 'medium':
        color = AppColors.accentOrange;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _getDeviationColor(double dev) {
    if (dev > 0) return AppColors.accentBlue;
    if (dev < 0) return AppColors.accentRed;
    return AppColors.textSecondary;
  }
}
