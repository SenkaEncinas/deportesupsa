import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Fondo de las pantallas principales: un degradado verde muy suave
/// arriba que se funde con el gris de la app. Estaba copiado en seis
/// pantallas.
class AppFondo extends StatelessWidget {
  final Widget child;

  const AppFondo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF5F1),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SizedBox.expand(child: SafeArea(child: child)),
      ),
    );
  }
}
