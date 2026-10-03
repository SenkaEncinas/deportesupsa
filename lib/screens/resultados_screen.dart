import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/partido_service.dart';
import '../utils/etiquetas.dart';
import '../utils/fechas.dart';
import '../utils/llaves.dart';
import '../utils/mensajes.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_info_box.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'resultado_form_screen.dart';

/// Qué partidos se listan. Arranca en "por cargar": es lo que se viene a
/// hacer a esta pantalla, y antes había que buscar los pendientes entre
/// todos los partidos del campeonato, ordenados por jornada.
enum _FiltroResultados { porCargar, conResultado, todos }

class ResultadosScreen extends StatefulWidget {
  final String campeonatoId;

  const ResultadosScreen({super.key, required this.campeonatoId});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  _FiltroResultados _filtro = _FiltroResultados.porCargar;

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final CampeonatoService _campeonatoService = CampeonatoService();
  late final PartidoService _partidoService = PartidoService();
  late final Stream<CampeonatoModel?> _campeonatoStream = _campeonatoService
      .streamCampeonato(widget.campeonatoId);
  late final Stream<List<PartidoModel>> _partidosStream = _partidoService
      .streamPartidos(widget.campeonatoId);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Los "pasa directo" y los cruces que esperan al ganador de otra
  /// llave no cuentan: no hay nada que cargar.
  static bool _porCargar(PartidoModel partido) => partido.faltaResultado;

  List<PartidoModel> _filtrar(List<PartidoModel> partidos) {
    final search = _search.trim().toLowerCase();

    final lista = partidos.where((partido) {
      final pasaFiltro = switch (_filtro) {
        _FiltroResultados.porCargar => _porCargar(partido),
        _FiltroResultados.conResultado => partido.resultadoRegistrado,
        _FiltroResultados.todos => true,
      };
      if (!pasaFiltro) return false;
      if (search.isEmpty) return true;

      return '${partido.equipoLocalNombre} ${partido.equipoVisitanteNombre}'
          .toLowerCase()
          .contains(search);
    }).toList();

    // Por cargar: el más próximo arriba. Con resultado: el último
    // jugado arriba. Los que no tienen fecha van siempre al final.
    final masRecientePrimero = _filtro == _FiltroResultados.conResultado;
    lista.sort((a, b) {
      final fa = a.fechaHora;
      final fb = b.fechaHora;
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;
      return masRecientePrimero ? fb.compareTo(fa) : fa.compareTo(fb);
    });

    return lista;
  }

  /// Por qué un partido no se puede cargar todavía, o null si se puede.
  /// Antes el botón aparecía apagado sin explicación.
  static String? _motivoBloqueo(
    PartidoModel partido,
    CampeonatoModel? campeonato,
  ) {
    if (campeonato?.estado == CampeonatoEstado.inscripcion) {
      return 'Activa el campeonato para cargar resultados.';
    }
    if (campeonato?.estado == CampeonatoEstado.finalizado) {
      return 'El campeonato está finalizado.';
    }
    if (partido.esBye) return 'Pasa directo: este cruce no se juega.';
    if (!partido.tieneEquiposDefinidos) {
      return 'Espera al ganador de la ronda anterior.';
    }
    if (partido.estado == PartidoEstado.pendienteProgramacion) {
      return 'Primero ponle fecha y hora en Fixture.';
    }
    return null;
  }

  void _abrirFormulario(PartidoModel partido, CampeonatoModel? campeonato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoFormScreen(
          campeonatoId: widget.campeonatoId,
          partido: partido,
          campeonato: campeonato,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoStream,
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando partidos...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar partidos',
                  message: mensajeDeError(snapshot.error!),
                );
              }

              final partidos = snapshot.data ?? [];
              final filtrados = _filtrar(partidos);
              final porCargar = partidos.where(_porCargar).length;
              final conResultado = partidos
                  .where((p) => p.resultadoRegistrado)
                  .length;

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Resultados',
                  subtitle: campeonato == null
                      ? 'Registro de resultados.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                  child: partidos.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.fact_check_outlined,
                          title: 'No hay partidos',
                          message:
                              'Primero genera el fixture para poder registrar resultados.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (campeonato?.estado ==
                                CampeonatoEstado.inscripcion) ...[
                              const AppInfoBox(
                                text:
                                    'El campeonato todavía está en inscripción. Actívalo desde su pantalla principal para poder cargar resultados.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppFilterPill(
                                  text: 'Por cargar',
                                  count: porCargar,
                                  selected:
                                      _filtro == _FiltroResultados.porCargar,
                                  onTap: () => setState(() {
                                    _filtro = _FiltroResultados.porCargar;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Con resultado',
                                  count: conResultado,
                                  selected:
                                      _filtro == _FiltroResultados.conResultado,
                                  onTap: () => setState(() {
                                    _filtro = _FiltroResultados.conResultado;
                                  }),
                                ),
                                AppFilterPill(
                                  text: 'Todos',
                                  count: partidos.length,
                                  selected: _filtro == _FiltroResultados.todos,
                                  onTap: () => setState(() {
                                    _filtro = _FiltroResultados.todos;
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Buscar partido',
                              hint: 'Nombre de alguno de los equipos...',
                              controller: _searchController,
                              prefixIcon: Icons.search_rounded,
                              onChanged: (value) {
                                setState(() => _search = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (filtrados.isEmpty)
                              AppInlineEmptyState(
                                icon: _search.trim().isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.task_alt_rounded,
                                text: _search.trim().isNotEmpty
                                    ? 'No hay partidos que coincidan con la búsqueda.'
                                    : _filtro == _FiltroResultados.porCargar
                                    ? 'No hay resultados pendientes. ¡Todo al día!'
                                    : 'Todavía no hay resultados cargados.',
                              )
                            else
                              ...filtrados.map((partido) {
                                final motivo = _motivoBloqueo(
                                  partido,
                                  campeonato,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ResultadoCard(
                                    partido: partido,
                                    esVolley: campeonato?.esVolley ?? false,
                                    motivoBloqueo: motivo,
                                    onEditar: () =>
                                        _abrirFormulario(partido, campeonato),
                                  ),
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

class _ResultadoCard extends StatelessWidget {
  final PartidoModel partido;
  final bool esVolley;

  /// Si no es null, el partido no se puede cargar y esto dice por qué.
  final String? motivoBloqueo;
  final VoidCallback onEditar;

  const _ResultadoCard({
    required this.partido,
    required this.esVolley,
    required this.motivoBloqueo,
    required this.onEditar,
  });

  /// Dónde se juega el partido dentro del campeonato: el grupo, la ronda
  /// del cuadro o "fase final" para un cruce cargado a mano. Antes decía
  /// "Vuelta 1 · Jornada 1" también en la semifinal, que no dice nada.
  String? get _contexto {
    if (partido.privilegio) return 'Privilegio';
    if (partido.tieneGrupo) {
      return '${partido.grupoId} · Jornada ${partido.jornada}';
    }
    if (partido.esDeLlave) {
      return '${RondaLlave.nombre(partido.rondaLlave!)} · Llave ${partido.llave}';
    }
    if (partido.esDeFaseFinal) return 'Fase final';
    return 'Jornada ${partido.jornada}';
  }

  String get _marcador {
    if (!partido.resultadoRegistrado) return '—';
    return esVolley ? '${partido.marcadorTexto} sets' : partido.marcadorTexto;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final fecha = partido.fechaHora;
    final bloqueado = motivoBloqueo != null;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(
              text: partido.resultadoRegistrado
                  ? 'Con resultado'
                  : Etiquetas.estadoPartido(partido.estado),
              type: partido.resultadoRegistrado
                  ? AppBadgeType.success
                  : AppBadge.typeFromEstado(partido.estado),
            ),
            if (_contexto != null)
              AppBadge(text: _contexto!, type: AppBadgeType.info),
            if (partido.tipoResultado != TipoResultado.normal)
              AppBadge(
                text: Etiquetas.tipoResultado(partido.tipoResultado),
                type: AppBadgeType.warning,
              ),
            if (partido.definidoPorPenales)
              const AppBadge(text: 'Penales', type: AppBadgeType.warning),
            if (partido.definidoPorProrroga)
              const AppBadge(text: 'Prórroga', type: AppBadgeType.warning),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              fecha == null
                  ? Icons.event_busy_outlined
                  : Icons.event_available_outlined,
              size: 15,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                fecha == null
                    ? 'Sin fecha'
                    : Fechas.diaYHora(fecha, separador: ' · '),
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (partido.sets.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Sets: ${partido.setsTexto}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (bloqueado) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  motivoBloqueo!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    final marcador = Text(
      _marcador,
      style: AppTextStyles.heading3.copyWith(
        color: partido.resultadoRegistrado
            ? AppColors.primaryDark
            : AppColors.textMuted,
      ),
    );

    final boton = partido.resultadoRegistrado
        ? AppButton.secondary(
            text: 'Editar',
            icon: Icons.edit_outlined,
            onPressed: bloqueado ? null : onEditar,
          )
        : AppButton.primary(
            text: 'Cargar resultado',
            icon: Icons.add_task_rounded,
            onPressed: bloqueado ? null : onEditar,
          );

    if (isMobile) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            info,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: marcador),
                boton,
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Row(
        children: [
          Expanded(child: info),
          const SizedBox(width: 14),
          marcador,
          const SizedBox(width: 18),
          boton,
        ],
      ),
    );
  }
}
