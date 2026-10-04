import 'dart:async';

/// Una consulta en vivo que comparten varias partes de una pantalla.
///
/// La fuente se abre una sola vez, con el primer interesado, y cada uno
/// que se suma recibe enseguida el último valor: no vuelve a "cargando"
/// ni abre otra conexión a Firestore. La vista pública abría la lista de
/// partidos cinco veces por separado, y además dentro de `build`, así
/// que cada redibujado las reabría.
///
/// [stream] es siempre el mismo objeto, así que un `StreamBuilder` no se
/// resuscribe al redibujarse. Hay que llamar a [cerrar] al salir.
class StreamCompartido<T> {
  StreamCompartido(this._fuente);

  final Stream<T> Function() _fuente;
  final _oyentes = <MultiStreamController<T>>{};
  StreamSubscription<T>? _sub;
  T? _ultimo;
  var _hayValor = false;

  late final Stream<T> stream = Stream<T>.multi((oyente) {
    if (_hayValor) oyente.add(_ultimo as T);
    _oyentes.add(oyente);
    oyente.onCancel = () => _oyentes.remove(oyente);

    _sub ??= _fuente().listen(
      (valor) {
        _ultimo = valor;
        _hayValor = true;
        for (final o in [..._oyentes]) {
          o.add(valor);
        }
      },
      onError: (Object error, StackTrace pila) {
        for (final o in [..._oyentes]) {
          o.addError(error, pila);
        }
      },
    );
  });

  Future<void> cerrar() async {
    await _sub?.cancel();
    _sub = null;
    for (final o in [..._oyentes]) {
      await o.close();
    }
    _oyentes.clear();
  }
}

/// Combina tres streams: emite cada vez que cambia cualquiera de ellos,
/// una vez que los tres dieron al menos un valor.
///
/// Dart no trae un `combineLatest` y no vale la pena sumar una
/// dependencia por esto.
Stream<R> combinarUltimos3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combinar,
) {
  late final StreamController<R> control;
  final subs = <StreamSubscription<dynamic>>[];

  late A ultimoA;
  late B ultimoB;
  late C ultimoC;
  var hayA = false;
  var hayB = false;
  var hayC = false;

  void emitir() {
    if (hayA && hayB && hayC) {
      control.add(combinar(ultimoA, ultimoB, ultimoC));
    }
  }

  control = StreamController<R>(
    onListen: () {
      subs.add(
        a.listen((valor) {
          ultimoA = valor;
          hayA = true;
          emitir();
        }, onError: control.addError),
      );
      subs.add(
        b.listen((valor) {
          ultimoB = valor;
          hayB = true;
          emitir();
        }, onError: control.addError),
      );
      subs.add(
        c.listen((valor) {
          ultimoC = valor;
          hayC = true;
          emitir();
        }, onError: control.addError),
      );
    },
    onCancel: () async {
      for (final sub in subs) {
        await sub.cancel();
      }
      subs.clear();
    },
  );

  return control.stream;
}
