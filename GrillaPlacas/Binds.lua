-- GrillaPlacas 0.1 - Binds
-- Que hace cada click sobre una celda. Los atributos se escriben una sola vez,
-- fuera de combate, porque la unidad de cada celda es fija.

local GP = GrillaPlacas
local MODS = { "", "shift-", "ctrl-", "alt-" }

function GP:ParsearClave(clave)
	local mod, boton = string.match(clave, "^(%a+)%-(%d)$")
	if mod then
		mod = string.lower(mod)
		if mod ~= "shift" and mod ~= "ctrl" and mod ~= "alt" then return nil, nil end
		mod = mod .. "-"
	else
		boton = string.match(clave, "^(%d)$")
		mod = ""
	end
	if not boton then return nil, nil end
	local n = tonumber(boton)
	if not n or n < 1 or n > 5 then return nil, nil end
	return mod, boton
end

local function limpiar(c)
	for _, m in ipairs(MODS) do
		for b = 1, 5 do
			c:SetAttribute(m .. "type" .. b, nil)
			c:SetAttribute(m .. "spell" .. b, nil)
			c:SetAttribute(m .. "macrotext" .. b, nil)
		end
	end
end

function GP:AplicarBinds()
	if not GP.celdas[1] then return end
	if InCombatLockdown() then
		GP.bindsPendientes = true
		return
	end

	local modo = GP.db.modoCast

	for i = 1, GP.MAX_TOKENS do
		local c = GP.celdas[i]
		if c then
			limpiar(c)
			for clave, b in pairs(GP.pj.binds) do
				local mod, boton = GP:ParsearClave(clave)
				if mod and boton and b and b.tipo then
					if b.tipo == "target" then
						c:SetAttribute(mod .. "type" .. boton, "target")
					elseif b.tipo == "focus" then
						c:SetAttribute(mod .. "type" .. boton, "focus")
					elseif b.tipo == "spell" and b.valor and b.valor ~= "" then
						if modo == "macro" then
							c:SetAttribute(mod .. "type" .. boton, "macro")
							c:SetAttribute(mod .. "macrotext" .. boton, "/cast [@" .. c.token .. "] " .. b.valor)
						else
							c:SetAttribute(mod .. "type" .. boton, "spell")
							c:SetAttribute(mod .. "spell" .. boton, b.valor)
						end
					elseif b.tipo == "macro" and b.valor and b.valor ~= "" then
						c:SetAttribute(mod .. "type" .. boton, "macro")
						c:SetAttribute(mod .. "macrotext" .. boton, string.gsub(b.valor, "@placa", "@" .. c.token))
					end
				end
			end
		end
	end
	GP.bindsPendientes = false
end

function GP:SetBind(clave, tipo, valor)
	local mod, boton = GP:ParsearClave(clave)
	if not boton then
		GP:Msg("Clave invalida. Se escribe asi: 1, 2, shift-1, ctrl-2, alt-1 (del 1 al 5).")
		return
	end
	if tipo == "borrar" then
		GP.pj.binds[clave] = nil
		GP:Msg("Borrado el bind " .. clave .. ".")
	else
		GP.pj.binds[clave] = { tipo = tipo, valor = valor }
		GP:Msg("Bind " .. clave .. " = " .. tipo .. (valor and (" " .. valor) or "") .. ".")
	end
	GP:AplicarBinds()
	if GP.RefrescarPanel then GP:RefrescarPanel() end
end

function GP:ListarBinds()
	GP:Msg("Binds de este personaje (modo de casteo: " .. GP.db.modoCast .. "):")
	local hay = false
	for _, m in ipairs(MODS) do
		for b = 1, 5 do
			local clave = m .. b
			local v = GP.pj.binds[clave]
			if v then
				hay = true
				DEFAULT_CHAT_FRAME:AddMessage("   " .. clave .. "  ->  " .. v.tipo .. (v.valor and v.valor ~= "" and (" " .. v.valor) or ""))
			end
		end
	end
	if not hay then DEFAULT_CHAT_FRAME:AddMessage("   (ninguno)") end
end

local vigia = CreateFrame("Frame")
vigia:RegisterEvent("PLAYER_REGEN_ENABLED")
vigia:SetScript("OnEvent", function()
	if GP.bindsPendientes then GP:AplicarBinds() end
	if GP.layoutPendiente then
		GP.layoutPendiente = false
		if GP.RearmarTodo then GP:RearmarTodo() else GP:Reiniciar() end
	end
end)
