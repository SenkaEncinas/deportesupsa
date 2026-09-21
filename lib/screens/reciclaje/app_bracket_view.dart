import 'package:flutter/material.dart';

import '../../models/partido_model.dart';
import '../../utils/fixture_grouping.dart';
import 'app_badge.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

// Alcanza para los dos equipos y el renglón de fecha/hora del cruce.
const double _kCardHeight = 104;
const double _kBaseGap = 22;
const double _kHeaderHeight = 40;
const double _kConnectorWidth = 34;
const double _kCampeonWidth = 150;

double _slotDeRonda(int ronda) => (_kCardHeight + _kBaseGap) * (1 << ronda);

double _offsetDeRonda(int ronda) => (_slotDeRonda(ronda) - _kCardHeight) / 2;

/// Una posición de la llave. Puede estar vacía: mientras no se sepa quién
/// pasa, el cruce todavía no existe como partido.
class _Slot {
  final PartidoModel? partido;

  const _Slot(this.partido);

  bool get vacio => partido == null;

  /// Nombre del ganador, si el partido ya se jugó y hubo ganador.
  String? get ganador {
    final p = partido;
    if (p == null || !p.resultadoRegistrado || p.empate) return null;
    if (p.ganadorId == p.equipoLocalId) return p.equipoLocalNombre;
    if (p.ganadorId == p.equipoVisitanteId) return p.equipoVisitanteNombre;
    return null;
  }
}

/// Llave eliminatoria visual (octavos, cuartos, semifinal, final y
/// campeón): columnas por ronda unidas con conectores, con scroll
/// horizontal para que quepa en cualquier ancho de pantalla.
///
/// El árbol se dibuja **completo desde el principio**, aunque solo estén
/// creados los cruces de la primera ronda: las rondas siguientes salen
/// como casilleros a definir ("Ganador · Octavos 1"). Sin esto, con una
/// sola ronda cargada la llave se veía como una simple lista de partidos
/// en una columna, sin forma de llave.
class AppBracketView extends StatelessWidget {
  final List<MapEntry<String, List<PartidoModel>>> rondas;
  final String deporte;

  const AppBracketView({
    super.key,
    required this.rondas,
    required this.deporte,
  });

  /// Completa el árbol: a partir de la cantidad de cruces de la primera
  /// ronda, arma todas las rondas siguientes hasta la final, usando los
  /// partidos que ya existan y dejando el resto en blanco.
  List<List<_Slot>> _armarArbol() {
    if (rondas.isEmpty) return const [];

    final arbol = <List<_Slot>>[];
    var cantidad = rondas.first.value.length;
    var indiceRonda = 0;

    while (cantidad >= 1) {
      final reales = indiceRonda < rondas.length
          ? rondas[indiceRonda].value
          : const <PartidoModel>[];

      arbol.add(
        List<_Slot>.generate(
          cantidad,
          (i) => _Slot(i < reales.length ? reales[i] : null),
        ),
      );

      if (cantidad == 1) break;

      // Con un número impar de cruces, el que queda libre pasa igual.
      cantidad = (cantidad / 2).ceil();
      indiceRonda++;
    }

    return arbol;
  }

  @override
  Widget build(BuildContext context) {
    if (rondas.isEmpty) return const SizedBox.shrink();

    final arbol = _armarArbol();
    if (arbol.isEmpty) return const SizedBox.shrink();

    final totalHeight = _slotDeRonda(0) * arbol.first.length;
    final anchoCard = MediaQuery.of(context).size.width < 700 ? 186.0 : 224.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int r = 0; r < arbol.length; r++) ...[
            _RoundColumn(
              titulo: r < rondas.length
                  ? rondas[r].key
                  : FixtureGrouping.nombreRondaEliminatoria(arbol[r].length),
              slots: arbol[r],
              // La ronda anterior alimenta los casilleros a definir.
              slotsPrevios: r == 0 ? const [] : arbol[r - 1],
              tituloPrevio: r == 0
                  ? ''
                  : (r - 1 < rondas.length
                        ? rondas[r - 1].key
                        : FixtureGrouping.nombreRondaEliminatoria(
                            arbol[r - 1].length,
                          )),
              ronda: r,
              totalHeight: totalHeight,
              anchoCard: anchoCard,
              deporte: deporte,
            ),
            if (r < arbol.length - 1)
              _ConnectorZone(
                ronda: r,
                cantidadOrigen: arbol[r].length,
                totalHeight: totalHeight,
              ),
          ],
          // Cierre de la llave: el campeón.
          _ConnectorZone(
            ronda: arbol.length - 1,
            cantidadOrigen: 1,
            totalHeight: totalHeight,
          ),
          _CampeonColumn(
            campeon: arbol.last.isEmpty ? null : arbol.last.first.ganador,
            totalHeight: totalHeight,
          ),
        ],
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final String titulo;
  final List<_Slot> slots;
  final List<_Slot> slotsPrevios;
  final String tituloPrevio;
  final int ronda;
  final double totalHeight;
  final double anchoCard;
  final String deporte;

  const _RoundColumn({
    required this.titulo,
    required this.slots,
    required this.slotsPrevios,
    required this.tituloPrevio,
    required this.ronda,
    required this.totalHeight,
    required this.anchoCard,
    required this.deporte,
  });

  /// Texto del casillero vacío: el ganador del cruce que lo alimenta, o
  /// su nombre ya resuelto si ese cruce se jugó.
  String _origen(int indiceSlot, int lado) {
    final indicePrevio = indiceSlot * 2 + lado;

    if (indicePrevio >= slotsPrevios.length) return 'Por definir';

    final previo = slotsPrevios[indicePrevio];
    return previo.ganador ?? 'Ganador · $tituloPrevio ${indicePrevio + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slotDeRonda(ronda);
    final offset = _offsetDeRonda(ronda);

    return SizedBox(
      width: anchoCard,
      height: _kHeaderHeight + totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: _kHeaderHeight,
            child: Center(
              // FittedBox y no solo Center: `AppBadge` se arma con
              // mainAxisSize.min y no se achica solo, así que con la
              // columna angosta de móvil un título largo ("Cuartos de
              // final") desbordaba la columna.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppBadge(text: titulo, type: AppBadgeType.primary),
              ),
            ),
          ),
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                for (int i = 0; i < slots.length; i++)
                  Positioned(
                    top: offset + i * slot,
                    left: 0,
                    right: 0,
                    height: _kCardHeight,
                    child: slots[i].vacio
                        ? _BracketPlaceholderCard(
                            arriba: _origen(i, 0),
                            abajo: _origen(i, 1),
                          )
                        : _BracketMatchCard(
                            partido: slots[i].partido!,
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

/// Columna final con el campeón (o el trofeo en gris mientras no se
/// defina), como cierre visual de la llave.
class _CampeonColumn extends StatelessWidget {
  final String? campeon;
  final double totalHeight;

  const _CampeonColumn({required this.campeon, required this.totalHeight});

  @override
  Widget build(BuildContext context) {
    final definido = campeon != null;

    return SizedBox(
      width: _kCampeonWidth,
      height: _kHeaderHeight + totalHeight,
      child: Column(
        children: [
          const SizedBox(
            height: _kHeaderHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppBadge(text: 'Campeón', type: AppBadgeType.warning),
              ),
            ),
          ),
          SizedBox(
            height: totalHeight,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: definido
                      ? AppColors.secondaryLight
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: definido ? AppColors.secondary : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: definido
                          ? AppColors.secondaryDark
                          : AppColors.textMuted,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campeon ?? 'Por definir',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w900,
                        color: definido
                            ? AppColors.secondaryDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
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

/// Casillero todavía sin cruce: muestra de dónde va a salir cada equipo.
class _BracketPlaceholderCard extends StatelessWidget {
  final String arriba;
  final String abajo;

  const _BracketPlaceholderCard({required this.arriba, required this.abajo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: AppColors.border),
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
                    _LineaPendiente(texto: arriba),
                    const SizedBox(height: 5),
                    _LineaPendiente(texto: abajo),
                    const SizedBox(height: 7),
                    const _FechaCruce(fecha: null),
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

class _LineaPendiente extends StatelessWidget {
  final String texto;

  const _LineaPendiente({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.small.copyWith(
        color: AppColors.textMuted,
        fontStyle: FontStyle.italic,
      ),
    );
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
                    const SizedBox(height: 7),
                    _FechaCruce(fecha: partido.fechaHora),
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

/// Fecha y hora en que se juega el cruce, debajo de los dos equipos.
/// Es la que el admin carga al programar el partido; mientras no la
/// tenga, queda "Sin programar" para que se note que falta ponerla.
class _FechaCruce extends StatelessWidget {
  final DateTime? fecha;

  const _FechaCruce({required this.fecha});

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get _texto {
    final f = fecha;
    if (f == null) return 'Sin programar';

    final dia = _dias[f.weekday - 1];
    final numero = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');

    return '$dia $numero/$mes · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final programado = fecha != null;

    return Row(
      children: [
        Icon(
          programado
              ? Icons.event_available_outlined
              : Icons.event_busy_outlined,
          size: 12,
          color: programado ? AppColors.textSecondary : AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              fontSize: 11,
              color: programado ? AppColors.textSecondary : AppColors.textMuted,
              fontWeight: programado ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
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
