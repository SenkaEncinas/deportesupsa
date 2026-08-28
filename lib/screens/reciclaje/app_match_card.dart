import 'package:flutter/material.dart';

import '../../models/campeonato_model.dart';
import '../../models/partido_model.dart';
import 'app_badge.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

/// Ícono representativo de cada deporte, reutilizado en toda la app para
/// que el mismo deporte siempre se vea con el mismo ícono.
IconData deporteIcono(String deporte) {
  switch (deporte) {
    case DeporteTipo.volley:
      return Icons.sports_volleyball_outlined;
    case DeporteTipo.basket:
      return Icons.sports_basketball_outlined;
    default:
      return Icons.sports_soccer;
  }
}

class AppMatchCard extends StatelessWidget {
  final PartidoModel partido;
  final bool showResult;

  /// Deporte del campeonato (fútbol/vóley/básquet, ver [DeporteTipo]):
  /// define el ícono y si se muestra el detalle de sets. Por defecto
  /// fútbol, para no romper a los llamadores que todavía no lo pasan.
  final String deporte;

  const AppMatchCard({
    super.key,
    required this.partido,
    this.showResult = false,
    this.deporte = DeporteTipo.futbol,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isAdministrative = partido.tipoResultado != TipoResultado.normal;
    final esVolley = deporte == DeporteTipo.volley;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? _MobileMatchCard(
              partido: partido,
              showResult: showResult,
              isAdministrative: isAdministrative,
              esVolley: esVolley,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        deporteIcono(deporte),
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
                      esVolley: esVolley,
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
                if (showResult && esVolley && partido.sets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Text(
                      'Sets: ${partido.setsTexto}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Card de partido en móvil: cada equipo va en su propia línea con su
/// marcador pegado al lado (estilo scoreboard), en vez de un marcador
/// flotando por separado arriba de los nombres.
class _MobileMatchCard extends StatelessWidget {
  final PartidoModel partido;
  final bool showResult;
  final bool isAdministrative;
  final bool esVolley;

  const _MobileMatchCard({
    required this.partido,
    required this.showResult,
    required this.isAdministrative,
    required this.esVolley,
  });

  @override
  Widget build(BuildContext context) {
    final esEmpate = partido.empate;
    final ganaLocal =
        showResult && !esEmpate && partido.ganadorId == partido.equipoLocalId;
    final ganaVisitante =
        showResult &&
        !esEmpate &&
        partido.ganadorId == partido.equipoVisitanteId;

    final extra = _resultadoExtraTexto(partido);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showResult) ...[
          _FechaInline(fecha: partido.fechaHora),
          const SizedBox(height: 12),
        ],
        _TeamScoreLine(
          nombre: partido.equipoLocalNombre,
          marcador: showResult ? '${partido.golesLocal ?? 0}' : null,
          esGanador: ganaLocal,
        ),
        const _VsDivider(),
        _TeamScoreLine(
          nombre: partido.equipoVisitanteNombre,
          marcador: showResult ? '${partido.golesVisitante ?? 0}' : null,
          esGanador: ganaVisitante,
        ),
        if (extra != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                partido.definidoPorPenales
                    ? Icons.sports_soccer
                    : Icons.timer_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  extra,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showResult && esVolley && partido.sets.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Sets: ${partido.setsTexto}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (showResult && isAdministrative) ...[
          const SizedBox(height: 10),
          AppBadge(
            text: _formatLabel(partido.tipoResultado),
            type: AppBadgeType.warning,
          ),
        ],
      ],
    );
  }
}

/// Nombre del equipo y su marcador en la misma línea, conectados: se lee
/// como un marcador real en vez de dos bloques sueltos.
class _TeamScoreLine extends StatelessWidget {
  final String nombre;
  final String? marcador;
  final bool esGanador;

  const _TeamScoreLine({
    required this.nombre,
    required this.marcador,
    required this.esGanador,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.3,
              fontWeight: esGanador ? FontWeight.w800 : FontWeight.w600,
              color: esGanador ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        if (marcador != null) ...[
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: esGanador ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esGanador ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              marcador!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: esGanador ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Separador "vs" entre los dos equipos, con líneas a los costados para
/// que el bloque se lea como un único marcador y no como dos filas sueltas.
class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'vs',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border, height: 1)),
        ],
      ),
    );
  }
}

/// Fecha/hora como metadato liviano en una sola línea, en vez de una caja
/// grande flotando por separado antes de los nombres de los equipos.
class _FechaInline extends StatelessWidget {
  final DateTime? fecha;

  const _FechaInline({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${_fechaTexto(fecha)} · ${_horaTexto(fecha)}',
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopMatchInfo extends StatelessWidget {
  final PartidoModel partido;
  final bool showResult;
  final bool esVolley;

  const _TopMatchInfo({
    required this.partido,
    required this.showResult,
    required this.esVolley,
  });

  @override
  Widget build(BuildContext context) {
    if (showResult) {
      return _ScoreBox(
        local: partido.golesLocal ?? 0,
        visitante: partido.golesVisitante ?? 0,
        etiqueta: esVolley ? 'sets' : null,
      );
    }

    return _DateChip(fecha: partido.fechaHora);
  }
}

class _TeamsBlock extends StatelessWidget {
  final String local;
  final String visitante;

  const _TeamsBlock({required this.local, required this.visitante});

  @override
  Widget build(BuildContext context) {
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

  const _DateChip({required this.fecha});

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
  final String? etiqueta;

  const _ScoreBox({
    required this.local,
    required this.visitante,
    this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$local - $visitante',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (etiqueta != null)
            Text(
              etiqueta!,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

String? _resultadoExtraTexto(PartidoModel partido) {
  if (partido.definidoPorPenales &&
      partido.penalesLocal != null &&
      partido.penalesVisitante != null) {
    return 'Definido por penales (${partido.penalesLocal} - ${partido.penalesVisitante})';
  }

  if (partido.definidoPorProrroga) {
    return 'Definido por prórroga';
  }

  return null;
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
      })
      .join(' ');
}
