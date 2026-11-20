-- GrillaPlacas 0.9 - Nucleo
-- Grilla de placas enemigas (nameplate1..N) con celdas seguras.
-- Cada celda tiene una unidad FIJA, asi que el click-cast nunca apunta a otro mob.
-- El acomodado (que no queden huecos) corre en el entorno seguro, por eso funciona en combate.

local GP = {}
_G.GrillaPlacas = GP

GP.MAX_TOKENS = 40
GP.MAX_DOTS = 6
GP.celdas = {}
GP.main = nil
GP.listo = false

local LAYOUT_DEF = {
	x = nil, y = nil,
	posiciones = 12,
	columnas = 1,
	ancho = 180,
	alto = 30,
	sepH = 2,
	sepV = 3,
	fuenteTam = 12,
	estilo = 4,
	escala = 1,
	soloCombate = false,
	soloEnemigos = true,
	maxDots = 3,
	iconoPos = "dentro",   -- dentro | fuera | abajo
	barraRoja = false,
	iconoTam = 0,         -- 0 = automatico
	avisoDot = 30,        -- %% restante para que el icono se ponga en rojo
	mostrarVidaTexto = true,
	hechizoRango = "",
	bloqueada = true,
	maxTokens = 40,
	modoCast = "spell",
}

local BINDS_DEF = {
	["1"] = { tipo = "target" },
	["2"] = { tipo = "focus" },
}

local function copiarDefaults(dest, def)
	for k, v in pairs(def) do
		if dest[k] == nil then
			if type(v) == "table" then
				dest[k] = {}
				copiarDefaults(dest[k], v)
			else
				dest[k] = v
			end
		end
	end
	return dest
end

function GP:Msg(texto)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99GrillaPlacas|r " .. tostring(texto))
end

------------------------------------------------------------------
-- Deteccion del parche
------------------------------------------------------------------
function GP:TieneAPI()
	if type(C_NamePlate) ~= "table" then return false end
	if type(C_NamePlate.GetNamePlates) ~= "function" and type(C_NamePlate.GetNamePlateForUnit) ~= "function" then
		return false
	end
	return true
end

------------------------------------------------------------------
-- Posiciones
------------------------------------------------------------------
function GP:PosDeIndice(i)
	local l = self.db
	local col = (i - 1) % l.columnas
	local fila = math.floor((i - 1) / l.columnas)
	local x = col * (l.ancho + l.sepH)
	local y = -fila * (l.alto + l.sepV)
	return x, y
end

------------------------------------------------------------------
-- Celdas
------------------------------------------------------------------
local BD_CELDA = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
local BD_ICONO = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
}

local function fuenteUI()
	return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

-- Tamanos y ubicacion de todo lo que depende del ancho/alto/cantidad de iconos.
-- Se llama al crear la celda y cada vez que se mueve un slider del panel.
function GP:MedidasCelda(c)
	local l = self.db
	local n = math.min(l.maxDots or 0, GP.MAX_DOTS)
	local gap = 2
	local pos = l.iconoPos or "dentro"
	local fnt = fuenteUI()

	c:SetWidth(l.ancho)
	c:SetHeight(l.alto)
	c.nombre:SetFont(fnt, l.fuenteTam, "OUTLINE")
	c.pct:SetFont(fnt, l.fuenteTam, "OUTLINE")

	-- Reparto del ancho. Primero se reserva lugar para el nombre y el %,
	-- recien despues se decide cuanto puede medir cada icono. Asi nunca
	-- quedan el texto o el numero empujados fuera de la celda.
	local anchoPct = 0
	if l.mostrarVidaTexto then anchoPct = math.floor(l.fuenteTam * 2.4) end
	local minNombre = math.floor(l.fuenteTam * 4)

	local lado
	if pos == "abajo" then
		-- Los iconos van abajo y envuelven en varias filas si no entran.
		-- Se elige el lado mas grande cuyas filas quepan sin tapar el nombre.
		local altoTexto = l.fuenteTam + 7
		local hDisp = l.alto - altoTexto - 3
		local maxCand = math.min(30, math.max(10, math.floor(l.alto * 0.55)))
		lado = 10
		if n > 0 then
			for cand = maxCand, 10, -1 do
				local porFila = math.max(1, math.floor((l.ancho - 4 + gap) / (cand + gap)))
				local filas = math.ceil(n / porFila)
				if filas * cand + (filas - 1) * gap <= hDisp then
					lado = cand
					break
				end
			end
		end
	elseif pos == "fuera" then
		lado = l.alto
	else
		local libre = l.ancho - 12 - anchoPct - minNombre
		if libre < 0 then libre = 0 end
		lado = math.floor((libre - (n - 1) * gap) / math.max(n, 1))
		if lado > l.alto - 6 then lado = l.alto - 6 end
		if lado < 10 then lado = 10 end
	end

	-- tamano fijado a mano desde el panel
	if l.iconoTam and l.iconoTam > 0 then lado = l.iconoTam end

	local porFila = math.max(n, 1)
	if pos == "abajo" then
		porFila = math.max(1, math.floor((l.ancho - 4 + gap) / (lado + gap)))
	end
	GP.ladoIcono = lado
	GP.filasIcono = 0
	if n > 0 then GP.filasIcono = math.ceil(n / porFila) end

	local bloque = 0
	if n > 0 then bloque = n * lado + (n - 1) * gap end

	for i = 1, GP.MAX_DOTS do
		local d = c.dots[i]
		d:ClearAllPoints()
		d.stacks:SetFont(fnt, l.fuenteTam, "OUTLINE")
		if i > n then
			d:Hide()
		else
			d:SetWidth(lado)
			d:SetHeight(lado)
			if pos == "abajo" then
				local fila = math.floor((i - 1) / porFila)
				local col = (i - 1) % porFila
				d:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT",
					2 + col * (lado + gap), 2 + fila * (lado + gap))
			elseif i == 1 then
				if pos == "fuera" then
					d:SetPoint("LEFT", c, "RIGHT", 3, 0)
				else
					d:SetPoint("LEFT", c, "LEFT", l.ancho - 3 - bloque, 0)
				end
			else
				d:SetPoint("LEFT", c.dots[i - 1], "RIGHT", gap, 0)
			end
		end
	end

	c.nombre:ClearAllPoints()
	c.pct:ClearAllPoints()
	local anchoNombre
	if pos == "abajo" then
		-- nombre arriba izquierda, vida arriba derecha, iconos pisando abajo
		c.nombre:SetPoint("TOPLEFT", c, "TOPLEFT", 5, -3)
		c.pct:SetPoint("TOPRIGHT", c, "TOPRIGHT", -5, -3)
		anchoNombre = l.ancho - 48
	elseif pos == "fuera" then
		c.nombre:SetPoint("LEFT", c, "LEFT", 5, 0)
		c.pct:SetPoint("RIGHT", c, "RIGHT", -5, 0)
		anchoNombre = l.ancho - 36
	else
		-- el % se recuesta contra el bloque de iconos, nunca fuera de la celda
		local xPct = l.ancho - 3 - bloque - 4
		if xPct < anchoPct + 8 then xPct = anchoPct + 8 end
		c.nombre:SetPoint("LEFT", c, "LEFT", 5, 0)
		c.pct:SetPoint("RIGHT", c, "LEFT", xPct, 0)
		anchoNombre = xPct - anchoPct - 7
	end
	if anchoNombre < 20 then anchoNombre = 20 end
	c.nombre:SetWidth(anchoNombre)
	c.nombre:SetHeight(l.fuenteTam + 3)
	c.maxChars = math.max(4, math.floor(anchoNombre / (l.fuenteTam * 0.55)))
end

-- Presets de aspecto. 1 = barra con gradiente e iconos a la derecha.
-- 2 = parecido a iTargetingFrames: dos columnas, barra roja, iconos pisando abajo.
function GP:Estilo(n)
	local l = GP.db
	if n == 2 then
		l.ancho, l.alto = 150, 46
		l.columnas, l.maxDots = 2, 3
		l.iconoPos, l.barraRoja = "abajo", true
		l.fuenteTam, l.sepH, l.sepV = 13, 2, 2
	elseif n == 3 then
		-- compacto: celdas casi cuadradas, bloque chico en pantalla
		l.ancho, l.alto = 110, 42
		l.columnas, l.maxDots = 3, 3
		l.iconoPos, l.barraRoja = "abajo", true
		l.fuenteTam, l.sepH, l.sepV = 11, 2, 2
	else
		l.ancho, l.alto = 180, 30
		l.columnas, l.maxDots = 1, 3
		l.iconoPos, l.barraRoja = "dentro", false
		l.fuenteTam, l.sepH, l.sepV = 12, 2, 3
	end
	GP:RearmarTodo()
end

local function crearCelda(token, indice)
	local l = GP.db
	local fnt, tam = fuenteUI(), l.fuenteTam
	local c = CreateFrame("Button", "GrillaPlacasCelda" .. indice, GP.main, "SecureActionButtonTemplate")
	c:SetWidth(l.ancho)
	c:SetHeight(l.alto)
	c:Hide()
	c:SetAttribute("unit", token)
	c:RegisterForClicks("AnyDown")
	c.token = token
	c.indice = indice

	c:SetBackdrop(BD_CELDA)
	c:SetBackdropColor(0, 0, 0, 1)
	c:SetBackdropBorderColor(0, 0, 0, 1)

	local vida = CreateFrame("StatusBar", nil, c)
	vida:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	vida:SetMinMaxValues(0, 100)
	vida:SetValue(100)
	vida:SetPoint("TOPLEFT", c, "TOPLEFT", 2, -2)
	vida:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -2, 2)
	vida:SetStatusBarColor(0.15, 0.7, 0.2)
	c.vida = vida

	local fondo = vida:CreateTexture(nil, "BACKGROUND")
	fondo:SetAllPoints(vida)
	fondo:SetTexture("Interface\\Buttons\\WHITE8x8")
	fondo:SetVertexColor(0.09, 0.09, 0.09, 1)

	-- brillo arriba, para que la barra no quede plana (estetica Blizzard)
	local brillo = vida:CreateTexture(nil, "OVERLAY")
	brillo:SetTexture("Interface\\Buttons\\WHITE8x8")
	brillo:SetPoint("TOPLEFT", vida, "TOPLEFT", 0, 0)
	brillo:SetPoint("TOPRIGHT", vida, "TOPRIGHT", 0, 0)
	brillo:SetHeight(math.max(2, math.floor((l.alto - 4) / 3)))
	brillo:SetVertexColor(1, 1, 1, 0.10)

	local pct = vida:CreateFontString(nil, "OVERLAY")
	pct:SetFont(fnt, tam, "OUTLINE")
	pct:SetPoint("RIGHT", vida, "RIGHT", -4, 0)
	pct:SetTextColor(1, 1, 1)
	c.pct = pct

	local nombre = vida:CreateFontString(nil, "OVERLAY")
	nombre:SetFont(fnt, tam, "OUTLINE")
	nombre:SetPoint("LEFT", vida, "LEFT", 5, 0)
	nombre:SetJustifyH("LEFT")
	nombre:SetTextColor(1, 1, 1)
	c.nombre = nombre

	-- resaltado al pasar el mouse
	local hl = vida:CreateTexture(nil, "ARTWORK")
	hl:SetAllPoints(vida)
	hl:SetTexture("Interface\\Buttons\\WHITE8x8")
	hl:SetVertexColor(1, 1, 1, 0.22)
	hl:Hide()
	c.hl = hl

	-- iconos de los DoTs propios (pool fijo, se ubican en MedidasCelda)
	c.dots = {}
	for i = 1, GP.MAX_DOTS do
		local d = CreateFrame("Frame", nil, c)
		d:SetFrameLevel(vida:GetFrameLevel() + 2)
		d:Hide()

		d:SetBackdrop(BD_ICONO)
		d:SetBackdropColor(0, 0, 0, 1)
		d:SetBackdropBorderColor(0, 0, 0, 1)

		local ico = d:CreateTexture(nil, "ARTWORK")
		ico:SetPoint("TOPLEFT", d, "TOPLEFT", 1, -1)
		ico:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -1, 1)
		ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		d.ico = ico

		local cd = CreateFrame("Cooldown", nil, d, "CooldownFrameTemplate")
		cd:SetPoint("TOPLEFT", d, "TOPLEFT", 1, -1)
		cd:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -1, 1)
		cd:SetReverse(true)
		d.cd = cd

		local topo = CreateFrame("Frame", nil, d)
		topo:SetAllPoints(d)
		topo:SetFrameLevel(cd:GetFrameLevel() + 1)
		local stacks = topo:CreateFontString(nil, "OVERLAY")
		stacks:SetFont(fnt, tam, "OUTLINE")
		stacks:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -1, 2)
		stacks:SetTextColor(1, 0.9, 0.4)
		d.stacks = stacks

		c.dots[i] = d
	end

	GP:MedidasCelda(c)

	c:SetScript("OnEnter", function(self)
		self.hl:Show()
		if UnitExists(self.token) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetUnit(self.token)
			GameTooltip:Show()
		end
	end)
	c:SetScript("OnLeave", function(self)
		self.hl:Hide()
		GameTooltip:Hide()
	end)

	return c
end

function GP:CrearMain()
	local l = self.db
	local m = CreateFrame("Frame", "GrillaPlacasMain", UIParent, "SecureHandlerStateTemplate")
	local ancho = (l.ancho + l.sepH) * l.columnas
	local filas = math.ceil(l.posiciones / l.columnas)
	m:SetWidth(ancho)
	m:SetHeight((l.alto + l.sepV) * filas)
	if l.x and l.y then
		m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l.x, l.y)
	else
		m:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
	end
	m:SetScale(l.escala)
	m:SetMovable(true)
	m:EnableMouse(false)
	m:SetClampedToScreen(true)

	m.fondo = m:CreateTexture(nil, "BACKGROUND")
	m.fondo:SetAllPoints(m)
	m.fondo:SetTexture("Interface\\Buttons\\WHITE8x8")
	m.fondo:SetVertexColor(0.4, 0.4, 0.4, 0.4)
	m.fondo:Hide()

	m:SetScript("OnDragStart", function(self) self:StartMoving() end)
	m:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetLeft(), self:GetTop()
		if x and y then
			GP.db.x = x
			GP.db.y = y
		end
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", GP.db.x, GP.db.y)
	end)
	m:RegisterForDrag("LeftButton")

	m:Execute([[gpVivos = table.new(); gpMostrando = table.new();]])
	self.main = m
end

function GP:CargarPosicionesSeguras()
	local tabla = "gpPos = table.new();"
	for i = 1, GP.MAX_TOKENS do
		local x, y = self:PosDeIndice(i)
		tabla = tabla .. string.format("gpPos[%d] = table.new(%d, %d);", i, x, y)
	end
	self.main:Execute(tabla)

	local visibles = math.min(self.db.posiciones, GP.MAX_TOKENS)
	self.main:SetAttribute("_gpacomodar", string.format([=[
		local maxTok = %d
		for i = 1, %d do
			if gpPos[i] and not gpMostrando[i] then
				for n = 1, maxTok do
					if gpVivos[n] == 0 then
						gpVivos[n] = i
						gpMostrando[i] = n
						local f = self:GetFrameRef("slot" .. n)
						if f then
							f:ClearAllPoints()
							f:SetPoint("TOPLEFT", self, "TOPLEFT", gpPos[i][1], gpPos[i][2])
							f:Show()
						end
						break
					end
				end
			end
		end
	]=], GP.MAX_TOKENS, visibles))
end

function GP:RegistrarDrivers()
	local cond = ",nodead"
	if self.db.soloEnemigos then cond = cond .. ",harm" end
	if self.db.soloCombate then cond = cond .. ",combat" end

	for i = 1, GP.MAX_TOKENS do
		local slot = "slot" .. i
		self.main:SetFrameRef(slot, self.celdas[i])
		self.main:SetAttribute("_onstate-" .. slot, string.format([=[
			local n = %d
			local f = self:GetFrameRef("slot" .. n)
			if newstate == "true" then
				if gpVivos[n] == nil then gpVivos[n] = 0 end
			else
				local p = gpVivos[n]
				if p and p > 0 then gpMostrando[p] = nil end
				gpVivos[n] = nil
				if f then f:Hide() end
			end
			control:RunAttribute("_gpacomodar")
		]=], i))
		RegisterStateDriver(self.main, slot, "[@nameplate" .. i .. ",exists" .. cond .. "] true;")
	end
end

function GP:Reiniciar()
	if InCombatLockdown() then
		self:Msg("En combate no puedo rearmar la grilla. Sali de combate y repeti.")
		return
	end
	for i = 1, GP.MAX_TOKENS do
		UnregisterStateDriver(self.main, "slot" .. i)
	end
	self.main:Execute(string.format([[
		for i = 1, %d do
			local f = self:GetFrameRef("slot"..i)
			if f then f:Hide() end
		end
		gpVivos = table.new()
		gpMostrando = table.new()
	]], GP.MAX_TOKENS))
	self:CargarPosicionesSeguras()
	self:RegistrarDrivers()
	if GP.AplicarBinds then GP:AplicarBinds() end
end

------------------------------------------------------------------
-- Refresco visual (sin eventos de vida para placas, va por OnUpdate)
------------------------------------------------------------------
-- verde -> amarillo -> rojo segun la vida que le queda
local function colorVida(p)
	if p >= 50 then
		local t = (p - 50) / 50
		return 0.90 + (0.15 - 0.90) * t, 0.80 + (0.70 - 0.80) * t, 0.10 + (0.20 - 0.10) * t
	else
		local t = p / 50
		return 0.80 + (0.90 - 0.80) * t, 0.12 + (0.80 - 0.12) * t, 0.12 + (0.10 - 0.12) * t
	end
end

local function cortar(texto, maxChars)
	if string.len(texto) > maxChars then
		return string.sub(texto, 1, maxChars - 2) .. ".."
	end
	return texto
end

local acum = 0
local function refrescar()
	local l = GP.db
	local spRango = l.hechizoRango
	if spRango == "" then spRango = nil end
	local ahora = GetTime()

	for i = 1, GP.MAX_TOKENS do
		local c = GP.celdas[i]
		if c and c:IsShown() then
			local u = c.token
			if UnitExists(u) then
				local hp, hpMax = UnitHealth(u), UnitHealthMax(u)
				local p = 100
				if hpMax and hpMax > 0 then
					p = hp / hpMax * 100
					c.vida:SetValue(p)
					if l.mostrarVidaTexto then
						c.pct:SetText(string.format("%d", p))
					else
						c.pct:SetText("")
					end
				end

				if l.barraRoja then
					c.vida:SetStatusBarColor(0.78, 0.15, 0.15)
				else
					c.vida:SetStatusBarColor(colorVida(p))
				end
				c.nombre:SetText(cortar(UnitName(u) or "", c.maxChars or 10))

				-- borde: objetivo (dorado), foco (azul), normal (negro)
				if UnitIsUnit(u, "target") then
					c:SetBackdropBorderColor(1, 0.82, 0.2, 1)
					c.nombre:SetTextColor(1, 0.95, 0.7)
				elseif UnitIsUnit(u, "focus") then
					c:SetBackdropBorderColor(0.3, 0.6, 1, 1)
					c.nombre:SetTextColor(0.8, 0.9, 1)
				else
					c:SetBackdropBorderColor(0, 0, 0, 1)
					c.nombre:SetTextColor(1, 1, 1)
				end

				-- fuera de rango: fila apagada y borde rojo
				if spRango and IsSpellInRange(spRango, u) == 0 then
					c:SetAlpha(0.42)
					c:SetBackdropBorderColor(0.9, 0.15, 0.15, 1)
				else
					c:SetAlpha(1)
				end

				-- mis DoTs
				local puesto = 0
				local idx = 1
				while idx <= 40 and puesto < l.maxDots do
					local nom, _, ico, cuenta, _, dur, exp, quien = UnitAura(u, idx, "HARMFUL")
					if not nom then break end
					if quien == "player" then
						puesto = puesto + 1
						local d = c.dots[puesto]
						d.ico:SetTexture(ico)
						d.ico:SetVertexColor(1, 1, 1)
						if dur and dur > 0 and exp then
							d.cd:SetCooldown(exp - dur, dur)
							d.cd:Show()
							-- por vencer: borde rojo, para ver de una cual hay que refrescar
							if (exp - ahora) / dur <= (l.avisoDot or 30) / 100 then
								d:SetBackdropBorderColor(1, 0.2, 0.2, 1)
							else
								d:SetBackdropBorderColor(0, 0, 0, 1)
							end
						else
							d.cd:Hide()
							d:SetBackdropBorderColor(0, 0, 0, 1)
						end
						if cuenta and cuenta > 1 then
							d.stacks:SetText(cuenta)
						else
							d.stacks:SetText("")
						end
						d:Show()
					end
					idx = idx + 1
				end
				for k = puesto + 1, l.maxDots do
					c.dots[k]:Hide()
				end
			else
				-- el token se fue: no dejar datos viejos en pantalla
				c.nombre:SetText("")
				c.pct:SetText("")
				c.vida:SetValue(0)
				c:SetAlpha(1)
				c:SetBackdropBorderColor(0, 0, 0, 1)
				for k = 1, l.maxDots do c.dots[k]:Hide() end
			end
		end
	end

	-- sonda: la primera vez que pasa el mouse por una celda viva, avisa si [@mouseover] resuelve
	if not GP.moProbado then
		local foco = GetMouseFocus()
		if foco and foco.token and UnitExists(foco.token) then
			GP.moProbado = true
			if UnitExists("mouseover") and UnitIsUnit("mouseover", foco.token) then
				GP:Msg("|cff55ff55Mouseover anda sobre la grilla.|r Ya podes usar macros con [@mouseover].")
			else
				GP:Msg("|cffff5555Mouseover NO resuelve sobre la grilla.|r Avisame y lo resuelvo por otro lado.")
			end
		end
	end
end

local motor = CreateFrame("Frame")
motor:SetScript("OnUpdate", function(self, elapsed)
	if not GP.listo then return end
	acum = acum + elapsed
	if acum < 0.1 then return end
	acum = 0
	refrescar()
end)

------------------------------------------------------------------
-- Arranque
------------------------------------------------------------------
local arranque = CreateFrame("Frame")
arranque:RegisterEvent("ADDON_LOADED")
arranque:RegisterEvent("PLAYER_LOGIN")
arranque:SetScript("OnEvent", function(self, evento, arg1)
	if evento == "ADDON_LOADED" and arg1 == "GrillaPlacas" then
		GrillaPlacasDB = GrillaPlacasDB or {}
		GrillaPlacasPJ = GrillaPlacasPJ or {}
		-- 0.5: medidas nuevas con los iconos adentro, una sola vez
		if GrillaPlacasDB.estilo ~= 4 then
			GrillaPlacasDB.estilo = 4
			GrillaPlacasDB.iconosDentro = nil
			GrillaPlacasDB.ancho = nil
			GrillaPlacasDB.alto = nil
			GrillaPlacasDB.sepV = nil
			GrillaPlacasDB.maxDots = nil
			GrillaPlacasDB.fuenteTam = nil
		end
		GP.db = copiarDefaults(GrillaPlacasDB, LAYOUT_DEF)
		GP.pj = GrillaPlacasPJ
		GP.MAX_TOKENS = tonumber(GP.db.maxTokens) or 40
		if GP.MAX_TOKENS < 10 then GP.MAX_TOKENS = 10 end
		if GP.MAX_TOKENS > 120 then GP.MAX_TOKENS = 120 end
		GP.pj.binds = GP.pj.binds or {}
		if not next(GP.pj.binds) then
			for k, v in pairs(BINDS_DEF) do
				GP.pj.binds[k] = { tipo = v.tipo, valor = v.valor }
			end
		end
	elseif evento == "PLAYER_LOGIN" then
		if not GP:TieneAPI() then
			GP:Msg("|cffff5555No encuentro la API de placas del parche.|r Esta grilla necesita el cliente con AwesomeWotlkLib.dll. Proba /grilla test para el detalle.")
			GP.sinAPI = true
			return
		end
		GP:CrearMain()
		for i = 1, GP.MAX_TOKENS do
			GP.celdas[i] = crearCelda("nameplate" .. i, i)
		end
		GP:CargarPosicionesSeguras()
		GP:RegistrarDrivers()
		if GP.AplicarBinds then GP:AplicarBinds() end
		GP.listo = true
	end
end)
