import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import 'equipo_form_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_inline_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';

class EquiposScreen extends StatefulWidget {
  final String campeonatoId;

  const EquiposScreen({super.key, required this.campeonatoId});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EquipoModel> _filtrar(List<EquipoModel> equipos) {
    final search = _search.trim().toLowerCase();
    if (search.isEmpty) return equipos;

    return equipos.where((equipo) {
      final searchable = [
        equipo.nombre,
        equipo.representante,
        equipo.carrera ?? '',
        equipo.facultad ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final equipoService = EquipoService();
    final campeonatoService = CampeonatoService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<EquipoModel>>(
            stream: equipoService.streamEquipos(widget.campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando equipos...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar equipos',
                  message: snapshot.error.toString(),
                );
              }

              final equipos = snapshot.data ?? [];
              final filtrados = _filtrar(equipos);

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Equipos',
                  subtitle: campeonato == null
                      ? 'Registro de equipos del campeonato.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (campeonato?.estado != CampeonatoEstado.finalizado)
                      AppButton.primary(
                        text: 'Nuevo equipo',
                        icon: Icons.add,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipoFormScreen(
                                campeonatoId: widget.campeonatoId,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                  child: equipos.isEmpty
                      ? AppEmptyState(
                          icon: Icons.groups_2_outlined,
                          title: 'No hay equipos registrados',
                          message:
                              'Registra los equipos participantes para poder cargar jugadores y generar el fixture.',
                          buttonText:
                              campeonato?.estado == CampeonatoEstado.finalizado
                              ? null
                              : 'Registrar equipo',
                          onPressed:
                              campeonato?.estado == CampeonatoEstado.finalizado
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EquipoFormScreen(
                                        campeonatoId: widget.campeonatoId,
                                      ),
                                    ),
                                  );
                                },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Buscar equipo',
                              hint:
                                  'Nombre, representante, carrera o facultad...',
                              controller: _searchController,
                              prefixIcon: Icons.search_rounded,
                              onChanged: (value) {
                                setState(() => _search = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (filtrados.isEmpty)
                              const AppInlineEmptyState(
                                icon: Icons.search_off_rounded,
                                text:
                                    'No hay equipos que coincidan con la búsqueda.',
                              )
                            else
                              _EquiposGrid(
                                campeonatoId: widget.campeonatoId,
                                campeonato: campeonato,
                                equipos: filtrados,
                              ),
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

class _EquiposGrid extends StatelessWidget {
  final String campeonatoId;
  final CampeonatoModel? campeonato;
  final List<EquipoModel> equipos;

  const _EquiposGrid({
    required this.campeonatoId,
    required this.campeonato,
    required this.equipos,
  });

  @override
  Widget build(BuildContext context) {
    // AppResponsiveGrid (Wrap + LayoutBuilder) deja que cada card tome su
    // altura natural: se reemplazó el GridView con childAspectRatio rígido
    // que cortaba el contenido en móvil.
    return AppResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      spacing: 14,
      children: equipos.map((equipo) {
        return AppCard(
          onTap: campeonato?.estado == CampeonatoEstado.finalizado
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipoFormScreen(
                        campeonatoId: campeonatoId,
                        equipo: equipo,
                      ),
                    ),
                  );
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBadge(
                text: equipo.estado,
                type: AppBadge.typeFromEstado(equipo.estado),
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 14),
              Text(
                equipo.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                'Representante: ${equipo.representante}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              _InfoLine(
                icon: Icons.school_outlined,
                label: 'Carrera',
                value: equipo.carrera ?? 'No aplica',
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: Icons.account_balance_outlined,
                label: 'Facultad',
                value: equipo.facultad ?? 'No aplica',
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: Icons.groups_2_outlined,
                label: 'Jugadores',
                value: '${equipo.cantidadJugadoresRegistrados}',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small,
          ),
        ),
      ],
    );
  }
}
