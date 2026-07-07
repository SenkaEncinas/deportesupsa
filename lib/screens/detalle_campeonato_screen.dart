import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/campeonato_service.dart';
import 'auditoria_screen.dart';
import 'equipos_screen.dart';
import 'fixture_screen.dart';
import 'jugadores_screen.dart';
import 'pdfs_screen.dart';
import 'ranking_goleadores_screen.dart';
import 'resultados_screen.dart';
import 'tabla_posiciones_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_dialogs.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

class DetalleCampeonatoScreen extends StatefulWidget {
  final String campeonatoId;

  const DetalleCampeonatoScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  State<DetalleCampeonatoScreen> createState() =>
      _DetalleCampeonatoScreenState();
}

class _DetalleCampeonatoScreenState extends State<DetalleCampeonatoScreen> {
  final CampeonatoService _service = CampeonatoService();

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

      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
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

      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingEstado = false;
        });
      }
    }
  }

  void _goTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: StreamBuilder<CampeonatoModel?>(
            stream: _service.streamCampeonato(widget.campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando campeonato...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar campeonato',
                  message: snapshot.error.toString(),
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
                      _HeaderCard(campeonato: campeonato),
                      const SizedBox(height: 20),
                      _InfoStats(campeonato: campeonato),
                      const SizedBox(height: 22),
                      _ModulesGrid(
                        campeonato: campeonato,
                        onEquipos: () => _goTo(
                          EquiposScreen(campeonatoId: campeonato.id),
                        ),
                        onJugadores: () => _goTo(
                          JugadoresScreen(campeonatoId: campeonato.id),
                        ),
                        onFixture: () => _goTo(
                          FixtureScreen(campeonatoId: campeonato.id),
                        ),
                        onResultados: () => _goTo(
                          ResultadosScreen(campeonatoId: campeonato.id),
                        ),
                        onTabla: () => _goTo(
                          TablaPosicionesScreen(campeonatoId: campeonato.id),
                        ),
                        onRanking: () => _goTo(
                          RankingGoleadoresScreen(campeonatoId: campeonato.id),
                        ),
                        onPdfs: () => _goTo(
                          PdfsScreen(campeonatoId: campeonato.id),
                        ),
                        onAuditoria: () => _goTo(
                          AuditoriaScreen(campeonatoId: campeonato.id),
                        ),
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
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _HeaderCard({
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003D2D),
              Color(0xFF005C45),
              AppColors.primary,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -48,
                top: -52,
                child: _DecorativeCircle(
                  size: isMobile ? 140 : 190,
                  opacity: 0.10,
                ),
              ),
              Positioned(
                right: isMobile ? 20 : 42,
                bottom: -40,
                child: _DecorativeCircle(
                  size: isMobile ? 90 : 130,
                  opacity: 0.08,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 22 : 30),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppLogoMark(),
                          const SizedBox(height: 20),
                          _HeaderText(campeonato: campeonato),
                          const SizedBox(height: 20),
                          _HeaderInfoBox(campeonato: campeonato),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppLogoMark(),
                                const SizedBox(height: 22),
                                _HeaderText(campeonato: campeonato),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          _HeaderInfoBox(campeonato: campeonato),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _HeaderText({
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AppBadge(
              text: _estadoTexto(campeonato.estado),
              type: _estadoBadgeType(campeonato.estado),
              icon: Icons.verified_outlined,
            ),
            AppBadge(
              text: _tipoTexto(campeonato.tipoCampeonato),
              type: AppBadgeType.primary,
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          campeonato.nombre,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: isMobile ? 26 : 34,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          campeonato.descripcion.trim().isEmpty
              ? 'Gestiona equipos, jugadores, fixture, resultados, tabla, goleadores y documentos del campeonato.'
              : campeonato.descripcion,
          style: AppTextStyles.body.copyWith(
            color: AppColors.white.withOpacity(0.88),
            fontSize: isMobile ? 14 : 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _HeaderInfoBox extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _HeaderInfoBox({
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: isMobile ? double.infinity : 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          _DarkInfoLine(
            icon: Icons.calendar_today_outlined,
            label: 'Temporada',
            value: campeonato.temporada,
          ),
          const SizedBox(height: 14),
          _DarkInfoLine(
            icon: Icons.sports_soccer,
            label: 'Modalidad',
            value: _modalidadTexto(campeonato.modalidad),
          ),
          const SizedBox(height: 14),
          _DarkInfoLine(
            icon: Icons.place_outlined,
            label: 'Cancha',
            value: campeonato.cancha,
          ),
          const SizedBox(height: 14),
          _DarkInfoLine(
            icon: Icons.flag_outlined,
            label: 'Estado',
            value: _estadoTexto(campeonato.estado),
          ),
        ],
      ),
    );
  }
}

class _InfoStats extends StatelessWidget {
  final CampeonatoModel campeonato;

  const _InfoStats({
    required this.campeonato,
  });

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
          value: _shortTipoTexto(campeonato.tipoCampeonato),
          icon: Icons.account_tree_outlined,
          subtitle: 'Competencia',
          color: AppColors.primary,
        ),
        StatCard(
          title: 'Vueltas',
          value: '${config.cantidadVueltas}',
          icon: Icons.repeat_rounded,
          subtitle: _vueltasSubtitle(campeonato),
          color: const Color(0xFFD6A100),
        ),
        StatCard(
          title: 'En cancha',
          value: '${config.cantidadJugadoresEnCancha}',
          icon: Icons.sports_soccer,
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
  final VoidCallback onFixture;
  final VoidCallback onResultados;
  final VoidCallback onTabla;
  final VoidCallback onRanking;
  final VoidCallback onPdfs;
  final VoidCallback onAuditoria;

  const _ModulesGrid({
    required this.campeonato,
    required this.onEquipos,
    required this.onJugadores,
    required this.onFixture,
    required this.onResultados,
    required this.onTabla,
    required this.onRanking,
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
        description: campeonato.estado == CampeonatoEstado.inscripcion
            ? 'Disponible cuando el campeonato esté activo.'
            : 'Registrar marcador final, tipo de resultado y goles.',
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
      _ModuleItem(
        title: 'Goleadores',
        description: 'Ver ranking de mejores anotadores.',
        icon: Icons.sports_soccer,
        enabled: true,
        tag: 'Público',
        onTap: onRanking,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Módulos del campeonato',
          subtitle: 'Gestiona toda la información desde este campeonato.',
        ),
        const SizedBox(height: 14),
        AppResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 4,
          spacing: 16,
          children: modules.map((module) {
            return _ModuleCard(module: module);
          }).toList(),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem module;

  const _ModuleCard({
    required this.module,
  });

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
                          ? AppColors.primary.withOpacity(0.12)
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
            Text(
              module.title,
              style: AppTextStyles.heading3,
            ),
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

  const _FormatSummaryCard({
    required this.campeonato,
  });

  @override
  Widget build(BuildContext context) {
    final config = campeonato.configuracion;

    final items = <_ConfigItem>[
      _ConfigItem(
        icon: Icons.account_tree_outlined,
        label: 'Tipo de campeonato',
        value: _tipoTexto(campeonato.tipoCampeonato),
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
          _InfoBox(
            icon: Icons.info_outline,
            text: _descripcionFormato(campeonato.tipoCampeonato),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final _ConfigItem item;

  const _ConfigTile({
    required this.item,
  });

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
            child: Icon(
              item.icon,
              color: AppColors.primary,
              size: 20,
            ),
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

class _DarkInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DarkInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'No definido' : value;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.white.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cleanValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.info.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 21),
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

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
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

String _estadoTexto(String estado) {
  switch (estado) {
    case CampeonatoEstado.inscripcion:
      return 'Inscripción';
    case CampeonatoEstado.activo:
      return 'Activo';
    case CampeonatoEstado.finalizado:
      return 'Finalizado';
    default:
      return _formatLabel(estado);
  }
}

AppBadgeType _estadoBadgeType(String estado) {
  switch (estado) {
    case CampeonatoEstado.inscripcion:
      return AppBadgeType.info;
    case CampeonatoEstado.activo:
      return AppBadgeType.success;
    case CampeonatoEstado.finalizado:
      return AppBadgeType.neutral;
    default:
      return AppBadge.typeFromEstado(estado);
  }
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
      return _formatLabel(tipo);
  }
}

String _shortTipoTexto(String tipo) {
  switch (tipo) {
    case TipoCampeonato.soloIda:
      return 'Solo ida';
    case TipoCampeonato.idaVuelta:
      return 'Ida/vuelta';
    case TipoCampeonato.eliminacionDirecta:
      return 'Eliminación';
    case TipoCampeonato.faseGrupos:
      return 'Grupos';
    case TipoCampeonato.gruposEliminacion:
      return 'Grupos + llaves';
    case TipoCampeonato.ligaFinal:
      return 'Liga + final';
    case TipoCampeonato.ligaPlayoffs:
      return 'Playoffs';
    default:
      return _formatLabel(tipo);
  }
}

String _modalidadTexto(String modalidad) {
  switch (modalidad) {
    case 'futsal':
      return 'Futsal';
    case 'futbol_7':
      return 'Fútbol 7';
    case 'futbol_11':
      return 'Fútbol 11';
    default:
      return _formatLabel(modalidad);
  }
}

String _vueltasSubtitle(CampeonatoModel campeonato) {
  final tipo = campeonato.tipoCampeonato;
  final config = campeonato.configuracion;

  if (tipo == TipoCampeonato.faseGrupos ||
      tipo == TipoCampeonato.gruposEliminacion) {
    return config.idaYVueltaEnGrupos ? 'En grupos' : 'Una vuelta';
  }

  if (tipo == TipoCampeonato.eliminacionDirecta) {
    return 'Partido único';
  }

  if (config.cantidadVueltas == 1) return 'Solo ida';
  if (config.cantidadVueltas == 2) return 'Ida y vuelta';

  return 'Formato liga';
}

String _rondaTexto(String ronda) {
  switch (ronda) {
    case 'final':
      return 'Final';
    case 'semifinal':
      return 'Semifinales';
    case 'cuartos':
      return 'Cuartos de final';
    case 'llaves':
      return 'Llaves eliminatorias';
    case 'no_aplica':
      return 'No aplica';
    default:
      return _formatLabel(ronda);
  }
}

String _descripcionFormato(String tipo) {
  switch (tipo) {
    case TipoCampeonato.soloIda:
      return 'Todos los equipos juegan entre sí una sola vez. La tabla de posiciones define el orden final.';
    case TipoCampeonato.idaVuelta:
      return 'Todos los equipos juegan entre sí dos veces, invirtiendo la localía en la segunda vuelta.';
    case TipoCampeonato.ligaFinal:
      return 'Primero se juega una liga general. Luego los dos mejores disputan una final.';
    case TipoCampeonato.ligaPlayoffs:
      return 'Primero se juega una liga general. Luego los mejores clasifican a una fase final.';
    case TipoCampeonato.faseGrupos:
      return 'Los equipos se dividen en grupos. Cada grupo maneja su propia tabla de posiciones.';
    case TipoCampeonato.gruposEliminacion:
      return 'Primero se juega una fase de grupos. Luego los clasificados pasan a llaves eliminatorias.';
    case TipoCampeonato.eliminacionDirecta:
      return 'Los equipos juegan llaves eliminatorias. El perdedor queda fuera del campeonato.';
    default:
      return 'Formato personalizado guardado para este campeonato.';
  }
}

String _formatLabel(String value) {
  final clean = value.trim();

  if (clean.isEmpty) return 'No definido';

  return clean
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map((word) {
    if (word.length == 1) return word.toUpperCase();

    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }).join(' ');
}