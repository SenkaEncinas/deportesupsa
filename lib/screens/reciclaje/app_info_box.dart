import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tono del recuadro: `info` (celeste) para explicaciones y avisos,
/// `primary` (verde) para confirmar lo que se está por hacer.
enum AppInfoBoxTone { info, primary }

/// Recuadro de ayuda con ícono y texto: "qué hace este formato", "por
/// qué este botón está bloqueado", etc.
///
/// Estaba copiado en cuatro pantallas con pequeñas diferencias de
/// padding y color; ahora todas usan este.
class AppInfoBox extends StatelessWidget {
  final String text;

  /// Si se pasa, va en negrita delante del texto ("Formato: ...").
  final String? title;
  final IconData? icon;
  final AppInfoBoxTone tone;

  const AppInfoBox({
    super.key,
    required this.text,
    this.title,
    this.icon,
    this.tone = AppInfoBoxTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final esInfo = tone == AppInfoBoxTone.info;
    final fondo = esInfo ? AppColors.infoLight : AppColors.primaryLight;
    final acento = esInfo ? AppColors.info : AppColors.primary;
    final textoColor = esInfo ? AppColors.info : AppColors.primaryDark;

    final estilo = AppTextStyles.body.copyWith(
      color: textoColor,
      fontWeight: FontWeight.w600,
      height: 1.45,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: acento.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? (esInfo ? Icons.info_outline : Icons.verified_outlined),
            color: acento,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: title == null
                ? Text(text, style: estilo)
                : Text.rich(
                    TextSpan(
                      style: estilo,
                      children: [
                        TextSpan(
                          text: '$title: ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: text),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
