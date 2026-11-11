import 'package:flutter/material.dart';

import '../../utils/fixture_grouping.dart';
import 'app_button.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Lo que eligió el admin: cuántos pasan directo por grupo y cuántos
/// mejores terceros entran a la fase final.
class ClasificacionResult {
  final int clasificanPorGrupo;
  final int mejoresTerceros;

  const ClasificacionResult({
    required this.clasificanPorGrupo,
    required this.mejoresTerceros,
  });

  int total(int grupos) => grupos * clasificanPorGrupo + mejoresTerceros;
}

/// Pide "clasifican por grupo" y "mejores terceros", con el total y la
/// ronda inicial calculados en vivo.
///
/// Lo usan "Editar clasificación" (Grupos) y "Agregar fase eliminatoria"
/// (Fixture), para que las dos validen y expliquen lo mismo.
class ClasificacionDialog extends StatefulWidget {
  final int grupos;
  final int clasificanInicial;
  final int tercerosInicial;
  final String titulo;
  final String descripcion;
  final String textoConfirmar;

  const ClasificacionDialog({
    super.key,
    required this.grupos,
    required this.clasificanInicial,
    required this.tercerosInicial,
    required this.titulo,
    required this.descripcion,
    this.textoConfirmar = 'Guardar',
  });

  @override
  State<ClasificacionDialog> createState() => _ClasificacionDialogState();
}

class _ClasificacionDialogState extends State<ClasificacionDialog> {
  late final TextEditingController _clasificanController =
      TextEditingController(text: '${widget.clasificanInicial}');
  late final TextEditingController _tercerosController = TextEditingController(
    text: '${widget.tercerosInicial}',
  );

  @override
  void dispose() {
    _clasificanController.dispose();
    _tercerosController.dispose();
    super.dispose();
  }

  int get _clasifican => int.tryParse(_clasificanController.text.trim()) ?? 0;
  int get _terceros => int.tryParse(_tercerosController.text.trim()) ?? 0;

  /// Mismo criterio que el servicio, para no dejar confirmar algo que
  /// después va a rechazar.
  String? get _error {
    if (_clasifican <= 0) return 'Debe clasificar al menos 1 por grupo.';
    if (_terceros < 0) return 'Los mejores terceros no pueden ser negativos.';
    if (_terceros > widget.grupos) {
      return 'Como mucho ${widget.grupos} mejores terceros (uno por grupo).';
    }
    if (widget.grupos * _clasifican + _terceros < 2) {
      return 'Define al menos 2 equipos clasificados.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = widget.grupos;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.titulo, style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.descripcion,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _clasificanController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Clasifican por grupo',
                  prefixIcon: Icon(Icons.military_tech_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _tercerosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mejores terceros',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: Listenable.merge([
                  _clasificanController,
                  _tercerosController,
                ]),
                builder: (context, _) {
                  final error = _error;
                  final total = grupos * _clasifican + _terceros;
                  final cuadra =
                      error == null && FixtureGrouping.esPotenciaDeDos(total);
                  final color = cuadra ? AppColors.success : AppColors.warning;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cuadra
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error ??
                          (cuadra
                              ? '$total equipos clasifican · arranca en ${FixtureGrouping.rondaSegunEquipos(total).toLowerCase()}.'
                              : '$total equipos clasifican, pero eso no arma una llave pareja (2, 4, 8, 16, 32). Se puede igual: las primeras rondas se arman a mano.'),
                      style: AppTextStyles.body.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([
            _clasificanController,
            _tercerosController,
          ]),
          builder: (context, _) => AppButton.primary(
            text: widget.textoConfirmar,
            onPressed: _error != null
                ? null
                : () => Navigator.pop(
                    context,
                    ClasificacionResult(
                      clasificanPorGrupo: _clasifican,
                      mejoresTerceros: _terceros,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
