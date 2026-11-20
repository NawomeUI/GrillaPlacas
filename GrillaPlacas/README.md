# GrillaPlacas

Grilla de placas enemigas para World of Warcraft 3.3.5a.

Sirve para pegarle a varios bichos sin cambiar de objetivo. Te muestra una
grilla con todos los enemigos que tienen placa visible, con su vida y tus DoTs,
y podes castear sobre cualquiera pasando el mouse por encima.

Pensado para brujos, sacerdotes sombra, druidas y cualquier clase que tenga que
mantener DoTs en varios objetivos a la vez.

---

## 1. Requisito: el parche del cliente

GrillaPlacas **no funciona con un cliente 3.3.5a de fabrica**. Necesita
AwesomeWotlk, un parche que le agrega al juego la capacidad de identificar cada
placa enemiga por separado.

Hace falta la **version 39 o superior**. Las anteriores no traen el registro de
tokens y el casteo sobre las celdas no engancha.

### Instalacion del parche

Todo lo que necesitas esta en la carpeta `1-PARCHE-CLIENTE` de este paquete.

1. **Cerra el juego.**
2. Guarda una copia de tu `AwesomeWotlkLib.dll` actual si ya tenias una.
3. Copia a la raiz de tu carpeta del juego, donde esta el `Wow.exe`:
   - `AwesomeWotlkLib.dll`
   - `skia.dll`
   - `AwesomeWotlkPatch.exe`
4. Copia la carpeta `Interface\AddOns\AwesomeCVar` a tu `Interface\AddOns`.
5. **Arrastra tu `Wow.exe` sobre `AwesomeWotlkPatch.exe`.** Esto hace dos cosas:
   engancha la DLL al ejecutable y le activa el modo LAA, que le permite usar
   hasta 4 GB de memoria en vez de 2.

### El paso 5 no es opcional

Si tu cliente no esta parcheado con LAA, el juego se te va a cerrar solo con un
error de memoria. El mensaje tipico es:

```
No hay suficientes recursos de memoria disponibles para procesar este comando.
File: .\MapObjRead.cpp
```

Eso pasa aunque te sobre RAM. Es el limite de 2 GB de los programas de 32 bits.
La version 39 del parche ocupa bastante mas memoria que las viejas, asi que si
tenes muchos addons lo vas a tocar seguro.

### Como verificar que quedo bien

Entra al juego y escribi:

```
/grilla test
```

Tiene que decir `UnitTokenFromGUID: si`. Si dice que no, la DLL no se cargo o
es vieja.

Si preferis bajar el parche de la fuente original en vez de usar el de este
paquete: https://github.com/noname08662/awesome_wotlk/releases

---

## 2. Instalacion del addon

Extrae la carpeta `GrillaPlacas` de `2-ADDON` dentro de tu
`Interface\AddOns`.

Te tiene que quedar asi:

```
Interface\AddOns\GrillaPlacas\GrillaPlacas.toc
```

Activa las placas enemigas en el juego con la tecla **V**.

---

## 3. Arranque rapido

Tres pasos y ya esta andando.

1. Escribi `/grilla` para abrir el panel.
2. Pestana **Grilla**, elegi un preset: Lista, Dos columnas o Compacto.
3. Pestana **Teclas**, boton **Escanear barras**.

Listo. Pasa el mouse por una celda de la grilla y apreta tus teclas de siempre.
El hechizo va al bicho que tengas debajo del cursor. Con el mouse en el aire,
las teclas funcionan exactamente como antes.

---

## 4. Las dos formas de castear sobre la grilla

En la pestana **Teclas**, abajo del todo, elegis como manda el hechizo.

### Targetear y volver (el que viene por defecto)

El addon targetea lo que tengas bajo el mouse, aprieta tu propio boton de la
barra y vuelve al objetivo anterior.

```
/target [@mouseover,harm,nodead]
/click BT4Button7
/targetlasttarget [@mouseover,harm,nodead]
```

Ventaja: **anda con cualquier cosa**. Hechizos, macros, items, habilidades de
mascota, y con cualquier addon de barras, porque nunca mira que hay adentro del
slot. Es el modo recomendado.

Precio: el objetivo parpadea un instante. Para DoTs no importa, porque el
objetivo queda fijado al empezar el casteo.

### Castear directo

El addon identifica que hechizo tenes en cada tecla y lo lanza al mouseover sin
tocar tu objetivo.

```
/cast [@mouseover,harm,nodead] Immolate
/stopmacro [@mouseover,harm,nodead]
/click BT4Button7
```

Ventaja: no toca tu objetivo en ningun momento.

Precio: depende de identificar bien el hechizo, y eso no es confiable en todos
los clientes 3.3.5a. Si ves hechizos equivocados en la lista, usa el otro modo.

### Si preferis macros a mano

No hace falta nada de esto. Podes dejar las teclas desactivadas y usar macros
comunes:

```
/cast [@mouseover] Corruption
```

La grilla funciona igual como destino de mouseover.

---

## 5. El panel

`/grilla` abre el panel. Tiene cuatro pestanas.

### Grilla

Tres presets y despues deslizadores para afinar: cuantas celdas mostrar,
columnas, ancho, alto, separacion y escala. Al costado te dice **cuantos pixeles
ocupa la grilla en pantalla**, asi la dejas del tamano que te entre.

| Preset | Celda | Columnas | Ocupa |
|---|---|---|---|
| Lista | 180x30 | 1 | 182 x 396 |
| Dos columnas | 150x46 | 2 | 304 x 288 |
| Compacto | 110x42 | 3 | 336 x 176 |

Tambien estan las opciones de mostrar solo en combate, solo enemigos, y el boton
para mover la grilla de lugar.

### Aspecto

- Tamano de letra
- Cuantos DoTs mostrar por celda
- Tamano de icono, con 0 = automatico. Al lado te dice de cuantos pixeles
  quedaron y en cuantas filas, y te avisa en rojo si quedan muy chicos
- Donde van los iconos: dentro de la celda, afuera a la derecha, o abajo
  pisando la esquina
- A que porcentaje restante el icono se pone en rojo avisando que el DoT se
  vence
- Barra de vida roja fija o con gradiente verde a rojo
- Mostrar el porcentaje de vida
- Con que hechizo medir el fuera de rango

### Teclas

El mouseover por tecla. Check para prender y apagar, boton para escanear las
barras, y la lista de lo que agarro con el icono de cada hechizo y de que boton
salio.

Si alguna esta mal, la cruz la saca y **no vuelve en el proximo escaneo**. Si te
arrepentis, boton **Levantar vetos**.

Tambien podes agregar teclas a mano con los dos campos de arriba.

### Clicks

Que hace cada click del mouse sobre una celda, y el modo de casteo del click.
Podes poner un hechizo, `target`, `focus`, o una macro empezando con `/`.

---

## 6. Comandos

```
/grilla                      abre el panel
/grilla estilo 1|2|3         presets de aspecto
/grilla iconos dentro|fuera|abajo
/grilla auto [on|off|borrar] mouseover por tecla
/grilla teclas [escaneo|off|restaurar]
/grilla tecla <clave> <hechizo|borrar>
/grilla modoteclas hechizo|objetivo
/grilla bind <clave> <hechizo|target|focus|/macro|borrar>
/grilla binds
/grilla modo spell|macro|tcast
/grilla rango <hechizo>
/grilla mover
/grilla tokens N
/grilla test                 diagnostico
/grilla volcar               guarda un diagnostico completo a disco
/grilla reset
```

---

## 7. Si algo no anda

### El juego se cierra con error de memoria

No parcheaste el exe con LAA. Arrastra `Wow.exe` sobre `AwesomeWotlkPatch.exe`.
Mira la seccion 1.

### La grilla no muestra nada

- Activa las placas enemigas con **V**
- `/grilla test` tiene que decir `UnitTokenFromGUID: si`
- Fijate que `nameplateShowEnemies` este en 1 y que haya bichos a la vista

### El casteo no sale al pasar el mouse

- Fijate que el check **Activado** de la pestana Teclas este tildado
- Corre **Escanear barras** de nuevo. Si moviste hechizos de lugar en la barra,
  hay que reescanear
- Proba el modo **Targetear y volver**, que no depende de identificar el hechizo

### Aparecen hechizos que no corresponden

Es el modo Castear directo fallando al identificar el contenido del slot. Dos
salidas: pasarte a **Targetear y volver**, o sacar las que esten mal con la cruz
y agregar a mano las que quieras.

### Apreto Enter en el chat y no manda el mensaje

No es el teclado. Cuando un comando de chat de cualquier addon tira un error de
Lua, el juego aborta el envio del mensaje y parece que Enter no responde.
Instala BugSack y BugGrabber: el ultimo error te dice que addon fue.

### En combate no me deja cambiar cosas

Es una restriccion del juego, no del addon. Los bindeos y el rearmado de la
grilla no se pueden tocar en combate. El addon lo deja pendiente y lo aplica
solo cuando salis.

---

## 8. Detalles que conviene saber

El mouseover vale para cualquier cosa hostil debajo del cursor, no solo la
grilla. Es lo mismo que haria una macro `[@mouseover]` comun.

Una celda agarra su lugar y no se mueve hasta que el bicho muere o sale de
pantalla, asi no te baila el objetivo bajo el dedo mientras clickeas.

Los ajustes de aspecto se guardan por cuenta. Las teclas y los clicks, por
personaje.

El addon lee tus bindeos desde adentro del juego. No toca tus macros, no toca
tus bindeos y no escribe nada fuera de su propio archivo de configuracion.
