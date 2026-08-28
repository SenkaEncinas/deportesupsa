import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// Shimmer implementado a mano (sin depender de un paquete externo):
/// una franja de brillo que recorre de izquierda a derecha un bloque de
/// color base, en loop. Se usa como estado de carga para listas, en vez
/// de un [CircularProgressIndicator] suelto que no comunica la forma del
/// contenido que está por aparecer.
class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_controller.value * 3 - 1);
            return LinearGradient(
              colors: [
                AppColors.surfaceContainerHigh,
                AppColors.surface,
                AppColors.surfaceContainerHigh,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;

  const _SlideGradient(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// Bloque rectangular con shimmer, para armar placeholders de cualquier
/// forma (línea de texto, ícono, chip, etc).
class AppSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AppSkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Placeholder con la silueta de una card de listado (ícono/avatar +
/// título + un par de líneas), del mismo tamaño aproximado que
/// [ChampionshipPublicCard]/[AppStandingCard]/[StatCard], para que la
/// pantalla no "salte" cuando el contenido real reemplaza al esqueleto.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Shimmer(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 16, width: 160)),
            ],
          ),
          const SizedBox(height: 16),
          const AppSkeletonBox(height: 12),
          const SizedBox(height: 8),
          const AppSkeletonBox(height: 12, width: 220),
          const SizedBox(height: 16),
          const AppSkeletonBox(
            height: 34,
            width: 130,
            radius: AppSizes.radiusMd,
          ),
        ],
      ),
    );
  }
}

/// Placeholder con la silueta compacta de un [AppMatchCard]: dos líneas
/// de equipo separadas por un espacio, del mismo alto aproximado.
class AppSkeletonMatchCard extends StatelessWidget {
  const AppSkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(height: 15, width: 160),
          SizedBox(height: 14),
          AppSkeletonBox(height: 15, width: 190),
        ],
      ),
    );
  }
}

/// Placeholder con la silueta de una fila de ranking: círculo de
/// posición + nombre + valor a la derecha.
class AppSkeletonListTile extends StatelessWidget {
  const AppSkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Shimmer(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(child: AppSkeletonBox(height: 14)),
          const SizedBox(width: 10),
          const AppSkeletonBox(height: 20, width: 30),
        ],
      ),
    );
  }
}

/// Lista de [AppSkeletonCard] apiladas, para reemplazar un
/// [CircularProgressIndicator] mientras carga un listado (campeonatos,
/// partidos, equipos...).
class AppSkeletonList extends StatelessWidget {
  final int count;
  final double spacing;

  const AppSkeletonList({super.key, this.count = 3, this.spacing = 14});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? spacing : 0),
          child: const AppSkeletonCard(),
        );
      }),
    );
  }
}
