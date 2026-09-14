import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// Logos de patrocinadores que se descubren solos desde los assets.
///
/// La convención es la misma que usa el PDF (ver `PdfService`): lo que se
/// deje en `assets/images/patrocinadores/principal/` es el auspiciador
/// principal y se muestra aparte, más grande; el resto va en la tira.
/// El orden lo da el nombre del archivo, por eso van numerados.
///
/// Se cachea: el manifiesto no cambia en tiempo de ejecución y el footer
/// aparece en varias pantallas, no tiene sentido releerlo cada vez.
class PatrocinadoresAssets {
  PatrocinadoresAssets._();

  static const String _dir = 'assets/images/patrocinadores/';
  static const String _dirPrincipal = 'assets/images/patrocinadores/principal/';

  static Future<PatrocinadoresLogos>? _cache;

  static Future<PatrocinadoresLogos> cargar() {
    return _cache ??= _leerManifiesto();
  }

  static Future<PatrocinadoresLogos> _leerManifiesto() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      final principal =
          assets
              .where(
                (ruta) => ruta.startsWith(_dirPrincipal) && _esImagen(ruta),
              )
              .toList()
            ..sort();

      final resto = assets.where((ruta) {
        if (!ruta.startsWith(_dir) || !_esImagen(ruta)) return false;
        // Sin bajar a subcarpetas: ahí vive el principal.
        return !ruta.substring(_dir.length).contains('/');
      }).toList()..sort();

      return PatrocinadoresLogos(principal: principal, secundarios: resto);
    } catch (_) {
      // Si el manifiesto no se puede leer, el footer simplemente no
      // muestra la franja en vez de romper la pantalla.
      return const PatrocinadoresLogos(principal: [], secundarios: []);
    }
  }

  static bool _esImagen(String ruta) {
    final minuscula = ruta.toLowerCase();
    return minuscula.endsWith('.png') ||
        minuscula.endsWith('.jpg') ||
        minuscula.endsWith('.jpeg');
  }
}

class PatrocinadoresLogos {
  final List<String> principal;
  final List<String> secundarios;

  const PatrocinadoresLogos({
    required this.principal,
    required this.secundarios,
  });

  bool get hayAlguno => principal.isNotEmpty || secundarios.isNotEmpty;
}
