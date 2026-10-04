import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/campeonato_service.dart';
import '../utils/mensajes.dart';
import 'campeonato_form_screen.dart';
import 'detalle_campeonato_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_buscador_campeonatos.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_campeonato_card.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_fondo.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/responsive.dart';

/// Listado completo de campeonatos del administrador, con buscador y
/// filtro por estado (incluye los finalizados, que el panel no muestra).
class CampeonatosScreen extends StatefulWidget {
  const CampeonatosScreen({super.key});

  @override
  State<CampeonatosScreen> createState() => _CampeonatosScreenState();
}

class _CampeonatosScreenState extends State<CampeonatosScreen> {
  // El stream se crea una sola vez y no dentro de build(): si se
  // reconstruye en cada build, cada redibujado abre una suscripción
  // nueva y la pantalla vuelve a mostrar el loading.
  late final Stream<List<CampeonatoModel>> _campeonatosStream =
      CampeonatoService().streamCampeonatos();

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppFondo(
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

          return SingleChildScrollView(
            child: AppPage(
              title: 'Campeonatos',
              subtitle: 'Crea, revisa y administra campeonatos universitarios.',
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
                  const AppHeroCard(
                    title: 'Gestión de campeonatos',
                    description:
                        'Crea campeonatos, revisa su estado y entra al detalle para administrar equipos, jugadores, fixture, resultados y documentos.',
                    badges: [
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
                  AppBuscadorCampeonatos(
                    campeonatos: campeonatos,
                    titulo: 'Listado de campeonatos',
                    subtitulo: campeonatos.isEmpty
                        ? 'Todavía no hay campeonatos registrados.'
                        : 'Selecciona un campeonato para administrar equipos, jugadores, fixture y resultados.',
                    vacio: AppEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'No hay campeonatos creados',
                      message:
                          'Crea el primer campeonato para empezar a registrar equipos, jugadores y fixture.',
                      buttonText: 'Crear campeonato',
                      onPressed: _openForm,
                    ),
                    itemBuilder: (campeonato) => AppCampeonatoCard(
                      admin: true,
                      campeonato: campeonato,
                      onTap: () => _openDetalle(campeonato),
                    ),
                  ),
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
