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
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            AppButton.ghost(
              text: cancelText,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              text: confirmText,
              variant: danger
                  ? AppButtonVariant.danger
                  : AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Confirmación que además pide un motivo (queda en la auditoría).
  /// Devuelve el motivo, o null si se canceló.
  static Future<String?> pedirMotivo({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    bool danger = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _MotivoDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        danger: danger,
      ),
    );
  }
}

class _MotivoDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final bool danger;

  const _MotivoDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.danger,
  });

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valido = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.title, style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ejemplo: se cargó el marcador al revés.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton(
          text: widget.confirmText,
          variant: widget.danger
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: valido
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
        ),
      ],
    );
  }
}
