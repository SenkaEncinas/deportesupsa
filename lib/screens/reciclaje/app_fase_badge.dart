import 'package:flutter/material.dart';

import '../../models/campeonato_model.dart';
import 'app_badge.dart';

/// En qué etapa está un campeonato de dos fases: "Fase de grupos" (o "de
/// liga") o "Fase eliminatoria". En los demás formatos no dibuja nada.
///
/// Estaba copiado en la vista pública (dos veces), en la tarjeta del
/// admin y en el PDF, cada copia con su propio texto.
class AppFaseBadge extends StatelessWidget {
  final CampeonatoModel campeonato;

  const AppFaseBadge({super.key, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    if (!campeonato.tieneFasesSeparadas) return const SizedBox.shrink();

    final regular = campeonato.estaEnFaseRegular;

    return AppBadge(
      text: campeonato.nombreFaseActual,
      type: regular ? AppBadgeType.info : AppBadgeType.warning,
      icon: regular
          ? (campeonato.usaGrupos
                ? Icons.grid_view_rounded
                : Icons.format_list_numbered_rounded)
          : Icons.bolt_outlined,
    );
  }
}
