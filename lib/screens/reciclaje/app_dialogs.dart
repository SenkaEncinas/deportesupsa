import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppDialogs {
  AppDialogs._();

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(title, style: AppTextStyles.heading3),
          content: Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            AppButton.ghost(
              text: cancelText,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              text: confirmText,
              variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  static Future<String?> askObservation({
    required BuildContext context,
    required String title,
    String message = 'Ingresa una observación para justificar este cambio.',
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(title, style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ejemplo: corrección por error de registro...',
                ),
              ),
            ],
          ),
          actions: [
            AppButton.ghost(
              text: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
            AppButton.primary(
              text: 'Guardar',
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }
}