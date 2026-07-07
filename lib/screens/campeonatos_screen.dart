import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/campeonato_service.dart';
import 'campeonato_form_screen.dart';
import 'detalle_campeonato_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_logo_mark.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/championship_public_card.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

class CampeonatosScreen extends StatefulWidget {
  const CampeonatosScreen({super.key});

  @override
  State<CampeonatosScreen> createState() => _CampeonatosScreenState();
}

enum _CampeonatoFilter {
  todos,
  inscripcion,
  activo,
  finalizado,
}

class _CampeonatosScreenState extends State<CampeonatosScreen> {
  final CampeonatoService _service = CampeonatoService();
  final TextEditingController _searchController = TextEditingController();

  _CampeonatoFilter _filter = _CampeonatoFilter.todos;
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CampeonatoFormScreen(),
      ),
    );
  }

  void _openDetalle(CampeonatoModel campeonato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleCampeonatoScreen(
          campeonatoId: campeonato.id,
        ),
      ),
    );
  }

  List<CampeonatoModel> _filterCampeonatos(List<CampeonatoModel> campeonatos) {
    return campeonatos.where((campeonato) {
      final matchesEstado = _matchesEstado(campeonato.estado);
      final search = _searchText.trim().toLowerCase();

      if (search.isEmpty) return matchesEstado;

      final searchable = [
        campeonato.nombre,
        campeonato.descripcion,
        campeonato.temporada,
        campeonato.modalidad,
        campeonato.tipoCampeonato,
        campeonato.cancha,
      ].join(' ').toLowerCase();

      return matchesEstado && searchable.contains(search);
    }).toList();
  }

  bool _matchesEstado(String estado) {
    switch (_filter) {
      case _CampeonatoFilter.todos:
        return true;
      case _CampeonatoFilter.inscripcion:
        return estado == CampeonatoEstado.inscripcion;
      case _CampeonatoFilter.activo:
        return estado == CampeonatoEstado.activo;
      case _CampeonatoFilter.finalizado:
        return estado == CampeonatoEstado.finalizado;
    }
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
          child: StreamBuilder<List<CampeonatoModel>>(
            stream: _service.streamCampeonatos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(
                  message: 'Cargando campeonatos...',
                );
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar campeonatos',
                  message: snapshot.error.toString(),
                );
              }

              final campeonatos = snapshot.data ?? [];
              final filtered = _filterCampeonatos(campeonatos);

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Campeonatos',
                  subtitle:
                      'Crea, revisa y administra campeonatos universitarios.',
                  actions: [
                    AppButton.secondary(
                      text: isMobile ? 'Volver' : 'Volver',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    AppButton.primary(
                      text: isMobile ? 'Nuevo' : 'Nuevo campeonato',
                      icon: Icons.add_rounded,
                      onPressed: _openForm,
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CampeonatosHero(
                        total: campeonatos.length,
                        onCreate: _openForm,
                      ),
                      const SizedBox(height: 20),
                      _CampeonatosStats(campeonatos: campeonatos),
                      const SizedBox(height: 22),
                      _FiltersCard(
                        controller: _searchController,
                        filter: _filter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _filter = filter;
                          });
                        },
                        onSearchChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      AppSectionHeader(
                        title: 'Listado de campeonatos',
                        subtitle: campeonatos.isEmpty
                            ? 'Todavía no hay campeonatos registrados.'
                            : 'Selecciona un campeonato para administrar equipos, jugadores, fixture y resultados.',
                      ),
                      const SizedBox(height: 14),
                      if (campeonatos.isEmpty)
                        AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'No hay campeonatos creados',
                          message:
                              'Crea el primer campeonato para empezar a registrar equipos, jugadores y fixture.',
                          buttonText: 'Crear campeonato',
                          onPressed: _openForm,
                        )
                      else if (filtered.isEmpty)
                        const AppInlineEmptyState(
                          icon: Icons.search_off_rounded,
                          text: 'No hay campeonatos con esos filtros.',
                          subtitle:
                              'Prueba cambiando el estado o el texto de búsqueda.',
                        )
                      else
                        AppResponsiveGrid(
                          mobileColumns: 1,
                          tabletColumns: 2,
                          desktopColumns: 3,
                          spacing: 16,
                          children: filtered.map((campeonato) {
                            return _CampeonatoAdminCard(
                              campeonato: campeonato,
                              onTap: () => _openDetalle(campeonato),
                            );
                          }).toList(),
                        ),
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

class _CampeonatosHero extends StatelessWidget {
  final int total;
  final VoidCallback onCreate;

  const _CampeonatosHero({
    required this.total,
    required this.onCreate,
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
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 22 : 30),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogoMark(),
                    const SizedBox(height: 20),
                    const _HeroText(),
                    const SizedBox(height: 20),
                    _HeroActionBox(
                      total: total,
                      onCreate: onCreate,
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLogoMark(),
                          SizedBox(height: 22),
                          _HeroText(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    _HeroActionBox(
                      total: total,
                      onCreate: onCreate,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            AppBadge(
              text: 'Administración',
              type: AppBadgeType.success,
              icon: Icons.admin_panel_settings_outlined,
            ),
            AppBadge(
              text: 'Campeonatos UPSA',
              type: AppBadgeType.primary,
              icon: Icons.emoji_events_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Gestión de campeonatos',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: isMobile ? 26 : 34,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Text(
            'Crea campeonatos, revisa su estado y entra al detalle para administrar equipos, jugadores, fixture, resultados y documentos.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.88),
              fontSize: isMobile ? 14 : 15,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroActionBox extends StatelessWidget {
  final int total;
  final VoidCallback onCreate;

  const _HeroActionBox({
    required this.total,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroStatLine(
            icon: Icons.emoji_events_outlined,
            label: 'Campeonatos registrados',
            value: '$total',
          ),
          const SizedBox(height: 14),
          Text(
            'Crea un nuevo campeonato cuando inicie una nueva competencia universitaria.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.white.withOpacity(0.76),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppButton.secondary(
            text: 'Nuevo campeonato',
            icon: Icons.add_rounded,
            expanded: true,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _HeroStatLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStatLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.80),
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CampeonatosStats extends StatelessWidget {
  final List<CampeonatoModel> campeonatos;

  const _CampeonatosStats({
    required this.campeonatos,
  });

  @override
  Widget build(BuildContext context) {
    final activos = campeonatos
        .where((item) => item.estado == CampeonatoEstado.activo)
        .length;

    final inscripcion = campeonatos
        .where((item) => item.estado == CampeonatoEstado.inscripcion)
        .length;

    final finalizados = campeonatos
        .where((item) => item.estado == CampeonatoEstado.finalizado)
        .length;

    return AppResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      children: [
        StatCard(
          title: 'Total',
          value: '${campeonatos.length}',
          icon: Icons.emoji_events_outlined,
          subtitle: 'Campeonatos',
          color: AppColors.primary,
        ),
        StatCard(
          title: 'Activos',
          value: '$activos',
          icon: Icons.verified_outlined,
          subtitle: 'En competencia',
          color: AppColors.success,
        ),
        StatCard(
          title: 'Inscripción',
          value: '$inscripcion',
          icon: Icons.how_to_reg_outlined,
          subtitle: 'Recibiendo equipos',
          color: AppColors.info,
        ),
        StatCard(
          title: 'Finalizados',
          value: '$finalizados',
          icon: Icons.flag_outlined,
          subtitle: 'Cerrados',
          color: const Color(0xFFD6A100),
        ),
      ],
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final TextEditingController controller;
  final _CampeonatoFilter filter;
  final ValueChanged<_CampeonatoFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const _FiltersCard({
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar y filtrar',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, temporada, modalidad o cancha...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterPill(
                text: 'Todos',
                selected: filter == _CampeonatoFilter.todos,
                onTap: () => onFilterChanged(_CampeonatoFilter.todos),
              ),
              _FilterPill(
                text: 'Inscripción',
                selected: filter == _CampeonatoFilter.inscripcion,
                onTap: () => onFilterChanged(_CampeonatoFilter.inscripcion),
              ),
              _FilterPill(
                text: 'Activo',
                selected: filter == _CampeonatoFilter.activo,
                onTap: () => onFilterChanged(_CampeonatoFilter.activo),
              ),
              _FilterPill(
                text: 'Finalizado',
                selected: filter == _CampeonatoFilter.finalizado,
                onTap: () => onFilterChanged(_CampeonatoFilter.finalizado),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.small.copyWith(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CampeonatoAdminCard extends StatelessWidget {
  final CampeonatoModel campeonato;
  final VoidCallback onTap;

  const _CampeonatoAdminCard({
    required this.campeonato,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SportIcon(modalidad: campeonato.modalidad),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  campeonato.nombre.trim().isEmpty
                      ? 'Campeonato sin nombre'
                      : campeonato.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                text: ChampionshipPublicCard.estadoTexto(campeonato.estado),
                type: ChampionshipPublicCard.badgeType(campeonato.estado),
              ),
              AppBadge(
                text: ChampionshipPublicCard.formatLabel(campeonato.modalidad),
                type: AppBadgeType.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            campeonato.descripcion.trim().isEmpty
                ? 'Sin descripción registrada.'
                : campeonato.descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: campeonato.temporada.trim().isEmpty
                ? 'Temporada no definida'
                : campeonato.temporada,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.account_tree_outlined,
            text: ChampionshipPublicCard.formatLabel(
              campeonato.tipoCampeonato,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_outlined,
            text: campeonato.cancha.trim().isEmpty
                ? 'Cancha no definida'
                : campeonato.cancha,
          ),
          const SizedBox(height: 16),
          AppButton.primary(
            text: 'Administrar campeonato',
            icon: Icons.settings_outlined,
            expanded: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String modalidad;

  const _SportIcon({
    required this.modalidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        modalidad.toLowerCase().contains('fut')
            ? Icons.sports_soccer
            : Icons.emoji_events_outlined,
        color: AppColors.primary,
        size: 25,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textMuted,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}