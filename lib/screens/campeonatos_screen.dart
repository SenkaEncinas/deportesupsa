import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/campeonato_service.dart';
import 'campeonato_form_screen.dart';
import 'detalle_campeonato_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_campeonato_admin_card.dart';
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
import 'reciclaje/responsive.dart';
import '../utils/mensajes.dart';

class CampeonatosScreen extends StatefulWidget {
  const CampeonatosScreen({super.key});

  @override
  State<CampeonatosScreen> createState() => _CampeonatosScreenState();
}

enum _CampeonatoFilter { todos, inscripcion, activo, finalizado }

class _CampeonatosScreenState extends State<CampeonatosScreen> {
  final CampeonatoService _service = CampeonatoService();

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<List<CampeonatoModel>> _campeonatosStream = _service
      .streamCampeonatos();
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
      MaterialPageRoute(builder: (_) => const CampeonatoFormScreen()),
    );
  }

  void _openDetalle(CampeonatoModel campeonato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleCampeonatoScreen(campeonatoId: campeonato.id),
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
            stream: _campeonatosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando campeonatos...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar campeonatos',
                  message: mensajeDeError(snapshot.error!),
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
                      text: 'Volver',
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
                      AppHeroCard(
                        title: 'Gestión de campeonatos',
                        description:
                            'Crea campeonatos, revisa su estado y entra al detalle para administrar equipos, jugadores, fixture, resultados y documentos.',
                        badges: const [
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
                      const SizedBox(height: 20),
                      AppCampeonatosStats(campeonatos: campeonatos),
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
                            return AppCampeonatoAdminCard(
                              campeonato: campeonato,
                              onAdministrar: () => _openDetalle(campeonato),
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
          Text('Buscar y filtrar', style: AppTextStyles.heading3),
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
                selected: filter == _CampeonatoFilter.todos,
                onTap: () => onFilterChanged(_CampeonatoFilter.todos),
              ),
              AppFilterPill(
                text: 'Inscripción',
                selected: filter == _CampeonatoFilter.inscripcion,
                onTap: () => onFilterChanged(_CampeonatoFilter.inscripcion),
              ),
              AppFilterPill(
                text: 'Activo',
                selected: filter == _CampeonatoFilter.activo,
                onTap: () => onFilterChanged(_CampeonatoFilter.activo),
              ),
              AppFilterPill(
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
