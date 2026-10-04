import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/partido_service.dart';
import 'auditoria_screen.dart';
import 'equipos_screen.dart';
import 'fixture_screen.dart';
import 'grupos_screen.dart';
import 'igualacion_screen.dart';
import 'llaves_screen.dart';
import 'jugadores_sancionados_screen.dart';
import 'jugadores_screen.dart';
import 'pdfs_screen.dart';
import 'ranking_goleadores_screen.dart';
import 'resultados_screen.dart';
import 'tabla_posiciones_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';
import '../utils/mensajes.dart';
import '../utils/etiquetas.dart';
import '../utils/llaves.dart';
import 'reciclaje/app_match_card.dart';
import 'reciclaje/app_info_box.dart';
import 'reciclaje/app_fondo.dart';

class DetalleCampeonatoScreen extends StatefulWidget {
  final String campeonatoId;

  const DetalleCampeonatoScreen({super.key, required this.campeonatoId});

  @override
  State<DetalleCampeonatoScreen> createState() =>
      _DetalleCampeonatoScreenState();
}

class _DetalleCampeonatoScreenState extends State<DetalleCampeonatoScreen> {
  final CampeonatoService _service = CampeonatoService();

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<CampeonatoModel?> _campeonatoStream = _service
      .streamCampeonato(widget.campeonatoId);

  late final Stream<List<PartidoModel>> _partidosStream = PartidoService()
      .streamPartidos(widget.campeonatoId);
  late final Stream<List<EquipoModel>> _equiposStream = EquipoService()
      .streamEquipos(widget.campeonatoId);

  bool _loadingEstado = false;

  Future<void> _activarCampeonato() async {
    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Activar campeonato',
      message:
          'Antes de activar, el sistema validará que existan equipos activos y que cumplan la cantidad mínima de jugadores. El fixture y las fechas podrán definirse después.',
      confirmText: 'Activar',
    );

    if (!confirm) return;

    setState(() {
      _loadingEstado = true;
    });

    try {
      await _service.activarCampeonato(widget.campeonatoId);

      if (!mounted) return;

      AppSnackbars.success(context, 'Campeonato activado correctamente.');
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(context, mensajeDeError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loadingEstado = false;
        });
      }
    }
  }

  Future<void> _finalizarCampeonato() async {
    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Finalizar campeonato',
      message:
          'Al finalizar el campeonato ya no se deberían realizar modificaciones normales. ¿Quieres continuar?',
      confirmText: 'Finalizar',
      danger: true,
    );

    if (!confirm) return;

    setState(() {
      _loadingEstado = true;
    });

    try {
      await _service.finalizarCampeonato(widget.campeonatoId);

      if (!mounted) return;

      AppSnackbars.success(context, 'Campeonato finalizado correctamente.');
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(context, mensajeDeError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loadingEstado = false;
        });
      }
    }
  }

  Future<void> _editarDatos(CampeonatoModel campeonato) async {
    final datos = await showDialog<_DatosEditados>(
      context: context,
      builder: (_) => _EditarCampeonatoDialog(campeonato: campeonato),
    );

    if (datos == null || !mounted) return;

    try {
      final admin = await AuthService().requireAdmin();

      await _service.actualizarDatosCampeonato(
        campeonatoId: campeonato.id,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        temporada: datos.temporada,
        cancha: datos.cancha,
        usuarioId: admin.id,
        usuarioNombre: admin.nombre,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Datos del campeonato actualizados.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, mensajeDeError(e));
    }
  }

  void _goTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppFondo(
      child: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando campeonato...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar campeonato',
              message: mensajeDeError(snapshot.error!),
            );
          }

          final campeonato = snapshot.data;

          if (campeonato == null) {
            return const AppEmptyState(
              icon: Icons.warning_amber_rounded,
              title: 'Campeonato no encontrado',
              message: 'El campeonato seleccionado no existe.',
            );
          }

          return SingleChildScrollView(
            child: AppPage(
              title: campeonato.nombre,
              subtitle: campeonato.descripcion.trim().isEmpty
                  ? 'Detalle administrativo del campeonato.'
                  : campeonato.descripcion,
              actions: [
                AppButton.secondary(
                  text: 'Volver',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                AppButton.secondary(
                  text: isMobile ? 'Editar' : 'Editar datos',
                  icon: Icons.edit_outlined,
                  onPressed: () => _editarDatos(campeonato),
                ),
                if (campeonato.estado == CampeonatoEstado.inscripcion)
                  AppButton.primary(
                    text: isMobile ? 'Activar' : 'Activar campeonato',
                    icon: Icons.play_arrow_rounded,
                    loading: _loadingEstado,
                    onPressed: _activarCampeonato,
                  ),
                if (campeonato.estado == CampeonatoEstado.activo)
                  AppButton.danger(
                    text: isMobile ? 'Finalizar' : 'Finalizar campeonato',
                    icon: Icons.flag_outlined,
                    loading: _loadingEstado,
                    onPressed: _finalizarCampeonato,
                  ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeroCard(
                    title: campeonato.nombre,
                    description: campeonato.descripcion.trim().isEmpty
                        ? 'Gestiona equipos, jugadores, fixture, resultados, tabla, goleadores y documentos del campeonato.'
                        : campeonato.descripcion,
                    badges: [
                      AppBadge(
                        text: Etiquetas.estadoCampeonato(campeonato.estado),
                        type: AppBadge.tipoEstadoCampeonato(campeonato.estado),
                        icon: Icons.verified_outlined,
                      ),
                      AppBadge(
                        text: Etiquetas.modalidad(campeonato.modalidad),
                        type: AppBadgeType.warning,
                        icon: deporteIcono(campeonato.deporteEfectivo),
                      ),
                      AppBadge(
                        text: Etiquetas.tipoCampeonato(
                          campeonato.tipoCampeonato,
                        ),
                        type: AppBadgeType.primary,
                        icon: Icons.account_tree_outlined,
                      ),
                    ],
                    infoItems: [
                      AppHeroInfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Temporada',
                        value: campeonato.temporada,
                      ),
                      AppHeroInfoItem(
                        icon: deporteIcono(campeonato.deporteEfectivo),
                        label: 'Modalidad',
                        value: Etiquetas.modalidad(campeonato.modalidad),
                      ),
                      AppHeroInfoItem(
                        icon: Icons.place_outlined,
                        label: 'Cancha',
                        value: campeonato.cancha,
                      ),
                      AppHeroInfoItem(
                        icon: Icons.flag_outlined,
                        label: 'Estado',
                        value: Etiquetas.estadoCampeonato(campeonato.estado),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PendientesCard(
                    campeonato: campeonato,
                    partidosStream: _partidosStream,
                    equiposStream: _equiposStream,
                    onEquipos: () =>
                        _goTo(EquiposScreen(campeonatoId: campeonato.id)),
                    onFixture: () =>
                        _goTo(FixtureScreen(campeonatoId: campeonato.id)),
                    onResultados: () =>
                        _goTo(ResultadosScreen(campeonatoId: campeonato.id)),
                  ),
                  const SizedBox(height: 20),
                  _InfoStats(campeonato: campeonato),
                  const SizedBox(height: 22),
                  _ModulesGrid(
                    campeonato: campeonato,
                    onEquipos: () =>
                        _goTo(EquiposScreen(campeonatoId: campeonato.id)),
                    onJugadores: () =>
                        _goTo(JugadoresScreen(campeonatoId: campeonato.id)),
                    onGrupos: () =>
                        _goTo(GruposScreen(campeonatoId: campeonato.id)),
                    onFixture: () =>
                        _goTo(FixtureScreen(campeonatoId: campeonato.id)),
                    onResultados: () =>
                        _goTo(ResultadosScreen(campeonatoId: campeonato.id)),
                    onTabla: () => _goTo(
                      TablaPosicionesScreen(campeonatoId: campeonato.id),
                    ),
                    onRanking: () => _goTo(
                      RankingGoleadoresScreen(campeonatoId: campeonato.id),
                    ),
                    onSancionados: () => _goTo(
                      JugadoresSancionadosScreen(campeonatoId: campeonato.id),
                    ),
                    onIgualacion: () =>
                        _goTo(IgualacionScreen(campeonatoId: campeonato.id)),
                    onLlaves: () =>
                        _goTo(LlavesScreen(campeonatoId: campeonato.id)),
                    onPdfs: () =>
                        _goTo(PdfsScreen(campeonatoId: campeonato.id)),
                    onAuditoria: () =>
                        _goTo(AuditoriaScreen(campeonatoId: campeonato.id)),
                  ),
                  const SizedBox(height: 22),
                  _FormatSummaryCard(campeonato: campeonato),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lo que falta hacer en el campeonato, con acceso directo al módulo
/// donde se resuelve: partidos ya jugados sin resultado, partidos sin
/// fecha, o que todavía no hay equipos. Antes la pantalla mostraba doce
/// módulos iguales y había que entrar a cada uno para saber qué faltaba.
class _PendientesCard extends StatelessWidget {
  final CampeonatoModel campeonato;
  final Stream<List<PartidoModel>> partidosStream;
  final Stream<List<EquipoModel>> equiposStream;
  final VoidCallback onEquipos;
  final VoidCallback onFixture;
  final VoidCallback onResultados;

  const _PendientesCard({
    required this.campeonato,
    required this.partidosStream,
    required this.equiposStream,
    required this.onEquipos,
    required this.onFixture,
    required this.onResultados,
  });

  @override
  Widget build(BuildContext context) {
    // Un campeonato cerrado no tiene nada pendiente.
    if (campeonato.estado == CampeonatoEstado.finalizado) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<EquipoModel>>(
      stream: equiposStream,
      builder: (context, equiposSnapshot) {
        return StreamBuilder<List<PartidoModel>>(
          stream: partidosStream,
          builder: (context, partidosSnapshot) {
            if (!equiposSnapshot.hasData || !partidosSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final equipos = equiposSnapshot.data!;
            final partidos = partidosSnapshot.data!;
            final ahora = DateTime.now();

            final atrasados = partidos
                .where((p) => p.faltaResultadoAl(ahora))
                .length;
            final sinFecha = partidos.where((p) => p.faltaProgramar).length;

            final items = <Widget>[
              if (equipos.isEmpty)
                _PendienteItem(
                  icon: Icons.groups_2_outlined,
                  texto: 'Todavía no hay equipos registrados.',
                  accion: 'Ir a Equipos',
                  onTap: onEquipos,
                ),
              if (campeonato.estado == CampeonatoEstado.activo && atrasados > 0)
                _PendienteItem(
                  icon: Icons.fact_check_outlined,
                  texto: atrasados == 1
                      ? '1 partido ya se jugó y no tiene resultado.'
                      : '$atrasados partidos ya se jugaron y no tienen resultado.',
                  accion: 'Cargar resultados',
                  onTap: onResultados,
                  urgente: true,
                ),
              if (sinFecha > 0)
                _PendienteItem(
                  icon: Icons.edit_calendar_outlined,
                  texto: sinFecha == 1
                      ? '1 partido no tiene fecha ni hora.'
                      : '$sinFecha partidos no tienen fecha ni hora.',
                  accion: 'Programar',
                  onTap: onFixture,
                ),
            ];

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    title: 'Pendientes',
                    subtitle: 'Lo que falta hacer en este campeonato.',
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            campeonato.estado == CampeonatoEstado.inscripcion
                                ? '${equipos.length} equipos registrados. Cuando estén completos, activa el campeonato.'
                                : 'Todo al día: no hay resultados atrasados ni partidos sin fecha.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      items[i],
                    ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PendienteItem extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String accion;
  final VoidCallback onTap;

  /// Algo que ya debería estar hecho (un resultado atrasado): se marca
  /// en naranja para que se vea primero.
  final bool urgente;

  const _PendienteItem({
    required this.icon,
    required this.texto,
    required this.accion,
    required this.onTap,
    this.urgente = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = urgente ? AppColors.warning : AppColors.primary;
    final isMobile = Responsive.isMobile(context);

    return Material(
      color: urgente ? AppColors.warningLight : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!isMobile)
                Text(
                  accion,
                  style: AppTextStyles.button.copyWith(color: color),
                ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStats extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _InfoStats({required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final config = campeonato.configuracion;

    return AppResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      spacing: 14,
      children: [
        StatCard(
          title: 'Formato',
          value: Etiquetas.tipoCampeonatoCorto(campeonato.tipoCampeonato),
          icon: Icons.account_tree_outlined,
          subtitle: 'Competencia',
          color: AppColors.primary,
        ),
        StatCard(
          title: 'Vueltas',
          value: '${config.cantidadVueltas}',
          icon: Icons.repeat_rounded,
          subtitle: _vueltasSubtitle(campeonato),
          color: AppColors.secondary,
        ),
        StatCard(
          title: 'En cancha',
          value: '${config.cantidadJugadoresEnCancha}',
          icon: deporteIcono(campeonato.deporteEfectivo),
          subtitle: 'Jugadores',
          color: AppColors.info,
        ),
        StatCard(
          title: 'Plantilla',
          value:
              '${config.cantidadMinimaJugadoresPorEquipo}-${config.cantidadMaximaJugadoresPorEquipo}',
          icon: Icons.groups_2_outlined,
          subtitle: 'Mínimo y máximo',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _ModulesGrid extends StatelessWidget {
  final CampeonatoModel campeonato;
  final VoidCallback onEquipos;
  final VoidCallback onJugadores;
  final VoidCallback onGrupos;
  final VoidCallback onFixture;
  final VoidCallback onResultados;
  final VoidCallback onTabla;
  final VoidCallback onRanking;
  final VoidCallback onSancionados;
  final VoidCallback onIgualacion;
  final VoidCallback onLlaves;
  final VoidCallback onPdfs;
  final VoidCallback onAuditoria;

  const _ModulesGrid({
    required this.campeonato,
    required this.onEquipos,
    required this.onJugadores,
    required this.onGrupos,
    required this.onFixture,
    required this.onResultados,
    required this.onTabla,
    required this.onRanking,
    required this.onSancionados,
    required this.onIgualacion,
    required this.onLlaves,
    required this.onPdfs,
    required this.onAuditoria,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleItem(
        title: 'Equipos',
        description: 'Registrar equipos, carrera/facultad y planillas.',
        icon: Icons.groups_2_outlined,
        enabled: true,
        tag: 'Inscripción',
        onTap: onEquipos,
      ),
      _ModuleItem(
        title: 'Jugadores',
        description: 'Registrar códigos, nombres, estados e historial.',
        icon: Icons.person_add_alt_1_outlined,
        enabled: true,
        tag: 'Planillas',
        onTap: onJugadores,
      ),
      if (campeonato.usaGrupos)
        _ModuleItem(
          title: 'Grupos',
          description: 'Inscribir equipos en cada grupo antes del fixture.',
          icon: Icons.grid_view_rounded,
          enabled: true,
          tag: 'Inscripción',
          onTap: onGrupos,
        ),
      _ModuleItem(
        title: 'Fixture',
        description: 'Generar cruces, asignar fechas y programar partidos.',
        icon: Icons.calendar_month_outlined,
        enabled: true,
        tag: 'Programación',
        onTap: onFixture,
      ),
      _ModuleItem(
        title: 'Resultados',
        description: 'Registrar marcador final, tipo de resultado y goles.',
        icon: Icons.fact_check_outlined,
        enabled: campeonato.estado != CampeonatoEstado.inscripcion,
        tag: 'Competencia',
        onTap: onResultados,
      ),
      _ModuleItem(
        title: 'Tabla',
        description: 'Ver posiciones, puntos, goles y diferencia.',
        icon: Icons.leaderboard_outlined,
        enabled: true,
        tag: 'Público',
        onTap: onTabla,
      ),
      // El ranking individual (goleadores) solo aplica a fútbol/futsal:
      // vóley y básquet no registran goles/puntos por jugador, así que
      // el módulo ni se muestra para esos deportes.
      if (campeonato.esFutbol)
        _ModuleItem(
          title: 'Goleadores',
          description: 'Ver ranking de mejores anotadores.',
          icon: Icons.sports_soccer,
          enabled: true,
          tag: 'Público',
          onTap: onRanking,
        ),
      if (campeonato.tieneFasesSeparadas)
        _ModuleItem(
          title: 'Llaves',
          description: 'Generar y retocar los cruces de la fase eliminatoria.',
          icon: Icons.account_tree_outlined,
          enabled: campeonato.estado != CampeonatoEstado.inscripcion,
          tag: 'Competencia',
          onTap: onLlaves,
        ),
      // La igualación compensa a los grupos con menos equipos: en una
      // liga o una eliminación directa no hay grupos que comparar.
      if (campeonato.usaGrupos)
        _ModuleItem(
          title: 'Igualación',
          description:
              'Sumar puntos a los grupos con menos equipos para compararlos parejo.',
          icon: Icons.balance_outlined,
          enabled: campeonato.estado != CampeonatoEstado.inscripcion,
          tag: 'Competencia',
          onTap: onIgualacion,
        ),
      _ModuleItem(
        title: 'Sancionados',
        description: campeonato.esFutbol
            ? 'Amarillas, rojas y expulsiones por jugador y partido.'
            : 'Sanciones por mesa o forzadas por jugador y partido.',
        icon: Icons.shield_outlined,
        enabled: true,
        tag: 'Control',
        onTap: onSancionados,
      ),
      _ModuleItem(
        title: 'PDFs',
        description: 'Descargar fixture, listas y planillas de partido.',
        icon: Icons.picture_as_pdf_outlined,
        enabled: true,
        tag: 'Documentos',
        onTap: onPdfs,
      ),
      _ModuleItem(
        title: 'Auditoría',
        description: 'Ver cambios, observaciones y trazabilidad.',
        icon: Icons.history,
        enabled: true,
        tag: 'Control',
        onTap: onAuditoria,
      ),
    ];

    final enInscripcion = campeonato.estado == CampeonatoEstado.inscripcion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Módulos del campeonato',
          subtitle: 'Ordenados según la etapa del campeonato en que se usan.',
        ),
        if (enInscripcion) ...[
          const SizedBox(height: 12),
          const AppInfoBox(
            icon: Icons.lock_outline_rounded,
            text:
                'Resultados, llaves e igualación se habilitan cuando actives el campeonato.',
          ),
        ],
        for (final (titulo, tags) in _secciones)
          if (modules.any((m) => tags.contains(m.tag))) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                titulo.toUpperCase(),
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            AppResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 4,
              spacing: 16,
              children: modules
                  .where((m) => tags.contains(m.tag))
                  .map((module) => _ModuleCard(module: module))
                  .toList(),
            ),
          ],
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: module.enabled ? 1 : 0.55,
      child: AppCard(
        onTap: module.enabled ? module.onTap : null,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: module.enabled
                        ? AppColors.primaryLight
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: module.enabled
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    module.icon,
                    color: module.enabled
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 25,
                  ),
                ),
                const Spacer(),
                AppBadge(
                  text: module.enabled ? module.tag : 'Bloqueado',
                  type: module.enabled
                      ? AppBadgeType.primary
                      : AppBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(module.title, style: AppTextStyles.heading3),
            const SizedBox(height: 7),
            Text(
              module.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  module.enabled ? 'Abrir módulo' : 'No disponible',
                  style: AppTextStyles.button.copyWith(
                    color: module.enabled
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  module.enabled
                      ? Icons.arrow_forward_rounded
                      : Icons.lock_outline_rounded,
                  color: module.enabled
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatSummaryCard extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _FormatSummaryCard({required this.campeonato});

  @override
  Widget build(BuildContext context) {
    final config = campeonato.configuracion;

    final items = <_ConfigItem>[
      _ConfigItem(
        icon: Icons.account_tree_outlined,
        label: 'Tipo de campeonato',
        value: Etiquetas.tipoCampeonato(campeonato.tipoCampeonato),
      ),
      _ConfigItem(
        icon: Icons.table_chart_outlined,
        label: 'Tabla de posiciones',
        value: config.generaTablaPosiciones ? 'Sí genera tabla' : 'No aplica',
      ),
      _ConfigItem(
        icon: Icons.handshake_outlined,
        label: 'Empates',
        value: config.permiteEmpate ? 'Permitidos' : 'No permitidos',
      ),
      _ConfigItem(
        icon: Icons.shuffle_rounded,
        label: 'Cruces aleatorios',
        value: config.generaCrucesAleatorios ? 'Habilitado' : 'Manual',
      ),
      if (config.cantidadGrupos > 0)
        _ConfigItem(
          icon: Icons.grid_view_rounded,
          label: 'Grupos',
          value: '${config.cantidadGrupos}',
        ),
      if (config.clasificanPorGrupo > 0)
        _ConfigItem(
          icon: Icons.military_tech_outlined,
          label: 'Clasifican por grupo',
          value: '${config.clasificanPorGrupo}',
        ),
      if (config.mejoresTerceros > 0)
        _ConfigItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Mejores terceros',
          value: '${config.mejoresTerceros}',
        ),
      if (config.clasificadosPlayoffs > 0)
        _ConfigItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Clasificados a fase final',
          value: '${config.clasificadosPlayoffs}',
        ),
      if (config.generaFaseEliminatoria)
        _ConfigItem(
          icon: Icons.bolt_outlined,
          label: 'Fase eliminatoria',
          value: _rondaTexto(config.rondaEliminatoriaInicial),
        ),
      if (config.incluyeTercerLugar)
        const _ConfigItem(
          icon: Icons.emoji_events_outlined,
          label: 'Tercer lugar',
          value: 'Incluido',
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Configuración del campeonato',
            subtitle:
                'Resumen del formato guardado para organizar el fixture y la competencia.',
          ),
          const SizedBox(height: 16),
          AppResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: 12,
            children: items.map((item) {
              return _ConfigTile(item: item);
            }).toList(),
          ),
          const SizedBox(height: 16),
          AppInfoBox(
            icon: Icons.info_outline,
            text: Etiquetas.descripcionFormato(campeonato.tipoCampeonato),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final _ConfigItem item;

  const _ConfigTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final bool enabled;
  final String tag;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.tag,
    required this.onTap,
  });
}

/// Las etapas en que se agrupan los módulos, en el orden en que se usan.
/// La [_ModuleItem.tag] de cada módulo dice a cuál pertenece.
const _secciones = <(String titulo, List<String> tags)>[
  ('Inscripción', ['Inscripción', 'Planillas']),
  ('Competencia', ['Programación', 'Competencia']),
  ('Consulta', ['Público']),
  ('Control y documentos', ['Control', 'Documentos']),
];

class _ConfigItem {
  final IconData icon;
  final String label;
  final String value;

  const _ConfigItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

String _vueltasSubtitle(CampeonatoModel campeonato) {
  final tipo = campeonato.tipoCampeonato;
  final config = campeonato.configuracion;

  if (campeonato.usaGrupos) {
    return config.idaYVueltaEnGrupos ? 'En grupos' : 'Una vuelta';
  }

  if (tipo == TipoCampeonato.eliminacionDirecta) {
    return 'Partido único';
  }

  if (config.cantidadVueltas == 1) return 'Solo ida';
  if (config.cantidadVueltas == 2) return 'Ida y vuelta';

  return 'Formato liga';
}

/// La ronda inicial guardada en la configuración. Además de las rondas
/// del cuadro puede valer "llaves" (se deduce de los clasificados) o
/// "no_aplica"; el resto lo nombra [RondaLlave.nombre].
String _rondaTexto(String ronda) {
  switch (ronda) {
    case 'llaves':
      return 'Llaves eliminatorias';
    case 'no_aplica':
      return 'No aplica';
    default:
      return RondaLlave.nombre(ronda);
  }
}

class _DatosEditados {
  final String nombre;
  final String descripcion;
  final String temporada;
  final String cancha;

  const _DatosEditados({
    required this.nombre,
    required this.descripcion,
    required this.temporada,
    required this.cancha,
  });
}

/// Corregir nombre, descripción, temporada o cancha. El formato y el
/// deporte quedan fijos: cambiarlos con partidos cargados rompería el
/// fixture y la tabla.
class _EditarCampeonatoDialog extends StatefulWidget {
  final CampeonatoModel campeonato;

  const _EditarCampeonatoDialog({required this.campeonato});

  @override
  State<_EditarCampeonatoDialog> createState() =>
      _EditarCampeonatoDialogState();
}

class _EditarCampeonatoDialogState extends State<_EditarCampeonatoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.campeonato.nombre);
  late final _descripcion = TextEditingController(
    text: widget.campeonato.descripcion,
  );
  late final _temporada = TextEditingController(
    text: widget.campeonato.temporada,
  );
  late final _cancha = TextEditingController(text: widget.campeonato.cancha);

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _temporada.dispose();
    _cancha.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _DatosEditados(
        nombre: _nombre.text,
        descripcion: _descripcion.text,
        temporada: _temporada.text,
        cancha: _cancha.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Editar campeonato', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Nombre',
                  controller: _nombre,
                  prefixIcon: Icons.emoji_events_outlined,
                  validator: (valor) => (valor ?? '').trim().isEmpty
                      ? 'El nombre es obligatorio.'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Descripción',
                  controller: _descripcion,
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Temporada',
                  controller: _temporada,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Cancha',
                  controller: _cancha,
                  prefixIcon: Icons.place_outlined,
                ),
                const SizedBox(height: 14),
                const AppInfoBox(
                  text:
                      'El formato, el deporte y las reglas no se pueden cambiar una vez creado el campeonato.',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Guardar',
          icon: Icons.check_rounded,
          onPressed: _guardar,
        ),
      ],
    );
  }
}
