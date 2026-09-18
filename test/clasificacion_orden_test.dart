import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/tabla_posicion_model.dart';
import 'package:futsal/utils/clasificacion.dart';

TablaPosicionModel _fila({
  required String nombre,
  required String grupo,
  required int posicion,
  required int puntos,
  int dif = 0,
  int gf = 0,
}) {
  return TablaPosicionModel(
    equipoId: nombre,
    equipoNombre: nombre,
    grupoId: grupo,
    partidosJugados: 3,
    partidosGanados: 0,
    partidosEmpatados: 0,
    partidosPerdidos: 0,
    golesFavor: gf,
    golesContra: gf - dif,
    diferenciaGoles: dif,
    puntos: puntos,
    posicion: posicion,
  );
}

void main() {
  test('la tabla general va por bloques: 1ros, 2dos y mejores terceros', () {
    final tabla = [
      // Grupo A
      _fila(nombre: 'A1', grupo: 'Grupo A', posicion: 1, puntos: 9, dif: 5),
      _fila(nombre: 'A2', grupo: 'Grupo A', posicion: 2, puntos: 6, dif: 2),
      _fila(nombre: 'A3', grupo: 'Grupo A', posicion: 3, puntos: 4, dif: 1),
      // Grupo B
      _fila(nombre: 'B1', grupo: 'Grupo B', posicion: 1, puntos: 7, dif: 3),
      _fila(nombre: 'B2', grupo: 'Grupo B', posicion: 2, puntos: 7, dif: 4),
      _fila(nombre: 'B3', grupo: 'Grupo B', posicion: 3, puntos: 5, dif: 0),
      // Grupo C
      _fila(nombre: 'C1', grupo: 'Grupo C', posicion: 1, puntos: 12, dif: 9),
      _fila(nombre: 'C2', grupo: 'Grupo C', posicion: 2, puntos: 3, dif: -2),
      _fila(nombre: 'C3', grupo: 'Grupo C', posicion: 3, puntos: 4, dif: 6),
    ];

    final clasificados = Clasificacion.calcular(
      tabla: tabla,
      clasificanPorGrupo: 2,
      mejoresTerceros: 2,
    );

    expect(clasificados.map((c) => c.equipo.equipoNombre).toList(), [
      // Primeros, ordenados entre sí por puntos.
      'C1', 'A1', 'B1',
      // Segundos. B2 antes que un 1ro nunca, aunque empate en puntos
      // con B1: el bloque manda.
      'B2', 'A2', 'C2',
      // Mejores terceros: B3 por puntos, y entre A3 y C3 (ambos 4 pts)
      // gana C3 por diferencia.
      'B3', 'C3',
    ]);

    // Los dos últimos son los que entraron por repechaje.
    expect(clasificados.where((c) => c.porMejorTercero).length, 2);

    // El puesto de origen queda registrado para poder etiquetar bloques.
    expect(clasificados.first.posicionEnGrupo, 1);
    expect(clasificados[3].posicionEnGrupo, 2);
  });

  test('sin mejores terceros solo entran los del corte directo', () {
    final tabla = [
      _fila(nombre: 'A1', grupo: 'Grupo A', posicion: 1, puntos: 9),
      _fila(nombre: 'A2', grupo: 'Grupo A', posicion: 2, puntos: 6),
      _fila(nombre: 'B1', grupo: 'Grupo B', posicion: 1, puntos: 7),
      _fila(nombre: 'B2', grupo: 'Grupo B', posicion: 2, puntos: 8),
    ];

    final clasificados = Clasificacion.calcular(
      tabla: tabla,
      clasificanPorGrupo: 1,
      mejoresTerceros: 0,
    );

    // Solo los primeros, y el de más puntos arriba.
    expect(clasificados.map((c) => c.equipo.equipoNombre).toList(), [
      'A1',
      'B1',
    ]);
  });
}
