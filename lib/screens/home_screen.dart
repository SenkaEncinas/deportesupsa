import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/public_home_service.dart';
import 'championship_detail_screen.dart';
import 'login_screen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _ChampionshipFilter {
  todos,
  inscripcion,
  activo,
  finalizado,
}

class _HomeScreenState extends State<HomeScreen> {
  final PublicHomeService _service = PublicHomeService();
  final TextEditingController _searchController = TextEditingController();

  _ChampionshipFilter _filter = _ChampionshipFilter.todos;
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CampeonatoModel> _filterCampeonatos(List<CampeonatoModel> campeonatos) {
    return campeonatos.where((campeonato) {
      final matchesEstado = switch (_filter) {
        _ChampionshipFilter.todos => true,
        _ChampionshipFilter.inscripcion =>
          campeonato.estado == CampeonatoEstado.inscripcion,
        _ChampionshipFilter.activo => campeonato.estado == CampeonatoEstado.activo,
        _ChampionshipFilter.finalizado =>
          campeonato.estado == CampeonatoEstado.finalizado,
      };

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
            stream: _service.streamCampeonatosPublicos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(
                  message: 'Cargando campeonatos...',
                );
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'No se pudo cargar la información',
                  message: snapshot.error.toString(),
                );
              }

              final campeonatos = snapshot.data ?? [];
              final filtered = _filterCampeonatos(campeonatos);

              return SingleChildScrollView(
                child: AppPage(
                  title: 'UPSA Campeonatos',
                  subtitle:
                      'Fixture, resultados, tabla de posiciones y goleadores de los campeonatos universitarios.',
                  actions: [
                    AppButton.secondary(
                      text: isMobile ? 'Admin' : 'Ingresar admin',
                      icon: Icons.admin_panel_settings_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHero(
                        totalCampeonatos: campeonatos.length,
                        activos: campeonatos
                            .where((item) => item.estado == CampeonatoEstado.activo)
                            .length,
                      ),
                      const SizedBox(height: 22),
                      _FiltersCard(
                        controller: _searchController,
                        filter: _filter,
                        onFilterChanged: (value) {
                          setState(() {
                            _filter = value;
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
                        title: 'Campeonatos disponibles',
                        subtitle: campeonatos.isEmpty
                            ? 'Aún no hay campeonatos creados.'
                            : 'Selecciona un campeonato para ver su información pública.',
                      ),
                      const SizedBox(height: 14),
                      if (campeonatos.isEmpty)
                        const AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'Todavía no hay campeonatos',
                          message:
                              'Cuando un administrador cree un campeonato, se mostrará aquí la información pública.',
                        )
                      else if (filtered.isEmpty)
                        const AppInlineEmptyState(
                          icon: Icons.search_off_rounded,
                          text: 'No hay campeonatos con esos filtros.',
                          subtitle: 'Prueba cambiando el estado o el texto de búsqueda.',
                        )
                      else
                        AppResponsiveGrid(
                          mobileColumns: 1,
                          tabletColumns: 2,
                          desktopColumns: 3,
                          spacing: 16,
                          children: filtered.map((campeonato) {
                            return ChampionshipPublicCard(
                              campeonato: campeonato,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChampionshipDetailScreen(
                                      campeonato: campeonato,
                                    ),
                                  ),
                                );
                              },
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

class _HomeHero extends StatelessWidget {
  final int totalCampeonatos;
  final int activos;

  const _HomeHero({
    required this.totalCampeonatos,
    required this.activos,
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
                    _HeroText(),
                    const SizedBox(height: 20),
                    _HeroStats(
                      totalCampeonatos: totalCampeonatos,
                      activos: activos,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppLogoMark(),
                          SizedBox(height: 22),
                          _HeroText(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    _HeroStats(
                      totalCampeonatos: totalCampeonatos,
                      activos: activos,
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
        Text(
          'Portal público de campeonatos UPSA',
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
            'Consulta campeonatos activos, fixtures, resultados, tablas de posiciones y ranking de goleadores desde un solo lugar.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.88),
              fontSize: isMobile ? 14 : 15,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroChip(
              icon: Icons.school_outlined,
              text: 'UPSA',
            ),
            _HeroChip(
              icon: Icons.sports_soccer,
              text: 'Fútbol y futsal',
            ),
            _HeroChip(
              icon: Icons.public_outlined,
              text: 'Vista pública',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  final int totalCampeonatos;
  final int activos;

  const _HeroStats({
    required this.totalCampeonatos,
    required this.activos,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: isMobile ? double.infinity : 280,
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
          _HeroStatLine(
            label: 'Campeonatos',
            value: '$totalCampeonatos',
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 14),
          _HeroStatLine(
            label: 'Activos',
            value: '$activos',
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }
}

class _HeroStatLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStatLine({
    required this.label,
    required this.value,
    required this.icon,
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
              color: AppColors.white.withOpacity(0.78),
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

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.white),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final TextEditingController controller;
  final _ChampionshipFilter filter;
  final ValueChanged<_ChampionshipFilter> onFilterChanged;
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
            'Buscar campeonato',
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
                selected: filter == _ChampionshipFilter.todos,
                onTap: () => onFilterChanged(_ChampionshipFilter.todos),
              ),
              _FilterPill(
                text: 'Inscripción',
                selected: filter == _ChampionshipFilter.inscripcion,
                onTap: () => onFilterChanged(_ChampionshipFilter.inscripcion),
              ),
              _FilterPill(
                text: 'Activo',
                selected: filter == _ChampionshipFilter.activo,
                onTap: () => onFilterChanged(_ChampionshipFilter.activo),
              ),
              _FilterPill(
                text: 'Finalizado',
                selected: filter == _ChampionshipFilter.finalizado,
                onTap: () => onFilterChanged(_ChampionshipFilter.finalizado),
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