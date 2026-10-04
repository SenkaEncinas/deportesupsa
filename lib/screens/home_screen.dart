import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../services/public_home_service.dart';
import 'championship_detail_screen.dart';
import 'login_screen.dart';
import 'reciclaje/app_buscador_campeonatos.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_public_footer.dart';
import 'reciclaje/app_campeonato_card.dart';
import 'reciclaje/responsive.dart';
import '../utils/mensajes.dart';
import 'reciclaje/app_fondo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PublicHomeService _service = PublicHomeService();
  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<List<CampeonatoModel>> _campeonatosStream = _service
      .streamCampeonatosPublicos();

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
              title: 'No se pudo cargar la información',
              message: mensajeDeError(snapshot.error!),
            );
          }

          final campeonatos = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                AppPage(
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
                            text: 'Fútbol, vóley y básquet',
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
                      AppBuscadorCampeonatos(
                        campeonatos: campeonatos,
                        titulo: 'Campeonatos disponibles',
                        subtitulo: campeonatos.isEmpty
                            ? 'Aún no hay campeonatos creados.'
                            : 'Selecciona un campeonato para ver su información pública.',
                        vacio: const AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'Todavía no hay campeonatos',
                          message:
                              'Cuando un administrador cree un campeonato, se mostrará aquí la información pública.',
                        ),
                        itemBuilder: (campeonato) => AppCampeonatoCard(
                          campeonato: campeonato,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChampionshipDetailScreen(
                                campeonato: campeonato,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const AppPublicFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}
