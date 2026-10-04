import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../services/datos_campeonato.dart';
import '../services/public_home_service.dart';
import '../utils/fixture_grouping.dart';
import '../utils/tabla_calculo.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_bracket_view.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_clasificados_card.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_public_footer.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_responsive_pair.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_skeleton.dart';
import 'reciclaje/app_standing_card.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';
import '../utils/etiquetas.dart';
import 'reciclaje/app_fase_badge.dart';
import 'reciclaje/app_fondo.dart';

class ChampionshipDetailScreen extends StatefulWidget {
  final CampeonatoModel campeonato;

  /// Solo para los tests, que necesitan apuntar a un Firestore de
  /// mentira. En la app queda en null y se usa el de siempre.
  final PublicHomeService? service;

  const ChampionshipDetailScreen({
    super.key,
    required this.campeonato,
    this.service,
  });

  @override
  State<ChampionshipDetailScreen> createState() =>
      _ChampionshipDetailScreenState();
}

class _ChampionshipDetailScreenState extends State<ChampionshipDetailScreen> {
  /// Una sola conexión por dato para toda la pantalla (ver
  /// [DatosCampeonato]).
  late final DatosCampeonato datos = DatosCampeonato(
    widget.service ?? PublicHomeService(),
    widget.campeonato.id,
  );

  CampeonatoModel get campeonato => widget.campeonato;

  @override
  void dispose() {
    datos.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppFondo(
      child: isMobile
          ? _MobileChampionshipView(datos: datos, campeonato: campeonato)
          : SingleChildScrollView(
              child: Column(
                children: [
                  AppPage(
                    title: campeonato.nombre,
                    subtitle: 'Información pública del campeonato.',
                    actions: [
                      AppButton.secondary(
                        text: 'Volver',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    child: _ChampionshipContent(
                      datos: datos,
                      campeonato: campeonato,
                    ),
                  ),
                  const AppPublicFooter(),
                ],
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
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _ChampionshipContent({required this.datos, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final estadoTexto = Etiquetas.estadoCampeonato(campeonato.estado);

    // En fase eliminatoria la vista pública se reduce a la llave, la
    // tabla de la fase de grupos y, en fútbol, los goleadores: los
    // próximos partidos y las estadísticas ya no aportan nada.
    if (campeonato.estaEnFaseEliminatoria) {
      return _ContenidoEliminatoria(datos: datos, campeonato: campeonato);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoMark(compact: true),
            const SizedBox(width: 12),
            AppBadge(
              text: estadoTexto,
              type: AppBadge.tipoEstadoCampeonato(campeonato.estado),
              icon: deporteIcono(campeonato.deporteEfectivo),
            ),
            if (campeonato.tieneFasesSeparadas) ...[
              const SizedBox(width: 8),
              AppFaseBadge(campeonato: campeonato),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _StatsSection(
          datos: datos,
          campeonato: campeonato,
          estadoTexto: estadoTexto,
        ),
        const SizedBox(height: 24),
        AppResponsivePair(
          first: _NextMatchesSection(
            datos: datos,
            deporte: campeonato.deporteEfectivo,
          ),
          second: _LastResultsSection(
            datos: datos,
            deporte: campeonato.deporteEfectivo,
          ),
        ),
        const SizedBox(height: 24),
        // Fuera de la eliminatoria, el cuadro solo existe en la
        // eliminación directa. En una liga o en la fase de grupos esta
        // sección solo decía "Todavía no hay partidos de fase final".
        if (campeonato.muestraLlave) ...[
          _FixtureSection(datos: datos, campeonato: campeonato),
          const SizedBox(height: 24),
        ],
        // Vóley y básquet no registran goles/puntos por jugador: sin esa
        // sección, la tabla usa todo el ancho en vez de dejar un hueco
        // al lado.
        if (campeonato.esFutbol)
          AppResponsivePair(
            firstFlex: 3,
            secondFlex: 2,
            first: _TableSection(datos: datos, campeonato: campeonato),
            second: _ScorersSection(datos: datos, campeonato: campeonato),
          )
        else
          _TableSection(datos: datos, campeonato: campeonato),
        // Desplegada, debajo de la tabla: muestra en vivo quién va
        // clasificando y en qué puesto de siembra, para que nadie tenga
        // que deducirlo de la tabla general.
        if (campeonato.tieneFasesSeparadas) ...[
          const SizedBox(height: 24),
          AppClasificadosEnVivo(
            campeonato: campeonato,
            tabla: () => datos.tabla,
            colapsable: false,
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Lo que se ve al entrar en fase eliminatoria: el cuadro y, debajo, la
/// lista de partidos de fase final, que hace de fixture (los que faltan,
/// con su fecha) y de resultados (los jugados, con su marcador). La
/// tabla y los clasificados se abren desde la barra lateral.
///
/// "Próximos partidos" y "Últimos resultados" no van acá: repetían los
/// mismos cruces que ya muestra esa lista, cada uno dos veces.
///
/// La usan escritorio y móvil, así que lo que aparece en la pantalla
/// principal es lo mismo en los dos.
class _PrincipalEliminatoria extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  /// En móvil el título de la sección ya dice "Llaves eliminatorias".
  final bool conEncabezado;

  const _PrincipalEliminatoria({
    required this.datos,
    required this.campeonato,
    this.conEncabezado = true,
  });

  @override
  Widget build(BuildContext context) {
    return _FixtureSection(
      datos: datos,
      campeonato: campeonato,
      conEncabezado: conEncabezado,
    );
  }
}

/// Contenido público de escritorio cuando el campeonato está en fase
/// eliminatoria: una barra lateral, igual a la del menú del celular,
/// y al lado la sección elegida. Arranca en las llaves; la tabla de la
/// fase de grupos (con los goleadores en fútbol) y los clasificados
/// quedan a un toque, en vez de estar siempre debajo del cuadro.
///
/// Los partidos de la fase final no modifican esa tabla: no tienen
/// grupo y el cálculo los ignora.
class _ContenidoEliminatoria extends StatefulWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _ContenidoEliminatoria({required this.datos, required this.campeonato});

  @override
  State<_ContenidoEliminatoria> createState() => _ContenidoEliminatoriaState();
}

class _ContenidoEliminatoriaState extends State<_ContenidoEliminatoria> {
  _SeccionPublica _seccion = _SeccionPublica.llaves;
  _VistaTabla _vistaTabla = _VistaTabla.general;

  CampeonatoModel get campeonato => widget.campeonato;
  DatosCampeonato get datos => widget.datos;

  void _ir(_SeccionPublica seccion, {_VistaTabla? vistaTabla}) {
    setState(() {
      _seccion = seccion;
      if (vistaTabla != null) _vistaTabla = vistaTabla;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _MenuSecciones(
              campeonato: campeonato,
              seccionActual: _seccion,
              vistaTabla: _vistaTabla,
              // El resumen ya está en la pantalla de llaves, debajo del
              // cuadro: en escritorio sería la misma información dos
              // veces.
              conResumen: false,
              onSelect: _ir,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: switch (_seccion) {
            _SeccionPublica.tabla => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TableSection(
                  // La key hace que cambiar entre "general" y "por
                  // grupos" desde la barra se aplique aunque la sección
                  // ya estuviera abierta.
                  key: ValueKey(_vistaTabla),
                  datos: datos,
                  campeonato: campeonato,
                  vistaInicial: _vistaTabla,
                ),
                if (campeonato.esFutbol) ...[
                  const SizedBox(height: 24),
                  _ScorersSection(datos: datos, campeonato: campeonato),
                ],
              ],
            ),
            _SeccionPublica.clasificados => AppClasificadosEnVivo(
              campeonato: campeonato,
              tabla: () => datos.tabla,
              colapsable: false,
            ),
            _SeccionPublica.llaves || _SeccionPublica.resumen =>
              _PrincipalEliminatoria(datos: datos, campeonato: campeonato),
          },
        ),
      ],
    );
  }
}

/// Qué sección del campeonato se está mirando. En móvil se elige desde
/// el sidebar ([_MobileDrawer]); en escritorio, durante la eliminatoria,
/// desde la barra lateral de [_ContenidoEliminatoria].
///
/// En móvil, "Resumen" (próximos
/// partidos + últimos resultados) es lo que se ve al entrar mientras se
/// juegan los grupos; el resto se abre desde el sidebar
/// ([_MobileDrawer]) en vez de pestañas arriba, para no gastar espacio
/// vertical en pantallas chicas.
///
/// "Llaves" aparece recién cuando el campeonato tiene fase eliminatoria,
/// y pasa a ser la sección con la que se abre la pantalla.
enum _SeccionPublica { resumen, llaves, tabla, clasificados }

/// Versión móvil: encabezado compacto y un sidebar para moverse entre
/// secciones.
///
/// Es la misma pantalla durante todo el campeonato. Al activarse la fase
/// eliminatoria no cambia la navegación: solo se suma "Llaves" al menú y
/// la pantalla abre ahí, que es lo que el usuario viene a mirar. Antes,
/// en cambio, la eliminatoria reemplazaba toda la vista y el sidebar
/// desaparecía, así que de un día para el otro se navegaba distinto.
class _MobileChampionshipView extends StatefulWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _MobileChampionshipView({
    required this.datos,
    required this.campeonato,
  });

  @override
  State<_MobileChampionshipView> createState() =>
      _MobileChampionshipViewState();
}

class _MobileChampionshipViewState extends State<_MobileChampionshipView> {
  late _SeccionPublica _seccion = widget.campeonato.estaEnFaseEliminatoria
      ? _SeccionPublica.llaves
      : _SeccionPublica.resumen;

  _VistaTabla _vistaTablaInicial = _VistaTabla.general;

  CampeonatoModel get campeonato => widget.campeonato;
  DatosCampeonato get datos => widget.datos;

  void _ir(_SeccionPublica seccion, {_VistaTabla? vistaTabla}) {
    setState(() {
      _seccion = seccion;
      if (vistaTabla != null) _vistaTablaInicial = vistaTabla;
    });
  }

  String _tituloSeccion() {
    switch (_seccion) {
      case _SeccionPublica.resumen:
        return campeonato.nombre;
      case _SeccionPublica.llaves:
        return 'Llaves eliminatorias';
      case _SeccionPublica.tabla:
        return 'Tabla de posiciones';
      case _SeccionPublica.clasificados:
        return 'Clasificados';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoTexto = Etiquetas.estadoCampeonato(campeonato.estado);

    return Scaffold(
      backgroundColor: Colors.transparent,
      endDrawer: _MobileDrawer(
        campeonato: campeonato,
        seccionActual: _seccion,
        vistaTabla: _vistaTablaInicial,
        onSelect: _ir,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Volver',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  const AppLogoMark(compact: true),
                  const Spacer(),
                  // El menú va a la derecha (el sidebar se abre como
                  // endDrawer, desde ese borde).
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Más secciones',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _tituloSeccion(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppBadge(
                    text: estadoTexto,
                    type: AppBadge.tipoEstadoCampeonato(campeonato.estado),
                    icon: deporteIcono(campeonato.deporteEfectivo),
                  ),
                  if (campeonato.tieneFasesSeparadas)
                    AppFaseBadge(campeonato: campeonato),
                ],
              ),
              const SizedBox(height: 10),
              // Los chips de partidos/goles son de la fase de grupos: en
              // eliminatoria la llave ya cuenta esa historia mejor.
              if (!campeonato.estaEnFaseEliminatoria) ...[
                _MobileTopStats(datos: datos, campeonato: campeonato),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 8),
              switch (_seccion) {
                _SeccionPublica.resumen => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NextMatchesSection(
                      datos: datos,
                      deporte: campeonato.deporteEfectivo,
                    ),
                    const SizedBox(height: 16),
                    _LastResultsSection(
                      datos: datos,
                      deporte: campeonato.deporteEfectivo,
                    ),
                  ],
                ),
                // El cuadro primero, que es lo que se viene a mirar, y
                // debajo el fixture con los resultados. La tabla y los
                // clasificados se abren desde el menú.
                _SeccionPublica.llaves => _PrincipalEliminatoria(
                  datos: datos,
                  campeonato: campeonato,
                  conEncabezado: false,
                ),
                _SeccionPublica.tabla => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TableSection(
                      key: ValueKey(_vistaTablaInicial),
                      datos: datos,
                      campeonato: campeonato,
                      vistaInicial: _vistaTablaInicial,
                    ),
                    if (campeonato.esFutbol) ...[
                      const SizedBox(height: 20),
                      _ScorersSection(datos: datos, campeonato: campeonato),
                    ],
                  ],
                ),
                _SeccionPublica.clasificados => AppClasificadosEnVivo(
                  campeonato: campeonato,
                  tabla: () => datos.tabla,
                  colapsable: false,
                ),
              },
              // El footer va fuera del padding lateral para que la
              // franja de auspiciadores ocupe todo el ancho.
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: AppPublicFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de chips chicos con ícono (equipos, partidos, goles/finalizados)
/// en vez de las `StatCard` grandes de escritorio: en móvil esa info es
/// secundaria al fixture/resultados, así que ocupa una sola línea.
class _MobileTopStats extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  const _MobileTopStats({required this.datos, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StreamBuilder<List<EquipoModel>>(
          stream: datos.equipos,
          builder: (context, snapshot) {
            return _MiniStatChip(
              icon: Icons.groups_2_outlined,
              value: '${snapshot.data?.length ?? 0}',
              label: 'equipos',
              color: AppColors.primary,
            );
          },
        ),
        StreamBuilder<List<PartidoModel>>(
          stream: datos.partidos,
          builder: (context, snapshot) {
            return _MiniStatChip(
              icon: Icons.sports_soccer,
              value: '${(snapshot.data ?? []).length}',
              label: 'partidos',
              color: AppColors.secondary,
            );
          },
        ),
        if (campeonato.esFutbol)
          StreamBuilder<List<PartidoModel>>(
            stream: datos.partidos,
            builder: (context, snapshot) {
              final totalGoles = (snapshot.data ?? [])
                  .where((p) => p.resultadoRegistrado)
                  .fold<int>(
                    0,
                    (total, p) =>
                        total + (p.golesLocal ?? 0) + (p.golesVisitante ?? 0),
                  );

              return _MiniStatChip(
                icon: Icons.emoji_events_outlined,
                value: '$totalGoles',
                label: 'goles',
                color: AppColors.info,
              );
            },
          )
        else
          StreamBuilder<List<PartidoModel>>(
            stream: datos.partidos,
            builder: (context, snapshot) {
              final finalizados = (snapshot.data ?? [])
                  .where((p) => p.resultadoRegistrado)
                  .length;

              return _MiniStatChip(
                icon: Icons.emoji_events_outlined,
                value: '$finalizados',
                label: 'finalizados',
                color: AppColors.info,
              );
            },
          ),
      ],
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar de navegación en móvil: fixture/llaves, tabla (general y por
/// grupos como accesos directos) y clasificados a la fase final, para no
/// competir con el título por el ancho de pantalla como hacían las
/// pestañas de antes.
class _MobileDrawer extends StatelessWidget {
  final CampeonatoModel campeonato;
  final _SeccionPublica seccionActual;
  final _VistaTabla vistaTabla;
  final void Function(_SeccionPublica seccion, {_VistaTabla? vistaTabla})
  onSelect;

  const _MobileDrawer({
    required this.campeonato,
    required this.seccionActual,
    required this.vistaTabla,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  const AppLogoMark(compact: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      campeonato.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _MenuSecciones(
              campeonato: campeonato,
              seccionActual: seccionActual,
              vistaTabla: vistaTabla,
              onSelect: (seccion, {vistaTabla}) {
                Navigator.pop(context);
                onSelect(seccion, vistaTabla: vistaTabla);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Las opciones del menú de secciones. Es una sola lista para el drawer
/// del celular y la barra lateral de escritorio: así las dos ofrecen
/// siempre lo mismo.
class _MenuSecciones extends StatelessWidget {
  final CampeonatoModel campeonato;
  final _SeccionPublica seccionActual;
  final _VistaTabla vistaTabla;
  final bool conResumen;
  final void Function(_SeccionPublica seccion, {_VistaTabla? vistaTabla})
  onSelect;

  const _MenuSecciones({
    required this.campeonato,
    required this.seccionActual,
    required this.vistaTabla,
    required this.onSelect,
    this.conResumen = true,
  });

  bool _tablaElegida(_VistaTabla vista) =>
      seccionActual == _SeccionPublica.tabla && vistaTabla == vista;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (campeonato.muestraLlave)
          _DrawerItem(
            icon: Icons.account_tree_outlined,
            label: 'Llaves eliminatorias',
            selected: seccionActual == _SeccionPublica.llaves,
            onTap: () => onSelect(_SeccionPublica.llaves),
          ),
        if (conResumen)
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Resumen',
            selected: seccionActual == _SeccionPublica.resumen,
            onTap: () => onSelect(_SeccionPublica.resumen),
          ),
        _DrawerItem(
          icon: Icons.leaderboard_outlined,
          label: 'Tabla de posiciones',
          selected: _tablaElegida(_VistaTabla.general),
          onTap: () =>
              onSelect(_SeccionPublica.tabla, vistaTabla: _VistaTabla.general),
        ),
        if (campeonato.usaGrupos)
          _DrawerItem(
            icon: Icons.grid_view_rounded,
            label: 'Tabla por grupos',
            selected: _tablaElegida(_VistaTabla.porGrupos),
            onTap: () => onSelect(
              _SeccionPublica.tabla,
              vistaTabla: _VistaTabla.porGrupos,
            ),
          ),
        if (campeonato.tieneFasesSeparadas)
          _DrawerItem(
            icon: Icons.emoji_events_outlined,
            label: 'Clasificados a la fase final',
            selected: seccionActual == _SeccionPublica.clasificados,
            onTap: () => onSelect(_SeccionPublica.clasificados),
          ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;
  final String estadoTexto;

  const _StatsSection({
    required this.datos,
    required this.campeonato,
    required this.estadoTexto,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      StreamBuilder(
        stream: datos.equipos,
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
        stream: datos.partidos,
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          return StatCard(
            title: 'Partidos',
            value: '${partidos.length}',
            icon: Icons.sports_soccer,
            subtitle: Etiquetas.tipoCampeonato(campeonato.tipoCampeonato),
            color: AppColors.secondary,
          );
        },
      ),
      // Para fútbol se muestran los goles registrados; para vóley y
      // básquet se muestran los partidos finalizados.
      //
      // El total sale de los partidos (golesLocal + golesVisitante), no
      // del ranking de goleadores: los resultados administrativos
      // (walkover/sanción) suman goles al marcador del partido pero no
      // generan goles por jugador, así que sumar solo el ranking
      // subcontaba el total real del campeonato.
      if (campeonato.esFutbol)
        StreamBuilder<List<PartidoModel>>(
          stream: datos.partidos,
          builder: (context, snapshot) {
            final partidos = snapshot.data ?? [];
            final totalGoles = partidos
                .where((p) => p.resultadoRegistrado)
                .fold<int>(
                  0,
                  (total, p) =>
                      total + (p.golesLocal ?? 0) + (p.golesVisitante ?? 0),
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
          stream: datos.partidos,
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
  final DatosCampeonato datos;
  final String deporte;

  const _NextMatchesSection({required this.datos, required this.deporte});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: datos.proximos,
        builder: (context, snapshot) {
          final partidos = snapshot.data ?? [];

          // Los de esta semana van primero, que son los que importan;
          // los de la semana que viene quedan debajo, en su propio bloque.
          final corte = PublicHomeService.rangoProximos(
            DateTime.now(),
          ).corteSemana;
          final estaSemana = partidos
              .where((p) => p.fechaHora != null && p.fechaHora!.isBefore(corte))
              .toList();
          final proximaSemana = partidos
              .where((p) => !estaSemana.contains(p))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Próximos partidos',
                subtitle: 'Programación de esta semana y la siguiente.',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MatchSkeletonColumn()
              else if (partidos.isEmpty)
                const AppInlineEmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'No hay partidos programados para estas dos semanas.',
                )
              else ...[
                _BloqueSemana(
                  titulo: 'ESTA SEMANA',
                  partidos: estaSemana,
                  deporte: deporte,
                  vacio: 'No quedan partidos esta semana.',
                ),
                if (proximaSemana.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BloqueSemana(
                    titulo: 'SEMANA QUE VIENE',
                    partidos: proximaSemana,
                    deporte: deporte,
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Un bloque de "Próximos partidos" ("Esta semana" o "Semana que
/// viene"): una etiqueta chica con la cantidad y los partidos debajo.
class _BloqueSemana extends StatelessWidget {
  final String titulo;
  final List<PartidoModel> partidos;
  final String deporte;

  /// Texto cuando el bloque no tiene partidos. Sin él, un bloque vacío
  /// no se dibuja.
  final String? vacio;

  const _BloqueSemana({
    required this.titulo,
    required this.partidos,
    required this.deporte,
    this.vacio,
  });

  @override
  Widget build(BuildContext context) {
    if (partidos.isEmpty && vacio == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (partidos.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${partidos.length}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (partidos.isEmpty)
          Text(
            vacio!,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          )
        else
          ...List.generate(partidos.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < partidos.length - 1 ? 10 : 0,
              ),
              child: AppMatchCard(partido: partidos[index], deporte: deporte),
            );
          }),
      ],
    );
  }
}

class _LastResultsSection extends StatelessWidget {
  final DatosCampeonato datos;
  final String deporte;

  const _LastResultsSection({required this.datos, required this.deporte});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: StreamBuilder<List<PartidoModel>>(
        stream: datos.ultimosResultados,
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
  final DatosCampeonato datos;
  final CampeonatoModel campeonato;

  /// En móvil la sección ya viene titulada por la pantalla (el nombre
  /// de la sección del sidebar), así que el encabezado propio sobra y
  /// solo repetiría el mismo texto dos veces seguidas.
  final bool conEncabezado;

  const _FixtureSection({
    required this.datos,
    required this.campeonato,
    this.conEncabezado = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartidoModel>>(
      stream: datos.partidos,
      builder: (context, snapshot) {
        final partidos = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conEncabezado) ...[
                  const AppSectionHeader(
                    title: 'Llaves eliminatorias',
                    subtitle: 'De la ronda inicial hasta la gran final.',
                  ),
                  const SizedBox(height: 16),
                ],
                const _MatchSkeletonColumn(),
              ],
            ),
          );
        }

        // El listado plano "fixture por grupo" ya no se muestra acá: la
        // tabla de posiciones y los clasificados cubren esa información
        // de forma más útil. Esta sección queda solo para la llave
        // visual de la fase eliminatoria.
        // Los partidos con privilegio también van sin grupo, pero no son
        // parte de la fase final: se filtran aparte.
        final deFaseFinal = partidos.where(campeonato.esDeFaseFinal).toList();

        final rondasLlave = FixtureGrouping.rondasEliminatorias(deFaseFinal);

        // Cruces de fase final que todavía no entran en ningún cuadro.
        // No son una ronda, pero se juegan igual, así que el público los
        // tiene que ver con su fecha y su resultado.
        final sueltos = FixtureGrouping.crucesSueltos(deFaseFinal);

        if (rondasLlave.isEmpty && sueltos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conEncabezado) ...[
                const AppSectionHeader(
                  title: 'Llaves eliminatorias',
                  subtitle: 'De la ronda inicial hasta la gran final.',
                ),
                const SizedBox(height: 16),
              ],
              const AppInlineEmptyState(
                icon: Icons.account_tree_outlined,
                text: 'Todavía no hay partidos de fase final.',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conEncabezado) ...[
              const AppSectionHeader(
                title: 'Llaves eliminatorias',
                subtitle: 'De la ronda inicial hasta la gran final.',
              ),
              const SizedBox(height: 16),
            ],
            if (rondasLlave.isNotEmpty)
              AppBracketView(
                rondas: rondasLlave,
                deporte: campeonato.deporteEfectivo,
              ),
            if (sueltos.isNotEmpty) ...[
              if (rondasLlave.isNotEmpty) const SizedBox(height: 24),
              _PartidosFaseFinalSection(
                partidos: sueltos,
                deporte: campeonato.deporteEfectivo,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Partidos de fase final que todavía no forman parte del cuadro.
///
/// Pasa en los formatos que no se pueden generar solos (12 clasificados
/// con repechaje, por ejemplo): esas primeras rondas las carga el admin
/// a mano y no son una ronda del cuadro hasta que lo arme. Igual se
/// juegan, así que se muestran acá con su fecha y su resultado.
class _PartidosFaseFinalSection extends StatelessWidget {
  final List<PartidoModel> partidos;
  final String deporte;

  const _PartidosFaseFinalSection({
    required this.partidos,
    required this.deporte,
  });

  @override
  Widget build(BuildContext context) {
    final ordenados = [...partidos]
      ..sort((a, b) {
        // Primero los que tienen fecha, en orden; los que todavía no se
        // programaron quedan al final.
        final fechaA = a.fechaHora;
        final fechaB = b.fechaHora;
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaA.compareTo(fechaB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Partidos de fase final',
          subtitle: 'Fixture y resultados de los cruces de fase final.',
        ),
        const SizedBox(height: 16),
        ...ordenados.map(
          (partido) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppMatchCard(
              partido: partido,
              deporte: deporte,
              // Sin esto la tarjeta mostraba solo la fecha, como si el
              // cruce todavía no se hubiera jugado.
              showResult: partido.resultadoRegistrado,
            ),
          ),
        ),
      ],
    );
  }
}

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
