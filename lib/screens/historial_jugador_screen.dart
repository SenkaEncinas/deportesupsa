import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/historial_cambio_model.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_text_styles.dart';

class HistorialJugadorScreen extends StatelessWidget {
  final String campeonatoId;
  final String jugadorId;
  final String jugadorNombre;

  const HistorialJugadorScreen({
    super.key,
    required this.campeonatoId,
    required this.jugadorId,
    required this.jugadorNombre,
  });

  Stream<List<HistorialCambioModel>> _streamHistorial() {
    return FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(campeonatoId)
        .collection('jugadores')
        .doc(jugadorId)
        .collection('historial_cambios')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return HistorialCambioModel.fromMap(doc.id, doc.data());
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

  String _mapText(Map<String, dynamic> data) {
    if (data.isEmpty) return 'Sin datos';

    return data.entries.map((entry) {
      return '${entry.key}: ${entry.value}';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<HistorialCambioModel>>(
        stream: _streamHistorial(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando historial...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar historial',
              message: snapshot.error.toString(),
            );
          }

          final historial = snapshot.data ?? [];

          return SingleChildScrollView(
            child: AppPage(
              title: 'Historial del jugador',
              subtitle: jugadorNombre,
              actions: [
                AppButton.secondary(
                  text: 'Volver',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              child: historial.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.history,
                      title: 'Sin cambios registrados',
                      message:
                          'Este jugador todavía no tiene historial de cambios.',
                    )
                  : Column(
                      children: historial.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppBadge(
                                      text: item.accion,
                                      type: AppBadgeType.info,
                                    ),
                                    const Spacer(),
                                    Text(
                                      _fechaTexto(item.fecha),
                                      style: AppTextStyles.small,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Observación',
                                  style: AppTextStyles.heading3,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.observacion,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Datos anteriores',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _mapText(item.datosAnteriores),
                                  style: AppTextStyles.small,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Datos nuevos',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _mapText(item.datosNuevos),
                                  style: AppTextStyles.small,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Usuario: ${item.usuarioNombre}',
                                  style: AppTextStyles.small,
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
      ),
    );
  }
}