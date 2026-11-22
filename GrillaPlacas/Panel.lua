-- GrillaPlacas - Panel de control
-- Todo lo configurable en un solo lugar, en pestanas, para no tener que
-- acordarse de ningun comando.

local GP = GrillaPlacas

local ANCHO_P, ALTO_P = 470, 548

local BD_PANEL = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
local BD_PLANO = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local COL = {
	fondo    = { 0.07, 0.07, 0.08, 0.96 },
	borde    = { 0.26, 0.26, 0.30, 1 },
	barra    = { 0.12, 0.12, 0.14, 1 },
	boton    = { 0.15, 0.15, 0.17, 1 },
	botonLuz = { 0.23, 0.23, 0.26, 1 },
	activo   = { 0.20, 0.34, 0.52, 1 },
	linea    = { 1, 1, 1, 0.07 },
}

local function pintar(f, c) f:SetBackdropColor(c[1], c[2], c[3], c[4]) end

-- boton plano, sin la textura gris de Blizzard
local function botonPlano(padre, texto, x, y, ancho, alto, alClick)
	local b = CreateFrame("Button", nil, padre)
	b:SetWidth(ancho)
	b:SetHeight(alto or 23)
	b:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	b:SetBackdrop(BD_PLANO)
	pintar(b, COL.boton)
	b:SetBackdropBorderColor(unpack(COL.borde))
	b.etq = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.etq:SetPoint("CENTER", b, "CENTER", 0, 0)
	b.etq:SetText(texto)
	b.SetTexto = function(self, t) self.etq:SetText(t) end
	b.Marcar = function(self, on)
		self.activo = on
		if on then
			pintar(self, COL.activo)
			self.etq:SetTextColor(1, 1, 1)
		else
			pintar(self, COL.boton)
			self.etq:SetTextColor(0.78, 0.78, 0.80)
		end
	end
	b:SetScript("OnEnter", function(self)
		if not self.activo then pintar(self, COL.botonLuz) end
	end)
	b:SetScript("OnLeave", function(self)
		if not self.activo then pintar(self, COL.boton) end
	end)
	b:SetScript("OnClick", alClick)
	b:Marcar(false)
	return b
end

local function divisor(padre, x, y, ancho)
	local t = padre:CreateTexture(nil, "ARTWORK")
	t:SetTexture("Interface\\Buttons\\WHITE8x8")
	t:SetVertexColor(unpack(COL.linea))
	t:SetWidth(ancho)
	t:SetHeight(1)
	t:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	return t
end

local function etiqueta(padre, texto, x, y, fuente)
	local f = padre:CreateFontString(nil, "OVERLAY", fuente or "GameFontNormalSmall")
	f:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	f:SetText(texto)
	return f
end

local nSlider = 0
local function slider(padre, texto, x, y, min, max, paso, campo, ancho)
	nSlider = nSlider + 1
	local s = CreateFrame("Slider", "GPPanelSlider" .. nSlider, padre, "OptionsSliderTemplate")
	s:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	s:SetWidth(ancho or 190)
	s:SetMinMaxValues(min, max)
	s:SetValueStep(paso)
	_G[s:GetName() .. "Low"]:SetText(min)
	_G[s:GetName() .. "High"]:SetText(max)
	s.titulo = _G[s:GetName() .. "Text"]
	s.campo, s.texto = campo, texto
	s:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v * 100 + 0.5) / 100
		GP.db[self.campo] = v
		self.titulo:SetText(self.texto .. ": " .. v)
	end)
	s:SetScript("OnMouseUp", function() GP:PedirRearmado() end)
	s:SetBackdrop(BD_PLANO)
	s:SetBackdropColor(0.04, 0.04, 0.05, 1)
	s:SetBackdropBorderColor(0.22, 0.22, 0.25, 1)
	s.titulo:SetTextColor(0.92, 0.92, 0.94)
	return s
end

local nCheck = 0
local function check(padre, texto, x, y, campo, alCambiar)
	nCheck = nCheck + 1
	local c = CreateFrame("CheckButton", "GPPanelCheck" .. nCheck, padre, "OptionsCheckButtonTemplate")
	c:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	_G[c:GetName() .. "Text"]:SetText(texto)
	c.campo = campo
	c:SetScript("OnClick", function(self)
		local v = self:GetChecked() and true or false
		if alCambiar then
			alCambiar(v)
		else
			GP.db[self.campo] = v
			GP:PedirRearmado()
		end
	end)
	return c
end

local function boton(padre, texto, x, y, ancho, alClick)
	return botonPlano(padre, texto, x, y, ancho, 23, alClick)
end

local nEB = 0
local function caja(padre, x, y, ancho, alAceptar)
	nEB = nEB + 1
	local e = CreateFrame("EditBox", "GPPanelEB" .. nEB, padre, "InputBoxTemplate")
	e:SetPoint("TOPLEFT", padre, "TOPLEFT", x, y)
	e:SetWidth(ancho)
	e:SetHeight(18)
	e:SetAutoFocus(false)
	e:SetScript("OnEnterPressed", function(self)
		alAceptar(self)
		self:ClearFocus()
	end)
	e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	return e
end

------------------------------------------------------------------
function GP:CrearPanel()
	local p = CreateFrame("Frame", "GrillaPlacasPanel", UIParent)
	p:SetWidth(ANCHO_P)
	p:SetHeight(ALTO_P)
	p:SetPoint("CENTER")
	p:SetBackdrop(BD_PANEL)
	pintar(p, COL.fondo)
	p:SetBackdropBorderColor(unpack(COL.borde))
	p:SetMovable(true)
	p:EnableMouse(true)
	p:RegisterForDrag("LeftButton")
	p:SetScript("OnDragStart", function(self) self:StartMoving() end)
	p:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	p:SetFrameStrata("DIALOG")
	p:Hide()
	tinsert(UISpecialFrames, "GrillaPlacasPanel")

	local barra = p:CreateTexture(nil, "ARTWORK")
	barra:SetTexture("Interface\\Buttons\\WHITE8x8")
	barra:SetVertexColor(unpack(COL.barra))
	barra:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
	barra:SetPoint("TOPRIGHT", p, "TOPRIGHT", -1, -1)
	barra:SetHeight(34)

	local tit = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tit:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -11)
	tit:SetText("GrillaPlacas")
	tit:SetTextColor(1, 0.82, 0.2)

	local cerrar = CreateFrame("Button", nil, p, "UIPanelCloseButton")
	cerrar:SetPoint("TOPRIGHT", p, "TOPRIGHT", -4, -3)

	------------------------------------------------------------------
	-- Pestanas
	------------------------------------------------------------------
	local NOMBRES = { "Grilla", "Aspecto", "Teclas", "Clicks" }
	p.hojas, p.pestanas = {}, {}

	local function mostrarHoja(n)
		for i, h in ipairs(p.hojas) do
			if i == n then h:Show() else h:Hide() end
			p.pestanas[i]:Marcar(i == n)
		end
		p.hojaActiva = n
		GP:RefrescarPanel()
	end
	p.MostrarHoja = mostrarHoja

	for i, nom in ipairs(NOMBRES) do
		local b = botonPlano(p, nom, 14 + (i - 1) * 110, -42, 106, 25, function() mostrarHoja(i) end)
		p.pestanas[i] = b

		local h = CreateFrame("Frame", nil, p)
		h:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -74)
		h:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 16)
		h:Hide()
		p.hojas[i] = h
	end

	------------------------------------------------------------------
	-- Hoja 1: Grilla
	------------------------------------------------------------------
	local g = p.hojas[1]
	etiqueta(g, "Presets", 22, -6, "GameFontNormal")
	divisor(g, 20, -22, 430)
	boton(g, "Lista", 20, -24, 130, function() GP:Estilo(1) GP:RefrescarPanel() end)
	boton(g, "Dos columnas", 158, -24, 130, function() GP:Estilo(2) GP:RefrescarPanel() end)
	boton(g, "Compacto", 296, -24, 130, function() GP:Estilo(3) GP:RefrescarPanel() end)
	etiqueta(g, "Despues retocalo con los deslizadores de abajo.", 22, -52)

	p.sPos = slider(g, "Celdas visibles", 25, -82, 1, 40, 1, "posiciones")
	p.sCol = slider(g, "Columnas", 240, -82, 1, 10, 1, "columnas")
	p.sAnc = slider(g, "Ancho de celda", 25, -132, 60, 300, 5, "ancho")
	p.sAlt = slider(g, "Alto de celda", 240, -132, 14, 80, 1, "alto")
	p.sSepH = slider(g, "Separacion horizontal", 25, -182, 0, 20, 1, "sepH")
	p.sSepV = slider(g, "Separacion vertical", 240, -182, 0, 20, 1, "sepV")
	p.sEsc = slider(g, "Escala general", 25, -232, 0.5, 2, 0.05, "escala")

	p.lblTam = etiqueta(g, "", 240, -238)

	p.cCombate = check(g, "Mostrar solo en combate", 20, -270, "soloCombate")
	p.cEnemigos = check(g, "Solo enemigos", 240, -270, "soloEnemigos")

	p.btnMover = boton(g, "Mover la grilla", 20, -310, 150, function()
		GP:AlternarMover()
		GP:RefrescarPanel()
	end)
	boton(g, "Valores de fabrica", 240, -310, 150, function()
		GP:Estilo(1)
		GP:RefrescarPanel()
	end)

	------------------------------------------------------------------
	-- Hoja 2: Aspecto
	------------------------------------------------------------------
	local a = p.hojas[2]
	p.sFuente = slider(a, "Tamano de letra", 25, -10, 8, 20, 1, "fuenteTam")
	p.sDot = slider(a, "DoTs por celda", 240, -10, 0, 6, 1, "maxDots")

	etiqueta(a, "Donde van los iconos de DoT", 22, -106, "GameFontNormal")
	divisor(a, 20, -120, 430)
	local function botIcono(texto, x, valor)
		return boton(a, texto, x, -124, 130, function()
			GP.db.iconoPos = valor
			GP:PedirRearmado()
			GP:RefrescarPanel()
		end)
	end
	p.bIcoDentro = botIcono("Dentro", 20, "dentro")
	p.bIcoFuera = botIcono("Afuera", 158, "fuera")
	p.bIcoAbajo = botIcono("Abajo", 296, "abajo")

	p.sIcoTam = slider(a, "Tamano de icono (0 = auto)", 25, -58, 0, 40, 1, "iconoTam")
	p.lblIco = etiqueta(a, "", 240, -64)
	p.sAviso = slider(a, "Avisar DoT por vencer (%)", 25, -164, 0, 60, 5, "avisoDot")

	p.cRoja = check(a, "Barra siempre roja (sin gradiente)", 20, -206, "barraRoja")
	p.cVida = check(a, "Mostrar % de vida", 20, -236, "mostrarVidaTexto")

	etiqueta(a, "Hechizo para el aviso de fuera de rango", 22, -272, "GameFontNormal")
	divisor(a, 20, -286, 430)
	p.ebRango = caja(a, 24, -296, 200, function(self)
		GP.db.hechizoRango = strtrim(self:GetText() or "")
		GP:Msg("Rango medido con: " .. (GP.db.hechizoRango ~= "" and GP.db.hechizoRango or "nada"))
	end)
	etiqueta(a, "Vacio = no mide rango.", 24, -318)

	------------------------------------------------------------------
	-- Hoja 3: Teclas
	------------------------------------------------------------------
	local t = p.hojas[3]
	etiqueta(t, "Castear sobre la celda que tengas debajo del mouse,", 22, -6)
	etiqueta(t, "apretando tus teclas de siempre. Sin macros.", 22, -22)

	p.cTeclas = check(t, "Activado", 20, -44, nil, function(v)
		GP:ActivarTeclas(v)
		GP:RefrescarPanel()
	end)

	boton(t, "Escanear barras", 240, -46, 150, function()
		GP:AutoTeclas()
		GP:RefrescarPanel()
	end)

	etiqueta(t, "Agregar a mano:", 22, -80, "GameFontNormal")
	p.ebTecla = caja(t, 24, -102, 70, function() end)
	p.ebHechizo = caja(t, 104, -102, 180, function() end)
	etiqueta(t, "tecla", 26, -122)
	etiqueta(t, "hechizo", 106, -122)
	boton(t, "Agregar", 292, -104, 100, function()
		GP:PonerTecla(p.ebTecla:GetText() or "", p.ebHechizo:GetText() or "")
		p.ebTecla:SetText("")
		p.ebHechizo:SetText("")
		GP:RefrescarPanel()
	end)

	etiqueta(t, "Teclas tomadas", 22, -150, "GameFontNormal")
	divisor(t, 20, -164, 430)
	p.filasTecla = {}
	for i = 1, 14 do
		local col = (i - 1) % 2
		local ren = math.floor((i - 1) / 2)
		local f = CreateFrame("Frame", nil, t)
		f:SetWidth(200)
		f:SetHeight(18)
		f:SetPoint("TOPLEFT", t, "TOPLEFT", 22 + col * 212, -172 - ren * 20)

		f.ico = f:CreateTexture(nil, "ARTWORK")
		f.ico:SetWidth(16)
		f.ico:SetHeight(16)
		f.ico:SetPoint("LEFT", f, "LEFT", 0, 0)
		f.ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)

		f.txt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.txt:SetPoint("LEFT", f, "LEFT", 20, 0)
		f.txt:SetWidth(158)
		f.txt:SetJustifyH("LEFT")

		f.x = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		f.x:SetWidth(20)
		f.x:SetHeight(20)
		f.x:SetPoint("RIGHT", f, "RIGHT", 4, 0)
		f.x:SetScript("OnClick", function(self)
			if self.clave then
				GP:PonerTecla(self.clave, "borrar")
				GP:RefrescarPanel()
			end
		end)
		f:Hide()
		p.filasTecla[i] = f
	end
	p.lblMasTeclas = etiqueta(t, "", 22, -320)

	boton(t, "Diagnostico de barras", 240, -348, 170, function() GP:EscaneoTeclas() end)
	boton(t, "Volcar a disco", 240, -378, 170, function() GP:Volcar() end)
	boton(t, "Levantar vetos", 22, -378, 170, function() GP:RestaurarVetadas() GP:RefrescarPanel() end)
	etiqueta(t, "Como manda el hechizo al bicho de abajo del mouse", 22, -412, "GameFontNormal")
	p.bModoHech = boton(t, "Castear directo", 22, -432, 170, function()
		GP:ModoTeclas("hechizo") GP:RefrescarPanel()
	end)
	p.bModoObj = boton(t, "Targetear y volver", 240, -432, 170, function()
		GP:ModoTeclas("objetivo") GP:RefrescarPanel()
	end)
	etiqueta(t, "Targetear y volver anda con cualquier barra, macro o item.", 22, -458)
	boton(t, "Borrar toda la lista", 22, -348, 170, function()
		GP:LimpiarTeclas()
		GP:RefrescarPanel()
	end)

	------------------------------------------------------------------
	-- Hoja 4: Clicks
	------------------------------------------------------------------
	local k = p.hojas[4]
	etiqueta(k, "Que hace cada click sobre una celda", 22, -6, "GameFontNormal")
	etiqueta(k, "1 izq, 2 der, 3 rueda. Vacio = no hace nada. Enter para guardar.", 22, -24)

	p.filas = {}
	for i, clave in ipairs(GP.CLAVES) do
		local col = (i - 1) % 2
		local ren = math.floor((i - 1) / 2)
		local f = CreateFrame("Frame", nil, k)
		f:SetWidth(200)
		f:SetHeight(18)
		f:SetPoint("TOPLEFT", k, "TOPLEFT", 22 + col * 212, -48 - ren * 24)

		f.ico = f:CreateTexture(nil, "ARTWORK")
		f.ico:SetWidth(16)
		f.ico:SetHeight(16)
		f.ico:SetPoint("LEFT", f, "LEFT", 0, 0)
		f.ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)

		f.lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.lbl:SetPoint("LEFT", f, "LEFT", 20, 0)
		f.lbl:SetWidth(48)
		f.lbl:SetJustifyH("LEFT")
		f.lbl:SetText(clave)

		local eb = caja(f, 0, 0, 108, function(self)
			local txt = strtrim(self:GetText() or "")
			local b = strlower(txt)
			if txt == "" then
				GP:SetBind(self.clave, "borrar")
			elseif b == "target" or b == "objetivo" then
				GP:SetBind(self.clave, "target")
			elseif b == "focus" or b == "foco" then
				GP:SetBind(self.clave, "focus")
			elseif strsub(txt, 1, 1) == "/" then
				GP:SetBind(self.clave, "macro", txt)
			else
				GP:SetBind(self.clave, "spell", txt)
			end
			GP:RefrescarPanel()
		end)
		eb:ClearAllPoints()
		eb:SetPoint("LEFT", f, "LEFT", 72, 0)
		eb.clave = clave
		f.eb = eb
		p.filas[clave] = f
	end

	etiqueta(k, "Modo de casteo del click", 22, -186, "GameFontNormal")
	etiqueta(k, "spell = directo. macro = /cast [@placa]. tcast = targetea, castea y vuelve.", 22, -204)
	p.btnModo = boton(k, "", 22, -224, 170, function()
		local m = GP.db.modoCast
		GP.db.modoCast = (m == "spell" and "macro") or (m == "macro" and "tcast") or "spell"
		GP:AplicarBinds()
		GP:RefrescarPanel()
	end)
	boton(k, "Diagnostico", 240, -224, 150, function() GP:Diagnostico() end)

	GP.panel = p
	mostrarHoja(1)
	p:Hide()
end

------------------------------------------------------------------
function GP:RefrescarPanel()
	local p = GP.panel
	if not p then return end
	local l = GP.db

	p.sPos:SetMinMaxValues(1, GP.MAX_TOKENS)
	_G[p.sPos:GetName() .. "High"]:SetText(GP.MAX_TOKENS)
	if l.posiciones > GP.MAX_TOKENS then l.posiciones = GP.MAX_TOKENS end
	p.sPos:SetValue(l.posiciones)
	p.sCol:SetValue(l.columnas)
	p.sAnc:SetValue(l.ancho)
	p.sAlt:SetValue(l.alto)
	p.sSepH:SetValue(l.sepH)
	p.sSepV:SetValue(l.sepV)
	p.sEsc:SetValue(l.escala)
	p.sFuente:SetValue(l.fuenteTam)
	p.sDot:SetValue(l.maxDots)
	p.sAviso:SetValue(l.avisoDot or 30)
	p.sIcoTam:SetValue(l.iconoTam or 0)
	local lado, filas = GP.ladoIcono or 0, GP.filasIcono or 0
	local aviso = string.format("Iconos de %dpx en %d fila(s)", lado, filas)
	if lado > 0 and lado < 18 then
		aviso = aviso .. "\n|cffff6666Quedan chicos. Subi el alto de celda.|r"
	end
	p.lblIco:SetText(aviso)

	local filas = math.ceil(l.posiciones / l.columnas)
	p.lblTam:SetText(string.format("Ocupa %d x %d pixeles en pantalla",
		math.floor((l.ancho + l.sepH) * l.columnas * l.escala),
		math.floor((l.alto + l.sepV) * filas * l.escala)))

	p.cCombate:SetChecked(l.soloCombate)
	p.cEnemigos:SetChecked(l.soloEnemigos)
	p.cRoja:SetChecked(l.barraRoja)
	p.cVida:SetChecked(l.mostrarVidaTexto)
	p.btnMover:SetText(l.bloqueada and "Mover la grilla" or "Fijar la grilla")
	p.ebRango:SetText(l.hechizoRango or "")

	local pos = l.iconoPos or "dentro"
	p.bIcoDentro:Marcar(pos == "dentro")
	p.bIcoFuera:Marcar(pos == "fuera")
	p.bIcoAbajo:Marcar(pos == "abajo")

	-- teclas
	p.cTeclas:SetChecked(GP.pj.teclasOn)
	local claves = {}
	for kk in pairs(GP.pj.teclas or {}) do claves[#claves + 1] = kk end
	table.sort(claves)
	for i, f in ipairs(p.filasTecla) do
		local cl = claves[i]
		if cl then
			local hechizo = GP.pj.teclas[cl]
			local nom, _, ico = GetSpellInfo(hechizo)
			f.ico:SetTexture(ico or "Interface\\Icons\\INV_Misc_QuestionMark")
			local b = GP.pj.teclasBoton and GP.pj.teclasBoton[cl]
			local sl = GP.pj.teclasSlot and GP.pj.teclasSlot[cl]
			local origen = ""
			if b or sl then origen = "  |cff777777" .. tostring(b or "?") .. "|r" end
			f.txt:SetText("|cffffd100" .. cl .. "|r  " .. (nom or hechizo) .. origen)
			f.x.clave = cl
			f:Show()
		else
			f:Hide()
		end
	end
	if #claves > #p.filasTecla then
		p.lblMasTeclas:SetText("y " .. (#claves - #p.filasTecla) .. " mas (usa /grilla teclas para verlas todas)")
	else
		p.lblMasTeclas:SetText("")
	end

	local mt = GP.pj.teclasModo or "hechizo"
	if p.bModoHech then p.bModoHech:Marcar(mt == "hechizo") end
	if p.bModoObj then p.bModoObj:Marcar(mt == "objetivo") end

	-- clicks
	p.btnModo:SetText("Casteo: " .. l.modoCast)
	for clave, f in pairs(p.filas) do
		local b = GP.pj.binds[clave]
		if b then
			if b.tipo == "target" then
				f.eb:SetText("target")
				f.ico:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
			elseif b.tipo == "focus" then
				f.eb:SetText("focus")
				f.ico:SetTexture("Interface\\Icons\\Ability_Hunter_MasterMarksman")
			else
				f.eb:SetText(b.valor or "")
				local tex = (b.tipo == "spell" and GetSpellTexture and GetSpellTexture(b.valor or "")) or nil
				f.ico:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
			end
		else
			f.eb:SetText("")
			f.ico:SetTexture(nil)
		end
	end
end
