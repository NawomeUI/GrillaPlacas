-- GrillaPlacas - Teclas
-- Castear sobre la celda que esta bajo el mouse apretando la tecla de siempre,
-- sin escribir ninguna macro a mano. El addon arma la macro y el bindeo solo.
--
-- Como funciona: a cada tecla registrada se le pone un bindeo de override que
-- apunta a un boton seguro con  /cast [@mouseover,harm,nodead][] <hechizo>
-- Si hay algo hostil debajo del mouse, va ahi. Si no, va a tu objetivo normal.
-- O sea que con el mouse en el aire la tecla se comporta igual que antes.

local GP = GrillaPlacas

GP.botonesTecla = {}
GP.duenoBinds = CreateFrame("Frame", "GrillaPlacasBinds", UIParent)

local function nombreSeguro(clave)
	local limpio = string.gsub(clave, "[^%w]", "_")
	return "GrillaPlacasTecla" .. limpio
end

local function botonDe(clave)
	local b = GP.botonesTecla[clave]
	if not b then
		b = CreateFrame("Button", nombreSeguro(clave), UIParent, "SecureActionButtonTemplate")
		b:SetWidth(1)
		b:SetHeight(1)
		b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500)
		b:RegisterForClicks("AnyDown")
		GP.botonesTecla[clave] = b
	end
	return b
end

-- Busca el boton VISIBLE que esta mostrando un slot de accion. Hace falta
-- porque un bindeo puede apuntar a ACTIONBUTTON7 mientras la barra de Blizzard
-- esta oculta por Bartender, y un /click sobre un boton oculto no hace nada.
local PATRONES_BOTON = {
	{ "BT4Button%d", 120 },
	{ "DominosActionButton%d", 120 },
	{ "ActionButton%d", 12 },
	{ "MultiBarBottomLeftButton%d", 12 },
	{ "MultiBarBottomRightButton%d", 12 },
	{ "MultiBarRightButton%d", 12 },
	{ "MultiBarLeftButton%d", 12 },
}

local function esVisible(f)
	return f and f.IsVisible and f:IsVisible()
end

local function botonVisibleDeSlot(slot)
	if not slot then return nil end
	for _, pat in ipairs(PATRONES_BOTON) do
		for i = 1, pat[2] do
			local nom = string.format(pat[1], i)
			local b = _G[nom]
			if b and esVisible(b) then
				local a = b.action or (b.GetAttribute and b:GetAttribute("action"))
				if a == slot then return nom end
			end
		end
	end
	for bar = 1, 10 do
		for bt = 1, 12 do
			local nom = "ElvUI_Bar" .. bar .. "Button" .. bt
			local b = _G[nom]
			if b and esVisible(b) then
				local a = b.action or (b.GetAttribute and b:GetAttribute("action"))
				if a == slot then return nom end
			end
		end
	end
	return nil
end

local function tabla()
	if not GP.pj then return {} end
	GP.pj.teclas = GP.pj.teclas or {}
	return GP.pj.teclas
end

-- Lo que el usuario borra a mano queda vetado, para que el proximo escaneo
-- no se lo vuelva a meter.
local function ignoradas()
	if not GP.pj then return {} end
	GP.pj.teclasIgnoradas = GP.pj.teclasIgnoradas or {}
	return GP.pj.teclasIgnoradas
end

function GP:AplicarTeclas(silencioso)
	if not GP.listo or not GP.pj then return 0 end
	if InCombatLockdown() then
		GP.teclasPendientes = true
		if not silencioso then
			GP:Msg("En combate no se pueden cambiar bindeos. Lo aplico al salir.")
		end
		return 0
	end
	GP.teclasPendientes = nil
	ClearOverrideBindings(GP.duenoBinds)
	if not GP.pj.teclasOn then return 0 end
	local n = 0
	for clave, hechizo in pairs(tabla()) do
		local b = botonDe(clave)
		b:SetAttribute("type", "macro")
		local slot = GP.pj.teclasSlot and GP.pj.teclasSlot[clave]
		local marco = botonVisibleDeSlot(slot)
		if not marco then
			local g = GP.pj.teclasBoton and GP.pj.teclasBoton[clave]
			if g and esVisible(_G[g]) then marco = g end
		end
		if marco then
			-- Castea directo sobre lo que tengas bajo el mouse y nunca toca
			-- tu objetivo. Si no hay nada hostil abajo, clickea tu propio
			-- boton y tu macro corre igual que siempre.
			b:SetAttribute("macrotext",
				"/cast [@mouseover,harm,nodead] " .. hechizo ..
				"\n/stopmacro [@mouseover,harm,nodead]" ..
				"\n/click " .. marco)
		else
			b:SetAttribute("macrotext", "/cast [@mouseover,harm,nodead][] " .. hechizo)
		end
		SetOverrideBindingClick(GP.duenoBinds, true, clave, b:GetName(), "LeftButton")
		n = n + 1
	end
	return n
end

function GP:PonerTecla(clave, hechizo)
	clave = strupper(strtrim(clave or ""))
	hechizo = strtrim(hechizo or "")
	if clave == "" then
		GP:Msg("Falta la tecla. Ej: /grilla tecla 3 Corruption")
		return
	end
	local t = tabla()
	if hechizo == "" or strlower(hechizo) == "borrar" then
		ignoradas()[clave] = true
		if GP.pj.teclasBoton then GP.pj.teclasBoton[clave] = nil end
		if GP.pj.teclasSlot then GP.pj.teclasSlot[clave] = nil end
		if t[clave] then
			t[clave] = nil
			GP:AplicarTeclas()
			GP:Msg("Tecla " .. clave .. " liberada. No vuelve en el proximo escaneo.")
		else
			GP:Msg("La tecla " .. clave .. " no estaba registrada.")
		end
		return
	end
	if not GetSpellInfo(hechizo) then
		GP:Msg("No conozco el hechizo |cffffd100" .. hechizo .. "|r. Escribilo igual que en el libro.")
		return
	end
	ignoradas()[clave] = nil
	t[clave] = hechizo
	GP:AplicarTeclas()
	GP:Msg("Tecla |cffffd100" .. clave .. "|r castea |cffffd100" .. hechizo .. "|r sobre lo que tengas debajo del mouse.")
end

function GP:ListarTeclas()
	local t = tabla()
	local claves = {}
	for k in pairs(t) do claves[#claves + 1] = k end
	table.sort(claves)
	if #claves == 0 then
		GP:Msg("No hay teclas registradas. Usa /grilla auto o /grilla tecla <clave> <hechizo>")
		return
	end
	GP:Msg("teclas con mouseover automatico:")
	for _, k in ipairs(claves) do
		local nom, _, ico = GetSpellInfo(t[k])
		local marca = ""
		if ico then marca = "|T" .. ico .. ":16:16:0:0:64:64:5:59:5:59|t " end
		local origen = ""
		local b = GP.pj.teclasBoton and GP.pj.teclasBoton[k]
		local sl = GP.pj.teclasSlot and GP.pj.teclasSlot[k]
		if b or sl then
			origen = "  |cff888888(" .. tostring(b or "?") .. ", slot " .. tostring(sl or "?") .. ")|r"
		end
		DEFAULT_CHAT_FRAME:AddMessage("   |cffffd100" .. k .. "|r  " .. marca .. (nom or t[k]) .. origen)
	end
end

------------------------------------------------------------------
-- Deteccion automatica desde las barras de accion
------------------------------------------------------------------
-- Botones de barra conocidos. Para cada uno se prueban varios nombres de
-- bindeo, porque cada addon de barras registra el suyo a su manera.
local FAMILIAS = {
	{ nombre = "Blizzard", botones = {
		{ "ActionButton%d",              12, { "ACTIONBUTTON%d" } },
		{ "MultiBarBottomLeftButton%d",  12, { "MULTIACTIONBAR1BUTTON%d" } },
		{ "MultiBarBottomRightButton%d", 12, { "MULTIACTIONBAR2BUTTON%d" } },
		{ "MultiBarRightButton%d",       12, { "MULTIACTIONBAR3BUTTON%d" } },
		{ "MultiBarLeftButton%d",        12, { "MULTIACTIONBAR4BUTTON%d" } },
	} },
	{ nombre = "Bartender4", botones = {
		{ "BT4Button%d", 120, {} },
	} },
	{ nombre = "Dominos", botones = {
		{ "DominosActionButton%d", 120, {} },
	} },
}

-- ElvUI: 10 barras de 12
local function familiaElvUI()
	local lista = {}
	for bar = 1, 10 do
		lista[#lista + 1] = { "ElvUI_Bar" .. bar .. "Button%d", 12,
			{ "ELVUIBAR" .. bar .. "BUTTON%d" } }
	end
	return { nombre = "ElvUI", botones = lista }
end

local function slotDe(btn)
	if not btn then return nil end
	if btn.action then return btn.action end
	if btn.GetAttribute then return btn:GetAttribute("action") end
	return nil
end

-- En 3.3.5 IsHarmfulSpell contesta mal para la mayoria de los hechizos puestos
-- en barra, asi que no se usa como filtro duro. Solo se descarta lo que el cliente
-- afirma que es de ayuda.
local function pedir(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b, c = pcall(fn, ...)
	if ok then return a, b, c end
	return nil
end

local function esOfensivo(nom)
	-- Un hechizo que no tiene rango no se lanza sobre nadie: invocaciones,
	-- buffs propios, piedras. Bindearlos al mouseover no sirve de nada y
	-- solo ensucia la lista. SpellHasRange es confiable para esto, al
	-- reves que IsHarmfulSpell.
	if SpellHasRange then
		local ok, tieneRango = pcall(SpellHasRange, nom)
		if ok and tieneRango == false then return false end
	end
	if pedir(IsHarmfulSpell, nom) then return true end
	if pedir(IsHelpfulSpell, nom) then return false end
	return true
end

-- En 3.3.5 GetSpellInfo(id, "spell") lanza "Invalid spell slot" en vez de
-- devolver nil cuando el numero no es un indice valido del libro, y los macros
-- de personaje traen numeros como 16777219. Siempre pasa por aca.
local function infoPorIndice(id)
	if not id or id <= 0 then return nil end
	local ok, n, r, t = pcall(GetSpellInfo, id, "spell")
	if ok then return n, r, t end
	return nil
end

local function infoPorId(id)
	if not id or id <= 0 then return nil end
	local ok, n, r, t = pcall(GetSpellInfo, id)
	if ok then return n, r, t end
	return nil
end

-- Hechizos que el personaje realmente tiene en el libro.
-- Indexado en minuscula y devolviendo el nombre canonico, porque los macros
-- suelen escribir el hechizo en minuscula (/cast immolate).
local function conocidos()
	local set, i = {}, 1
	while i <= 1024 do
		local nom = pedir(GetSpellName, i, "spell")
		if not nom then break end
		set[strlower(nom)] = nom
		i = i + 1
	end
	return set
end

-- Primer hechizo conocido dentro de un trozo de linea de macro
local function primerHechizo(texto, set)
	texto = string.gsub(texto, "%b[]", "")          -- condicionales [mod:shift] etc
	texto = string.gsub(texto, "reset=%S+", "")     -- reset de castsequence
	for parte in string.gmatch(texto, "[^;,]+") do
		local p = strtrim(parte)
		p = string.gsub(p, "^!", "")                -- !Hechizo
		p = string.gsub(p, "%s*%(.-%)%s*$", "")     -- Hechizo(Rank 3)
		p = strtrim(p)
		if p ~= "" and set[strlower(p)] then return set[strlower(p)] end
	end
	return nil
end

-- Lee el cuerpo del macro y saca el hechizo que lanza
local function hechizoDeMacro(id, set)
	if not GetMacroInfo then return nil end
	local _, _, cuerpo = pedir(GetMacroInfo, id)
	if not cuerpo then return nil end
	for linea in string.gmatch(cuerpo, "[^\r\n]+") do
		local l = strtrim(linea)
		local resto = string.match(l, "^#showtooltip%s+(.+)$")
		if resto then
			local h = primerHechizo(resto, set)
			if h then return h end
		end
	end
	for linea in string.gmatch(cuerpo, "[^\r\n]+") do
		local l = strtrim(linea)
		local resto = string.match(l, "^/cast%s+(.+)$")
			or string.match(l, "^/use%s+(.+)$")
			or string.match(l, "^/castsequence%s+(.+)$")
			or string.match(l, "^/lanzar%s+(.+)$")
		if resto then
			local h = primerHechizo(resto, set)
			if h then return h end
		end
	end
	return nil
end

-- Segun el cliente, GetActionInfo devuelve el ID del hechizo o el indice del
-- libro, y las dos lecturas pueden dar un nombre que existe. El desempate que
-- no falla es la textura: la del boton tiene que ser la del hechizo.
-- Devuelve nombre, y si hubo que desempatar sin textura (menos confiable).
local function hechizoDeSlot(slot, set)
	if not slot then return nil end
	local tipo, id = pedir(GetActionInfo, slot)
	if tipo == "macro" and id and id > 0 then
		if not set then set = conocidos() end
		local h = hechizoDeMacro(id, set)
		if h and esOfensivo(h) then return h, false, true end
		return nil
	end
	if tipo ~= "spell" or not id or id <= 0 then return nil end

	local nomId, _, icoId = infoPorId(id)
	local nomIdx, _, icoIdx = infoPorIndice(id)
	local icoAccion = pedir(GetActionTexture, slot)

	local elegido, dudoso
	if icoAccion then
		if nomId and icoId == icoAccion then
			elegido = nomId
		elseif nomIdx and icoIdx == icoAccion then
			elegido = nomIdx
		end
	end

	-- sin textura disponible, se cae al libro y se marca como dudoso
	if not elegido then
		if not set then set = conocidos() end
		if nomId and set[strlower(nomId)] then elegido, dudoso = nomId, true
		elseif nomIdx and set[strlower(nomIdx)] then elegido, dudoso = nomIdx, true end
	end

	if not elegido then return nil end
	if not esOfensivo(elegido) then return nil end
	return elegido, dudoso
end

-- Saca de la lista guardada todo lo que el personaje no conozca
function GP:PurgarTeclas()
	local set = conocidos()
	if not next(set) then return 0 end
	local t, fuera = tabla(), 0
	for k, v in pairs(t) do
		if not set[strlower(v)] then
			t[k] = nil
			if GP.pj.teclasBoton then GP.pj.teclasBoton[k] = nil end
			fuera = fuera + 1
		end
	end
	return fuera
end

-- Devuelve las teclas de un boton probando los nombres de bindeo posibles
local function teclasDe(nombreBoton, plantillas, i)
	for _, pl in ipairs(plantillas) do
		local k1, k2 = GetBindingKey(string.format(pl, i))
		if k1 or k2 then return k1, k2 end
	end
	return GetBindingKey("CLICK " .. nombreBoton .. ":LeftButton")
end

-- Metodo principal: leer la tabla de bindeos del juego y resolver cada
-- accion bindeada a su hechizo. No depende de adivinar nombres de barras.
local BASE_MULTIBAR = { [1] = 60, [2] = 48, [3] = 24, [4] = 36 }

local MARCO_MULTIBAR = { [1] = "MultiBarBottomLeftButton", [2] = "MultiBarBottomRightButton",
                         [3] = "MultiBarRightButton", [4] = "MultiBarLeftButton" }

-- Devuelve el slot de accion y el nombre del boton que lo muestra
local function slotDeAccion(accion)
	local nom = string.match(accion, "^CLICK%s+(.-):")
	if nom then return slotDe(_G[nom]), nom end

	local n = string.match(accion, "^ACTIONBUTTON(%d+)$")
	if n then return tonumber(n), "ActionButton" .. n end

	local bar, bt = string.match(accion, "^MULTIACTIONBAR(%d+)BUTTON(%d+)$")
	if bar and bt and BASE_MULTIBAR[tonumber(bar)] then
		return BASE_MULTIBAR[tonumber(bar)] + tonumber(bt), MARCO_MULTIBAR[tonumber(bar)] .. bt
	end

	bar, bt = string.match(accion, "^ELVUIBAR(%d+)BUTTON(%d+)$")
	if bar and bt then
		local marco = "ElvUI_Bar" .. bar .. "Button" .. bt
		return slotDe(_G[marco]), marco
	end

	return nil
end

local function recorrerBindings(alEncontrar)
	if not GetNumBindings or not GetBinding then return 0, 0 end
	local set = conocidos()
	local conTecla, conHechizo = 0, 0
	for i = 1, GetNumBindings() do
		local accion, k1, k2 = GetBinding(i)
		if accion and (k1 or k2) then
			conTecla = conTecla + 1
			local slot, marco = slotDeAccion(accion)
			local h, dudoso, esMacro = hechizoDeSlot(slot, set)
			if h then
				conHechizo = conHechizo + 1
				if dudoso then GP.resolDudosa = (GP.resolDudosa or 0) + 1 end
				if alEncontrar then alEncontrar(h, k1, k2, marco, slot) end
			end
		end
	end
	return conTecla, conHechizo
end

-- Recorre todo y llama a cada acierto. Devuelve el resumen por familia.
local function recorrer(alEncontrar)
	local resumen = {}
	local set = conocidos()
	local familias = { FAMILIAS[1], FAMILIAS[2], FAMILIAS[3], familiaElvUI() }
	for _, fam in ipairs(familias) do
		local conBoton, conHechizo, conTecla = 0, 0, 0
		for _, def in ipairs(fam.botones) do
			local patron, cuantos, plantillas = def[1], def[2], def[3]
			for i = 1, cuantos do
				local nom = string.format(patron, i)
				local btn = _G[nom]
				if btn then
					conBoton = conBoton + 1
					local h, _, esMacro = hechizoDeSlot(slotDe(btn), set)
					if h then
						conHechizo = conHechizo + 1
						local k1, k2 = teclasDe(nom, plantillas, i)
						if k1 or k2 then
							conTecla = conTecla + 1
							if alEncontrar then alEncontrar(h, k1, k2, nom, slotDe(btn)) end
						end
					end
				end
			end
		end
		if conBoton > 0 then
			resumen[#resumen + 1] = { fam.nombre, conBoton, conHechizo, conTecla }
		end
	end
	return resumen
end

function GP:AutoTeclas()
	if InCombatLockdown() then
		GP:Msg("Sali de combate y volve a probar.")
		return
	end
	local fuera = GP:PurgarTeclas()
	GP.resolDudosa = 0
	local t = tabla()
	local nuevos = 0
	GP.pj.teclasBoton = GP.pj.teclasBoton or {}
	GP.pj.teclasSlot = GP.pj.teclasSlot or {}
	local tb, ts = GP.pj.teclasBoton, GP.pj.teclasSlot
	local ign = ignoradas()
	local function guardar(h, k1, k2, marco, slot)
		if k1 and ign[k1] then k1 = nil end
		if k2 and ign[k2] then k2 = nil end
		if k1 then
			if not t[k1] then nuevos = nuevos + 1 end
			t[k1] = h
			tb[k1] = marco
			ts[k1] = slot
		end
		if k2 then
			if not t[k2] then nuevos = nuevos + 1 end
			t[k2] = h
			tb[k2] = marco
			ts[k2] = slot
		end
	end

	-- 1) por la tabla de bindeos del juego, que es la fuente confiable
	local bindTeclas, bindHechizos = recorrerBindings(guardar)
	-- 2) barrido de botones de barra: solo rellena huecos, nunca pisa lo de arriba
	local yaResueltas = {}
	for k in pairs(t) do yaResueltas[k] = true end
	local resumen = recorrer(function(h, k1, k2, marco, slot)
		if k1 and yaResueltas[k1] then k1 = nil end
		if k2 and yaResueltas[k2] then k2 = nil end
		guardar(h, k1, k2, marco, slot)
	end)

	local total = 0
	for _ in pairs(t) do total = total + 1 end

	if total == 0 then
		GP:Msg("|cffff5555No encontre ninguna tecla.|r Corre /grilla teclas escaneo y pasame lo que diga.")
		return
	end
	GP.pj.teclasOn = true
	local activas = GP:AplicarTeclas(true)
	GP:Msg("Agregadas |cffffd100" .. nuevos .. "|r teclas nuevas. Activas: |cffffd100" .. activas .. "|r")
	DEFAULT_CHAT_FRAME:AddMessage(string.format(
		"   bindeos del juego: %d con tecla, %d apuntan a un hechizo de dano", bindTeclas, bindHechizos))
	for _, r in ipairs(resumen) do
		DEFAULT_CHAT_FRAME:AddMessage(string.format(
			"   %s: %d botones, %d con hechizo de dano, %d con tecla", r[1], r[2], r[3], r[4]))
	end
	if (GP.resolDudosa or 0) > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("   |cffffaa00" .. GP.resolDudosa ..
			" se resolvieron sin poder comparar el icono, revisalos|r")
	end
	if fuera > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("   saque " .. fuera .. " entradas invalidas de la lista vieja")
	end
	local nIgn = 0
	for _ in pairs(ign) do nIgn = nIgn + 1 end
	if nIgn > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("   " .. nIgn .. " teclas vetadas por vos, no se tocaron")
	end
	GP:Msg("Revisalas en /grilla, pestana Teclas.")
end

-- Diagnostico detallado, por si no engancha ninguna barra
function GP:EscaneoTeclas()
	GP:Msg("escaneo de barras:")
	local bt, bh = recorrerBindings(nil)
	DEFAULT_CHAT_FRAME:AddMessage(string.format(
		"   tabla de bindeos: %d acciones con tecla, %d resuelven a hechizo de dano", bt, bh))
	local resumen = recorrer(nil)
	if #resumen == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("   no se encontro ninguna barra conocida")
	end
	for _, r in ipairs(resumen) do
		DEFAULT_CHAT_FRAME:AddMessage(string.format(
			"   %-12s botones: %3d   con hechizo de dano: %2d   con tecla: %2d", r[1], r[2], r[3], r[4]))
	end
	-- muestra de que ve en los primeros botones de cada familia
	local ejemplos = { "ActionButton1", "BT4Button1", "ElvUI_Bar1Button1", "DominosActionButton1" }
	for _, nom in ipairs(ejemplos) do
		local b = _G[nom]
		if b then
			local slot = slotDe(b)
			local tipo, id = nil, nil
			if slot then tipo, id = GetActionInfo(slot) end
			local h = slot and hechizoDeSlot(slot, nil) or nil
			local k = GetBindingKey("CLICK " .. nom .. ":LeftButton")
			DEFAULT_CHAT_FRAME:AddMessage(string.format(
				"   %s  slot=%s tipo=%s hechizo=%s clickbind=%s",
				nom, tostring(slot), tostring(tipo), tostring(h), tostring(k)))
		end
	end
	local n = 0
	for _ in pairs(tabla()) do n = n + 1 end
	DEFAULT_CHAT_FRAME:AddMessage("   guardadas ahora: " .. n .. "   activado: " .. tostring(GP.pj.teclasOn))
end

function GP:RestaurarVetadas()
	local n = 0
	for _ in pairs(ignoradas()) do n = n + 1 end
	GP.pj.teclasIgnoradas = {}
	GP:Msg("Se levantaron " .. n .. " vetos. Tira /grilla auto para que vuelvan.")
end

function GP:ActivarTeclas(on)
	if InCombatLockdown() then
		GP:Msg("Sali de combate y volve a probar.")
		return
	end
	GP.pj.teclasOn = (on and true) or false
	local n = GP:AplicarTeclas(true)
	if GP.pj.teclasOn then
		if n == 0 then
			GP:Msg("Activado, pero no hay ninguna tecla en la lista. Tira |cffffd100/grilla auto|r para que las busque.")
		else
			GP:Msg("Mouseover por tecla |cff55ff55activado|r. Teclas tomadas: |cffffd100" .. n .. "|r")
		end
	else
		GP:Msg("Mouseover por tecla |cffff5555apagado|r. Tus teclas vuelven a hacer exactamente lo de siempre.")
	end
	GP:RefrescarPanel()
end

function GP:LimpiarTeclas()
	if InCombatLockdown() then
		GP:Msg("Sali de combate y volve a probar.")
		return
	end
	GP.pj.teclas = {}
	GP.pj.teclasBoton = {}
	GP.pj.teclasSlot = {}
	GP.pj.teclasIgnoradas = {}
	ClearOverrideBindings(GP.duenoBinds)
	GP:Msg("Todas las teclas liberadas. Vuelven a funcionar como siempre.")
end

------------------------------------------------------------------
-- Volcado completo a SavedVariables, para poder revisarlo desde afuera
------------------------------------------------------------------
function GP:Volcar()
	local set = conocidos()
	local libro = {}
	for _, nom in pairs(set) do libro[#libro + 1] = nom end
	table.sort(libro)

	local filas = {}
	if GetNumBindings and GetBinding then
		for i = 1, GetNumBindings() do
			local accion, k1, k2 = GetBinding(i)
			if accion and (k1 or k2) and accion ~= "NONE" then
				local slot, marco = slotDeAccion(accion)
				local tipo, id
				if slot then tipo, id = GetActionInfo(slot) end
				local nomId, _, texId = infoPorId(id)
				local nomIdx, _, texIdx = infoPorIndice(id)
				local cuerpo
				if tipo == "macro" and id then
					local _, _, c = pedir(GetMacroInfo, id)
					cuerpo = c
				end
				filas[#filas + 1] = {
					tecla1 = k1, tecla2 = k2, accion = accion,
					slot = slot, marco = marco, tipo = tipo, id = id,
					texAccion = slot and pedir(GetActionTexture, slot) or nil,
					nomPorId = nomId, texPorId = texId,
					nomPorIndice = nomIdx, texPorIndice = texIdx,
					macro = cuerpo,
					resuelto = slot and hechizoDeSlot(slot, set) or nil,
				}
			end
		end
	end

	GP.pj.volcado = {
		cuando = (date and date("%Y-%m-%d %H:%M")) or "",
		personaje = UnitName and UnitName("player") or "",
		libro = libro,
		filas = filas,
	}
	GP:Msg("Volcado armado con " .. #filas .. " bindeos y " .. #libro ..
		" hechizos del libro. Ahora hace |cffffd100/reload|r para que se escriba a disco.")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(self, evento)
	if evento == "PLAYER_LOGIN" or evento == "PLAYER_ENTERING_WORLD" then
		if GP.pj then GP:PurgarTeclas() end
		GP:AplicarTeclas(true)
	elseif GP.teclasPendientes then
		GP:AplicarTeclas(true)
	end
end)
