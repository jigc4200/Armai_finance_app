import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InsightIaCard extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final String iconName;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final bool isRepose;

  const InsightIaCard({
    super.key,
    required this.title,
    required this.message,
    required this.actionText,
    required this.iconName,
    required this.onTap,
    required this.onDismiss,
  }) : isRepose = false;

  const InsightIaCard.repose({
    super.key,
    required this.title,
    required this.message,
    required this.actionText,
    required this.iconName,
    required this.onTap,
  }) : onDismiss = null,
       isRepose = true;

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'car':
        return Icons.directions_car_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'psychology':
      default:
        return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isRepose 
        ? const Color(0xFFFAFAFA) 
        : const Color(0xFFF0F5FF);
    final borderColor = isRepose 
        ? const Color(0xFFE5E5EA) 
        : const Color(0xFFD6E4FF);
    final iconBgColor = isRepose 
        ? const Color(0xFFF2F2F7) 
        : const Color(0xFF2563EB);
    final iconColor = isRepose 
        ? const Color(0xFF8E8E93) 
        : Colors.white;
    final actionColor = isRepose 
        ? const Color(0xFF8E8E93) 
        : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del Copiloto
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(iconName), 
                    color: iconColor, 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: onDismiss != null ? 24.0 : 0.0
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Link de acción
                      Row(
                        children: [
                          Text(
                            actionText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: actionColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios, 
                            size: 10, 
                            color: actionColor
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onDismiss != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onDismiss!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0EAFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShimmerInsightCard extends StatefulWidget {
  const ShimmerInsightCard({super.key});

  @override
  State<ShimmerInsightCard> createState() => _ShimmerInsightCardState();
}

class _ShimmerInsightCardState extends State<ShimmerInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FF).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E4FF), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E4FF),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E4FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E9F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E9F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
