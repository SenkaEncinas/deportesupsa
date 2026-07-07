import 'package:flutter/material.dart';

import '../../models/partido_model.dart';
import 'app_badge.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

class AppMatchCard extends StatelessWidget {
  final PartidoModel partido;
  final bool showResult;

  const AppMatchCard({
    super.key,
    required this.partido,
    this.showResult = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isAdministrative = partido.tipoResultado != TipoResultado.normal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopMatchInfo(
                  partido: partido,
                  showResult: showResult,
                ),
                const SizedBox(height: 12),
                _TeamsBlock(
                  local: partido.equipoLocalNombre,
                  visitante: partido.equipoVisitanteNombre,
                  vertical: true,
                ),
                if (showResult && isAdministrative) ...[
                  const SizedBox(height: 10),
                  AppBadge(
                    text: _formatLabel(partido.tipoResultado),
                    type: AppBadgeType.warning,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamsBlock(
                    local: partido.equipoLocalNombre,
                    visitante: partido.equipoVisitanteNombre,
                  ),
                ),
                const SizedBox(width: 12),
                _TopMatchInfo(
                  partido: partido,
                  showResult: showResult,
                ),
                if (showResult && isAdministrative) ...[
                  const SizedBox(width: 10),
                  AppBadge(
                    text: _formatLabel(partido.tipoResultado),
                    type: AppBadgeType.warning,
                  ),
                ],
              ],
            ),
    );
  }
}

class _TopMatchInfo extends StatelessWidget {
  final PartidoModel partido;
  final bool showResult;

  const _TopMatchInfo({
    required this.partido,
    required this.showResult,
  });

  @override
  Widget build(BuildContext context) {
    if (showResult) {
      return _ScoreBox(
        local: partido.golesLocal ?? 0,
        visitante: partido.golesVisitante ?? 0,
      );
    }

    return _DateChip(fecha: partido.fechaHora);
  }
}

class _TeamsBlock extends StatelessWidget {
  final String local;
  final String visitante;
  final bool vertical;

  const _TeamsBlock({
    required this.local,
    required this.visitante,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            local,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.3),
          ),
          const SizedBox(height: 3),
          Text(
            'vs',
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            visitante,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.3),
          ),
        ],
      );
    }

    return Text(
      '$local vs $visitante',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(height: 1.35),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime? fecha;

  const _DateChip({
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _fechaTexto(fecha),
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _horaTexto(fecha),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int local;
  final int visitante;

  const _ScoreBox({
    required this.local,
    required this.visitante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD6A100).withOpacity(0.45),
        ),
      ),
      child: Text(
        '$local - $visitante',
        textAlign: TextAlign.center,
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _fechaTexto(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$dia/$mes/$anio';
}

String _horaTexto(DateTime? fecha) {
  if (fecha == null) return '--:--';

  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');

  return '$hora:$minuto';
}

String _formatLabel(String value) {
  final clean = value.trim();

  if (clean.isEmpty) return 'No definido';

  return clean
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map((word) {
    if (word.length == 1) return word.toUpperCase();

    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }).join(' ');
}