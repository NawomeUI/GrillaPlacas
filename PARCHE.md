# El parche del cliente (AwesomeWotLK v39)

GrillaPlacas no funciona sin el. El parche **no es mio**: es de
noname08662 y se baja de su repositorio.

> **Por que no viene incluido aca.** Antes lo traia esta misma carpeta, pero
> el parche son dos DLL y un .exe que inyecta codigo en el `Wow.exe`. Un ZIP
> con binarios sin firmar hace que Chrome bloquee la descarga entera con
> "Este archivo es peligroso", y el addon se volvia imposible de repartir.
> Ahora este repositorio es solo texto (Lua y Markdown) y el parche se baja
> del original, que es ademas de donde conviene bajarlo siempre.

## De donde

https://github.com/noname08662/awesome_wotlk/releases

GrillaPlacas necesita **v39 o superior**.

## Que trae la v39

| Archivo | Tamano | Para que |
|---|---|---|
| `AwesomeWotlkLib.dll` | 2.312.192 | El parche. Agrega los tokens de placa que usa GrillaPlacas |
| `skia.dll` | 2.833.920 | Lo necesita la DLL de arriba. Sin esto se rompen las fuentes |
| `AwesomeWotlkPatch.exe` | 404.480 | Engancha la DLL al Wow.exe y le activa el modo LAA (4 GB) |
| `Interface\AddOns\AwesomeCVar` | — | Panel para configurar las opciones del parche |

## Para verificar que bajaste lo mismo que probe yo

SHA256 de los tres archivos de la v39:

```
1757530bc304894258a8491ac104ae78d06fc1473568e1c21ec18b1f4f0a577c  AwesomeWotlkLib.dll
ef23addd3f27c748f5ef07608da2c71c3551454debdcb8d4d40141b6e9a057d4  skia.dll
661c4b7684cc4a0757d1604dcd0f1a31fe3ace8b55906aedc32fe3a5ef5d89c1  AwesomeWotlkPatch.exe
```

En PowerShell, parado en la carpeta donde los descomprimiste:

```
Get-FileHash .\AwesomeWotlkLib.dll -Algorithm SHA256
Get-FileHash .\skia.dll -Algorithm SHA256
Get-FileHash .\AwesomeWotlkPatch.exe -Algorithm SHA256
```

Si te da distinto, no lo uses: o bajaste otra version o el archivo no es el
original.

Esos hashes tambien se pueden pegar directo en https://virustotal.com sin
subir nada, en la solapa **Search**, y te muestra que dice cada antivirus de
ese archivo exacto. Es normal que algunos marquen el `.exe` como
*hacktool* o *riskware*: inyecta una DLL en otro proceso, que es
literalmente lo que hace, y es lo mismo que hace cualquier parche de
cliente de WoW.

## Instalacion

1. Descomprimi la release en la carpeta del juego, al lado del `Wow.exe`.
2. Corre `AwesomeWotlkPatch.exe` **una vez**. Engancha la DLL y activa el
   modo LAA.
3. Entra al juego y escribi `/grilla test`. Tiene que decir
   `UnitTokenFromGUID: si`.

El paso 2 no es opcional: sin eso el `Wow.exe` queda limitado a 2 GB de
memoria y se cae con `MapObjRead.cpp:391` o "No hay suficientes recursos de
memoria".
