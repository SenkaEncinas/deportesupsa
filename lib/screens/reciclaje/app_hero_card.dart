import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_colors.dart';
import 'app_info_line.dart';
import 'app_logo_mark.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

/// Chip decorativo del hero. En móvil no se muestra para ahorrar altura.
class AppHeroChipData {
  final IconData icon;
  final String text;

  const AppHeroChipData({
    required this.icon,
    required this.text,
  });
}

/// Dato informativo del hero (Cancha, Modalidad, Temporada, etc.).
/// En desktop se muestra como caja lateral; en móvil como grilla
/// compacta de 2 columnas.
class AppHeroInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const AppHeroInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Hero institucional UPSA reutilizable con degradado verde.
///
/// En desktop mantiene el diseño original: logo, badges, título,
/// descripción y una caja lateral con la información.
/// En móvil usa una versión compacta que ocupa mucho menos pantalla:
/// paddings reducidos, título más chico, descripción acotada, chips
/// ocultos y la información en una grilla de 2 columnas.
class AppHeroCard extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> badges;
  final List<AppHeroChipData> chips;
  final List<AppHeroInfoItem> infoItems;

  /// Contenido lateral personalizado (reemplaza a [infoItems] en desktop).
  /// En móvil se muestra debajo del texto a ancho completo.
  final Widget? side;

  final bool showLogo;

  const AppHeroCard({
    super.key,
    required this.title,
    this.description,
    this.badges = const [],
    this.chips = const [],
    this.infoItems = const [],
    this.side,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003D2D),
              Color(0xFF005C45),
              AppColors.primary,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -48,
                top: -52,
                child: _DecorativeCircle(
                  size: isMobile ? 110 : 190,
                  opacity: 0.10,
                ),
              ),
              Positioned(
                right: isMobile ? 16 : 42,
                bottom: -40,
                child: _DecorativeCircle(
                  size: isMobile ? 70 : 130,
                  opacity: 0.08,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 18 : 30),
                child: isMobile ? _buildMobile(context) : _buildDesktop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo compacto y badges en la misma línea para no gastar
        // dos filas de altura.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showLogo) const AppLogoMark(compact: true),
            ...badges,
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: 22,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
        if (infoItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CompactInfoGrid(items: infoItems),
        ],
        if (side != null) ...[
          const SizedBox(height: 14),
          side!,
        ],
      ],
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showLogo) const AppLogoMark(),
            ...badges,
            ...chips.map((chip) => _HeroChip(data: chip)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: 34,
            letterSpacing: -0.4,
          ),
        ),
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Text(
              description!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white.withValues(alpha: 0.88),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
        ],
      ],
    );

    final lateral = side ??
        (infoItems.isEmpty ? null : _DesktopInfoBox(items: infoItems));

    if (lateral == null) return texto;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: texto),
        const SizedBox(width: 28),
        lateral,
      ],
    );
  }
}

/// Caja lateral con la información en desktop (diseño original).
class _DesktopInfoBox extends StatelessWidget {
  final List<AppHeroInfoItem> items;

  const _DesktopInfoBox({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 305,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            AppInfoLine(
              icon: items[i].icon,
              label: items[i].label,
              value: items[i].value,
              dark: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Grilla compacta de 2 columnas para móvil: reemplaza la caja lateral
/// que en pantallas chicas ocupaba media pantalla de altura.
class _CompactInfoGrid extends StatelessWidget {
  final List<AppHeroInfoItem> items;

  const _CompactInfoGrid({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            fontSize: 10.5,
                            color: AppColors.white.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.value.trim().isEmpty
                              ? 'No definido'
                              : item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeroChip extends StatelessWidget {
  final AppHeroChipData data;

  const _HeroChip({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.14),
        ),
      ),
      // Flexible + ellipsis: un Wrap acota el ancho máximo de cada hijo
      // al ancho del propio Wrap, así que un chip con texto largo (p. ej.
      // "Universidad Privada de Santa Cruz") puede recibir menos espacio
      // del que necesita en pantallas angostas. Sin esto, el Row interno
      // desbordaba en vez de recortar el texto.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 15, color: AppColors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              data.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
