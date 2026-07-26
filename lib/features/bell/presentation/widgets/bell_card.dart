import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bell_entities.dart';

class BellCard extends StatelessWidget {
  final Bell bell;
  final int index;
  final VoidCallback? onTap;

  const BellCard({super.key, required this.bell, this.index = 0, this.onTap});

  Color get _typeColor => switch (bell.type) {
        BellType.buy => AppColors.bullGreen,
        BellType.sell => AppColors.bearRed,
        BellType.exit => AppColors.infoBlue,
        BellType.adjust => AppColors.accentGold,
        BellType.alert => AppColors.accentGold,
      };

  @override
  Widget build(BuildContext context) {
    final isUrgent = bell.priority == BellPriority.urgent;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUrgent ? Icons.priority_high_rounded : Icons.notifications_rounded,
                  color: _typeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bell.type.label,
                            style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bell.instrument,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(bell.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(bell.message, style: Theme.of(context).textTheme.bodyMedium),
                    if (bell.price != null || bell.targetPrice != null || bell.stopLoss != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (bell.price != null) _priceChip(context, 'Entry', bell.price!, AppColors.infoBlue),
                          if (bell.targetPrice != null)
                            _priceChip(context, 'Target', bell.targetPrice!, AppColors.bullGreen),
                          if (bell.stopLoss != null) _priceChip(context, 'SL', bell.stopLoss!, AppColors.bearRed),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '— ${bell.createdByName}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _priceChip(BuildContext context, String label, double value, Color color) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          TextSpan(
            text: value.toStringAsFixed(2),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
