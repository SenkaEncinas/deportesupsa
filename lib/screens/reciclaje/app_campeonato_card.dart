import 'package:flutter/material.dart';

import '../../models/campeonato_model.dart';
import '../../utils/etiquetas.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_colors.dart';
import 'app_fase_badge.dart';
import 'app_match_card.dart';
import 'app_responsive_grid.dart';
import 'app_text_styles.dart';
import 'responsive.dart';
import 'stat_card.dart';

/// Tarjeta de un campeonato: la usan la portada pública, el panel del
/// administrador y el listado de campeonatos.
///
/// Había dos copias casi iguales (la pública y la del admin) que solo
/// cambiaban en el pie. Ahora es una sola: con [admin] en true el pie
/// trae el botón "Administrar" (y "Ver público" si se pasa
/// [onVerPublico]); si no, el enlace "Ver campeonato".
class AppCampeonatoCard extends StatelessWidget {
  final CampeonatoModel campeonato;
  final VoidCallback onTap;
  final bool admin;
  final VoidCallback? onVerPublico;

  const AppCampeonatoCard({
    super.key,
    required this.campeonato,
    required this.onTap,
    this.admin = false,
    this.onVerPublico,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = campeonato.descripcion.trim();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  deporteIcono(campeonato.deporteEfectivo),
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
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
                text: Etiquetas.estadoCampeonato(campeonato.estado),
                type: AppBadge.tipoEstadoCampeonato(campeonato.estado),
              ),
              AppBadge(
                text: Etiquetas.modalidad(campeonato.modalidad),
                type: AppBadgeType.primary,
              ),
              if (campeonato.estado == CampeonatoEstado.activo)
                AppFaseBadge(campeonato: campeonato),
            ],
          ),
          // El público ve un texto de ayuda si no hay descripción; el
          // admin no lo necesita.
          if (descripcion.isNotEmpty || !admin) ...[
            const SizedBox(height: 14),
            Text(
              descripcion.isEmpty
                  ? 'Consulta fixture, resultados, tabla de posiciones y ranking de goleadores.'
                  : descripcion,
              maxLines: admin ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
            text: Etiquetas.tipoCampeonato(campeonato.tipoCampeonato),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_outlined,
            text: campeonato.cancha.trim().isEmpty
                ? 'Cancha no definida'
                : campeonato.cancha,
          ),
          const SizedBox(height: 16),
          if (admin)
            _AccionesAdmin(onAdministrar: onTap, onVerPublico: onVerPublico)
          else
            Row(
              children: [
                Text(
                  'Ver campeonato',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccionesAdmin extends StatelessWidget {
  final VoidCallback onAdministrar;
  final VoidCallback? onVerPublico;

  const _AccionesAdmin({required this.onAdministrar, this.onVerPublico});

  @override
  Widget build(BuildContext context) {
    final administrar = AppButton.primary(
      text: 'Administrar',
      icon: Icons.settings_outlined,
      expanded: true,
      onPressed: onAdministrar,
    );

    final verPublico = onVerPublico;
    if (verPublico == null) return administrar;

    final publico = AppButton.secondary(
      text: 'Ver público',
      icon: Icons.visibility_outlined,
      expanded: true,
      onPressed: verPublico,
    );

    if (Responsive.isMobile(context)) {
      return Column(
        children: [administrar, const SizedBox(height: 10), publico],
      );
    }

    return Row(
      children: [
        Expanded(child: administrar),
        const SizedBox(width: 10),
        Expanded(child: publico),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Cuántos campeonatos hay en cada estado. Lo usan el panel y el
/// listado; el panel contaba un estado "próximamente" que no existe, así
/// que esa tarjeta siempre decía 0 en vez de mostrar los de inscripción.
class AppCampeonatosStats extends StatelessWidget {
  final List<CampeonatoModel> campeonatos;

  const AppCampeonatosStats({super.key, required this.campeonatos});

  int _contar(String estado) =>
      campeonatos.where((campeonato) => campeonato.estado == estado).length;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: 14,
      children: [
        StatCard(
          title: 'Total',
          value: '${campeonatos.length}',
          icon: Icons.emoji_events_outlined,
          subtitle: 'Campeonatos',
          color: AppColors.primary,
        ),
        StatCard(
          title: 'Activos',
          value: '${_contar(CampeonatoEstado.activo)}',
          icon: Icons.verified_outlined,
          subtitle: 'En competencia',
          color: AppColors.success,
        ),
        StatCard(
          title: 'Inscripción',
          value: '${_contar(CampeonatoEstado.inscripcion)}',
          icon: Icons.how_to_reg_outlined,
          subtitle: 'Recibiendo equipos',
          color: AppColors.info,
        ),
        StatCard(
          title: 'Finalizados',
          value: '${_contar(CampeonatoEstado.finalizado)}',
          icon: Icons.flag_outlined,
          subtitle: 'Cerrados',
          color: AppColors.secondary,
        ),
      ],
    );
  }
}
