// "Liga + final" y "Liga + playoffs": se juega la liga, se activa la
// fase eliminatoria y la final (o los playoffs) se arma con los mejores
// de la tabla. Antes estos formatos quedaban a medias: la fase final se
// cargaba a mano y, si se cargaba, sus puntos se sumaban a la liga.

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/equipo_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/utils/clasificacion.dart';
import 'package:futsal/utils/tabla_calculo.dart';

CampeonatoModel _liga({
  String tipo = TipoCampeonato.ligaFinal,
  String fase = FaseCampeonato.grupos,
  int playoffs = 0,
}) {
  return CampeonatoModel.fromMap('camp-1', {
    'nombre': 'Liga de prueba',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': tipo,
    'estado': CampeonatoEstado.activo,
    'faseActual': fase,
    'configuracion': {
      'formato': tipo,
      'permiteEmpate': true,
      'clasificadosPlayoffs': playoffs,
    },
  });
}

EquipoModel _equipo(String id) {
  return EquipoModel(
    id: id,
    nombre: id,
    representante: 'rep',
    estado: EquipoEstado.activo,
    cantidadJugadoresRegistrados: 6,
    creadoPor: 'test',
    actualizadoPor: 'test',
  );
}

PartidoModel _jugado(
  String local,
  String visitante,
  int gl,
  int gv, {
  bool sistema = true,
  String? ronda,
  int? llave,
}) {
  return PartidoModel.fromMap('p-$local-$visitante-${ronda ?? ''}', {
    'jornada': 1,
    'vuelta': 1,
    'equipoLocalId': local,
    'equipoLocalNombre': local,
    'equipoVisitanteId': visitante,
    'equipoVisitanteNombre': visitante,
    'estado': PartidoEstado.finalizado,
    'golesLocal': gl,
    'golesVisitante': gv,
    'resultadoRegistrado': true,
    'empate': gl == gv,
    'generadoPorSistema': sistema,
    'tipoResultado': TipoResultado.normal,
    'rondaLlave': ronda,
    'llave': llave,
  });
}

void main() {
  final equipos = ['a', 'b', 'c', 'd'].map(_equipo).toList();

  // a 6 pts; b y c 3 pts, pero c va segundo por diferencia de goles
  // (+1 contra 0); d 0.
  final liga = [
    _jugado('a', 'b', 2, 0),
    _jugado('a', 'c', 1, 0),
    _jugado('b', 'd', 3, 1),
    _jugado('c', 'd', 2, 0),
  ];

  test('es un formato de dos fases, sin grupos', () {
    final campeonato = _liga();
    expect(campeonato.tieneFasesSeparadas, isTrue);
    expect(campeonato.usaGrupos, isFalse);
    expect(campeonato.nombreFaseRegular, 'Fase de liga');
    expect(campeonato.debeRestringirCrucesAlGrupo, isFalse);
  });

  test('la final no suma puntos a la tabla de la liga', () {
    final campeonato = _liga(fase: FaseCampeonato.eliminatoria);
    final finalJugada = _jugado('b', 'a', 5, 0, ronda: 'final', llave: 1);

    expect(campeonato.esDeFaseFinal(finalJugada), isTrue);
    expect(campeonato.esDeFaseFinal(liga.first), isFalse);

    final tabla = TablaCalculo.calcular(
      campeonato: campeonato,
      equipos: equipos,
      partidos: [...liga, finalJugada],
    );
    final puntos = {for (final fila in tabla) fila.equipoId: fila.puntos};

    expect(puntos['a'], 6);
    expect(puntos['b'], 3);
  });

  test('a la final van los 2 mejores de la tabla', () {
    final campeonato = _liga();
    final tabla = TablaCalculo.calcular(
      campeonato: campeonato,
      equipos: equipos,
      partidos: liga,
    );

    final clasificados = Clasificacion.paraCampeonato(
      campeonato: campeonato,
      tabla: tabla,
    );

    expect(clasificados.map((c) => c.equipo.equipoId).toList(), ['a', 'c']);
    expect(clasificados.every((c) => c.deLiga), isTrue);
  });

  test('a los playoffs van los N configurados', () {
    final campeonato = _liga(tipo: TipoCampeonato.ligaPlayoffs, playoffs: 4);
    final tabla = TablaCalculo.calcular(
      campeonato: campeonato,
      equipos: equipos,
      partidos: liga,
    );

    final clasificados = Clasificacion.paraCampeonato(
      campeonato: campeonato,
      tabla: tabla,
    );

    expect(clasificados, hasLength(4));
    expect(clasificados.first.equipo.equipoId, 'a');
    expect(clasificados.last.equipo.equipoId, 'd');
  });

  test('en la eliminatoria un empate exige ganador', () {
    final campeonato = _liga(fase: FaseCampeonato.eliminatoria);
    final finalEmpatada = _jugado('a', 'b', 1, 1, ronda: 'final', llave: 1);

    expect(campeonato.requiereGanador(finalEmpatada), isTrue);
    expect(campeonato.requiereGanador(liga.first), isFalse);
  });
}
