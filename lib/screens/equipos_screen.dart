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
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/responsive.dart';

class EquiposScreen extends StatelessWidget {
  final String campeonatoId;

  const EquiposScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    final equipoService = EquipoService();
    final campeonatoService = CampeonatoService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<EquipoModel>>(
            stream: equipoService.streamEquipos(campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(
                  message: 'Cargando equipos...',
                );
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar equipos',
                  message: snapshot.error.toString(),
                );
              }

              final equipos = snapshot.data ?? [];

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
                                campeonatoId: campeonatoId,
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
                                            campeonatoId: campeonatoId,
                                          ),
                                        ),
                                      );
                                    },
                        )
                      : _EquiposGrid(
                          campeonatoId: campeonatoId,
                          campeonato: campeonato,
                          equipos: equipos,
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
    final columns = Responsive.gridColumns(context);

    return GridView.builder(
      itemCount: equipos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: Responsive.isMobile(context) ? 1.25 : 1.35,
      ),
      itemBuilder: (context, index) {
        final equipo = equipos[index];

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
              const Spacer(),
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
      },
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
        Icon(
          icon,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w700,
          ),
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