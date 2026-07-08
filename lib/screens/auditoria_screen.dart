import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/auditoria_model.dart';
import '../models/campeonato_model.dart';
import '../services/campeonato_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';

class AuditoriaScreen extends StatelessWidget {
  final String campeonatoId;

  const AuditoriaScreen({super.key, required this.campeonatoId});

  Stream<List<AuditoriaModel>> _streamAuditoria() {
    return FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('auditoria')
        .orderBy('fecha', descending: true)
        .limit(80)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return AuditoriaModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final campeonatoService = CampeonatoService();

    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: campeonatoService.streamCampeonato(campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<AuditoriaModel>>(
            stream: _streamAuditoria(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando auditoría...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar auditoría',
                  message: snapshot.error.toString(),
                );
              }

              final auditorias = snapshot.data ?? [];

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Auditoría',
                  subtitle: campeonato == null
                      ? 'Historial de acciones administrativas.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                  child: auditorias.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.history,
                          title: 'No hay registros de auditoría',
                          message:
                              'Cuando se registren acciones administrativas, aparecerán aquí.',
                        )
                      : Column(
                          children: auditorias.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Wrap en vez de Row + Spacer: con textos
                                    // largos la fila desbordaba en móvil.
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        AppBadge(
                                          text: item.modulo,
                                          type: AppBadgeType.primary,
                                        ),
                                        AppBadge(
                                          text: item.accion,
                                          type: AppBadgeType.info,
                                        ),
                                        Text(
                                          _fechaTexto(item.fecha),
                                          style: AppTextStyles.small,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item.detalle,
                                      style: AppTextStyles.heading3,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Usuario: ${item.usuarioNombre}',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (item.observacion != null &&
                                        item.observacion!
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          item.observacion!,
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
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
