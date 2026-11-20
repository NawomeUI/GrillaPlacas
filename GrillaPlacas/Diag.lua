-- GrillaPlacas 0.1 - Diagnostico
-- /grilla test corre todo solo y deja el reporte guardado para pasarlo.

local GP = GrillaPlacas
local MAX = 40          -- lo que mira la grilla
local MAX_BARRIDO = 200 -- lo que mira el diagnostico (la dll puede dar indices altos)

local function linea(t)
	DEFAULT_CHAT_FRAME:AddMessage("   " .. t)
end

local function si(v) if v then return "|cff55ff55si|r" else return "|cffff5555no|r" end end

function GP:Diagnostico()
	local rep = {}
	GrillaPlacasDB.reporte = rep
	rep.fecha = date("%Y-%m-%d %H:%M")
	rep.cliente = (GetBuildInfo and select(2, GetBuildInfo())) or "?"

	GP:Msg("--- diagnostico ---")

	-- 1. API del parche
	local tieneTabla = (type(C_NamePlate) == "table")
	rep.C_NamePlate = tieneTabla
	linea("Tabla C_NamePlate: " .. si(tieneTabla))
	if tieneTabla then
		local fns = {}
		for _, n in ipairs({ "GetNamePlates", "GetNamePlateForUnit", "GetNamePlateByGUID",
			"GetNamePlateForGUID", "GetNamePlateTokenByGUID", "GetGUIDForNamePlate",
			"GetNamePlatesDistance", "GetDistanceForUnit" }) do
			if type(C_NamePlate[n]) == "function" then table.insert(fns, n) end
		end
		rep.funciones = table.concat(fns, ", ")
		linea("Funciones: " .. (rep.funciones ~= "" and rep.funciones or "ninguna"))
	end
	rep.UnitTokenFromGUID = (type(UnitTokenFromGUID) == "function")
	linea("UnitTokenFromGUID: " .. si(rep.UnitTokenFromGUID))

	-- 2. CVars
	local cvars = {}
	for _, n in ipairs({ "nameplateDistance", "nameplateShowEnemies", "nameplateStacking", "nameplateMouseMode" }) do
		local ok, v = pcall(GetCVar, n)
		if ok and v ~= nil then table.insert(cvars, n .. "=" .. tostring(v)) end
	end
	rep.cvars = table.concat(cvars, "  ")
	linea("CVars: " .. (rep.cvars ~= "" and rep.cvars or "no hay CVars del parche"))

	-- 3. Tokens vivos
	local vivos, guids, repetidos = 0, {}, 0
	local detalle = {}
	for i = 1, MAX do
		local u = "nameplate" .. i
		if UnitExists(u) then
			vivos = vivos + 1
			local g = UnitGUID(u)
			local n = UnitName(u) or "?"
			local enemigo = UnitCanAttack("player", u) and "enemigo" or "amigo"
			if g then
				if guids[g] then
					repetidos = repetidos + 1
				else
					guids[g] = true
				end
			end
			if vivos <= 8 then
				table.insert(detalle, u .. " " .. n .. " (" .. enemigo .. ")")
			end
		end
	end
	-- barrido largo: si hay unidades mas alla de la grilla, hay que subir maxTokens
	local masAlto, fueraDeRango = 0, 0
	for i = 1, MAX_BARRIDO do
		if UnitExists("nameplate" .. i) then
			masAlto = i
			if i > GP.MAX_TOKENS then fueraDeRango = fueraDeRango + 1 end
		end
	end
	rep.indiceMasAlto = masAlto
	rep.fueraDeRango = fueraDeRango
	rep.maxTokens = GP.MAX_TOKENS

	rep.vivos = vivos
	rep.repetidos = repetidos
	rep.detalle = table.concat(detalle, " | ")
	linea("Placas con unidad: |cffffff00" .. vivos .. "|r   repetidas: " .. repetidos)
	linea("Indice mas alto con unidad: " .. masAlto .. " (la grilla mira hasta " .. GP.MAX_TOKENS .. ")")
	if fueraDeRango > 0 then
		linea("|cffff5555" .. fueraDeRango .. " unidades quedan fuera de la grilla.|r Subilo con /grilla tokens " .. (masAlto + 10))
	end
	if vivos == 0 then
		linea("|cffff5555Sin unidades.|r Activa las placas enemigas con V y parate cerca de mobs.")
	else
		for _, d in ipairs(detalle) do linea("   " .. d) end
	end

	-- 4. Se pueden targetear
	if vivos > 0 then
		if InCombatLockdown() then
			linea("Prueba de objetivo: salteada (estas en combate).")
			rep.targeteable = "sin probar"
		else
			local original = UnitGUID("target")
			local primero
			for i = 1, MAX do
				if UnitExists("nameplate" .. i) then
					primero = "nameplate" .. i
					break
				end
			end
			local esperado = UnitGUID(primero)
			local ok, err = pcall(TargetUnit, primero)
			if not ok then
				rep.targeteable = "error: " .. tostring(err)
				linea("Objetivo desde codigo normal: error (" .. tostring(err) .. ")")
			else
				local logrado = UnitGUID("target")
				local anduvo = (logrado ~= nil and logrado == esperado)
				rep.targeteable = anduvo and "si" or "bloqueado"
				linea("Objetivo desde codigo normal sobre " .. primero .. ": " .. si(anduvo))
				if not anduvo then
					linea("   |cffaaaaaaOjo: esto se bloquea aunque el token este bien. Lo que vale es el click sobre la celda.|r")
				end
				if original and original ~= logrado then
					pcall(TargetLastTarget)
				elseif not original then
					pcall(ClearTarget)
				end
			end
		end
	end

	-- 5. Estado del addon
	linea("Grilla armada: " .. si(GP.listo) .. "   celdas creadas: " .. (GP.celdas[1] and GP.MAX_TOKENS or 0))
	if GP.listo then
		local mostrando = 0
		for i = 1, GP.MAX_TOKENS do
			if GP.celdas[i] and GP.celdas[i]:IsShown() then mostrando = mostrando + 1 end
		end
		rep.mostrando = mostrando
		linea("Celdas visibles ahora: |cffffff00" .. mostrando .. "|r")
	end
	rep.modoCast = GP.db and GP.db.modoCast or "?"
	linea("Modo de casteo: " .. rep.modoCast)

	GP:Msg("Falta la prueba de casteo, que necesita un click tuyo: |cffffff00/grilla test casteo <hechizo>|r")
	GP:Msg("El reporte queda guardado. Pasame una captura del chat.")
end

------------------------------------------------------------------
-- Boton de prueba de casteo (necesita click de verdad)
------------------------------------------------------------------
function GP:BotonPrueba(hechizo)
	if InCombatLockdown() then
		GP:Msg("Sali de combate para armar el boton de prueba.")
		return
	end
	local token
	for i = 1, MAX do
		if UnitExists("nameplate" .. i) and UnitCanAttack("player", "nameplate" .. i) then
			token = "nameplate" .. i
			break
		end
	end
	if not token then
		GP:Msg("No hay ninguna placa enemiga viva para probar. Parate frente a un mob.")
		return
	end

	if not GP.pruebaBtn then
		local b = CreateFrame("Button", "GrillaPlacasPrueba", UIParent, "SecureActionButtonTemplate")
		b:SetWidth(260)
		b:SetHeight(44)
		b:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
		b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
		b:SetBackdropColor(0, 0, 0, 0.85)
		b:RegisterForClicks("AnyDown")
		b.texto = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.texto:SetPoint("CENTER")
		b.ico = b:CreateTexture(nil, "ARTWORK")
		b.ico:SetWidth(32)
		b.ico:SetHeight(32)
		b.ico:SetPoint("LEFT", b, "LEFT", 6, 0)
		b.ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		GP.pruebaBtn = b
	end

	local b = GP.pruebaBtn
	b:SetAttribute("unit", token)
	b:SetAttribute("type1", "spell")
	b:SetAttribute("spell1", hechizo)
	b:SetAttribute("type2", "macro")
	b:SetAttribute("macrotext2", "/cast [@" .. token .. "] " .. hechizo)
	b.ico:SetTexture(GetSpellTexture and GetSpellTexture(hechizo) or nil)
	b.texto:SetText("izq: spell  /  der: macro")
	b:Show()
	GP:Msg("Boton armado sobre " .. token .. " (" .. (UnitName(token) or "?") .. ") con " .. hechizo .. ".")
	GP:Msg("Clic izquierdo prueba el modo spell y el derecho el modo macro. Decime cual de los dos sale.")
	GP:Msg("Para sacarlo: /grilla test cerrar")
end
