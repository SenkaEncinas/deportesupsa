import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/public_home_service.dart';
import 'championship_detail_screen.dart';
import 'login_screen.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_filter_pill.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
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

enum _ChampionshipFilter { todos, inscripcion, activo, finalizado }

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
        _ChampionshipFilter.activo =>
          campeonato.estado == CampeonatoEstado.activo,
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
                return const AppLoading(message: 'Cargando campeonatos...');
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
                      AppHeroCard(
                        title: 'Deportes UPSA',
                        description:
                            'Consulta campeonatos activos, fixtures, resultados, tablas de posiciones y ranking de goleadores desde un solo lugar.',
                        chips: const [
                          AppHeroChipData(
                            icon: Icons.school_outlined,
                            text: 'UPSA',
                          ),
                          AppHeroChipData(
                            icon: Icons.sports_soccer,
                            text: 'Fútbol y futsal',
                          ),
                          AppHeroChipData(
                            icon: Icons.public_outlined,
                            text: 'Vista pública',
                          ),
                        ],
                        infoItems: [
                          AppHeroInfoItem(
                            icon: Icons.emoji_events_outlined,
                            label: 'Campeonatos',
                            value: '${campeonatos.length}',
                          ),
                          AppHeroInfoItem(
                            icon: Icons.verified_outlined,
                            label: 'Activos',
                            value:
                                '${campeonatos.where((item) => item.estado == CampeonatoEstado.activo).length}',
                          ),
                        ],
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
          Text('Buscar campeonato', style: AppTextStyles.heading3),
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
              AppFilterPill(
                text: 'Todos',
                selected: filter == _ChampionshipFilter.todos,
                onTap: () => onFilterChanged(_ChampionshipFilter.todos),
              ),
              AppFilterPill(
                text: 'Inscripción',
                selected: filter == _ChampionshipFilter.inscripcion,
                onTap: () => onFilterChanged(_ChampionshipFilter.inscripcion),
              ),
              AppFilterPill(
                text: 'Activo',
                selected: filter == _ChampionshipFilter.activo,
                onTap: () => onFilterChanged(_ChampionshipFilter.activo),
              ),
              AppFilterPill(
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
