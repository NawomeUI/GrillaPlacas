# El parche del cliente (AwesomeWotLK v39)

Esta todo en la carpeta `awesome-wotlk-v39` de este repositorio. GrillaPlacas
no funciona sin el.

El parche **no es mio**: es de noname08662. Lo que hay aca es la release **v39**
tal cual, sin tocar, publicada el 02/11/2026 en
https://github.com/noname08662/awesome_wotlk/releases

| Archivo | Tamano | Para que |
|---|---|---|
| `AwesomeWotlkLib.dll` | 2.312.192 | El parche. Agrega los tokens de placa que usa GrillaPlacas |
| `skia.dll` | 2.833.920 | Lo necesita la DLL de arriba. Sin esto se rompen las fuentes |
| `AwesomeWotlkPatch.exe` | 404.480 | Engancha la DLL al Wow.exe y le activa el modo LAA (4 GB) |
| `Interface\AddOns\AwesomeCVar` | — | Panel para configurar las opciones del parche |

---

## Si Chrome te bloquea la descarga

Es normal y es esperable. Chrome muestra **"Este archivo es peligroso"** y no
deja bajar el ZIP.

**No encontro un virus.** Lo que pasa es que el ZIP tiene un `.exe` y dos
`.dll` sin firma digital, y viene de un repositorio nuevo que casi nadie
descargo todavia. Esa combinacion dispara el bloqueo sola, sin mirar el
contenido. Ademas el `AwesomeWotlkPatch.exe` inyecta una DLL en el `Wow.exe`,
que es exactamente lo que hace, y es lo que los antivirus clasifican como
*hacktool* o *riskware*. Cualquier parche de cliente de WoW da lo mismo.

### Como bajarlo igual

Probar en este orden, lo primero que funcione:

1. Abrir `chrome://downloads`, buscar el archivo bloqueado, y en los tres
   puntitos de esa fila elegir **Conservar** o **Conservar archivo peligroso**.
2. Si no aparece esa opcion: Configuracion -> Privacidad y seguridad ->
   Seguridad, pasar de **Proteccion mejorada** a **Proteccion estandar**,
   bajar el archivo, y despues volver a dejarlo como estaba.
3. O bajarlo con otro navegador. Firefox no lo bloquea.
4. O bajar el parche directo de la pagina del autor, que es la misma release:
   https://github.com/noname08662/awesome_wotlk/releases

### Como verificar que es lo que tiene que ser

SHA256 de los tres archivos:

```
1757530bc304894258a8491ac104ae78d06fc1473568e1c21ec18b1f4f0a577c  AwesomeWotlkLib.dll
ef23addd3f27c748f5ef07608da2c71c3551454debdcb8d4d40141b6e9a057d4  skia.dll
661c4b7684cc4a0757d1604dcd0f1a31fe3ace8b55906aedc32fe3a5ef5d89c1  AwesomeWotlkPatch.exe
```

En PowerShell, parado en la carpeta donde los descomprimiste:

```
Get-FileHash .\AwesomeWotlkLib.dll -Algorithm SHA256
```

Esos hashes tambien se pueden pegar en https://virustotal.com, solapa
**Search**, sin subir ningun archivo, y te muestra que dice cada antivirus de
ese archivo exacto.

---

## Instalacion

1. **Cerra el juego.**
2. Copia a la carpeta donde esta tu `Wow.exe`: `AwesomeWotlkLib.dll`,
   `skia.dll` y `AwesomeWotlkPatch.exe`.
3. Copia `awesome-wotlk-v39\Interface\AddOns\AwesomeCVar` a tu
   `Interface\AddOns`.
4. **Arrastra tu `Wow.exe` encima de `AwesomeWotlkPatch.exe`.**
5. Entra al juego y escribi `/grilla test`. Tiene que decir
   `UnitTokenFromGUID: si`.

El paso 4 no es opcional: sin eso el `Wow.exe` queda limitado a 2 GB de
memoria y se cae con `MapObjRead.cpp:391` o "No hay suficientes recursos de
memoria".
