# Apuntes

Cosas pendientes y decisiones que conviene no olvidar.

## Sacar antes de entregar

- **Número de versión del pie público.** Vive en
  `lib/utils/version_build.dart` y se muestra chiquito en la esquina
  inferior derecha del footer. Está sólo para saber, mirando el sitio,
  si Netlify ya sirvió el último deploy o si el navegador está con caché
  vieja. Para sacarlo: borrar ese archivo y el bloque `_VersionDiscreta`
  de `lib/screens/reciclaje/app_public_footer.dart`.

  El número se sube a mano en cada cambio que se despliega.

## Reglas de puntaje por deporte

Están en `ReglasPuntuacion` (`lib/models/campeonato_model.dart`) y las
aplica `reglasPuntuacionEfectivas`.

| Deporte | Victoria | Empate | Derrota |
|---|---|---|---|
| Fútbol / futsal | 3 | 1 | 0 |
| Vóley | 2 | — | 1 |
| Básquet | 2 | — | 1 |

En vóley y básquet no hay empates, y las reglas las fija el deporte: no
se leen de lo que tenga guardado el campeonato. Los campeonatos creados
antes de que esto existiera quedaron con las de fútbol (3/1/0) y por eso
mostraban 9 puntos donde correspondían 6.

### Walkover (no presentarse) y sanciones

| Deporte | Marcador | Diferencia | Puntos del que no se presentó |
|---|---|---|---|
| Vóley | 25-0 por set | +50 | 0 |
| Básquet | 20-0 | +20 | 0 |
| Fútbol | el que cargue el admin | según marcador | 0 |

El punto por perder (vóley y básquet) es por presentarse y jugar, así
que el que no se presenta no lo cobra.

En vóley los 50 puntos salen de `setsParaGanar × puntosSetNormal`: si
algún campeonato se configura con otros valores, la cuenta los sigue.

## La tabla se calcula, no se lee

`tabla_posiciones` **no es la fuente de verdad**. La tabla la arma
`TablaCalculo.calcular()` (`lib/utils/tabla_calculo.dart`), que es una
función pura, y `PublicHomeService.streamTabla()` la recalcula en vivo
cada vez que cambia el campeonato, un equipo o un partido.

La colección se sigue escribiendo al registrar un resultado, pero queda
como registro histórico. **No agregar pantallas que lean directamente de
ahí**: van a mostrar números viejos.

Esto fue un bug real: durante varios días la tabla mostró 9 y 6 puntos
en vóley porque la copia guardada databa de antes del cambio de reglas y
nada la había vuelto a escribir.

## Cómo se arman las llaves

La regla está en `lib/utils/llaves.dart`: en **todas** las rondas, la
llave `i` se cruza con la llave `n + 1 - i`.

```
Octavos:   1-16, 2-15, 3-14, 4-13, 5-12, 6-11, 7-10, 8-9
Cuartos:   L1-L8, L2-L7, L3-L6, L4-L5
Semis:     L1-L4, L2-L3
Final:     L1-L2
```

Así el 1° y el 2° de la tabla sólo se pueden cruzar en la final. El
cuadro se genera completo de una (todas las rondas, esperando al ganador
de cada llave) y los ganadores avanzan solos al cargar cada resultado.

El orden de dibujo no es el mismo que el número de llave: se reordena
para que los conectores no se crucen y para que el 1 quede arriba de
todo y el 2 abajo de todo.

## Desempate

Cuando dos equipos empatan en puntos, el orden lo define la **diferencia
de puntos**, después los puntos a favor y después los puntos en contra.

En fútbol y básquet da igual: los puntos a favor son el marcador. En
vóley no, y ahí está el detalle — `golesFavor` son los **sets** ganados
y `puntosFavor` los **puntos** de cada set. El desempate mira los
puntos, que es lo que hace que un walkover (50-0) pese de verdad; si
mirara sets, valdría +2 y los 50 no servirían para nada.

Esto se equivocó una vez: los dos comparadores (el de la tabla y el de
la siembra) usaban diferencia de sets, y en vóley damas eso movía 8 de
las 12 posiciones de la llave.

## Orden de los clasificados

`Clasificacion.calcular()` ordena por bloques: primero todos los 1ros de
grupo entre sí, después todos los 2dos, y al final los mejores terceros.

Consecuencia a tener presente: **un 1° de grupo nunca queda debajo de un
2°, aunque tenga menos puntos** (por ejemplo si jugó menos partidos). Si
alguna vez se quiere ordenar puramente por puntos, hay que cambiar esa
función.

## Firestore

Las reglas permiten **lectura pública** y exigen sesión de admin para
escribir. Para diagnosticar datos alcanza con un script de Node usando
el SDK web y la config de `lib/firebase_options.dart`; para corregirlos
hay que hacerlo desde la app con un admin logueado.
