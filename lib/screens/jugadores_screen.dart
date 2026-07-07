import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/jugador_model.dart';
import '../services/campeonato_service.dart';
import '../services/jugador_service.dart';
import 'jugador_form_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_table_container.dart';
import 'reciclaje/app_text_styles.dart';

class JugadoresScreen extends StatelessWidget {
  final String campeonatoId;

  const JugadoresScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  Widget build(BuildContext context) {
    final campeonatoService = CampeonatoService();
    final jugadorService = JugadorService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<JugadorModel>>(
            stream: jugadorService.streamJugadores(campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando jugadores...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar jugadores',
                  message: snapshot.error.toString(),
                );
              }

              final jugadores = snapshot.data ?? [];

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Jugadores',
                  subtitle: campeonato == null
                      ? 'Jugadores registrados.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (campeonato?.estado != CampeonatoEstado.finalizado)
                      AppButton.primary(
                        text: 'Nuevo jugador',
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JugadorFormScreen(
                                campeonatoId: campeonatoId,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                  child: jugadores.isEmpty
                      ? AppEmptyState(
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'No hay jugadores registrados',
                          message:
                              'Registra jugadores con código de estudiante y nombre completo.',
                          buttonText:
                              campeonato?.estado == CampeonatoEstado.finalizado
                                  ? null
                                  : 'Registrar jugador',
                          onPressed:
                              campeonato?.estado == CampeonatoEstado.finalizado
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => JugadorFormScreen(
                                            campeonatoId: campeonatoId,
                                          ),
                                        ),
                                      );
                                    },
                        )
                      : AppTableContainer(
                          headers: const [
                            'Código',
                            'Nombre',
                            'Equipo',
                            'Estado',
                            'Acción',
                          ],
                          rows: jugadores.map((jugador) {
                            return [
                              Text(jugador.codigoEstudiante),
                              Text(jugador.nombreCompleto),
                              Text(jugador.equipoNombre),
                              AppBadge(
                                text: jugador.estado,
                                type: AppBadge.typeFromEstado(jugador.estado),
                              ),
                              TextButton(
                                onPressed: campeonato?.estado ==
                                        CampeonatoEstado.finalizado
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JugadorFormScreen(
                                              campeonatoId: campeonatoId,
                                              jugador: jugador,
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Editar',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ];
                          }).toList(),
                          emptyMessage: 'No hay jugadores registrados.',
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