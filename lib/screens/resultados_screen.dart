import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/partido_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';
import 'resultado_form_screen.dart';

class ResultadosScreen extends StatelessWidget {
  final String campeonatoId;

  const ResultadosScreen({
    super.key,
    required this.campeonatoId,
  });

  String _resultadoTexto(PartidoModel partido) {
    if (!partido.resultadoRegistrado) return 'Sin resultado';
    return '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}';
  }

  @override
  Widget build(BuildContext context) {
    final campeonatoService = CampeonatoService();
    final partidoService = PartidoService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: partidoService.streamPartidos(campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando partidos...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar partidos',
                  message: snapshot.error.toString(),
                );
              }

              final partidos = snapshot.data ?? [];

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
                          children: partidos.map((partido) {
                            final habilitado =
                                campeonato?.estado == CampeonatoEstado.activo &&
                                    partido.estado !=
                                        PartidoEstado.pendienteProgramacion;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppBadge(
                                            text: partido.estado,
                                            type: AppBadge.typeFromEstado(
                                              partido.estado,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                                            style: AppTextStyles.heading3,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Vuelta ${partido.vuelta} · Jornada ${partido.jornada}',
                                            style: AppTextStyles.small,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _resultadoTexto(partido),
                                      style: AppTextStyles.heading3,
                                    ),
                                    const SizedBox(width: 14),
                                    AppButton.secondary(
                                      text: partido.resultadoRegistrado
                                          ? 'Editar'
                                          : 'Registrar',
                                      icon: Icons.edit_outlined,
                                      onPressed: habilitado
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ResultadoFormScreen(
                                                    campeonatoId: campeonatoId,
                                                    partido: partido,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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