import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0), // Padding espacioso por defecto
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white, // Blanco puro contrastando con el fondo F2F2F6
        borderRadius: BorderRadius.circular(24), // Curvas de Apple
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Sombra 96% transparente
            blurRadius: 24, // Súper difuminada
            offset: const Offset(0, 8), // Cae hacia abajo suavemente
          ),
        ],
      ),
      child: child,
    );
  }
}
