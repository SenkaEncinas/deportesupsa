// Carga Roboto (la trae el SDK de Flutter) para que los tests midan los
// textos con letras de tamaño real. Sin esto, flutter_test dibuja cada
// letra como un cuadrado de 1 em, casi el doble de ancho que la fuente
// de verdad, y cualquier maqueta parece desbordar.

import 'dart:io';

import 'package:flutter/services.dart';

Future<void> cargarFuenteReal() async {
  final dir = _materialFonts();
  if (dir == null) return;

  final loader = FontLoader('Roboto');
  for (final archivo in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final f = File('${dir.path}/$archivo');
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await loader.load();
}

Directory? _materialFonts() {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  final candidatos = <String>[
    if (raiz != null) '$raiz/bin/cache/artifacts/material_fonts',
  ];
  // Si no está la variable, se sube desde el ejecutable del test.
  var actual = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    candidatos.add('${actual.path}/bin/cache/artifacts/material_fonts');
    candidatos.add('${actual.path}/artifacts/material_fonts');
    actual = actual.parent;
  }
  for (final c in candidatos) {
    final d = Directory(c);
    if (d.existsSync()) return d;
  }
  return null;
}
