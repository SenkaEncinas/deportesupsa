import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_model.dart';
import '../models/campeonato_model.dart';
import '../services/auth_service.dart';
import '../services/public_home_service.dart';
import 'campeonato_form_screen.dart';
import 'campeonatos_screen.dart';
import 'championship_detail_screen.dart';
import 'detalle_campeonato_screen.dart';
import 'home_screen.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_campeonato_card.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/responsive.dart';
import '../utils/mensajes.dart';
import 'reciclaje/app_fondo.dart';

/// Pantalla de inicio del administrador.
///
/// Muestra los números generales y los campeonatos en curso, con acceso
/// directo a cada uno. Antes tenía cuatro botones que llevaban al mismo
/// listado ("Gestionar campeonatos" en el encabezado, en el banner, en
/// una tarjeta de "Acciones rápidas" y en cada campeonato), y ninguno
/// abría el campeonato que se tocaba.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AuthService _authService = AuthService();
  final PublicHomeService _publicHomeService = PublicHomeService();

  // Los streams se crean una sola vez y no dentro de build(): si se
  // reconstruyen en cada build, cada setState (una tecla en un
  // buscador, por ejemplo) genera una suscripción nueva, el
  // StreamBuilder vuelve a "waiting" y la pantalla entera se
  // reemplaza por el loading, perdiendo el foco del campo.
  late final Stream<List<CampeonatoModel>> _campeonatosStream =
      _publicHomeService.streamCampeonatosPublicos();

  Future<AdminModel?>? _adminFuture;

  @override
  void initState() {
    super.initState();
    // En Windows desktop el token puede no estar propagado al entrar a
    // esta pantalla: se espera el primer evento de authStateChanges que
    // confirme el usuario antes de consultar Firestore.
    _adminFuture = FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user != null)
        .then((_) => _authService.getAdminActual());
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    AppSnackbars.info(context, 'Sesión cerrada.');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _abrir(Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppFondo(
      child: FutureBuilder<AdminModel?>(
        future: _adminFuture,
        builder: (context, adminSnapshot) {
          final admin = adminSnapshot.data;

          return StreamBuilder<List<CampeonatoModel>>(
            stream: _campeonatosStream,
            builder: (context, campeonatoSnapshot) {
              final campeonatos = campeonatoSnapshot.data ?? [];

              if (campeonatoSnapshot.connectionState ==
                      ConnectionState.waiting &&
                  campeonatos.isEmpty) {
                return const AppLoading(
                  message: 'Cargando panel administrativo...',
                );
              }

              if (campeonatoSnapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'No se pudo cargar el panel',
                  message: mensajeDeError(campeonatoSnapshot.error!),
                );
              }

              // Los finalizados no se gestionan día a día: el panel
              // muestra lo que está en curso y el resto queda en el
              // listado completo.
              final enCurso = campeonatos
                  .where((c) => c.estado != CampeonatoEstado.finalizado)
                  .toList();

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Panel administrativo',
                  subtitle: admin == null
                      ? 'Gestión de campeonatos universitarios.'
                      : 'Hola, ${admin.nombre}.',
                  actions: [
                    AppButton.secondary(
                      text: isMobile ? 'Pública' : 'Ver página pública',
                      icon: Icons.visibility_outlined,
                      onPressed: () => _abrir(const HomeScreen()),
                    ),
                    AppButton.danger(
                      text: isMobile ? 'Salir' : 'Cerrar sesión',
                      icon: Icons.logout,
                      onPressed: _logout,
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeroCard(
                        title: 'Campeonatos UPSA',
                        description:
                            'Entra a un campeonato para cargar equipos, programar el fixture y registrar resultados.',
                        side: _AccionesHero(
                          onNuevo: () => _abrir(const CampeonatoFormScreen()),
                          onVerTodos: () => _abrir(const CampeonatosScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppCampeonatosStats(campeonatos: campeonatos),
                      const SizedBox(height: 24),
                      AppSectionHeader(
                        title: 'Campeonatos en curso',
                        subtitle: campeonatos.length > enCurso.length
                            ? 'Los finalizados están en "Ver todos".'
                            : 'Toca uno para administrarlo.',
                      ),
                      const SizedBox(height: 14),
                      if (enCurso.isEmpty)
                        AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'No hay campeonatos en curso',
                          message:
                              'Crea un campeonato para empezar a registrar equipos, fixture y resultados.',
                          buttonText: 'Crear campeonato',
                          onPressed: () => _abrir(const CampeonatoFormScreen()),
                        )
                      else
                        AppResponsiveGrid(
                          mobileColumns: 1,
                          tabletColumns: 2,
                          desktopColumns: 3,
                          spacing: 16,
                          children: enCurso.map((campeonato) {
                            return AppCampeonatoCard(
                              admin: true,
                              campeonato: campeonato,
                              onTap: () => _abrir(
                                DetalleCampeonatoScreen(
                                  campeonatoId: campeonato.id,
                                ),
                              ),
                              onVerPublico: () => _abrir(
                                ChampionshipDetailScreen(
                                  campeonato: campeonato,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 30),
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

/// Las dos acciones generales del panel, dentro del banner: crear un
/// campeonato nuevo o ir al listado completo (con los finalizados y el
/// buscador).
class _AccionesHero extends StatelessWidget {
  final VoidCallback onNuevo;
  final VoidCallback onVerTodos;

  const _AccionesHero({required this.onNuevo, required this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.isMobile(context) ? double.infinity : 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.secondary(
            text: 'Nuevo campeonato',
            icon: Icons.add_rounded,
            expanded: true,
            onPressed: onNuevo,
          ),
          const SizedBox(height: 10),
          // Blanco también: un botón "ghost" (texto gris sin fondo) no
          // se lee sobre el verde del banner.
          AppButton.secondary(
            text: 'Ver todos los campeonatos',
            icon: Icons.list_alt_rounded,
            expanded: true,
            onPressed: onVerTodos,
          ),
        ],
      ),
    );
  }
}
