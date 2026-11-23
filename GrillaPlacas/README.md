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

Esta todo en la carpeta `awesome-wotlk-v39` de este repositorio.

> **Si Chrome te bloquea el ZIP** con "Este archivo es peligroso": no encontro
> ningun virus, le molesta que el archivo traiga un `.exe` y dos `.dll` sin
> firma digital. En `PARCHE.md` estan los pasos para bajarlo igual y los
> SHA256 para verificar que es lo que tiene que ser.

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

---

## 2. Instalacion del addon

Boton verde **Code -> Download ZIP**. Extrae la carpeta `GrillaPlacas` dentro de tu
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
3. Armate un macro de mouseover por cada DoT (abajo esta el modelo) y poneselo
   a las teclas que ya usas.

Listo. Pasa el mouse por una celda de la grilla, apreta tu tecla y el DoT va a
ese bicho sin que cambies de objetivo.

---

## 4. Como le pegas a las celdas

Hay dos formas, y ninguna de las dos le toca el objetivo.

### Con tus propios macros de mouseover

Es lo mas simple y lo que menos se rompe. Un macro por hechizo, con la forma
de siempre:

```
#showtooltip
/cast [@mouseover,harm,nodead][] Corruption
```

El `[@mouseover,harm,nodead]` manda el hechizo a lo que tengas debajo del
cursor si es un enemigo vivo. El `[]` del final es el que hace que, con el
mouse en el aire, la tecla siga funcionando sobre tu objetivo normal.

Las celdas de la grilla cuentan como mouseover, asi que pasas el mouse por una
celda, apretas tu tecla y el DoT va ahi.

Esto es tuyo, no del addon: la grilla solo es el destino.

### Con clicks sobre la celda

En la pestana **Clicks** le asignas un hechizo a cada boton del mouse (izq,
der, rueda, y las combinaciones con shift, ctrl y alt). De fabrica el click
izquierdo targetea y el derecho pone en foco.

El casteo por click usa la unidad fija de la celda, no el mouseover, asi que no
hay forma de que le pegue a otro bicho.

> **Que paso con el mouseover automatico por teclas.** Hasta la 1.14 el addon
> podia leer tus bindeos y reescribirte las teclas solo, para no tener que
> armar macros. Daba demasiados problemas (en la 1.13 cambiaba el objetivo solo
> y hacia parpadear las barras) y lo saque entero en la 1.15. El addon ya no
> toca tus bindeos, no escribe macros y no usa `/target` en ningun lado. Si
> venis de una version vieja, los datos que habia guardados se borran solos al
> entrar.

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
- Mostrar la marca de banda
- Con que hechizo medir el fuera de rango

### Clicks

Que hace cada click del mouse sobre una celda, y el modo de casteo del click.
Podes poner un hechizo, `target`, `focus`, o una macro empezando con `/`.

---

## 6. Comandos

```
/grilla                      abre el panel
/grilla estilo 1|2|3         presets de aspecto
/grilla iconos dentro|fuera|abajo
/grilla bind <clave> <hechizo|target|focus|/macro|borrar>
/grilla binds
/grilla modo spell|macro
/grilla rango <hechizo>
/grilla mover
/grilla tokens N
/grilla test                 diagnostico
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

- La condicion del macro tiene que ser `[@mouseover,harm,nodead][]`
- El bicho de la celda tiene que estar vivo y ser hostil
- `/grilla test` te dice si la API del parche esta respondiendo

### Se me cambia el objetivo solo

Desde la 1.15 el addon no usa `/target` en ningun lado, asi que no puede ser
el. Fijate si tenes otro addon de placas o de barras con auto-target, o el
`autoSelfCast` / click-to-move del juego.

### Apreto Enter en el chat y no manda el mensaje

No es el teclado. Cuando un comando de chat de cualquier addon tira un error de
Lua, el juego aborta el envio del mensaje y parece que Enter no responde.
Instala BugSack y BugGrabber: el ultimo error te dice que addon fue.

GrillaPlacas no puede causarte esto. Sus comandos estan envueltos de forma que
si algo falla te lo dice por pantalla y el chat sigue funcionando. Si te pasa,
el culpable es otro addon.

### En combate no me deja cambiar cosas

Es una restriccion del juego, no del addon. Los bindeos y el rearmado de la
grilla no se pueden tocar en combate. El addon lo deja pendiente y lo aplica
solo cuando salis.

---

## 8. Detalles que conviene saber

Si el bicho tiene una marca de banda (calavera, cuadrado, luna, lo que sea),
la celda la muestra a la izquierda del nombre y el nombre se corre solo para
no quedar tapado. Se apaga desde la pestana Aspecto.

Una celda agarra su lugar y no se mueve hasta que el bicho muere o sale de
pantalla, asi no te baila el objetivo bajo el dedo mientras clickeas.

Los ajustes de aspecto se guardan por cuenta. Los clicks, por personaje.

El addon no toca tus macros, no toca tus bindeos y no escribe nada fuera de su
propio archivo de configuracion.
