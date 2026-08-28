import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/public_home_service.dart';
import '../utils/clasificacion.dart';
import '../utils/fixture_grouping.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_bracket_view.dart';
import 'reciclaje/app_clasificados_card.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_responsive_pair.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_skeleton.dart';
import 'reciclaje/app_standing_card.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/championship_public_card.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

class ChampionshipDetailScreen extends StatelessWidget {
  final CampeonatoModel campeonato;

  const ChampionshipDetailScreen({super.key, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final service = PublicHomeService();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: isMobile
              ? _MobileChampionshipView(
                  service: service,
                  campeonato: campeonato,
                )
              : SingleChildScrollView(
                  child: AppPage(
                    title: campeonato.nombre,
                    subtitle: 'Información pública del campeonato.',
                    actions: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Volver'),
                      ),
                    ],
                    child: _ChampionshipContent(
                      service: service,
                      campeonato: campeonato,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// El contenido completo del campeonato, sin encabezado ni scroll
/// propios (eso lo pone quien lo use): pensado para desktop/tablet, que
/// ya tenían lugar de sobra para ver todo en una sola columna larga. En
/// vez del cartel verde grande de antes (con descripción, universidad,
/// cancha, modalidad...) solo se muestra el logo de la UPSA: esa info ya
/// la vio el usuario al entrar al campeonato, no hace falta repetirla.
class _ChampionshipContent extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _ChampionshipContent({required this.service, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final estadoTexto = ChampionshipPublicCard.estadoTexto(campeonato.estado);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoMark(compact: true),
            const SizedBox(width: 12),
            AppBadge(
              text: estadoTexto,
              type: ChampionshipPublicCard.badgeType(campeonato.estado),
              icon: Icons.sports_soccer,
            ),
            if (campeonato.tieneFasesSeparadas) ...[
              const SizedBox(width: 8),
              AppBadge(
                text: campeonato.estaEnFaseDeGrupos
                    ? 'Fase de grupos'
                    : 'Fase eliminatoria',
                type: campeonato.estaEnFaseDeGrupos
                    ? AppBadgeType.info
                    : AppBadgeType.warning,
                icon: campeonato.estaEnFaseDeGrupos
                    ? Icons.grid_view_rounded
                    : Icons.bolt_outlined,
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _StatsSection(
          service: service,
          campeonato: campeonato,
          estadoTexto: estadoTexto,
        ),
        const SizedBox(height: 24),
        AppResponsivePair(
          first: _NextMatchesSection(
            service: service,
            campeonatoId: campeonato.id,
            deporte: campeonato.deporteEfectivo,
          ),
          second: _LastResultsSection(
            service: service,
            campeonatoId: campeonato.id,
            deporte: campeonato.deporteEfectivo,
          ),
        ),
        const SizedBox(height: 24),
        _FixtureSection(service: service, campeonato: campeonato),
        if (campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion) ...[
          const SizedBox(height: 24),
          _ClasificadosSection(service: service, campeonato: campeonato),
        ],
        const SizedBox(height: 24),
        // Vóley y básquet no registran goles/puntos por jugador: sin esa
        // sección, la tabla usa todo el ancho en vez de dejar un hueco
        // al lado.
        if (campeonato.esFutbol)
          AppResponsivePair(
            firstFlex: 3,
            secondFlex: 2,
            first: _TableSection(service: service, campeonato: campeonato),
            second: _ScorersSection(service: service, campeonato: campeonato),
          )
        else
          _TableSection(service: service, campeonato: campeonato),
        const SizedBox(height: 28),
      ],
    );
  }
}

enum _MobileTab { resumen, fixture, tabla }

/// Versión móvil, separada en pestañas en vez de una sola columna larga:
/// antes había que scrollear muchísimo para llegar a la tabla o los
/// goleadores. Se arma con `AppFilterPill` (el mismo patrón de "General /
/// Por grupos" que ya usa la tabla de posiciones) en vez de un `TabBar`
/// de Material, para no meter un estilo de pestañas distinto al resto
/// de la app.
class _MobileChampionshipView extends StatefulWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _MobileChampionshipView({
    required this.service,
    required this.campeonato,
  });

  @override
  State<_MobileChampionshipView> createState() =>
      _MobileChampionshipViewState();
}

class _MobileChampionshipViewState extends State<_MobileChampionshipView> {
  _MobileTab _tab = _MobileTab.resumen;

  CampeonatoModel get campeonato => widget.campeonato;
  PublicHomeService get service => widget.service;

  @override
  Widget build(BuildContext context) {
    final estadoTexto = ChampionshipPublicCard.estadoTexto(campeonato.estado);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                const AppLogoMark(compact: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(campeonato.nombre, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppBadge(
                  text: estadoTexto,
                  type: ChampionshipPublicCard.badgeType(campeonato.estado),
                  icon: Icons.sports_soccer,
                ),
                if (campeonato.tieneFasesSeparadas)
                  AppBadge(
                    text: campeonato.estaEnFaseDeGrupos
                        ? 'Fase de grupos'
                        : 'Fase eliminatoria',
                    type: campeonato.estaEnFaseDeGrupos
                        ? AppBadgeType.info
                        : AppBadgeType.warning,
                    icon: campeonato.estaEnFaseDeGrupos
                        ? Icons.grid_view_rounded
                        : Icons.bolt_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterPill(
                  text: 'Resumen',
                  selected: _tab == _MobileTab.resumen,
                  onTap: () => setState(() => _tab = _MobileTab.resumen),
                ),
                AppFilterPill(
                  text: 'Fixture',
                  selected: _tab == _MobileTab.fixture,
                  onTap: () => setState(() => _tab = _MobileTab.fixture),
                ),
                AppFilterPill(
                  text: 'Tabla',
                  selected: _tab == _MobileTab.tabla,
                  onTap: () => setState(() => _tab = _MobileTab.tabla),
                ),
              ],
            ),
            const SizedBox(height: 18),
            switch (_tab) {
              _MobileTab.resumen => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsSection(
                    service: service,
                    campeonato: campeonato,
                    estadoTexto: estadoTexto,
                  ),
                  const SizedBox(height: 20),
                  _NextMatchesSection(
                    service: service,
                    campeonatoId: campeonato.id,
                    deporte: campeonato.deporteEfectivo,
                  ),
                  const SizedBox(height: 16),
                  _LastResultsSection(
                    service: service,
                    campeonatoId: campeonato.id,
                    deporte: campeonato.deporteEfectivo,
                  ),
                ],
              ),
              _MobileTab.fixture => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FixtureSection(service: service, campeonato: campeonato),
                  if (campeonato.tipoCampeonato ==
                      TipoCampeonato.gruposEliminacion) ...[
                    const SizedBox(height: 20),
                    _ClasificadosSection(
                      service: service,
                      campeonato: campeonato,
                    ),
                  ],
                ],
              ),
              _MobileTab.tabla => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TableSection(service: service, campeonato: campeonato),
                  if (campeonato.esFutbol) ...[
                    const SizedBox(height: 20),
                    _ScorersSection(service: service, campeonato: campeonato),
                  ],
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _StatsSection({
    required this.service,
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      StreamBuilder(
        stream: service.streamEquipos(campeonato.id),
        builder: (context, snapshot) {
          return StatCard(
            title: 'Equipos',
            value: '${snapshot.data?.length ?? 0}',
            icon: Icons.groups_2_outlined,
            subtitle: 'Registrados',
            color: AppColors.primary,
          );
        },
      ),
      StreamBuilder<List<PartidoModel>>(
        stream: service.streamPartidos(campeonato.id),
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return StatCard(
            title: 'Partidos',
            value: '${partidos.length}',
            icon: Icons.sports_soccer,
            subtitle: ChampionshipPublicCard.formatLabel(
              campeonato.tipoCampeonato,
            ),
            color: AppColors.secondary,
          );
        },
      ),
      // Para fútbol se muestran los goles registrados; para vóley y
      // básquet se muestran los partidos finalizados.
      if (campeonato.esFutbol)
        StreamBuilder<List<RankingGoleadorModel>>(
          stream: service.streamRankingGoleadores(campeonato.id),
          builder: (context, snapshot) {
            final ranking = snapshot.data ?? [];
            final totalGoles = ranking.fold<int>(
              0,
              (total, item) => total + item.totalGoles,
            );

            return StatCard(
              title: 'Goles',
              value: '$totalGoles',
              icon: Icons.emoji_events_outlined,
              subtitle: 'Registrados',
              color: AppColors.info,
            );
          },
        )
      else
        StreamBuilder<List<PartidoModel>>(
          stream: service.streamPartidos(campeonato.id),
          builder: (context, snapshot) {
            final finalizados = (snapshot.data ?? [])
                .where((p) => p.resultadoRegistrado)
                .length;

            return StatCard(
              title: 'Finalizados',
              value: '$finalizados',
              icon: Icons.emoji_events_outlined,
              subtitle: 'Con resultado',
              color: AppColors.info,
            );
          },
        ),
      StatCard(
        title: 'Estado',
        value: estadoTexto,
        icon: Icons.verified_outlined,
        subtitle: 'Campeonato',
        color: AppColors.success,
      ),
    ];

    return AppResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      children: cards,
    );
  }
}

class _NextMatchesSection extends StatelessWidget {
  final PublicHomeService service;
  final String campeonatoId;
  final String deporte;

  const _NextMatchesSection({
    required this.service,
    required this.campeonatoId,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: service.streamProximosPartidos(campeonatoId),
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Próximos partidos',
                subtitle: 'Programación oficial del campeonato.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MatchSkeletonColumn()
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'Todavía no hay partidos programados.',
                )
              else
                ...List.generate(partidos.length, (index) {
                  final partido = partidos[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < partidos.length - 1 ? 10 : 0,
                    ),
                    child: AppMatchCard(partido: partido, deporte: deporte),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LastResultsSection extends StatelessWidget {
  final PublicHomeService service;
  final String campeonatoId;
  final String deporte;

  const _LastResultsSection({
    required this.service,
    required this.campeonatoId,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: service.streamUltimosResultados(campeonatoId),
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Últimos resultados',
                subtitle: 'Marcadores finales registrados.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MatchSkeletonColumn()
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.scoreboard_outlined,
                  text: 'Todavía no hay resultados registrados.',
                )
              else
                ...List.generate(partidos.length, (index) {
                  final partido = partidos[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < partidos.length - 1 ? 10 : 0,
                    ),
                    child: AppMatchCard(
                      partido: partido,
                      showResult: true,
                      deporte: deporte,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

/// Fixture completo, público y de solo lectura. Según el formato del
/// campeonato separa dos cosas distintas:
/// - Los cruces de todos contra todos (liga o fase de grupos): lista
///   agrupada, igual que en la pantalla de administración.
/// - Los cruces de eliminación directa (octavos, cuartos, semifinal,
///   final...): una llave visual con `AppBracketView`, mucho más clara
///   que una lista de texto una vez que el torneo llega a esa etapa.
class _FixtureSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _FixtureSection({required this.service, required this.campeonato});

  bool get _esEliminacionPura =>
      campeonato.tipoCampeonato == TipoCampeonato.eliminacionDirecta;

  bool get _esGruposEliminacion =>
      campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartidoModel>>(
      stream: service.streamPartidos(campeonato.id),
      builder: (context, snapshot) {
        final partidos = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  title: 'Llaves eliminatorias',
                  subtitle: 'De la ronda inicial hasta la gran final.',
                ),
                const SizedBox(height: 16),
                const _MatchSkeletonColumn(),
              ],
            ),
          );
        }

        // El listado plano "fixture por grupo" ya no se muestra acá: la
        // tabla de posiciones y los clasificados cubren esa información
        // de forma más útil. Esta sección queda solo para la llave
        // visual de la fase eliminatoria.
        final List<MapEntry<String, List<PartidoModel>>> rondasLlave;

        if (_esEliminacionPura) {
          rondasLlave = FixtureGrouping.rondasEliminatorias(partidos);
        } else if (_esGruposEliminacion) {
          final deFaseFinal = partidos
              .where((p) => p.grupoId == null || p.grupoId!.isEmpty)
              .toList();

          rondasLlave = FixtureGrouping.rondasEliminatorias(deFaseFinal);
        } else {
          rondasLlave = const [];
        }

        if (rondasLlave.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Llaves eliminatorias',
                subtitle: 'De la ronda inicial hasta la gran final.',
              ),
              const SizedBox(height: 16),
              const AppInlineEmptyState(
                icon: Icons.account_tree_outlined,
                text: 'Todavía no hay llaves eliminatorias generadas.',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Llaves eliminatorias',
              subtitle: 'De la ronda inicial hasta la gran final.',
            ),
            const SizedBox(height: 16),
            AppBracketView(
              rondas: rondasLlave,
              deporte: campeonato.deporteEfectivo,
            ),
          ],
        );
      },
    );
  }
}

/// Quién clasifica de la fase de grupos a la fase final (directos por
/// grupo + mejores terceros), calculado en vivo con los resultados
/// actuales. Solo aplica al formato "grupos + eliminación".
class _ClasificadosSection extends StatelessWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _ClasificadosSection({
    required this.service,
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final config = campeonato.configuracion;
    final total =
        config.cantidadGrupos * config.clasificanPorGrupo +
        config.mejoresTerceros;

    return StreamBuilder<List<TablaPosicionModel>>(
      stream: service.streamTabla(campeonato.id),
      builder: (context, snapshot) {
        final tabla = snapshot.data ?? [];

        final clasificados = Clasificacion.calcular(
          tabla: tabla,
          clasificanPorGrupo: config.clasificanPorGrupo,
          mejoresTerceros: config.mejoresTerceros,
        );

        return AppClasificadosCard(
          clasificados: clasificados,
          totalEsperado: total,
        );
      },
    );
  }
}

enum _VistaTabla { general, porGrupos }

class _TableSection extends StatefulWidget {
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _TableSection({required this.service, required this.campeonato});

  @override
  State<_TableSection> createState() => _TableSectionState();
}

class _TableSectionState extends State<_TableSection> {
  _VistaTabla _vista = _VistaTabla.general;

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
    final puntos = Text(
      '${item.puntos}',
      style: (_compacta ? AppTextStyles.tableCell : AppTextStyles.bodyMedium)
          .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w900),
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
      rows: items.map((item) => _row(item, incluirGrupo: incluirGrupo)).toList(),
      emptyMessage: 'Todavía no hay tabla de posiciones.',
      compact: _compacta,
    );
  }

  int _compararGeneral(TablaPosicionModel a, TablaPosicionModel b) {
    var compare = b.puntos.compareTo(a.puntos);
    if (compare != 0) return compare;

    compare = b.diferenciaGoles.compareTo(a.diferenciaGoles);
    if (compare != 0) return compare;

    compare = b.golesFavor.compareTo(a.golesFavor);
    if (compare != 0) return compare;

    compare = a.golesContra.compareTo(b.golesContra);
    if (compare != 0) return compare;

    return a.equipoNombre.compareTo(b.equipoNombre);
  }

  /// Copia cada equipo con la posición recalculada para el ranking
  /// general (1..N sobre todos los grupos juntos): la posición que trae
  /// el modelo es la posición dentro de su propio grupo, no sirve acá.
  List<TablaPosicionModel> _rankingGeneral(List<TablaPosicionModel> tabla) {
    final ordenado = [...tabla]..sort(_compararGeneral);

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
      stream: widget.service.streamTabla(campeonato.id),
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
                    onTap: () =>
                        setState(() => _vista = _VistaTabla.porGrupos),
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
  final PublicHomeService service;
  final CampeonatoModel campeonato;

  const _ScorersSection({required this.service, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    // El ranking individual (goleadores) solo existe para fútbol/futsal:
    // vóley y básquet no registran goles/puntos por jugador, así que
    // este widget ni se llama para esos deportes (ver el build principal).
    return AppCard(
      child: StreamBuilder<List<RankingGoleadorModel>>(
        stream: service.streamRankingGoleadores(campeonato.id),
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
