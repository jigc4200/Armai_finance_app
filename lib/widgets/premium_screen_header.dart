import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const PremiumScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    this.onPrimary,
    this.secondaryIcon,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        _CircleHeaderButton(
          icon: primaryIcon,
          background: const Color(0xFF0A0A0A),
          foreground: Colors.white,
          onTap: onPrimary,
        ),
        if (secondaryIcon != null) ...[
          const SizedBox(width: 10),
          _CircleHeaderButton(
            icon: secondaryIcon!,
            background: Colors.white,
            foreground: const Color(0xFF0A0A0A),
            onTap: onSecondary,
          ),
        ],
      ],
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _CircleHeaderButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFF7F7F7) : background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: onTap == null ? const Color(0xFF8A8A8A) : foreground,
            size: 21,
          ),
        ),
      ),
    );
  }
}
