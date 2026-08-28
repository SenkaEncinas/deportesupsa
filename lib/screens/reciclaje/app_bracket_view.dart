import 'package:flutter/material.dart';

import '../../models/partido_model.dart';
import 'app_badge.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

const double _kCardHeight = 86;
const double _kCardWidth = 224;
const double _kBaseGap = 22;
const double _kHeaderHeight = 40;
const double _kConnectorWidth = 30;

double _slotDeRonda(int ronda) => (_kCardHeight + _kBaseGap) * (1 << ronda);

double _offsetDeRonda(int ronda) => (_slotDeRonda(ronda) - _kCardHeight) / 2;

/// Llave eliminatoria visual (octavos, cuartos, semifinal, final...):
/// columnas por ronda unidas con conectores, con scroll horizontal para
/// que quepa en cualquier ancho de pantalla.
class AppBracketView extends StatelessWidget {
  final List<MapEntry<String, List<PartidoModel>>> rondas;
  final String deporte;

  const AppBracketView({
    super.key,
    required this.rondas,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    if (rondas.isEmpty) return const SizedBox.shrink();

    final totalHeight = _slotDeRonda(0) * rondas.first.value.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int r = 0; r < rondas.length; r++) ...[
            _RoundColumn(
              titulo: rondas[r].key,
              partidos: rondas[r].value,
              ronda: r,
              totalHeight: totalHeight,
              deporte: deporte,
            ),
            if (r < rondas.length - 1)
              _ConnectorZone(
                ronda: r,
                cantidadOrigen: rondas[r].value.length,
                totalHeight: totalHeight,
              ),
          ],
        ],
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final String titulo;
  final List<PartidoModel> partidos;
  final int ronda;
  final double totalHeight;
  final String deporte;

  const _RoundColumn({
    required this.titulo,
    required this.partidos,
    required this.ronda,
    required this.totalHeight,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    final slot = _slotDeRonda(ronda);
    final offset = _offsetDeRonda(ronda);

    return SizedBox(
      width: _kCardWidth,
      height: _kHeaderHeight + totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: _kHeaderHeight,
            child: Center(
              child: AppBadge(text: titulo, type: AppBadgeType.primary),
            ),
          ),
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                for (int i = 0; i < partidos.length; i++)
                  Positioned(
                    top: offset + i * slot,
                    left: 0,
                    right: 0,
                    height: _kCardHeight,
                    child: _BracketMatchCard(
                      partido: partidos[i],
                      deporte: deporte,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorZone extends StatelessWidget {
  final int ronda;
  final int cantidadOrigen;
  final double totalHeight;

  const _ConnectorZone({
    required this.ronda,
    required this.cantidadOrigen,
    required this.totalHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kConnectorWidth,
      height: _kHeaderHeight + totalHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: _kHeaderHeight),
        child: CustomPaint(
          size: Size(_kConnectorWidth, totalHeight),
          painter: _ConnectorPainter(
            ronda: ronda,
            cantidadOrigen: cantidadOrigen,
          ),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int ronda;
  final int cantidadOrigen;

  const _ConnectorPainter({required this.ronda, required this.cantidadOrigen});

  @override
  void paint(Canvas canvas, Size size) {
    final slot = _slotDeRonda(ronda);
    final offset = _offsetDeRonda(ronda);
    final midX = size.width / 2;

    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < cantidadOrigen; i += 2) {
      final yTop = offset + i * slot + _kCardHeight / 2;

      if (i + 1 >= cantidadOrigen) {
        // Cruce impar (bye): una sola línea recta hacia la siguiente ronda.
        canvas.drawLine(Offset(0, yTop), Offset(size.width, yTop), paint);
        continue;
      }

      final yBot = offset + (i + 1) * slot + _kCardHeight / 2;
      final yMid = (yTop + yBot) / 2;

      canvas.drawLine(Offset(0, yTop), Offset(midX, yTop), paint);
      canvas.drawLine(Offset(0, yBot), Offset(midX, yBot), paint);
      canvas.drawLine(Offset(midX, yTop), Offset(midX, yBot), paint);
      canvas.drawLine(Offset(midX, yMid), Offset(size.width, yMid), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.ronda != ronda ||
        oldDelegate.cantidadOrigen != cantidadOrigen;
  }
}

class _BracketMatchCard extends StatelessWidget {
  final PartidoModel partido;
  final String deporte;

  const _BracketMatchCard({required this.partido, required this.deporte});

  @override
  Widget build(BuildContext context) {
    final jugado = partido.resultadoRegistrado;
    final ganaLocal =
        jugado && !partido.empate && partido.ganadorId == partido.equipoLocalId;
    final ganaVisitante =
        jugado &&
        !partido.empate &&
        partido.ganadorId == partido.equipoVisitanteId;

    final colorEstado = jugado
        ? AppColors.success
        : partido.estaProgramado
        ? AppColors.info
        : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: colorEstado),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BracketTeamRow(
                      nombre: partido.equipoLocalNombre,
                      marcador: jugado ? '${partido.golesLocal ?? 0}' : null,
                      ganador: ganaLocal,
                    ),
                    const SizedBox(height: 5),
                    _BracketTeamRow(
                      nombre: partido.equipoVisitanteNombre,
                      marcador: jugado
                          ? '${partido.golesVisitante ?? 0}'
                          : null,
                      ganador: ganaVisitante,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketTeamRow extends StatelessWidget {
  final String nombre;
  final String? marcador;
  final bool ganador;

  const _BracketTeamRow({
    required this.nombre,
    required this.marcador,
    required this.ganador,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              fontWeight: ganador ? FontWeight.w900 : FontWeight.w600,
              color: ganador ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        if (marcador != null) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: ganador ? AppColors.primary : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              marcador!,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.w900,
                color: ganador ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
