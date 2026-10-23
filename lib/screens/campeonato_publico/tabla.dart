part of '../championship_detail_screen.dart';

// Tabla de posiciones, goleadores y sus esqueletos de carga.

enum _VistaTabla { general, porGrupos }

class _TableSection extends StatefulWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  /// Vista con la que arranca ("General" o "Por grupos"): el drawer de
  /// móvil tiene un acceso directo a "Tabla por grupos", así que puede
  /// abrir esta sección con ese filtro ya aplicado en vez de forzar un
  /// toque extra sobre el toggle interno.
  final _VistaTabla vistaInicial;

  const _TableSection({
    super.key,
    required this.datos,
    required this.campeonato,
    this.vistaInicial = _VistaTabla.general,
  });

  @override
  State<_TableSection> createState() => _TableSectionState();
}

class _TableSectionState extends State<_TableSection> {
  late _VistaTabla _vista = widget.vistaInicial;

  CampeonatoModel get campeonato => widget.campeonato;

  /// Encabezados según el deporte, con una columna "Grupo" opcional
  /// (vista general con varios grupos):
  /// - Fútbol: PJ, G, E, P, GF, GC, DG, Pts.
  /// - Vóley: PJ, G, P, SF, SC, DS, PF, PC, DP, Pts (sets y puntos).
  /// - Básquet: PJ, G, P, PF, PC, DP, Pts.
  List<String> _headers({required bool incluirGrupo}) {
    final base = campeonato.esVolley
        ? const [
            '#',
            'Equipo',
            'PJ',
            'G',
            'P',
            'SF',
            'SC',
            'DS',
            'PF',
            'PC',
            'DP',
            'Pts',
          ]
        : campeonato.esBasket
        ? const ['#', 'Equipo', 'PJ', 'G', 'P', 'PF', 'PC', 'DP', 'Pts']
        : const ['#', 'Equipo', 'PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'Pts'];

    if (!incluirGrupo) return base;

    return [...base]..insert(2, 'Grupo');
  }

  /// Estadísticas por equipo para la card compacta de móvil, sin
  /// posición/nombre/puntos (esos van en la cabecera de la card).
  List<MapEntry<String, String>> _statsCompactos(
    TablaPosicionModel item, {
    required bool incluirGrupo,
  }) {
    final base = campeonato.esVolley
        ? [
            MapEntry('PJ', '${item.partidosJugados}'),
            MapEntry('G', '${item.partidosGanados}'),
            MapEntry('P', '${item.partidosPerdidos}'),
            MapEntry('SF', '${item.golesFavor}'),
            MapEntry('SC', '${item.golesContra}'),
            MapEntry('DS', '${item.diferenciaGoles}'),
            MapEntry('PF', '${item.puntosFavor}'),
            MapEntry('PC', '${item.puntosContra}'),
            MapEntry('DP', '${item.diferenciaPuntos}'),
          ]
        : campeonato.esBasket
        ? [
            MapEntry('PJ', '${item.partidosJugados}'),
            MapEntry('G', '${item.partidosGanados}'),
            MapEntry('P', '${item.partidosPerdidos}'),
            MapEntry('PF', '${item.golesFavor}'),
            MapEntry('PC', '${item.golesContra}'),
            MapEntry('DP', '${item.diferenciaGoles}'),
          ]
        : [
            MapEntry('PJ', '${item.partidosJugados}'),
            MapEntry('G', '${item.partidosGanados}'),
            MapEntry('E', '${item.partidosEmpatados}'),
            MapEntry('P', '${item.partidosPerdidos}'),
            MapEntry('GF', '${item.golesFavor}'),
            MapEntry('GC', '${item.golesContra}'),
            MapEntry('DG', '${item.diferenciaGoles}'),
          ];

    if (!incluirGrupo || item.grupoId == null || item.grupoId!.isEmpty) {
      return base;
    }

    return [MapEntry('Grupo', _grupoCorto(item.grupoId!)), ...base];
  }

  /// La tabla va angosta y compacta solo en fútbol, donde comparte fila
  /// con la card de goleadores (ver [_ChampionshipContent]) y necesita
  /// ese espacio recortado. Vóley/básquet no tienen esa card al lado, así
  /// que la tabla usa toda la pantalla disponible con el espaciado normal.
  bool get _compacta => campeonato.esFutbol;

  List<Widget> _row(TablaPosicionModel item, {required bool incluirGrupo}) {
    final posicion = _PositionCell(position: item.posicion);
    // maxWidth acotado: sin esto, TextOverflow.ellipsis no recorta nada
    // porque DataCell le da a su contenido ancho intrínseco (ilimitado).
    final nombre = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _compacta ? 128 : 190),
      child: Text(
        item.equipoNombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (_compacta ? AppTextStyles.tableCell : AppTextStyles.bodyMedium)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
    // Con igualación se muestra "14 (+2)": el total ya la incluye, y el
    // paréntesis deja claro cuánto vino del ajuste manual del admin.
    final puntos = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${item.puntos}',
          style:
              (_compacta ? AppTextStyles.tableCell : AppTextStyles.bodyMedium)
                  .copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
        ),
        if (item.puntosIgualacion > 0) ...[
          const SizedBox(width: 3),
          Text(
            '(+${item.puntosIgualacion})',
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
    final grupo = Text(
      item.grupoId == null ? '-' : _grupoCorto(item.grupoId!),
      style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
    );

    final List<Widget> stats;

    if (campeonato.esVolley) {
      // En vóley golesFavor/golesContra guardan sets a favor/en contra.
      stats = [
        Text('${item.partidosJugados}'),
        Text('${item.partidosGanados}'),
        Text('${item.partidosPerdidos}'),
        Text('${item.golesFavor}'),
        Text('${item.golesContra}'),
        Text('${item.diferenciaGoles}'),
        Text('${item.puntosFavor}'),
        Text('${item.puntosContra}'),
        Text('${item.diferenciaPuntos}'),
        puntos,
      ];
    } else if (campeonato.esBasket) {
      stats = [
        Text('${item.partidosJugados}'),
        Text('${item.partidosGanados}'),
        Text('${item.partidosPerdidos}'),
        Text('${item.golesFavor}'),
        Text('${item.golesContra}'),
        Text('${item.diferenciaGoles}'),
        puntos,
      ];
    } else {
      stats = [
        Text('${item.partidosJugados}'),
        Text('${item.partidosGanados}'),
        Text('${item.partidosEmpatados}'),
        Text('${item.partidosPerdidos}'),
        Text('${item.golesFavor}'),
        Text('${item.golesContra}'),
        Text('${item.diferenciaGoles}'),
        puntos,
      ];
    }

    return [posicion, nombre, if (incluirGrupo) grupo, ...stats];
  }

  /// Arma una tabla (móvil o escritorio) para una lista de equipos ya
  /// lista para mostrar, con la posición ya calculada para ese contexto
  /// (general o por grupo).
  Widget _tabla(
    BuildContext context,
    List<TablaPosicionModel> items, {
    required bool incluirGrupo,
  }) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      // En móvil una DataTable con hasta 12 columnas obliga a un scroll
      // horizontal poco descubrible y filas muy angostas. Se reemplaza
      // por una card por equipo con sus estadísticas en una grilla
      // compacta, igual que se hizo con AppHeroCard.
      if (items.isEmpty) {
        return AppCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Todavía no hay tabla de posiciones.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppStandingCard(
              item: item,
              stats: _statsCompactos(item, incluirGrupo: incluirGrupo),
            ),
          );
        }).toList(),
      );
    }

    return AppTableContainer(
      headers: _headers(incluirGrupo: incluirGrupo),
      rows: items
          .map((item) => _row(item, incluirGrupo: incluirGrupo))
          .toList(),
      emptyMessage: 'Todavía no hay tabla de posiciones.',
      compact: _compacta,
    );
  }

  /// Copia cada equipo con la posición recalculada para el ranking
  /// general (1..N sobre todos los grupos juntos): la posición que trae
  /// el modelo es la posición dentro de su propio grupo, no sirve acá.
  List<TablaPosicionModel> _rankingGeneral(List<TablaPosicionModel> tabla) {
    // El mismo criterio que la tabla de cada grupo y que la siembra de
    // la llave: hay uno solo para todo el sistema.
    final ordenado = [...tabla]..sort(TablaCalculo.comparar);

    return List.generate(ordenado.length, (i) {
      final item = ordenado[i];

      return TablaPosicionModel(
        equipoId: item.equipoId,
        equipoNombre: item.equipoNombre,
        grupoId: item.grupoId,
        partidosJugados: item.partidosJugados,
        partidosGanados: item.partidosGanados,
        partidosEmpatados: item.partidosEmpatados,
        partidosPerdidos: item.partidosPerdidos,
        golesFavor: item.golesFavor,
        golesContra: item.golesContra,
        diferenciaGoles: item.diferenciaGoles,
        puntos: item.puntos,
        posicion: i + 1,
        fechaActualizacion: item.fechaActualizacion,
        puntosFavor: item.puntosFavor,
        puntosContra: item.puntosContra,
        diferenciaPuntos: item.diferenciaPuntos,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TablaPosicionModel>>(
      stream: widget.datos.tabla,
      builder: (context, snapshot) {
        final tabla = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(child: AppLoading(message: 'Cargando tabla...'));
        }

        // Se agrupa por grupoId: los campeonatos sin fase de grupos (o
        // sin ese dato todavía) caen en un único grupo "sin nombre".
        final porGrupo = <String, List<TablaPosicionModel>>{};

        for (final item in tabla) {
          final clave = item.grupoId ?? '';
          porGrupo.putIfAbsent(clave, () => []).add(item);
        }

        for (final lista in porGrupo.values) {
          lista.sort((a, b) => a.posicion.compareTo(b.posicion));
        }

        final claves = porGrupo.keys.toList()..sort();
        final hayVariosGrupos = claves.length > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Tabla de posiciones',
              subtitle: campeonato.esVolley
                  ? 'Partidos, sets y puntos de cada equipo.'
                  : !hayVariosGrupos
                  ? 'Desempeño general de los equipos.'
                  : _vista == _VistaTabla.general
                  ? 'Todos los equipos juntos, sin importar su grupo.'
                  : 'Cada grupo con su propia tabla.',
            ),
            if (hayVariosGrupos) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterPill(
                    text: 'General',
                    selected: _vista == _VistaTabla.general,
                    onTap: () => setState(() => _vista = _VistaTabla.general),
                  ),
                  AppFilterPill(
                    text: 'Por grupos',
                    selected: _vista == _VistaTabla.porGrupos,
                    onTap: () => setState(() => _vista = _VistaTabla.porGrupos),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (!hayVariosGrupos)
              _tabla(context, tabla, incluirGrupo: false)
            else if (_vista == _VistaTabla.general)
              _tabla(context, _rankingGeneral(tabla), incluirGrupo: true)
            else
              ...claves.map((clave) {
                final index = claves.indexOf(clave);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < claves.length - 1 ? 22 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clave, style: AppTextStyles.heading3),
                      const SizedBox(height: 10),
                      _tabla(context, porGrupo[clave]!, incluirGrupo: false),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

/// Estado de carga para "Próximos partidos" / "Últimos resultados":
/// dos siluetas del alto aproximado de un [AppMatchCard] en vez de un
/// spinner suelto.
class _MatchSkeletonColumn extends StatelessWidget {
  const _MatchSkeletonColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonMatchCard(),
        SizedBox(height: 10),
        AppSkeletonMatchCard(),
      ],
    );
  }
}

/// Estado de carga para "Goleadores": filas de ranking con la misma
/// silueta que [_ScorerTile].
class _RankingSkeletonColumn extends StatelessWidget {
  const _RankingSkeletonColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonListTile(),
        SizedBox(height: 10),
        AppSkeletonListTile(),
        SizedBox(height: 10),
        AppSkeletonListTile(),
      ],
    );
  }
}

/// "Grupo B" -> "B": en la tabla de posiciones el grupo se muestra solo
/// con su letra, tanto en la columna de la tabla de escritorio como en
/// el chip de la card de móvil (ver `nombreGrupo` en GrupoService, que
/// siempre arma el nombre como "Grupo" seguido de una letra).
String _grupoCorto(String grupoId) {
  final partes = grupoId.trim().split(RegExp(r'\s+'));
  return partes.isEmpty ? grupoId : partes.last;
}

class _PositionCell extends StatelessWidget {
  final int position;

  const _PositionCell({required this.position});

  @override
  Widget build(BuildContext context) {
    final isTop = position <= 3;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop ? AppColors.primaryLight : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Text(
        '$position',
        style: AppTextStyles.small.copyWith(
          color: isTop ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScorersSection extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _ScorersSection({required this.datos, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    // El ranking individual (goleadores) solo existe para fútbol/futsal:
    // vóley y básquet no registran goles/puntos por jugador, así que
    // este widget ni se llama para esos deportes (ver el build principal).
    return AppCard(
      child: StreamBuilder<List<RankingGoleadorModel>>(
        stream: datos.ranking,
        builder: (context, snapshot) {
          final ranking = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Goleadores',
                subtitle: 'Ranking de mejores anotadores.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _RankingSkeletonColumn()
              else if (ranking.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.sports_soccer_outlined,
                  text: 'Todavía no hay goles registrados.',
                )
              else
                ...List.generate(ranking.length, (index) {
                  final item = ranking[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < ranking.length - 1 ? 10 : 0,
                    ),
                    child: _ScorerTile(position: index + 1, item: item),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ScorerTile extends StatelessWidget {
  final int position;
  final RankingGoleadorModel item;

  const _ScorerTile({required this.position, required this.item});

  @override
  Widget build(BuildContext context) {
    final retirado = item.jugadorEstado == 'retirado';
    final isTop = position <= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.primaryLight.withValues(alpha: 0.65)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTop
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              position.toString(),
              style: AppTextStyles.small.copyWith(
                color: isTop ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jugadorNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.equipoNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ),
                    if (retirado) ...[
                      const SizedBox(width: 8),
                      const AppBadge(
                        text: 'Retirado',
                        type: AppBadgeType.danger,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalGoles}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.totalGoles == 1 ? 'gol' : 'goles',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
