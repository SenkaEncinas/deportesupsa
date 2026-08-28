import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/grupo_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/grupo_service.dart';
import '../services/partido_service.dart';
import '../services/pdf_service.dart';
import '../utils/fixture_grouping.dart';
import 'grupos_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

/// Filtros disponibles para la lista de partidos del fixture.
enum _FixtureFiltro { todos, sinProgramar, programados, manuales, automaticos }

class FixtureScreen extends StatefulWidget {
  final String campeonatoId;

  const FixtureScreen({super.key, required this.campeonatoId});

  @override
  State<FixtureScreen> createState() => _FixtureScreenState();
}

class _FixtureScreenState extends State<FixtureScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final EquipoService _equipoService = EquipoService();
  final GrupoService _grupoService = GrupoService();
  final PartidoService _partidoService = PartidoService();
  final PdfService _pdfService = PdfService();

  bool _loading = false;
  _FixtureFiltro _filtro = _FixtureFiltro.todos;

  Future<void> _generarFixture(CampeonatoModel campeonato) async {
    setState(() {
      _loading = true;
    });

    try {
      await _partidoService.generarFixtureSegunFormato(campeonato: campeonato);

      if (!mounted) return;
      AppSnackbars.success(
        context,
        'Fixture generado respetando el formato "${_tipoTexto(campeonato.tipoCampeonato)}".',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _crearCruceManual(CampeonatoModel? campeonato) async {
    setState(() {
      _loading = true;
    });

    try {
      final equipos = await _equipoService.getEquipos(widget.campeonatoId);
      final activos = equipos
          .where((equipo) => equipo.estado == EquipoEstado.activo)
          .toList();

      if (!mounted) return;

      if (activos.length < 2) {
        AppSnackbars.error(
          context,
          'Debe existir al menos 2 equipos activos para crear un cruce.',
        );
        return;
      }

      // Mientras el campeonato deba restringir los cruces al mismo
      // grupo (fase de grupos pura, o grupos+eliminación sin activar la
      // fase eliminatoria), el diálogo necesita saber a qué grupo
      // pertenece cada equipo para no dejar armar cruces entre grupos.
      final restringirAGrupo =
          campeonato?.debeRestringirCrucesAlGrupo ?? false;

      final grupos = restringirAGrupo
          ? await _grupoService.getGrupos(widget.campeonatoId)
          : <GrupoModel>[];

      if (!mounted) return;

      final result = await showDialog<_CruceManualResult>(
        context: context,
        builder: (_) => _CruceManualDialog(
          equipos: activos,
          grupos: grupos,
          restringirAGrupo: restringirAGrupo,
          // En grupos+eliminación el grupoId de los cruces de fase final
          // debe quedar vacío para que la vista pública los muestre como
          // llave visual en vez de una sección de grupo más: no tiene
          // sentido dejar que el admin lo pise a mano con texto libre.
          ocultarCampoGrupoLibre: campeonato?.tieneFasesSeparadas ?? false,
        ),
      );

      if (result == null) return;

      await _partidoService.crearCruceManual(
        campeonatoId: widget.campeonatoId,
        equipoLocal: result.local,
        equipoVisitante: result.visitante,
        jornada: result.jornada,
        idaYVuelta: result.idaYVuelta,
        grupoId: result.grupoId,
      );

      if (!mounted) return;

      AppSnackbars.success(
        context,
        result.idaYVuelta
            ? 'Cruce manual creado con ida y vuelta.'
            : 'Partido único creado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _activarFaseEliminatoria(CampeonatoModel campeonato) async {
    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Activar fase eliminatoria',
      message:
          'A partir de ahora "Agregar cruce manual" va a dejar de limitarse a equipos del mismo grupo, para que puedas armar las llaves (octavos, cuartos...) con los equipos que clasificaron. Esta acción no se puede deshacer.',
      confirmText: 'Activar',
      danger: true,
    );

    if (!confirm) return;

    setState(() {
      _loading = true;
    });

    try {
      await _campeonatoService.activarFaseEliminatoria(campeonato);

      if (!mounted) return;
      AppSnackbars.success(
        context,
        'Fase eliminatoria activada: ya puedes cruzar equipos de distintos grupos.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _programarPartido(PartidoModel partido) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime(2035),
      initialDate: partido.fechaHora ?? DateTime.now(),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: partido.fechaHora == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(partido.fechaHora!),
    );

    if (time == null) return;

    final fechaHora = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await _partidoService.programarPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: partido.id,
        fechaHora: fechaHora,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Partido programado correctamente.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> _descargarFixture(
    CampeonatoModel campeonato,
    List<PartidoModel> partidos,
  ) async {
    final bytes = await _pdfService.generarFixturePdf(
      campeonato: campeonato,
      partidos: partidos,
    );

    await Printing.layoutPdf(
      name: 'fixture_${campeonato.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  List<PartidoModel> _aplicarFiltro(List<PartidoModel> partidos) {
    switch (_filtro) {
      case _FixtureFiltro.sinProgramar:
        return partidos.where((p) => p.fechaHora == null).toList();
      case _FixtureFiltro.programados:
        return partidos.where((p) => p.fechaHora != null).toList();
      case _FixtureFiltro.manuales:
        return partidos.where((p) => !p.generadoPorSistema).toList();
      case _FixtureFiltro.automaticos:
        return partidos.where((p) => p.generadoPorSistema).toList();
      case _FixtureFiltro.todos:
        return partidos;
    }
  }

  /// Agrupa los partidos para mostrarlos por secciones: primero por grupo
  /// (si existe), luego por vuelta o por ronda eliminatoria. Comparte la
  /// lógica con la vista pública a través de [FixtureGrouping].
  Map<String, List<PartidoModel>> _agruparPartidos(
    List<PartidoModel> partidos,
    List<PartidoModel> todos,
    CampeonatoModel? campeonato,
  ) {
    return FixtureGrouping.agrupar(
      partidos: partidos,
      todos: todos,
      tipoCampeonato: campeonato?.tipoCampeonato,
    );
  }

  bool _esFormatoDosFases(CampeonatoModel campeonato) {
    return campeonato.tipoCampeonato == TipoCampeonato.ligaFinal ||
        campeonato.tipoCampeonato == TipoCampeonato.ligaPlayoffs ||
        campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion;
  }

  bool _usaGrupos(CampeonatoModel campeonato) {
    return campeonato.tipoCampeonato == TipoCampeonato.faseGrupos ||
        campeonato.tipoCampeonato == TipoCampeonato.gruposEliminacion;
  }

  String _mensajeDosFases(CampeonatoModel campeonato) {
    switch (campeonato.tipoCampeonato) {
      case TipoCampeonato.ligaFinal:
        return 'Liga + final: cuando termine la liga y la tabla esté completa, crea la final con "Agregar cruce manual" usando a los mejores clasificados. La generación automática de la final queda preparada para una siguiente fase.';
      case TipoCampeonato.ligaPlayoffs:
        return 'Liga + playoffs: al terminar la fase de liga, crea las llaves de playoffs con "Agregar cruce manual" según la tabla final (${campeonato.configuracion.clasificadosPlayoffs} clasificados).';
      case TipoCampeonato.gruposEliminacion:
        return campeonato.estaEnFaseDeGrupos
            ? 'Fase de grupos en curso: "Agregar cruce manual" solo deja cruzar equipos del mismo grupo. Cuando termine la fase de grupos, usa "Activar fase eliminatoria" y arma las llaves con los ${campeonato.configuracion.clasificanPorGrupo} mejores de cada grupo (y los mejores terceros, si aplica).'
            : 'Fase eliminatoria activada: ya puedes cruzar equipos de cualquier grupo con "Agregar cruce manual" para armar octavos, cuartos, semifinal y final.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidoService.streamPartidos(widget.campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando fixture...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar fixture',
                  message: snapshot.error.toString(),
                );
              }

              final partidos = snapshot.data ?? [];
              final filtrados = _aplicarFiltro(partidos);
              final secciones = _agruparPartidos(
                filtrados,
                partidos,
                campeonato,
              );

              final puedeEditarFixture =
                  campeonato != null &&
                  campeonato.estado != CampeonatoEstado.finalizado;

              final programados = partidos
                  .where((p) => p.fechaHora != null)
                  .length;
              final pendientes = partidos
                  .where((p) => p.fechaHora == null)
                  .length;
              final manuales = partidos
                  .where((p) => !p.generadoPorSistema)
                  .length;

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Fixture',
                  subtitle: campeonato == null
                      ? 'Cruces y programación de partidos.'
                      : campeonato.tieneFasesSeparadas
                      ? '${campeonato.nombre} · ${_tipoTexto(campeonato.tipoCampeonato)} · ${campeonato.estaEnFaseDeGrupos ? 'Fase de grupos' : 'Fase eliminatoria'}'
                      : '${campeonato.nombre} · ${_tipoTexto(campeonato.tipoCampeonato)}',
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (campeonato != null &&
                        _usaGrupos(campeonato) &&
                        partidos.isEmpty)
                      AppButton.secondary(
                        text: 'Grupos',
                        icon: Icons.grid_view_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GruposScreen(campeonatoId: widget.campeonatoId),
                            ),
                          );
                        },
                      ),
                    if (puedeEditarFixture &&
                        partidos.isEmpty &&
                        campeonato.configuracion.generaCrucesAleatorios)
                      AppButton.primary(
                        text: 'Generar fixture',
                        icon: Icons.shuffle,
                        loading: _loading,
                        onPressed: () => _generarFixture(campeonato),
                      ),
                    if (puedeEditarFixture &&
                        campeonato.tieneFasesSeparadas &&
                        campeonato.estaEnFaseDeGrupos)
                      AppButton.secondary(
                        text: 'Activar fase eliminatoria',
                        icon: Icons.bolt_outlined,
                        loading: _loading,
                        onPressed: () => _activarFaseEliminatoria(campeonato),
                      ),
                    if (puedeEditarFixture)
                      AppButton.secondary(
                        text: 'Agregar cruce manual',
                        icon: Icons.add,
                        loading: _loading,
                        onPressed: () => _crearCruceManual(campeonato),
                      ),
                    if (partidos.isNotEmpty && campeonato != null)
                      AppButton.secondary(
                        text: 'Descargar PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () =>
                            _descargarFixture(campeonato, partidos),
                      ),
                  ],
                  child: partidos.isEmpty
                      ? Column(
                          children: [
                            AppEmptyState(
                              icon: Icons.calendar_month_outlined,
                              title: 'No hay fixture generado',
                              message: campeonato == null
                                  ? 'Puedes generar el fixture completo o agregar cruces manuales uno por uno.'
                                  : _usaGrupos(campeonato)
                                  ? 'Antes de generar el fixture, revisa "Grupos" para inscribir a cada equipo en su grupo. Si no lo haces, se repartirán automáticamente.'
                                  : 'El botón "Generar fixture" creará los cruces según el formato "${_tipoTexto(campeonato.tipoCampeonato)}". También puedes agregar cruces manuales uno por uno.',
                              buttonText: puedeEditarFixture
                                  ? 'Agregar cruce manual'
                                  : null,
                              onPressed: puedeEditarFixture
                                  ? () => _crearCruceManual(campeonato)
                                  : null,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppResponsiveGrid(
                              mobileColumns: 2,
                              tabletColumns: 2,
                              desktopColumns: 4,
                              spacing: 12,
                              children: [
                                StatCard(
                                  title: 'Partidos',
                                  value: '${partidos.length}',
                                  icon: Icons.sports_outlined,
                                  subtitle: 'Totales',
                                  color: AppColors.primary,
                                ),
                                StatCard(
                                  title: 'Programados',
                                  value: '$programados',
                                  icon: Icons.event_available_outlined,
                                  subtitle: 'Con fecha y hora',
                                  color: AppColors.success,
                                ),
                                StatCard(
                                  title: 'Pendientes',
                                  value: '$pendientes',
                                  icon: Icons.pending_actions_outlined,
                                  subtitle: 'Sin programar',
                                  color: AppColors.secondary,
                                ),
                                StatCard(
                                  title: 'Manuales',
                                  value: '$manuales',
                                  icon: Icons.pan_tool_alt_outlined,
                                  subtitle: 'Cruces manuales',
                                  color: AppColors.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppFilterPill(
                                  text: 'Todos',
                                  count: partidos.length,
                                  selected: _filtro == _FixtureFiltro.todos,
                                  onTap: () => setState(() {
                                    _filtro = _FixtureFiltro.todos;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Sin programar',
                                  count: pendientes,
                                  selected:
                                      _filtro == _FixtureFiltro.sinProgramar,
                                  onTap: () => setState(() {
                                    _filtro = _FixtureFiltro.sinProgramar;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Programados',
                                  count: programados,
                                  selected:
                                      _filtro == _FixtureFiltro.programados,
                                  onTap: () => setState(() {
                                    _filtro = _FixtureFiltro.programados;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Manuales',
                                  count: manuales,
                                  selected: _filtro == _FixtureFiltro.manuales,
                                  onTap: () => setState(() {
                                    _filtro = _FixtureFiltro.manuales;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Automáticos',
                                  count: partidos.length - manuales,
                                  selected:
                                      _filtro == _FixtureFiltro.automaticos,
                                  onTap: () => setState(() {
                                    _filtro = _FixtureFiltro.automaticos;
                                  }),
                                ),
                              ],
                            ),
                            if (campeonato != null &&
                                _esFormatoDosFases(campeonato)) ...[
                              const SizedBox(height: 16),
                              _InfoBox(text: _mensajeDosFases(campeonato)),
                            ],
                            const SizedBox(height: 20),
                            if (filtrados.isEmpty)
                              const AppEmptyState(
                                icon: Icons.filter_alt_off_outlined,
                                title: 'Sin partidos para este filtro',
                                message:
                                    'Prueba con otro filtro para ver los partidos del fixture.',
                              )
                            else
                              ...secciones.entries.map((entry) {
                                return _SeccionFixture(
                                  titulo: entry.key,
                                  partidos: entry.value,
                                  puedeEditar: puedeEditarFixture,
                                  deporte: campeonato?.deporteEfectivo ??
                                      DeporteTipo.futbol,
                                  onProgramar: _programarPartido,
                                );
                              }),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SeccionFixture extends StatelessWidget {
  final String titulo;
  final List<PartidoModel> partidos;
  final bool puedeEditar;
  final String deporte;
  final void Function(PartidoModel) onProgramar;

  const _SeccionFixture({
    required this.titulo,
    required this.partidos,
    required this.puedeEditar,
    required this.deporte,
    required this.onProgramar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: AppTextStyles.heading3)),
              AppBadge(
                text: '${partidos.length} partidos',
                type: AppBadgeType.neutral,
              ),
            ],
          ),
        ),
        ...partidos.map((partido) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FixturePartidoCard(
              partido: partido,
              puedeEditar: puedeEditar,
              deporte: deporte,
              onProgramar: () => onProgramar(partido),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _FixturePartidoCard extends StatelessWidget {
  final PartidoModel partido;
  final bool puedeEditar;
  final String deporte;
  final VoidCallback onProgramar;

  const _FixturePartidoCard({
    required this.partido,
    required this.puedeEditar,
    required this.deporte,
    required this.onProgramar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppBadge(
          text: _estadoTexto(partido.estado),
          type: AppBadge.typeFromEstado(partido.estado),
        ),
        AppBadge(
          text: partido.generadoPorSistema ? 'Aleatorio' : 'Manual',
          type: partido.generadoPorSistema
              ? AppBadgeType.info
              : AppBadgeType.primary,
        ),
        AppBadge(
          text: 'J${partido.jornada} · V${partido.vuelta}',
          type: AppBadgeType.neutral,
        ),
      ],
    );

    final boton = AppButton.secondary(
      text: partido.fechaHora == null ? 'Programar' : 'Reprogramar',
      icon: Icons.edit_calendar_outlined,
      onPressed: puedeEditar ? onProgramar : null,
    );

    if (isMobile) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badges,
            const SizedBox(height: 12),
            AppMatchCard(partido: partido, deporte: deporte),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: boton),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badges,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppMatchCard(partido: partido, deporte: deporte),
              ),
              const SizedBox(width: 14),
              boton,
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CruceManualDialog extends StatefulWidget {
  final List<EquipoModel> equipos;
  final List<GrupoModel> grupos;
  final bool restringirAGrupo;
  final bool ocultarCampoGrupoLibre;

  const _CruceManualDialog({
    required this.equipos,
    this.grupos = const [],
    this.restringirAGrupo = false,
    this.ocultarCampoGrupoLibre = false,
  });

  @override
  State<_CruceManualDialog> createState() => _CruceManualDialogState();
}

class _CruceManualDialogState extends State<_CruceManualDialog> {
  EquipoModel? _local;
  EquipoModel? _visitante;
  bool _idaYVuelta = false;

  final TextEditingController _jornadaController = TextEditingController(
    text: '1',
  );
  final TextEditingController _grupoController = TextEditingController();

  @override
  void dispose() {
    _jornadaController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  String? _grupoDe(EquipoModel? equipo) {
    if (equipo == null) return null;

    for (final grupo in widget.grupos) {
      if (grupo.equipoIds.contains(equipo.id)) return grupo.nombre;
    }

    return null;
  }

  void _guardar() {
    final jornada = int.tryParse(_jornadaController.text.trim()) ?? 0;

    if (_local == null || _visitante == null) return;
    if (_local!.id == _visitante!.id) return;
    if (jornada <= 0) return;

    Navigator.pop(
      context,
      _CruceManualResult(
        local: _local!,
        visitante: _visitante!,
        jornada: jornada,
        idaYVuelta: _idaYVuelta,
        // En fase de grupos el servicio ignora este valor y lo calcula
        // solo a partir de la inscripción real, así que acá solo importa
        // para la fase eliminatoria (texto libre, ej. "Semifinal").
        grupoId: _grupoController.text.trim().isEmpty
            ? null
            : _grupoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupoLocal = widget.restringirAGrupo ? _grupoDe(_local) : null;

    final visitantes = widget.equipos.where((equipo) {
      if (equipo.id == _local?.id) return false;
      if (widget.restringirAGrupo && grupoLocal != null) {
        return _grupoDe(equipo) == grupoLocal;
      }
      return true;
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Agregar cruce manual', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.restringirAGrupo) ...[
                _InfoBox(
                  text:
                      'Todavía es fase de grupos: solo puedes cruzar equipos del mismo grupo. Activa la fase eliminatoria para armar cruces entre grupos distintos.',
                ),
                const SizedBox(height: 14),
              ],
              _EquipoDropdown(
                label: 'Equipo local',
                value: _local,
                equipos: widget.equipos,
                onChanged: (value) {
                  setState(() {
                    _local = value;

                    if (_visitante?.id == value?.id) {
                      _visitante = null;
                    }

                    if (widget.restringirAGrupo &&
                        _grupoDe(_visitante) != _grupoDe(value)) {
                      _visitante = null;
                    }
                  });
                },
              ),
              if (widget.restringirAGrupo && _local != null) ...[
                const SizedBox(height: 8),
                Text(
                  grupoLocal == null
                      ? '${_local!.nombre} todavía no está inscrito en ningún grupo. Complétalo en "Grupos" primero.'
                      : 'Grupo de ${_local!.nombre}: $grupoLocal',
                  style: AppTextStyles.small.copyWith(
                    color: grupoLocal == null
                        ? AppColors.danger
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _EquipoDropdown(
                label: 'Equipo visitante',
                value: _visitante,
                equipos: visitantes,
                onChanged: (value) {
                  setState(() {
                    _visitante = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _jornadaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jornada / fase',
                  hintText: 'Ejemplo: 1, 2, 3...',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 14),
              if (!widget.restringirAGrupo &&
                  !widget.ocultarCampoGrupoLibre) ...[
                TextField(
                  controller: _grupoController,
                  decoration: const InputDecoration(
                    labelText: 'Grupo o fase (opcional)',
                    hintText: 'Ejemplo: Octavos, Semifinal, Final...',
                    prefixIcon: Icon(Icons.grid_view_rounded),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SwitchListTile(
                value: _idaYVuelta,
                onChanged: (value) {
                  setState(() {
                    _idaYVuelta = value;
                  });
                },
                title: const Text('Crear ida y vuelta'),
                subtitle: const Text(
                  'Desactívalo para semifinales, finales o partido único.',
                ),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _idaYVuelta
                      ? 'Se crearán dos partidos: ida y vuelta con localía invertida.'
                      : 'Se creará un solo partido. Útil para semifinales, finales o partidos especiales.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Crear cruce',
          icon: Icons.add,
          onPressed:
              _local == null ||
                  _visitante == null ||
                  _local?.id == _visitante?.id
              ? null
              : _guardar,
        ),
      ],
    );
  }
}

class _EquipoDropdown extends StatelessWidget {
  final String label;
  final EquipoModel? value;
  final List<EquipoModel> equipos;
  final void Function(EquipoModel?) onChanged;

  const _EquipoDropdown({
    required this.label,
    required this.value,
    required this.equipos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EquipoModel>(
      initialValue: value,
      isExpanded: true,
      items: equipos.map((equipo) {
        return DropdownMenuItem(value: equipo, child: Text(equipo.nombre));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.groups_2_outlined),
      ),
    );
  }
}

class _CruceManualResult {
  final EquipoModel local;
  final EquipoModel visitante;
  final int jornada;
  final bool idaYVuelta;
  final String? grupoId;

  const _CruceManualResult({
    required this.local,
    required this.visitante,
    required this.jornada,
    required this.idaYVuelta,
    this.grupoId,
  });
}

String _tipoTexto(String tipo) {
  switch (tipo) {
    case TipoCampeonato.soloIda:
      return 'Liga solo ida';
    case TipoCampeonato.idaVuelta:
      return 'Liga ida y vuelta';
    case TipoCampeonato.eliminacionDirecta:
      return 'Eliminación directa';
    case TipoCampeonato.faseGrupos:
      return 'Fase de grupos';
    case TipoCampeonato.gruposEliminacion:
      return 'Grupos + eliminación';
    case TipoCampeonato.ligaFinal:
      return 'Liga + final';
    case TipoCampeonato.ligaPlayoffs:
      return 'Liga + playoffs';
    default:
      return tipo.replaceAll('_', ' ');
  }
}

String _estadoTexto(String estado) {
  switch (estado) {
    case PartidoEstado.pendienteProgramacion:
      return 'Sin programar';
    case PartidoEstado.programado:
      return 'Programado';
    case PartidoEstado.finalizado:
      return 'Finalizado';
    case PartidoEstado.suspendido:
      return 'Suspendido';
    default:
      return estado.replaceAll('_', ' ');
  }
}
