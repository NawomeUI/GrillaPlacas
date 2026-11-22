-- GrillaPlacas 0.1 - Panel y comandos

local GP = GrillaPlacas
local CLAVES = { "1", "2", "3", "shift-1", "shift-2", "shift-3", "ctrl-1", "ctrl-2", "alt-1", "alt-2" }
GP.CLAVES = CLAVES

local function etiqueta(padre, texto, x, y, fuente)
	local f = padre:CreateFontString(nil, "OVERLAY", fuente or "GameFontNormalSmall")
	f:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	f:SetText(texto)
	return f
end

local function slider(padre, nombre, texto, x, y, min, max, paso, campo)
	local s = CreateFrame("Slider", "GrillaPlacasSlider" .. nombre, padre, "OptionsSliderTemplate")
	s:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	s:SetWidth(170)
	s:SetMinMaxValues(min, max)
	s:SetValueStep(paso)
	_G[s:GetName() .. "Low"]:SetText(min)
	_G[s:GetName() .. "High"]:SetText(max)
	s.titulo = _G[s:GetName() .. "Text"]
	s.campo = campo
	s.texto = texto
	s:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v * 100 + 0.5) / 100
		GP.db[self.campo] = v
		self.titulo:SetText(self.texto .. ": " .. v)
	end)
	-- el rearmado recien cuando sueltas, para no rehacer 40 drivers por cada paso
	s:SetScript("OnMouseUp", function() GP:PedirRearmado() end)
	return s
end

local function check(padre, nombre, texto, x, y, campo)
	local c = CreateFrame("CheckButton", "GrillaPlacasCheck" .. nombre, padre, "OptionsCheckButtonTemplate")
	c:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	_G[c:GetName() .. "Text"]:SetText(texto)
	c.campo = campo
	c:SetScript("OnClick", function(self)
		GP.db[self.campo] = (self:GetChecked() and true or false)
		GP:PedirRearmado()
	end)
	return c
end

function GP:PedirRearmado()
	if InCombatLockdown() then
		GP.layoutPendiente = true
		return
	end
	GP:RearmarTodo()
end

function GP:RearmarTodo()
	if not GP.listo then return end
	local l = GP.db
	local filas = math.ceil(l.posiciones / l.columnas)
	GP.main:SetWidth((l.ancho + l.sepH) * l.columnas)
	GP.main:SetHeight((l.alto + l.sepV) * filas)
	GP.main:SetScale(l.escala)
	for i = 1, GP.MAX_TOKENS do
		local c = GP.celdas[i]
		if c then
			GP:MedidasCelda(c)
		end
	end
	GP:Reiniciar()
end

------------------------------------------------------------------
-- Panel
------------------------------------------------------------------


function GP:AlternarMover()
	if not GP.main then return end
	GP.db.bloqueada = not GP.db.bloqueada
	if GP.db.bloqueada then
		GP.main:EnableMouse(false)
		GP.main.fondo:Hide()
		GP:Msg("Grilla fijada.")
	else
		GP.main:EnableMouse(true)
		GP.main.fondo:Show()
		GP:Msg("Arrastra la grilla con el boton izquierdo. Despues volve a fijarla.")
	end
	GP:RefrescarPanel()
end

------------------------------------------------------------------
-- Comandos
------------------------------------------------------------------
local function ayuda()
	GP:Msg("comandos:")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla            abre el panel")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla test       diagnostico completo")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla test casteo <hechizo>   boton de prueba de casteo")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla test cerrar")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla bind <clave> <hechizo|target|focus|/macro|borrar>")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla binds      lista los clicks")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla modo spell|macro|tcast")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla auto [on|off|borrar]   mouseover por tecla, sin macros")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla teclas [escaneo|off]   lista, diagnostica o libera las teclas")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla tecla <clave> <hechizo|borrar>")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla volcar     guarda un diagnostico completo a disco")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla estilo 1|2   presets de aspecto")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla iconos dentro|fuera|abajo   donde van los iconos de DoT")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla mouseover  prueba si [@mouseover] resuelve sobre la grilla")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla rango <hechizo>   pinta la celda de rojo fuera de rango")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla mover      desbloquea para arrastrar")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla tokens N   cuantas placas mira (si el test avisa que faltan)")
	DEFAULT_CHAT_FRAME:AddMessage("   /grilla reset      vuelve a los valores de fabrica")
end

SLASH_GRILLAPLACAS1 = "/grilla"
SLASH_GRILLAPLACAS2 = "/gp"
-- El cuerpo real va envuelto en pcall mas abajo. Si un comando revienta,
-- el juego aborta ChatEdit_SendText y parece que la tecla Enter dejo de
-- andar. Atrapando el error, el chat sigue funcionando y el problema se
-- reporta en pantalla.
local function ejecutarComando(msg)
	msg = strtrim(msg or "")
	local cmd, resto = string.match(msg, "^(%S*)%s*(.-)$")
	cmd = strlower(cmd or "")

	if cmd == "" then
		if not GP.panel then GP:CrearPanel() end
		GP:RefrescarPanel()
		if GP.panel:IsShown() then GP.panel:Hide() else GP.panel:Show() end

	elseif cmd == "test" then
		local sub, arg = string.match(resto, "^(%S*)%s*(.-)$")
		sub = strlower(sub or "")
		if sub == "casteo" then
			if arg == "" then
				GP:Msg("Falta el hechizo: /grilla test casteo Corruption")
			else
				GP:BotonPrueba(arg)
			end
		elseif sub == "cerrar" then
			if GP.pruebaBtn then GP.pruebaBtn:Hide() end
			GP:Msg("Boton de prueba cerrado.")
		else
			GP:Diagnostico()
		end

	elseif cmd == "bind" then
		local clave, valor = string.match(resto, "^(%S+)%s*(.-)$")
		if not clave then
			GP:Msg("Ejemplo: /grilla bind shift-1 Corruption")
		else
			valor = strtrim(valor or "")
			if valor == "" or strlower(valor) == "borrar" then
				GP:SetBind(clave, "borrar")
			elseif strlower(valor) == "target" then
				GP:SetBind(clave, "target")
			elseif strlower(valor) == "focus" then
				GP:SetBind(clave, "focus")
			elseif strsub(valor, 1, 1) == "/" then
				GP:SetBind(clave, "macro", valor)
			else
				GP:SetBind(clave, "spell", valor)
			end
		end

	elseif cmd == "binds" then
		GP:ListarBinds()

	elseif cmd == "modo" then
		local m = strlower(strtrim(resto))
		if m == "spell" or m == "macro" or m == "tcast" then
			GP.db.modoCast = m
			GP:AplicarBinds()
			GP:Msg("Modo de casteo: " .. m)
		else
			GP:Msg("Modo actual: " .. GP.db.modoCast .. ". Opciones: spell, macro, tcast")
		end

	elseif cmd == "auto" then
		local a = strlower(strtrim(resto))
		if a == "off" then GP:ActivarTeclas(false)
		elseif a == "on" then GP:ActivarTeclas(true)
		elseif a == "borrar" then GP:LimpiarTeclas()
		else GP:AutoTeclas() end

	elseif cmd == "volcar" then
		GP:Volcar()

	elseif cmd == "teclas" then
		local a = strlower(strtrim(resto))
		if a == "off" then GP:LimpiarTeclas()
		elseif a == "escaneo" then GP:EscaneoTeclas()
		elseif a == "restaurar" then GP:RestaurarVetadas()
		else GP:ListarTeclas() end

	elseif cmd == "tecla" then
		local clave, hechizo = string.match(strtrim(resto), "^(%S+)%s*(.*)$")
		GP:PonerTecla(clave or "", hechizo or "")

	elseif cmd == "estilo" then
		local e = strtrim(resto)
		if e == "1" or e == "2" then
			GP:Estilo(tonumber(e))
			GP:Msg("Estilo " .. e .. " aplicado.")
		else
			GP:Msg("Estilos: 1 = una columna, barra con gradiente, iconos a la derecha")
			DEFAULT_CHAT_FRAME:AddMessage("           2 = dos columnas, barra roja, iconos pisando abajo (tipo iTargetingFrames)")
		end

	elseif cmd == "iconos" then
		local m = strlower(strtrim(resto))
		if m == "dentro" or m == "fuera" or m == "abajo" then
			GP.db.iconoPos = m
			GP:RearmarTodo()
			GP:Msg("Iconos de DoT: " .. m .. ".")
		else
			GP:Msg("Iconos: " .. (GP.db.iconoPos or "dentro") .. ". Opciones: dentro, fuera, abajo")
		end

	elseif cmd == "mouseover" or cmd == "mo" then
		GP.moProbado = nil
		GP:Msg("Pasa el mouse por una celda de la grilla y te digo si [@mouseover] resuelve.")

	elseif cmd == "rango" then
		GP.db.hechizoRango = strtrim(resto)
		if GP.db.hechizoRango == "" then
			GP:Msg("Aviso de rango apagado.")
		else
			GP:Msg("Aviso de rango con " .. GP.db.hechizoRango .. ".")
		end

	elseif cmd == "mover" or cmd == "fijar" then
		GP:AlternarMover()

	elseif cmd == "tokens" then
		local n = tonumber(strtrim(resto))
		if not n then
			GP:Msg("Placas que mira la grilla: " .. GP.MAX_TOKENS .. ". Se cambia con /grilla tokens 60 y despues /reload")
		else
			if n < 10 then n = 10 end
			if n > 120 then n = 120 end
			GP.db.maxTokens = n
			GP:Msg("Va a mirar " .. n .. " placas. Hace /reload para que tome efecto.")
		end

	elseif cmd == "reset" then
		GrillaPlacasDB = nil
		GP:Msg("Configuracion de layout borrada. Reinicia la interfaz con /reload")

	else
		ayuda()
	end
end

SlashCmdList["GRILLAPLACAS"] = function(msg)
	local ok, err = pcall(ejecutarComando, msg)
	if not ok then
		GP:Msg("|cffff5555Se rompio el comando:|r " .. tostring(err))
		GP:Msg("El chat sigue andando. Pasale este texto a quien te dio el addon.")
	end
end
