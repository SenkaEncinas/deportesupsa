import 'package:flutter/material.dart';

import '../../utils/clasificacion.dart';
import '../../utils/fixture_grouping.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_colors.dart';
import 'app_section_header.dart';
import 'app_text_styles.dart';

/// Lista de clasificados a la fase final de un campeonato de grupos +
/// eliminación: los que pasan directo por grupo y los mejores terceros,
/// junto con la ronda con la que arrancaría la llave (octavos, cuartos,
/// etc.) según cuántos clasifican en total.
///
/// Colapsada por defecto: es información de referencia que no necesita
/// competir por atención con el fixture ni la tabla. Un toggle +/- en la
/// esquina superior derecha del encabezado la despliega si alguien
/// quiere verla.
///
/// [colapsable] en `false` la deja siempre desplegada y sin el toggle:
/// se usa en la vista de fase eliminatoria en móvil, donde esta card ya
/// es un destino explícito (no compite con nada más en pantalla), así
/// que no tiene sentido pedir un toque extra para verla.
class AppClasificadosCard extends StatefulWidget {
  final List<ClasificadoInfo> clasificados;
  final int totalEsperado;
  final bool colapsable;

  const AppClasificadosCard({
    super.key,
    required this.clasificados,
    required this.totalEsperado,
    this.colapsable = true,
  });

  @override
  State<AppClasificadosCard> createState() => _AppClasificadosCardState();
}

class _AppClasificadosCardState extends State<AppClasificadosCard> {
  bool _expandido = false;

  bool get _mostrarContenido => !widget.colapsable || _expandido;

  @override
  Widget build(BuildContext context) {
    final ronda = FixtureGrouping.rondaSegunEquipos(widget.totalEsperado);
    final faltan = widget.totalEsperado - widget.clasificados.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.colapsable
                ? () => setState(() => _expandido = !_expandido)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: AppSectionHeader(
                    title: 'Clasificados a la fase final',
                    subtitle:
                        'Directos por grupo y mejores terceros, en vivo según los resultados actuales.',
                  ),
                ),
                if (widget.totalEsperado >= 2) ...[
                  AppBadge(text: ronda, type: AppBadgeType.primary),
                  const SizedBox(width: 8),
                ],
                if (widget.colapsable) _ToggleIcon(expandido: _expandido),
              ],
            ),
          ),
          if (_mostrarContenido) ...[
            const SizedBox(height: 14),
            if (widget.clasificados.isEmpty)
              Text(
                'Todavía no hay clasificados definidos: se calculan a medida que se juegan los partidos de grupos.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Column(children: _filasPorBloque(widget.clasificados)),
            if (faltan > 0) ...[
              const SizedBox(height: 6),
              Text(
                faltan == 1
                    ? 'Falta 1 cupo por definir.'
                    : 'Faltan $faltan cupos por definir.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Arma la lista con un encabezado por bloque (primeros de grupo,
/// segundos, mejores terceros) y el número de siembra a la izquierda,
/// que es el orden con el que se cruzan las llaves.
List<Widget> _filasPorBloque(List<ClasificadoInfo> clasificados) {
  final filas = <Widget>[];
  int? bloqueAnterior;

  for (var i = 0; i < clasificados.length; i++) {
    final clasificado = clasificados[i];
    final bloque = clasificado.porMejorTercero
        ? -1
        : clasificado.posicionEnGrupo;

    if (bloque != bloqueAnterior) {
      filas.add(
        Padding(
          padding: EdgeInsets.only(top: filas.isEmpty ? 0 : 12, bottom: 8),
          child: Text(
            _tituloBloque(clasificado),
            style: AppTextStyles.small.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
      bloqueAnterior = bloque;
    }

    filas.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ClasificadoRow(clasificado: clasificado, siembra: i + 1),
      ),
    );
  }

  return filas;
}

String _tituloBloque(ClasificadoInfo clasificado) {
  if (clasificado.porMejorTercero) return 'MEJORES TERCEROS';

  switch (clasificado.posicionEnGrupo) {
    case 1:
      return 'PRIMEROS DE GRUPO';
    case 2:
      return 'SEGUNDOS DE GRUPO';
    case 3:
      return 'TERCEROS DE GRUPO';
    default:
      return '${clasificado.posicionEnGrupo}° DE CADA GRUPO';
  }
}

class _ToggleIcon extends StatelessWidget {
  final bool expandido;

  const _ToggleIcon({required this.expandido});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        expandido ? Icons.remove : Icons.add,
        size: 18,
        color: AppColors.primaryDark,
      ),
    );
  }
}

class _ClasificadoRow extends StatelessWidget {
  final ClasificadoInfo clasificado;

  /// Puesto en la tabla general de clasificados (1 = mejor sembrado).
  final int siembra;

  const _ClasificadoRow({required this.clasificado, required this.siembra});

  @override
  Widget build(BuildContext context) {
    final equipo = clasificado.equipo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$siembra',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipo.equipoNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${equipo.posicion}° de grupo · ${equipo.puntos} pts · DIF ${equipo.diferenciaGoles >= 0 ? '+' : ''}${equipo.diferenciaGoles}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (equipo.grupoId != null && equipo.grupoId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AppBadge(
                text: equipo.grupoId!,
                type: AppBadgeType.neutral,
              ),
            ),
          AppBadge(
            text: clasificado.porMejorTercero ? 'Mejor 3ro' : 'Directo',
            type: clasificado.porMejorTercero
                ? AppBadgeType.warning
                : AppBadgeType.success,
          ),
        ],
      ),
    );
  }
}
