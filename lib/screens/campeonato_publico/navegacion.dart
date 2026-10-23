part of '../championship_detail_screen.dart';

// Vista móvil y menú de secciones (drawer del celular y barra lateral).

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
