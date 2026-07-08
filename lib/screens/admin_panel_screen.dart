import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_model.dart';
import '../models/campeonato_model.dart';
import '../services/auth_service.dart';
import '../services/public_home_service.dart';
import 'campeonatos_screen.dart';
import 'championship_detail_screen.dart';
import 'home_screen.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_hero_card.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_responsive_grid.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';
import 'reciclaje/championship_public_card.dart';
import 'reciclaje/responsive.dart';
import 'reciclaje/stat_card.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AuthService _authService = AuthService();
  final PublicHomeService _publicHomeService = PublicHomeService();

  Future<AdminModel?>? _adminFuture;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Esperar a que auth esté confirmado antes de consultar Firestore.
    // En Windows desktop el token puede no estar propagado al entrar a esta pantalla,
    // por eso esperamos el primer evento de authStateChanges que confirme el usuario.
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
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  void _openPublicHome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _openCampeonatos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CampeonatosScreen(),
      ),
    );
  }

  void _openPublicDetail(CampeonatoModel campeonato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChampionshipDetailScreen(
          campeonato: campeonato,
        ),
      ),
    );
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
          child: FutureBuilder<AdminModel?>(
            future: _adminFuture,
            builder: (context, adminSnapshot) {
              final admin = adminSnapshot.data;
              final loadingAdmin =
                  adminSnapshot.connectionState == ConnectionState.waiting;

              return StreamBuilder<List<CampeonatoModel>>(
                stream: _publicHomeService.streamCampeonatosPublicos(),
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
                      message: campeonatoSnapshot.error.toString(),
                    );
                  }

                  return SingleChildScrollView(
                    child: AppPage(
                      title: 'Panel administrativo',
                      subtitle: loadingAdmin
                          ? 'Cargando información del administrador...'
                          : admin == null
                              ? 'Gestión de campeonatos universitarios.'
                              : 'Bienvenido, ${admin.nombre}.',
                      actions: [
                        AppButton.secondary(
                          text: isMobile ? 'Pública' : 'Ver pantalla pública',
                          icon: Icons.visibility_outlined,
                          onPressed: _openPublicHome,
                        ),
                        AppButton.primary(
                          text: isMobile ? 'Campeonatos' : 'Gestionar campeonatos',
                          icon: Icons.emoji_events_outlined,
                          onPressed: _openCampeonatos,
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
                            title: loadingAdmin
                                ? 'Cargando...'
                                : admin != null
                                    ? 'Bienvenido, ${admin.nombre}'
                                    : 'Panel Administrativo',
                            description:
                                'Gestiona campeonatos, equipos y resultados desde aquí.',
                            side: _AdminResumeBox(
                              totalCampeonatos: campeonatos.length,
                              onOpenCampeonatos: _openCampeonatos,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _AdminStats(campeonatos: campeonatos),
                          const SizedBox(height: 24),
                          _MainActionCard(
                            onOpenCampeonatos: _openCampeonatos,
                            onOpenPublicHome: _openPublicHome,
                          ),
                          const SizedBox(height: 24),
                          _ChampionshipsAdminSection(
                            campeonatos: campeonatos,
                            onOpenCampeonatos: _openCampeonatos,
                            onOpenPublicDetail: _openPublicDetail,
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
        ),
      ),
    );
  }
}

class _AdminResumeBox extends StatelessWidget {
  final int totalCampeonatos;
  final VoidCallback onOpenCampeonatos;

  const _AdminResumeBox({
    required this.totalCampeonatos,
    required this.onOpenCampeonatos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenCampeonatos,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$totalCampeonatos',
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
            Text(
              'Campeonatos',
              style: AppTextStyles.small.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStats extends StatelessWidget {
  final List<CampeonatoModel> campeonatos;

  const _AdminStats({required this.campeonatos});

  @override
  Widget build(BuildContext context) {
    final activos = campeonatos.where((c) => c.estado == 'activo').length;
    final finalizados = campeonatos.where((c) => c.estado == 'finalizado').length;
    final proximamente = campeonatos.where((c) => c.estado == 'proximamente').length;

    return AppResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: 14,
      children: [
        StatCard(
          icon: Icons.emoji_events_outlined,
          title: 'Total',
          value: '${campeonatos.length}',
          color: AppColors.primary,
        ),
        StatCard(
          icon: Icons.play_circle_outline,
          title: 'Activos',
          value: '$activos',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.schedule_outlined,
          title: 'Próximamente',
          value: '$proximamente',
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.check_circle_outline,
          title: 'Finalizados',
          value: '$finalizados',
          color: Colors.grey,
        ),
      ],
    );
  }
}

class _MainActionCard extends StatelessWidget {
  final VoidCallback onOpenCampeonatos;
  final VoidCallback onOpenPublicHome;

  const _MainActionCard({
    required this.onOpenCampeonatos,
    required this.onOpenPublicHome,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acciones rápidas', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            'Accede directamente a las secciones principales del panel.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton.primary(
                text: 'Gestionar campeonatos',
                icon: Icons.emoji_events_outlined,
                onPressed: onOpenCampeonatos,
              ),
              AppButton.secondary(
                text: 'Ver pantalla pública',
                icon: Icons.visibility_outlined,
                onPressed: onOpenPublicHome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChampionshipsAdminSection extends StatelessWidget {
  final List<CampeonatoModel> campeonatos;
  final VoidCallback onOpenCampeonatos;
  final void Function(CampeonatoModel campeonato) onOpenPublicDetail;

  const _ChampionshipsAdminSection({
    required this.campeonatos,
    required this.onOpenCampeonatos,
    required this.onOpenPublicDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Campeonatos registrados',
          subtitle:
              'Resumen de campeonatos creados. Para editar datos, ingresa al módulo de campeonatos.',
        ),
        const SizedBox(height: 14),
        if (campeonatos.isEmpty)
          AppEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Todavía no hay campeonatos',
            message:
                'Crea el primer campeonato desde el módulo de campeonatos para empezar a registrar equipos, fixture y resultados.',
            buttonText: 'Crear campeonato',
            onPressed: onOpenCampeonatos,
          )
        else
          AppResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: 16,
            children: campeonatos.map((campeonato) {
              return _AdminChampionshipCard(
                campeonato: campeonato,
                onManage: onOpenCampeonatos,
                onViewPublic: () => onOpenPublicDetail(campeonato),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AdminChampionshipCard extends StatelessWidget {
  final CampeonatoModel campeonato;
  final VoidCallback onManage;
  final VoidCallback onViewPublic;

  const _AdminChampionshipCard({
    required this.campeonato,
    required this.onManage,
    required this.onViewPublic,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SportIcon(modalidad: campeonato.modalidad),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  campeonato.nombre.trim().isEmpty
                      ? 'Campeonato sin nombre'
                      : campeonato.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                text: ChampionshipPublicCard.estadoTexto(campeonato.estado),
                type: ChampionshipPublicCard.badgeType(campeonato.estado),
              ),
              AppBadge(
                text: ChampionshipPublicCard.formatLabel(campeonato.modalidad),
                type: AppBadgeType.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            campeonato.descripcion.trim().isEmpty
                ? 'Sin descripción registrada.'
                : campeonato.descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: campeonato.temporada.trim().isEmpty
                ? 'Temporada no definida'
                : campeonato.temporada,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.account_tree_outlined,
            text: ChampionshipPublicCard.formatLabel(
              campeonato.tipoCampeonato,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_outlined,
            text: campeonato.cancha.trim().isEmpty
                ? 'Cancha no definida'
                : campeonato.cancha,
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                AppButton.primary(
                  text: 'Gestionar',
                  icon: Icons.settings_outlined,
                  expanded: true,
                  onPressed: onManage,
                ),
                const SizedBox(height: 10),
                AppButton.secondary(
                  text: 'Ver público',
                  icon: Icons.visibility_outlined,
                  expanded: true,
                  onPressed: onViewPublic,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    text: 'Gestionar',
                    icon: Icons.settings_outlined,
                    expanded: true,
                    onPressed: onManage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton.secondary(
                    text: 'Ver público',
                    icon: Icons.visibility_outlined,
                    expanded: true,
                    onPressed: onViewPublic,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String modalidad;

  const _SportIcon({
    required this.modalidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        modalidad.toLowerCase().contains('fut')
            ? Icons.sports_soccer
            : Icons.emoji_events_outlined,
        color: AppColors.primary,
        size: 25,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textMuted,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}