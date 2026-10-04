import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Lista desplegable con su etiqueta arriba, como el resto de los campos
/// de los formularios. Estaba copiada en cuatro formularios con pequeñas
/// diferencias; esta reúne lo de todas.
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  /// Si es obligatorio elegir algo antes de guardar.
  final bool requerido;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.requerido = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          // Sin esto un texto largo (un nombre de equipo, por ejemplo)
          // empuja la flecha fuera del campo.
          isExpanded: true,
          onChanged: enabled ? onChanged : null,
          decoration: const InputDecoration(),
          style: AppTextStyles.body,
          dropdownColor: AppColors.surface,
          validator: requerido
              ? (valor) => valor == null ? 'Selecciona una opción.' : null
              : null,
        ),
      ],
    );
  }
}

/// Título de una sección dentro de un formulario: un punto verde, el
/// título y una línea de ayuda.
class AppFormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppFormSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
