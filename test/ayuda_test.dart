// La ayuda del administrador: que las guías estén bien armadas y que
// cada paso de cada guía se vea sin desbordes en todos los anchos.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/ayuda/ayuda_modelo.dart';

import 'fuente_real.dart';
import 'package:futsal/ayuda/centro_ayuda.dart';

const _anchos = <String, Size>{
  '320 px': Size(320, 640),
  '390 px': Size(390, 844),
  'tablet': Size(768, 1024),
  'desktop': Size(1280, 900),
};

/// El contenedor donde vive la ayuda: pantalla completa en el celular y
/// diálogo de hasta 560 px en pantallas grandes.
Widget _app(Size size, Widget hijo) {
  final completa = size.width < 600;
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: completa ? size.width : 560,
            maxHeight: completa ? size.height : size.height * 0.9,
          ),
          child: Material(child: hijo),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(cargarFuenteReal);

  group('Las guías están bien armadas', () {
    test('ids sin repetir', () {
      final ids = todasLasGuias.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('entre 3 y 6 pasos por guía', () {
      for (final guia in todasLasGuias) {
        expect(guia.pasos.length, inInclusiveRange(3, 6), reason: guia.id);
      }
    });

    test('cada guía tiene algún rol y alguna pantalla', () {
      for (final guia in todasLasGuias) {
        expect(guia.roles, isNotEmpty, reason: guia.id);
        expect(guia.pantallas, isNotEmpty, reason: guia.id);
      }
    });

    test('el último paso de cada guía es "¡Listo!"', () {
      for (final guia in todasLasGuias) {
        expect(guia.pasos.last.titulo, '¡Listo!', reason: guia.id);
      }
    });

    test('cada pantalla del admin tiene sus guías', () {
      for (final pantalla in PantallaAyuda.values) {
        expect(
          guiasDe(pantalla, RolAyuda.admin),
          isNotEmpty,
          reason: pantalla.name,
        );
      }
    });

    test('un rol solo ve las guías que le corresponden', () {
      for (final rol in RolAyuda.values) {
        for (final guia in guiasPara(rol)) {
          expect(guia.roles, contains(rol), reason: guia.id);
        }
        for (final pantalla in PantallaAyuda.values) {
          for (final guia in guiasDe(pantalla, rol)) {
            expect(guia.roles, contains(rol), reason: guia.id);
          }
        }
      }
    });
  });

  group('Centro de ayuda sin desbordes', () {
    for (final ancho in _anchos.entries) {
      testWidgets('lista de guías en ${ancho.key}', (tester) async {
        tester.view.physicalSize = ancho.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            ancho.value,
            const CentroAyuda(pantalla: PantallaAyuda.resultados),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('¿Qué querés hacer?'), findsOneWidget);
        expect(find.text('EN ESTA PANTALLA'), findsOneWidget);
      });
    }
  });

  group('Cada paso de cada guía, sin desbordes', () {
    for (final ancho in _anchos.entries) {
      testWidgets('en ${ancho.key}', (tester) async {
        tester.view.physicalSize = ancho.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final desbordes = <String>[];
        for (final guia in guiasPara(RolAyuda.admin)) {
          for (var i = 0; i < guia.pasos.length; i++) {
            await tester.pumpWidget(
              _app(
                ancho.value,
                ReproductorGuia(
                  key: ValueKey('${guia.id}-$i'),
                  guia: guia,
                  pasoInicial: i,
                  onVolver: () {},
                  onCerrar: () {},
                  onIrAPantalla: () {},
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));

            // Se juntan todos para ver la lista completa de una vez.
            final error = tester.takeException();
            if (error != null) {
              desbordes.add('${guia.id} paso ${i + 1}: $error');
            }
          }
        }

        expect(desbordes, isEmpty, reason: desbordes.join(' | '));
      });
    }
  });

  testWidgets('las flechas del teclado avanzan y retroceden', (tester) async {
    final guia = todasLasGuias.first;
    await tester.pumpWidget(
      _app(
        const Size(1280, 900),
        ReproductorGuia(guia: guia, onVolver: () {}, onCerrar: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('PASO 1 DE ${guia.pasos.length}'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PASO 2 DE ${guia.pasos.length}'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PASO 1 DE ${guia.pasos.length}'), findsOneWidget);
  });
}
