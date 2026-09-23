// Verifica que los logos del pie público sean realmente clicables y que
// cada uno abra la dirección que le corresponde.
//
// Se reemplaza la plataforma de url_launcher por una falsa que anota qué
// se intentó abrir, así el test no depende de que haya un navegador.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/screens/reciclaje/app_public_footer.dart';
import 'package:futsal/utils/patrocinadores_assets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _LanzadorFalso extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> abiertos = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    abiertos.add(url);
    return true;
  }
}

/// Envuelve el pie en un scroll para que entre en la pantalla del test
/// sin desbordar.
Widget _app() {
  return const MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: AppPublicFooter())),
  );
}

void main() {
  late _LanzadorFalso lanzador;

  setUp(() {
    lanzador = _LanzadorFalso();
    UrlLauncherPlatform.instance = lanzador;
  });

  testWidgets('el crédito de 57 Nations abre su sitio', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final credito = find.byTooltip('Ir al sitio de 57 Nations');
    expect(
      credito,
      findsOneWidget,
      reason: 'el crédito tiene que ser un enlace',
    );

    await tester.tap(credito, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(lanzador.abiertos, ['https://nations-2b049.web.app']);
  });

  // La franja de auspiciantes se arma leyendo el manifiesto de assets,
  // que en un widget test viene vacío: por eso el logo de EM no se puede
  // tocar acá y su enlace se verifica sobre el mapeo, que es la parte
  // que puede romperse al renombrar un archivo.
  test('el logo de EM Business Group tiene su sitio cargado', () {
    expect(
      PatrocinadoresAssets.sitioDe(
        'assets/images/patrocinadores/principal/em_business_group.png',
      ),
      'https://www.embusinessgroup.com',
    );
  });

  test('los auspiciantes sin sitio cargado no llevan a ningún lado', () {
    expect(
      PatrocinadoresAssets.sitioDe('assets/images/patrocinadores/1_revive.png'),
      isNull,
    );
    expect(
      PatrocinadoresAssets.sitioDe(
        'assets/images/patrocinadores/principal/pedidosya.png',
      ),
      isNull,
    );
  });
}
