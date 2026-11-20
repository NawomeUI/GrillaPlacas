# De donde sale este parche

Los archivos de esta carpeta **no son mios**. Son la release **v39** de
AwesomeWotLK, de noname08662, publicada el 02/11/2026.

Repositorio original y releases:
https://github.com/noname08662/awesome_wotlk/releases

Estan incluidos aca para que la instalacion de GrillaPlacas sea un solo
paso, porque el addon no funciona sin ellos. Las licencias de los
componentes de terceros que usa el parche estan en `licenses/`.

Si queres la version mas nueva, bajala siempre del repositorio original.
GrillaPlacas necesita **v39 o superior**.

## Que es cada archivo

| Archivo | Para que |
|---|---|
| `AwesomeWotlkLib.dll` | El parche. Agrega los tokens de placa que usa GrillaPlacas |
| `skia.dll` | Lo necesita la DLL de arriba. Sin esto se rompen las fuentes |
| `AwesomeWotlkPatch.exe` | Engancha la DLL al Wow.exe y le activa el modo LAA (4 GB) |
| `Interface/AddOns/AwesomeCVar` | Panel para configurar las opciones del parche |
