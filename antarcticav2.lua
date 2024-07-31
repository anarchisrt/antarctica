--[[
	API: https://docs.gamesense.gs/docs/api
]]--



cvar.cl_foot_contact_shadows:set_int(0)
cvar.sv_airaccelerate:set_int(100)

local render = renderer
local events = client

local ffi = require 'ffi'
local vector = require 'vector'
local entitys = require 'gamesense/entity'

local VGUI_System010 =  events.create_interface('vgui2.dll', 'VGUI_System010')
local VGUI_System = ffi.cast(ffi.typeof('void***'), VGUI_System010)

ffi.cdef [[
	typedef int(__thiscall* get_clipboard_text_count)(void*);
	typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
	typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
	]]

	local get_clipboard_text_count = ffi.cast('get_clipboard_text_count', VGUI_System[0][7])
	local set_clipboard_text = ffi.cast('set_clipboard_text', VGUI_System[0][9])
	local get_clipboard_text = ffi.cast('get_clipboard_text', VGUI_System[0][11])

	local clipboard_import = function()
	  local clipboard_text_length = get_clipboard_text_count( VGUI_System )
	local clipboard_data = ''

	if clipboard_text_length > 0 then
		buffer = ffi.new('char[?]', clipboard_text_length)
		size = clipboard_text_length * ffi.sizeof('char[?]', clipboard_text_length)

		get_clipboard_text( VGUI_System, 0, buffer, size )
		clipboard_data = ffi.string( buffer, clipboard_text_length-1 )
	end

	return clipboard_data
end

local lua = {}

lua.sound = 'ui/csgo_ui_contract_type1'
lua.network = panorama.open().SteamOverlayAPI.OpenExternalBrowserURL
cvar.play:invoke_callback(lua.sound)

local software = {}
local motion = {}
local backup = {}
local gui = {}
local g_ctx = {}
local builder = {}
local indicators = {}
local corrections = {}
local cwar = {}
local def = {}

do
	function software.init()
		software.rage = {
			binds = {
				minimum_damage = ui.reference('rage', 'aimbot', 'minimum damage'),
				minimum_damage_override = {ui.reference('rage', 'aimbot', 'minimum damage override')},
				minimum_hitchance = ui.reference('rage', 'aimbot', 'minimum hit chance'),
				double_tap = {ui.reference('rage', 'aimbot', 'double tap')},
				ps = { ui.reference('misc', 'miscellaneous', 'ping spike') },
				quickpeek = {ui.reference('rage', 'other', 'quick peek assist')},
				on_shot_anti_aim = {ui.reference('aa', 'other', 'on shot anti-aim')},
				usercmd = ui.reference('misc', 'settings', 'sv_maxusrcmdprocessticks2')
			}
		}
		software.antiaim = {
			angles = {
				enabled = ui.reference('AA', 'Anti-aimbot angles', 'Enabled'),
				pitch = { ui.reference('AA', 'Anti-aimbot angles', 'Pitch') },
				roll = ui.reference('AA', 'Anti-aimbot angles', 'Roll'),
				yaw_base = ui.reference('AA', 'Anti-aimbot angles', 'Yaw base'),
				yaw = { ui.reference('AA', 'Anti-aimbot angles', 'Yaw') },
				freestanding_body_yaw = ui.reference('AA', 'anti-aimbot angles', 'Freestanding body yaw'),
				edge_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Edge yaw'),
				yaw_jitter = { ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter') },
				desync = { ui.reference('AA', 'Anti-aimbot angles', 'Body yaw') },
				freestanding = { ui.reference('AA', 'Anti-aimbot angles', 'Freestanding') },
				roll_aa = ui.reference('AA', 'Anti-aimbot angles', 'Roll')
			},
			fakelag = {
				on = {ui.reference('AA', 'Fake lag', 'Enabled')},
				amount = ui.reference('AA', 'Fake lag', 'Amount'),
				variance = ui.reference('AA', 'Fake lag', 'Variance'),
				limit = ui.reference('AA', 'Fake lag', 'Limit')
			},
			other = {
				slide = {ui.reference('AA','other','slow motion')},
				fakeduck = ui.reference('rage','other','duck peek assist'),
				slow_motion = {ui.reference('AA', 'Other', 'Slow motion')},
				fake_peek = {ui.reference('AA', 'Other', 'Fake peek')},
				leg_movement = ui.reference('AA', 'Other', 'Leg movement')
			}
		}
		software.visuals = {
			effects = {
				thirdperson = { ui.reference('VISUALS', 'Effects', 'Force third person (alive)') },
				dpi = ui.reference('misc', 'settings', 'dpi scale'),
				clrmenu = ui.reference('misc', 'settings', 'menu color'),
				output = ui.reference('Misc', 'Miscellaneous', 'Draw console output'),
				fov = ui.reference('Misc', 'Miscellaneous', 'override fov'),
				zfov = ui.reference('Misc', 'Miscellaneous', 'override zoom fov')
			}
		}
	end
end

do
	local function linear(t, b, c, d)
		return c * t / d + b
	end

	local function get_deltatime()
		return globals.frametime()
	end

	local function solve(easing_fn, prev, new, clock, duration)
		if clock <= 0 then return new end
		if clock >= duration then return new end

		prev = easing_fn(clock, prev, new - prev, duration)

		if type(prev) == 'number' then
			if math.abs(new - prev) < 0.001 then
				return new
			end

			local remainder = math.fmod(prev, 1.0)

			if remainder < 0.001 then
				return math.floor(prev)
			end

			if remainder > 0.999 then
				return math.ceil(prev)
			end
		end

		return prev
	end

	function motion.interp(a, b, t, easing_fn)
		easing_fn = easing_fn or linear

		if type(b) == 'boolean' then
			b = b and 1 or 0
		end

		return solve(easing_fn, a, b, get_deltatime(), t)
	end

	function motion.lerp(a, b, t)
		return (b - a) * t + a
	end

	function motion.lerp_color(r1, g1, b1, a1, r2, g2, b2, a2, t)
		local r = motion.lerp(r1, r2, t)
		local g = motion.lerp(g1, g2, t)
		local b = motion.lerp(b1, b2, t)
		local a = motion.lerp(a1, a2, t)

		return r, g, b, a
	end

	function motion.normalize_acid(x, min, max)
		local delta = max - min

		while x < min do
			x = x + delta
		end

		while x > max do
			x = x - delta
		end

		return x
	end

	function motion.normalize_yaw_acid(x)
		return motion.normalize_acid(x, -180, 180)
	end

	function motion.animation(name, value, speed)
		return name + (value - name) * globals.frametime() * speed
	end

	function motion.logs()
		local offset, x, y = 0, 10, -9
		for idx, data in ipairs(lua) do
			if globals.curtime() - data[3] < 5 and not (#lua > 7 and idx < #lua - 7) and entity.is_alive(g_ctx.lp) then
				data[2] = motion.animation(data[2], 255, 4)
			else
				data[2] = motion.animation(data[2], 0, 4)
			end
	
			local opt = ''
			if ui.get(gui.menu.logsfont) == 'Small' then
				opt = '-'
			elseif ui.get(gui.menu.logsfont) == 'Default' then
				opt = ''
			elseif ui.get(gui.menu.logsfont) == 'Bold' then
				opt = 'b'
			end

			offset = offset - 16 * (data[2] / 255)
			local text_log = data[5] and data[1] or data[1]
			local text_sizex, text_sizey = render.measure_text(opt, text_log)
			if data[12] then
				render.text(x, y - offset, data[8], data[9], data[10], data[11] * (data[2] / 255), opt, nil, ui.get(gui.menu.logsfont) == 'Small' and text_log:upper() or text_log)
			end

			if data[7] then
				render.text(x + g_ctx.screen[1] / 2 - text_sizex / 2, y + g_ctx.screen[2] - 300 - offset, data[8], data[9], data[10], data[11] * (data[2] / 255), opt, nil, ui.get(gui.menu.logsfont) == 'Small' and text_log:upper() or text_log)
			end
			
			if data[2] < .1 then table.remove(lua, idx) end
		end
	end
	
	function motion.push(text, shadow, icon, font, center, r, g, b, a, output)
		table.insert(lua, { text, 0, globals.curtime(), shadow, icon, font, center, r, g, b, a, output })
	end
end

do
	function gui.init()
		gui.anim = {}
		gui.anim.builder = {}
		gui.menu = {}
		gui.aa = 'aa'
		gui.aaim = 'anti-aimbot angles'
		gui.lag = 'fake lag'
		gui.abcd = 'other'
		gui.color = def.gui:hex_label({ui.get(software.visuals.effects.clrmenu)})
		lua.user = entity.get_player_name(entity.get_local_player())
		gui.warning = def.gui:hex_label({215, 55, 55, 215})
		gui.risk = def.gui:hex_label({215, 215, 55, 215})
		gui.menuc = def.gui:hex_label({215, 215, 215, 215})
		--9FCA2BFF
		
		gui.menu.luac = ui.new_label(gui.aa,gui.lag, gui.color..'2.0 Debug, ' .. lua.user)
		gui.menu.lua = ui.new_combobox(gui.aa, gui.lag, gui.menuc..'Antarctica' ..gui.color..' Recode', 'Antiaim', 'Visuals', 'Misc')--⛧
		gui.menu.miscellaneous = ui.new_combobox(gui.aa, gui.lag, '\n', 'Main', 'Other')

		gui.anim.builderanim = {'off', '1', '.5', '.0', 'bsod'}
		gui.anim.anm = {'Move lean', 'Run in air', 'Line run', 'Static legs in air', 'Static legs on ground', 'Model scale'}
		gui.anim.animbreaker = ui.new_combobox(gui.aa, gui.abcd, gui.risk..'Animations', 'Move lean', 'Run in air', 'Line run', 'Static legs in air', 'Static legs on ground', 'Model scale')

		ui.set_callback(gui.anim.animbreaker, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)

		for i, name in pairs(gui.anim.anm) do
			gui.anim.builder[name] = {
				pose_layer = ui.new_combobox(gui.aa, gui.abcd, gui.risk..'Settings '..name, gui.anim.builderanim),
				bsod1 = ui.new_slider(gui.aa,gui.abcd, gui.risk..'Bsod start '..name, .0, 10, .1, true, nil, .1),
				bsod2 = ui.new_slider(gui.aa,gui.abcd, gui.risk..'Bsod end '..name, .0, 10, .1, true, nil, .1),
			}
			ui.set_callback(gui.anim.builder[name].pose_layer, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
		end
		gui.menu.grfl = ui.new_checkbox(gui.aa, gui.abcd, gui.risk..'Flashed')

		gui.menu.outputlogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Output logs')
		gui.menu.cenlogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Center logs')
		gui.menu.hitlogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Hit logs')
		gui.menu.hitcolor = ui.new_color_picker(gui.aa,gui.aaim, 'Hit logs color', 215, 215, 215)
		gui.menu.misslogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Miss logs')
		gui.menu.misscolor = ui.new_color_picker(gui.aa,gui.aaim,'Miss logs color', 215, 155, 155)
		gui.menu.reglogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Reg logs')
		gui.menu.regcolor = ui.new_color_picker(gui.aa,gui.aaim,'Reg logs color', 155, 155, 215)
		gui.menu.nadelogs = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Hurt logs')
		gui.menu.nadecolor = ui.new_color_picker(gui.aa,gui.aaim,'Hurt logs color', 155, 215, 155)
		gui.menu.logsfont = ui.new_combobox(gui.aa, gui.aaim, '\n Logs font', 'Small', 'Verdana', 'Bold')

		gui.thirdperson = ui.new_slider(gui.aa, gui.abcd, gui.menuc..'Thirdperson distance', 30, 300, cvar.cam_idealdist:get_int(), true, '°')
		gui.thirdperson_on = ui.new_checkbox(gui.aa, gui.abcd, gui.menuc..'Enable thirdperson animation')
		gui.aspectratio = ui.new_slider(gui.aa, gui.abcd, gui.menuc..'Aspect ratio', 0, 300, 0, true, 'px', .01)
		gui.fov = ui.new_slider(gui.aa, gui.abcd, gui.menuc..'Field of view', 1, 135, ui.get(software.visuals.effects.fov), true, '°')
		gui.zoom = ui.new_slider(gui.aa, gui.abcd, gui.menuc..'Zoom field of view', 0, 90, 0, true, '°')
		gui.zoom_on = ui.new_checkbox(gui.aa, gui.abcd, gui.menuc..'Enable zoom animation')

		ui.set_callback(gui.menu.lua, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.miscellaneous, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.outputlogs, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.cenlogs, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.logsfont, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.hitlogs, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.misslogs, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.reglogs, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.menu.grfl, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.thirdperson_on, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.zoom_on, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
	end

		local native_GetClientEntity = vtable_bind('client.dll', 'VClientEntityList003', 3, 'void*(__thiscall*)(void*, int)')
		local char_ptr = ffi.typeof('char*')
		local nullptr = ffi.new('void*')
		local class_ptr = ffi.typeof('void***')
		local animation_layer_t = ffi.typeof([[
		struct {										char pad0[0x18];
			uint32_t	sequence;
			float		prev_cycle;
			float		weight;
			float		weight_delta_rate;
			float		playback_rate;
			float		cycle;
			void		*entity;				char pad1[0x4];
		} **
		]])
	
		def.gui = {
			hide_aa_tab = function(boolean)
				ui.set_visible(software.antiaim.angles.enabled, not boolean)
				ui.set_visible(software.antiaim.angles.pitch[1], not boolean)
				ui.set_visible(software.antiaim.angles.pitch[2], not boolean)
				ui.set_visible(software.antiaim.angles.roll, not boolean)
				ui.set_visible(software.antiaim.angles.yaw_base, not boolean)
				ui.set_visible(software.antiaim.angles.yaw[1], not boolean)
				ui.set_visible(software.antiaim.angles.yaw[2], not boolean)
				ui.set_visible(software.antiaim.angles.yaw_jitter[1], not boolean)
				ui.set_visible(software.antiaim.angles.yaw_jitter[2], not boolean)
				ui.set_visible(software.antiaim.angles.desync[1], not boolean)
				ui.set_visible(software.antiaim.angles.desync[2], not boolean)
				ui.set_visible(software.antiaim.angles.freestanding[1], not boolean)
				ui.set_visible(software.antiaim.angles.freestanding[2], not boolean)
				ui.set_visible(software.antiaim.angles.freestanding_body_yaw, not boolean)
				ui.set_visible(software.antiaim.angles.edge_yaw, not boolean)
				ui.set_visible(software.antiaim.fakelag.on[1], not boolean)
				ui.set_visible(software.antiaim.fakelag.on[2], not boolean)
				ui.set_visible(software.antiaim.fakelag.variance, not boolean)
				ui.set_visible(software.antiaim.fakelag.amount, not boolean)
				ui.set_visible(software.antiaim.fakelag.limit, not boolean)
				ui.set_visible(software.rage.binds.on_shot_anti_aim[1], not boolean)	
				ui.set_visible(software.rage.binds.on_shot_anti_aim[2], not boolean)
				ui.set_visible(software.antiaim.other.slow_motion[1], not boolean)
				ui.set_visible(software.antiaim.other.slow_motion[2], not boolean)
				ui.set_visible(software.antiaim.other.fake_peek[1], not boolean)
				ui.set_visible(software.antiaim.other.fake_peek[2], not boolean)
				ui.set_visible(software.antiaim.other.leg_movement, not boolean)
			end,
			anim = function()
				local player_ptr = ffi.cast(class_ptr, native_GetClientEntity(g_ctx.lp))
				if player_ptr == nullptr then
					return
				end

				local first_velocity, second_velocity = entity.get_prop(g_ctx.lp, 'm_vecVelocity')
				local speed = math.floor(math.sqrt(first_velocity*first_velocity+second_velocity*second_velocity))
	
				local a12 = ui.get(gui.anim.builder['Move lean'].pose_layer)
				local a6 = ui.get(gui.anim.builder['Run in air'].pose_layer)
				local p7 = ui.get(gui.anim.builder['Line run'].pose_layer)
				local p6 = ui.get(gui.anim.builder['Static legs in air'].pose_layer)
				local p0 = ui.get(gui.anim.builder['Static legs on ground'].pose_layer)
				local mdscl = ui.get(gui.anim.builder['Model scale'].pose_layer)
				local bsdstrt12 = ui.get(gui.anim.builder['Move lean'].bsod1) * .1
				local bsdnd12 = ui.get(gui.anim.builder['Move lean'].bsod2) * .1
				local bsdstrt6 = ui.get(gui.anim.builder['Run in air'].bsod1) * .1
				local bsdnd6 = ui.get(gui.anim.builder['Run in air'].bsod2) * .1
				local bsdstrt7 = ui.get(gui.anim.builder['Line run'].bsod1) * .1
				local bsdnd7 = ui.get(gui.anim.builder['Line run'].bsod2) * .1
				local sbsdstrt = ui.get(gui.anim.builder['Static legs in air'].bsod1) * .1
				local sbsdnd = ui.get(gui.anim.builder['Static legs in air'].bsod2) * .1
				local bsdstrt0 = ui.get(gui.anim.builder['Static legs on ground'].bsod1) * .1
				local bsdnd0 = ui.get(gui.anim.builder['Static legs on ground'].bsod2) * .1
				local models = ui.get(gui.anim.builder['Model scale'].bsod1) * .1
				local modelsc = ui.get(gui.anim.builder['Model scale'].bsod2) * .1
	
				local realtime12 = globals.realtime() / 2 % 1
				local nolag12 = realtime12
	
				local realtime6 = globals.realtime() / 2 % 1
				local nolag6 = realtime6
				local anim_layers = ffi.cast(animation_layer_t, ffi.cast(char_ptr, player_ptr) + 0x2990)[0]
	
				if speed > 5 then
					if a12 == '1' then
						anim_layers[12]['weight'] = 1
						anim_layers[12]['cycle'] = nolag12
					elseif a12 == '.5' then
						anim_layers[12]['weight'] = .5
						anim_layers[12]['cycle'] = nolag12
					elseif a12 == '.0' then
						anim_layers[12]['weight'] = .0
						anim_layers[12]['cycle'] = nolag12
					elseif a12 == 'bsod' then
						anim_layers[12]['weight'] = events.random_float(bsdstrt12, bsdnd12)
						anim_layers[12]['cycle'] = nolag12
					end
			
					if not g_ctx.grtck then
						if a6 == '1' then
							anim_layers[6]['weight'] = 1
							anim_layers[6]['cycle'] = nolag6
						elseif a6 == '.5' then
							anim_layers[6]['weight'] = .5
							anim_layers[6]['cycle'] = nolag6
						elseif a6 == '.0' then
							anim_layers[6]['weight'] = .0
							anim_layers[6]['cycle'] = nolag6
						elseif a6 == 'bsod' then
							anim_layers[6]['weight'] = events.random_float(bsdstrt6, bsdnd6)
							anim_layers[6]['cycle'] = nolag6
						end
					end
			
					if p7 == '1' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', 1, 7)
					elseif p7 == '.5' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .5, 7)
					elseif p7 == '.0' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .0, 7)
					elseif p7 == 'bsod' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', events.random_float(bsdstrt7, bsdnd7), 7)
					end
			
					if p6 == '1' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', 1, 6)
					elseif p6 == '.5' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .5, 6)
					elseif p6 == '.0' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .0, 6)
					elseif p6 == 'bsod' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', events.random_float(sbsdstrt, sbsdnd), 6)
					end

					if p0 == '1' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', 1, 0)
					elseif p0 == '.5' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .5, 0)
					elseif p0 == '.0' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', .0, 0)
					elseif p0 == 'bsod' then
						entity.set_prop(g_ctx.lp, 'm_flPoseParameter', events.random_float(bsdstrt0, bsdnd0), 0)
					end
				end
	
				if mdscl == '1' then
					entity.set_prop(g_ctx.lp, 'm_flModelScale', 1)
				elseif mdscl == '.5' then
					entity.set_prop(g_ctx.lp, 'm_flModelScale', .5)
				elseif mdscl == '.0' then
					entity.set_prop(g_ctx.lp, 'm_flModelScale', .0)
				elseif mdscl == 'bsod' then
					entity.set_prop(g_ctx.lp, 'm_flModelScale', events.random_float(models, modelsc))
				else
					entity.set_prop(g_ctx.lp, 'm_flModelScale', 1)
				end

				if ui.get(gui.menu.grfl) then
					anim_layers[0]['sequence'] = 227
				end
			end,
			hex_label = function(self, rgb)
				local hexadecimal= '\a'
				
				for key, value in pairs(rgb) do
					local hex = ''
			
					while value > 0 do
						local index = math.fmod(value, 16) + 1
						value = math.floor(value/16)
						hex = ('0123456789ABCDEF'):sub(index, index) .. hex
					end
			
					if #hex == 0 then 
						hex= '00' 
					elseif #hex == 1 then 
						hex= '0' .. hex 
					end
			
					hexadecimal = hexadecimal .. hex
				end 
				
				return hexadecimal
			end,
			text = function(color1, color11, color111, color1111, color2, color22, color222, color2222, text, speed)
				local r1, g1, b1, a1 = color1, color11, color111, color1111
				local r2, g2, b2, a2 = color2, color22, color222, color2222
				local highlight_fraction =  (globals.realtime() / 2 % 1.2 * speed) - 1.2
				local output = ''
				for idx = 1, #text do
					local character = text:sub(idx, idx)
					local character_fraction = idx / #text
					local r, g, b, a = r1, g1, b1, a1
					local highlight_delta = (character_fraction - highlight_fraction)
					if highlight_delta >= 0 and highlight_delta <= 1.4 then
						if highlight_delta > 0.7 then
							highlight_delta = 1.4 - highlight_delta
						end
						local r_fraction, g_fraction, b_fraction, a_fraction = r2 - r, g2 - g, b2 - b
						r = r + r_fraction * highlight_delta / 0.8
						g = g + g_fraction * highlight_delta / 0.8
						b = b + b_fraction * highlight_delta / 0.8
					end
					output = output .. ('\a%02x%02x%02x%02x%s'):format(r, g, b, 255, text:sub(idx, idx))
				end
				return output
			end,
		}

		function gui.shut()
			def.gui.hide_aa_tab(false)
		end

		function gui.render()
			local luatabaa = ui.get(gui.menu.lua) == 'Antiaim'
			local luatabvis = ui.get(gui.menu.lua) == 'Visuals'
			local luatabmisc = ui.get(gui.menu.lua) == 'Misc'
			local indsd = ui.get(gui.indicators.indicator)
			local dmgind = ui.get(gui.indicators.damage_indicator)
			ui.set_visible(gui.menu.miscellaneous, luatabaa)
			ui.set_visible(gui.indicators.manual2arrows, luatabvis)
			ui.set_visible(gui.indicators.maincolor, luatabvis)
			ui.set_visible(gui.indicators.backcolor, luatabvis)
			ui.set_visible(gui.indicators.wmaincolor, luatabvis)
			ui.set_visible(gui.indicators.wbackcolor, luatabvis)
			ui.set_visible(gui.indicators.indicator, luatabvis)
			ui.set_visible(gui.indicators.indicator_color, luatabvis and indsd)
			ui.set_visible(gui.indicators.indicator_font, luatabvis and indsd)
			ui.set_visible(gui.indicators.indicator_slider, luatabvis and indsd)
			ui.set_visible(gui.indicators.damage_indicator, luatabvis)
			ui.set_visible(gui.indicators.damage_indicator_color, luatabvis and dmgind)
			ui.set_visible(gui.indicators.damage_indicator_font, luatabvis and dmgind)
			ui.set_visible(gui.indicators.watermark_style, luatabvis)
			ui.set_visible(gui.indicators.watermark_font, luatabvis)
			ui.set_visible(gui.thirdperson, luatabvis)
			ui.set_visible(gui.thirdperson_on, luatabvis)
			ui.set_visible(gui.menu.hitlogs, luatabmisc)
			ui.set_visible(gui.menu.reglogs, luatabmisc)
			ui.set_visible(gui.menu.misslogs, luatabmisc)
			ui.set_visible(gui.menu.regcolor, luatabmisc)
			ui.set_visible(gui.menu.hitcolor, luatabmisc)
			ui.set_visible(gui.menu.misscolor, luatabmisc)
			ui.set_visible(gui.menu.logsfont, luatabmisc)
			ui.set_visible(gui.menu.cenlogs, luatabmisc)
			ui.set_visible(gui.menu.outputlogs, luatabmisc)
			ui.set_visible(gui.menu.nadelogs, luatabmisc)
			ui.set_visible(gui.menu.nadecolor, luatabmisc)
			ui.set_visible(gui.aspectratio, luatabvis)
			ui.set_visible(gui.fov, luatabvis)
			ui.set_visible(gui.zoom, luatabvis)
			ui.set_visible(gui.zoom_on, luatabvis)
			ui.set_visible(gui.menu.grfl, luatabmisc)

			ui.set_visible(gui.anim.animbreaker, luatabmisc)
			for i, name in pairs(gui.anim.anm) do
				local opened = name == ui.get(gui.anim.animbreaker)
				local bsod = ui.get(gui.anim.builder[name].pose_layer) == 'bsod'
				ui.set_visible(gui.anim.builder[name].pose_layer, opened and luatabmisc)
				ui.set_visible(gui.anim.builder[name].bsod1, opened and luatabmisc and bsod)
				ui.set_visible(gui.anim.builder[name].bsod2, opened and luatabmisc and bsod)
			end

			ui.set(software.visuals.effects.output, false)
			ui.set_enabled(software.visuals.effects.output, false)
		end

		function gui.animbuilder()
			if not entity.is_alive(g_ctx.lp) then
				return
			end
			def.gui:anim()
		end
end

do 
	function g_ctx.render()
		g_ctx.lp = entity.get_local_player()
		g_ctx.screen = {events.screen_size()}
	end
end

do
	body = function(animstate)
		local yaw = animstate.eye_angles_y - animstate.goal_feet_yaw
		yaw = motion.normalize_yaw_acid(yaw)
		return yaw
	end

	def.values = {
		cmd = 0,
		check = 0,
		defensive = 0,
		flags = 0,
        packets = 0,
		body = 0,
		choking = 0,
		spin = 0,
		spinv2 = 0,
		choking_bool = false,
		run = function(cmd)
			def.values.cmd = cmd.command_number
			def.values.choking = 1
			def.values.choking_bool = false
		end,
		predict = function(cmd)
			if cmd.command_number == def.values.cmd then
				local tickbase = entity.get_prop(entity.get_local_player(), 'm_nTickBase')
				def.values.defensive = math.abs(tickbase - def.values.check)
				def.values.check = math.max(tickbase, def.values.check or 0)
				def.values.cmd = 0
			end
		end,
		net = function(cmd)
			if g_ctx.lp == nil then return end
			local my_data = entitys(g_ctx.lp)
            if my_data == nil then return end

            local animstate = entitys.get_anim_state(my_data)
            if animstate == nil then return end

			local chokedcommands = globals.chokedcommands()
            if chokedcommands == 0 then
                def.values.packets = def.values.packets + 1
                def.values.choking = def.values.choking * -1
                def.values.choking_bool = not def.values.choking_bool
				def.values.body = body(animstate)
            end
		end
	}
end

do
	local ctx = {}

	function builder.init()
		ctx.onground = false
		ctx.ticks = -1
		ctx.state = 'Shared'
		ctx.condition_names = {'Shared', 'Stand', 'Moving', 'Slow Moving', 'Duck', 'Duck Moving', 'Air', 'Air Duck', 'Freestand'}
		
		gui.conditions = {}
		gui.conditions.state = ui.new_combobox(gui.aa, gui.aaim, 'State', 'Shared', 'Stand', 'Moving', 'Slow Moving', 'Duck', 'Duck Moving', 'Air', 'Air Duck', 'Freestand')

		ctx.amount = { [1] = 'Off', [15] = 'Max', [16] = 'Ext', [17] = 'Lag' }

		gui.spinwhendead = ui.new_checkbox(gui.aa,gui.lag, gui.menuc..'Spin when'.. gui.warning .. ' enemies' .. gui.menuc ..' dead')
		gui.antihead = ui.new_checkbox(gui.aa,gui.lag, gui.menuc..'Anti back')
		gui.ladder = ui.new_checkbox(gui.aa,gui.lag, gui.menuc..'Fast ladder')
		gui.fl_amount = ui.new_combobox(gui.aa, gui.aaim, gui.menuc..'Amount', 'Dynamic', 'Maximum', 'Fluctuate')
		gui.fl_variance = ui.new_slider(gui.aa, gui.aaim, gui.menuc..'Variance', 0, 100, 0, true, '%')
		gui.fl_limit = ui.new_slider(gui.aa, gui.aaim, gui.menuc..'Limit', 1, ui.get(software.rage.binds.usercmd) - 1, 15, true, 'tk', 1, ctx.amount)
		gui.fl_break = ui.new_slider(gui.aa, gui.aaim, gui.menuc..'Break', 1, ui.get(software.rage.binds.usercmd) - 1, 0, true, 'tk', 1, ctx.amount)
		gui.ot_leg = ui.new_combobox(gui.aa, gui.lag, gui.menuc..'Leg movement', 'Off', 'Never slide', 'Always slide')
		gui.manual_left = ui.new_hotkey(gui.aa, gui.abcd, gui.menuc..'Manual left')
		gui.manual_right = ui.new_hotkey(gui.aa, gui.abcd, gui.menuc..'Manual right')
		gui.freestand = ui.new_hotkey(gui.aa, gui.abcd, gui.menuc..'Freestand')
		gui.hideshots = ui.new_hotkey(gui.aa, gui.abcd, gui.menuc..'Hideshots')
		gui.export = ui.new_button(gui.aa, gui.lag, gui.menuc..'Export config anti-aim', function() def.antiaim:export_cfg() end)
		gui.import = ui.new_button(gui.aa, gui.lag, gui.menuc..'Import config anti-aim', function() def.antiaim:import_cfg() end)

		ui.set_callback(gui.conditions.state, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.ladder, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.fl_amount, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.antihead, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.spinwhendead, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.ot_leg, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)

		ctx.pitch = { [0] = 'Zero', [-89] = 'Up', [-45] = 'Semi-Up', [45] = 'Semi-Down', [89] = 'Down' }
		ctx.statez = { [0] = 'Off' }
		ctx.tick1 = { [3] = 'Default', [6] = 'Largest' }
		ctx.tick2 = { [9] = 'Predict', [11] = 'Default', [13] = 'Largest' }

		for i, name in pairs(ctx.condition_names) do
			gui.state = '\a00000000'..name..''
			gui.defensive = 'Lag'
			gui.conditions[name] = {
				override = ui.new_checkbox(gui.aa,gui.aaim, gui.menuc..'Override '..name),
				pitch = ui.new_slider(gui.aa,gui.aaim, gui.menuc..'Pitch'..gui.state, -89, 89, 0, true, '°', 1, ctx.pitch),
				yaw_base = ui.new_combobox(gui.aa,gui.aaim, gui.menuc..'Yaw base'..gui.state, 'Local view', 'At targets'),
				yaw = ui.new_combobox(gui.aa,gui.aaim, '\n ybo'..gui.state, 'Off', '180'),
				yaw_value = ui.new_slider(gui.aa,gui.aaim, '\n ybv'..gui.state, -60, 60, 0, true, '°', 1, ctx.statez),
				yaw_modifier = ui.new_combobox(gui.aa,gui.aaim, gui.menuc..'Yaw modifier'..gui.state, 'Off', 'Center', 'Offset', 'Original', 'Hidden'),
				modifier_offset = ui.new_slider(gui.aa,gui.aaim, '\n ymv'..gui.state, -60, 60, 0, true, '°', 1, ctx.statez),
				lr_yaw = ui.new_checkbox(gui.aa,gui.aaim, gui.menuc..'Left / right'..gui.state),
				yaw_left = ui.new_slider(gui.aa,gui.aaim, '\n ylv'..gui.state, -60, 60, 0, true, '°', 1, ctx.statez),
				yaw_right = ui.new_slider(gui.aa,gui.aaim, '\n yrv'..gui.state, -60, 60, 0, true, '°', 1, ctx.statez),
				desync = ui.new_combobox(gui.aa,gui.aaim, gui.menuc..'Body yaw'..gui.state, 'Off', 'Static', 'Process'),
				desync_value = ui.new_slider(gui.aa,gui.aaim, '\n byw'..gui.state, 0, 180, 1, true, '°', 1, ctx.statez),
				desync_invert = ui.new_hotkey(gui.aa, gui.aaim, gui.menuc..'Invert'..gui.state),
				delay = ui.new_slider(gui.aa,gui.aaim, gui.menuc..'Delay'..gui.state, 1, 15, 1, true, 'tk', 1, ctx.amount),
				roll = ui.new_checkbox(gui.aa,gui.aaim, gui.warning..'Roll'..gui.state),
				roll_value = ui.new_slider(gui.aa,gui.aaim, '\n ryw'..gui.state, -45, 45, 0, true, '°', 1, ctx.statez),
				defensive_on = ui.new_combobox(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod'..gui.state, 'Off', 'Peek', 'Always'),
				defensive_builder = ui.new_checkbox(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod builder'..gui.state),
				defensive_pitch = ui.new_slider(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod pitch'..gui.state, -89, 89, 0, true, '°', 1, ctx.pitch),
				defensive_yaw = ui.new_combobox(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod yaw'..gui.state, 'Off', '1 Way', '2 Way', '3 Way', 'Hidden', 'Hidden V2', 'Hidden V3'),
				defensive_start = ui.new_slider(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod start'..gui.state, 3, 6, 3, true, 'tk', 1, ctx.tick1),
				defensive_end = ui.new_slider(gui.aa,gui.abcd, gui.risk..gui.defensive..' bsod end'..gui.state, 9, 13, 11, true, 'tk', 1, ctx.tick2),
			}

			ui.set_callback(gui.conditions[name].override, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].yaw_base, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].yaw, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].yaw_modifier, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].lr_yaw, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].desync, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].roll, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].defensive_on, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].defensive_builder, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
			ui.set_callback(gui.conditions[name].defensive_yaw, function()
				cvar.play:invoke_callback(lua.sound)
			end, true)
		end
	end

	function builder.render() 
		local selected_state = ui.get(gui.conditions.state) 
		local luatabaacfg = ui.get(gui.menu.lua) == 'Antiaim' and ui.get(gui.menu.miscellaneous) == 'Other'
		local luatabaa = ui.get(gui.menu.lua) == 'Antiaim' and ui.get(gui.menu.miscellaneous) == 'Main'
		local luatabaafl = ui.get(gui.menu.lua) == 'Antiaim' and ui.get(gui.menu.miscellaneous) == 'Other'
		local luatabaaot = ui.get(gui.menu.lua) == 'Antiaim' and ui.get(gui.menu.miscellaneous) == 'Other'

		ui.set_visible(gui.fl_amount, luatabaafl)
		ui.set_visible(gui.fl_break, luatabaafl)
		ui.set_visible(gui.fl_variance, luatabaafl)
		ui.set_visible(gui.fl_limit, luatabaafl)
		ui.set_visible(gui.ot_leg, luatabaaot)
		ui.set_visible(gui.manual_left, luatabaaot)
		ui.set_visible(gui.antihead, luatabaaot)
		ui.set_visible(gui.ladder, luatabaaot)
		ui.set_visible(gui.manual_right, luatabaaot)
		ui.set_visible(gui.freestand, luatabaaot)
		ui.set_visible(gui.hideshots, luatabaaot)
		ui.set_visible(gui.export, luatabaa)
		ui.set_visible(gui.import, luatabaa)
		ui.set_visible(gui.spinwhendead, luatabaaot)

		for i, name in pairs(ctx.condition_names) do
			local enabled = name == selected_state

			local ok = ui.get(gui.conditions[name].desync) ~= 'Off'
			local ik2 = ui.get(gui.conditions[name].defensive_builder)
			ui.set_visible(gui.conditions[name].override, enabled and i > 1 and luatabaa)
			ui.set_visible(gui.conditions.state, luatabaa)
			local yw = ui.get(gui.conditions[name].yaw) == '180'
			local bs = ui.get(gui.conditions[name].roll)
			local db = ui.get(gui.conditions[name].defensive_on) ~= 'Off'

			local overriden = i == 1 or ui.get(gui.conditions[name].override)

			def.gui.hide_aa_tab(true)
			ui.set_visible(gui.conditions[name].pitch, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].yaw_base, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].yaw, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].yaw_modifier, enabled and overriden and luatabaa and yw)
			ui.set_visible(gui.conditions[name].modifier_offset, enabled and overriden and luatabaa and ui.get(gui.conditions[name].yaw_modifier) ~= 'Off' and ui.get(gui.conditions[name].yaw_modifier) ~= 'Hidden' and yw)
			ui.set_visible(gui.conditions[name].yaw_value, enabled and overriden and luatabaa and yw)
			ui.set_visible(gui.conditions[name].lr_yaw, enabled and overriden and luatabaa and yw)
			ui.set_visible(gui.conditions[name].yaw_left, enabled and overriden and luatabaa and ui.get(gui.conditions[name].lr_yaw) and yw)
			ui.set_visible(gui.conditions[name].yaw_right, enabled and overriden and luatabaa and ui.get(gui.conditions[name].lr_yaw) and yw)		
			ui.set_visible(gui.conditions[name].desync, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].desync_invert, enabled and overriden and luatabaa and ok)
			ui.set_visible(gui.conditions[name].desync_value, enabled and overriden and luatabaa and ok)
			ui.set_visible(gui.conditions[name].delay, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].roll, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].roll_value, enabled and overriden and luatabaa and bs)
			ui.set_visible(gui.conditions[name].defensive_on, enabled and overriden and luatabaa)
			ui.set_visible(gui.conditions[name].defensive_builder, enabled and overriden and luatabaa and db)
			ui.set_visible(gui.conditions[name].defensive_pitch, enabled and overriden and luatabaa and ik2 and db)
			ui.set_visible(gui.conditions[name].defensive_yaw, enabled and overriden and luatabaa and ik2 and db)
			ui.set_visible(gui.conditions[name].defensive_start, enabled and overriden and luatabaa and ik2 and db)
			ui.set_visible(gui.conditions[name].defensive_end, enabled and overriden and luatabaa and ik2 and db)
		end
	end

	def.antistab = {
		is_active = false,
		backstab = 220 * 220,
		get_enemies_with_knife = function()
			local enemies = entity.get_players(true)
			if next(enemies) == nil then
				return { }
			end
			local list = { }

			for i = 1, #enemies do
				local enemy = enemies[i]
				local wpn = entity.get_player_weapon(enemy)
	
				if wpn == nil then
					goto continue
				end
	
				local wpn_class = entity.get_classname(wpn)
	
				if wpn_class == 'CKnife' then
					list[#list + 1] = enemy
				end
	
				::continue::
			end
	
			return list
		end,
        get_closest_target = function(me)
			local targets, deadz = def.antistab.get_enemies_with_knife()
			if next(targets) == nil then return end
	
			local best_delta
	
			local my_origin = vector(entity.get_origin(me))
			local best_distance = def.antistab.backstab
	
			for i = 1, #targets do
				local target = targets[i]
	
				local origin = vector(entity.get_origin(target))
				local delta = origin - my_origin
	
				local distance = delta:lengthsqr()
	
				if distance < best_distance then
					best_delta = delta
	
					best_distance = distance
				end
			end
	
			return best_distance, best_delta
		end,
	}

	get_state = function()
		if not entity.is_alive(g_ctx.lp) then
			return 'Shared'
		end

		local first_velocity, second_velocity = entity.get_prop(g_ctx.lp, 'm_vecVelocity')
		local speed = math.floor(math.sqrt(first_velocity*first_velocity+second_velocity*second_velocity))

		if entity.get_prop(g_ctx.lp, 'm_hGroundEntity') == 0 then
			ctx.ticks = ctx.ticks + 1
		else
			ctx.ticks = 0
		end

		g_ctx.grtck = ctx.onground
		
		ctx.onground = ctx.ticks > 32

		if ui.get(gui.freestand) and ui.get(gui.conditions['Freestand'].override) then
			return 'Freestand'
		end
		
		if not ctx.onground then
			if entity.get_prop(g_ctx.lp, 'm_flDuckAmount') == 1 then
				return 'Air Duck'
			end
	
			return 'Air'
		end
		
		if entity.get_prop(g_ctx.lp, 'm_flDuckAmount') == 1 or ui.get(software.antiaim.other.fakeduck) then
			if speed > 5 then
				return 'Duck Moving'
			end
	
			return 'Duck'
		end
	
		if speed > 5 then
			if ui.get(software.antiaim.other.slide[2]) then
				return 'Slow Moving'
			end

			return 'Moving'
		end
	
		return 'Stand'
	end

	def.antiaim = {
		brute = 0,
		brute_end = 0,
		off_while = function()
			if not ui.get(gui.spinwhendead) then
				return
			end

            local alive = 0

            for i = 1, globals.maxplayers() do
                if entity.get_classname(i) ~= 'CCSPlayer' then
                    goto skip
                end

                if not entity.is_alive(i) or not entity.is_enemy(i) then
                    goto skip
                end

                alive = alive + 1
                ::skip::
            end

            return alive
		end,
		enable = function(cmd)
			cmd.allow_send_packet = false
			ui.set(software.antiaim.angles.enabled, true)
			ui.set(software.antiaim.angles.edge_yaw, false)
		end,
		hideshot = function()
			ui.set(software.rage.binds.on_shot_anti_aim[2], 'always on')
			ui.set(software.rage.binds.on_shot_anti_aim[1], ui.get(gui.hideshots))
		end,
		manual = function()
			ui.set(gui.manual_left, 'On hotkey')
			ui.set(gui.manual_right, 'On hotkey')
	
			if g_ctx.selected_manual == nil then
				g_ctx.selected_manual = 0
			end
		
			local left_pressed = ui.get(gui.manual_left)
			if left_pressed and not g_ctx.left_pressed then
				if g_ctx.selected_manual == 1 then
					g_ctx.selected_manual = 0
				else
					g_ctx.selected_manual = 1
				end
			end
		
			local right_pressed = ui.get(gui.manual_right)
			if right_pressed and not g_ctx.right_pressed then
				if g_ctx.selected_manual == 2 then
					g_ctx.selected_manual = 0
				else
					g_ctx.selected_manual = 2
				end
			end
			
			g_ctx.left_pressed = left_pressed
			g_ctx.right_pressed = right_pressed
		end,
		freestand = function()
			local fs = ui.get(gui.freestand)
			if g_ctx.selected_manual ~= 0 then
				fs = false
			end

			ui.set(software.antiaim.angles.freestanding[2], 'always on')
			ui.set(software.antiaim.angles.freestanding[1], fs)
		end,
		pitch = function()
			ctx.state = get_state()
			if not ui.get(gui.conditions[ctx.state].override) then
				ctx.state = 'Shared'
			end

			local mode = 'custom'
			local pitch = ui.get(gui.conditions[ctx.state].pitch)
			if def.antiaim:off_while() == 0 then
				pitch = 0
			elseif def.values.defensive > 3 and def.values.defensive < 11 and ui.get(gui.conditions[ctx.state].defensive_builder) and ui.get(gui.conditions[ctx.state].defensive_on) ~= 'Off' then
				pitch = ui.get(gui.conditions[ctx.state].defensive_pitch)
			else
				pitch = ui.get(gui.conditions[ctx.state].pitch)
			end

			ui.set(software.antiaim.angles.pitch[1], mode)
			ui.set(software.antiaim.angles.pitch[2], pitch)
		end,
		desync_and_yaw = function(cmd)
			ctx.state = get_state()
			if not ui.get(gui.conditions[ctx.state].override) then
				ctx.state = 'Shared'
			end
			local yawl = ui.get(gui.conditions[ctx.state].yaw_left)
			local yawr = ui.get(gui.conditions[ctx.state].yaw_right)
			local offsetyaw = ui.get(gui.conditions[ctx.state].yaw_value)
			local delayedzv = ui.get(gui.conditions[ctx.state].delay)
			local yoffset = offsetyaw
			local yaw_modifier = ui.get(gui.conditions[ctx.state].yaw_modifier)
			local yawmodofs = ui.get(gui.conditions[ctx.state].modifier_offset)
			local checklr = ui.get(gui.conditions[ctx.state].lr_yaw)
		    local inverted = def.values.body < 0
			local yaw_value = inverted and yawl or yawr
			if not checklr then
				yaw_value = 0
			end
			local yaw = ui.get(gui.conditions[ctx.state].yaw)
			local yaw_base = ui.get(gui.conditions[ctx.state].yaw_base)
			local distance, delta = def.antistab.get_closest_target(g_ctx.lp)
			local body_yaw_value = ui.get(gui.conditions[ctx.state].desync_invert) and ui.get(gui.conditions[ctx.state].desync_value) or -ui.get(gui.conditions[ctx.state].desync_value)
			local desync = ui.get(gui.conditions[ctx.state].desync)
			local body_yaw_delay = delayedzv
			local freestanding_body_yaw = false
	
			if def.values.defensive > ui.get(gui.conditions[ctx.state].defensive_start) and def.values.defensive < ui.get(gui.conditions[ctx.state].defensive_end) and ui.get(gui.conditions[ctx.state].defensive_builder) and ui.get(gui.conditions[ctx.state].defensive_on) ~= 'Off' and def.antiaim:off_while() ~= 0  then

				local chokedcommands = globals.chokedcommands()
				if chokedcommands == 0 then
					def.values.spin = def.values.spin + 25
				end
				if def.values.spin > 180 then
					def.values.spin = -180
				end

				if globals.tickcount() % 14 then
					def.values.spinv2 = def.values.spinv2 + 25
				end
				if def.values.spinv2 > 180 then
					def.values.spinv2 = -180
				end

				local value = 0
				local val = ui.get(gui.conditions[ctx.state].defensive_yaw)
				if val == '2 Way' then
					value = def.values.packets % 2 == 0 and 90 or -90
				elseif val == '3 Way' then
					value = def.values.packets % 3 == 1 and 90 or def.values.packets % 3 == 2 and -180 or -90
				elseif val == '1 Way' then
					value = 180
				elseif val == 'Hidden' then
					value = def.values.spin
				elseif val == 'Hidden V2' then
					value = def.values.spinv2
				elseif val == 'Hidden V3' then
					value = def.values.spinv2 / 2
				else
					value = 0
				end

				ui.set(software.antiaim.angles.desync[1], 'opposite')
				ui.set(software.antiaim.angles.desync[2], 1)
				ui.set(software.antiaim.angles.freestanding_body_yaw, true)
				ui.set(software.antiaim.angles.yaw_base, 'at targets')
				ui.set(software.antiaim.angles.yaw[1], '180')
				ui.set(software.antiaim.angles.yaw[2], value)
			else
				if def.antiaim:off_while() == 0 then
					yaw = 'spin'
					yaw_value = 4
					yawmodofs = 0
					yaw_base = 'local view'
					desync = 'off'
				elseif distance ~= nil and distance < 35000 and ui.get(gui.antihead) then
					yaw = '180'
					yaw_value = 180
					yawmodofs = 0
					yaw_base = 'at targets'
					desync = 'opposite'
				elseif g_ctx.selected_manual == 1 then
					yaw = '180'
					yaw_value = -90
					yawmodofs = 0
					yaw_base = 'local view'
					desync = 'opposite'
				elseif g_ctx.selected_manual == 2 then
					yaw = '180'
					yaw_value = 90
					yawmodofs = 0
					yaw_base = 'local view'
					desync = 'opposite'
				elseif ui.get(software.antiaim.angles.freestanding[2]) and ui.get(software.antiaim.angles.freestanding[1]) and ctx.state == 'Moving' then
					yaw = '180'
					yaw_value = 0
					yawmodofs = 0
					yaw_base = 'local view'
				elseif desync == 'Process' then
					local chokedcommands = globals.chokedcommands()
					local delay = body_yaw_delay
					local target = delay * 2
					inverted = (def.values.packets % target) >= delay
					local val = inverted and ui.get(gui.conditions[ctx.state].desync_value) or -ui.get(gui.conditions[ctx.state].desync_value)
	
					yaw = ui.get(gui.conditions[ctx.state].yaw)
					desync = 'static'
					body_yaw_value = val
	
					if chokedcommands == 0 then
						def.values.spin = def.values.spin + 25
					end
					if def.values.spin > 180 then
						def.values.spin = -180
					end
	
					if yaw_modifier == 'Center' then
						yawmodofs = inverted and yawmodofs or -yawmodofs
					elseif yaw_modifier == 'Offset' then
						yawmodofs = inverted and yawmodofs or 0
					elseif yaw_modifier == 'Original' then
						yawmodofs = def.values.packets % 3 == 1 and yawmodofs or def.values.packets % 3 == 2 and 0 or -yawmodofs
					elseif yaw_modifier == 'Hidden' then
						yawmodofs = def.values.spin / 4
					else
						yawmodofs = 0
					end
	
					if checklr then
						yaw_value = inverted and yawr or yawl
					end
				else
					yaw = ui.get(gui.conditions[ctx.state].yaw)
					inverted = def.values.body < 0
					if checklr then
						yaw_value = inverted and yawr or yawl
					end

					local delay = body_yaw_delay
					local target = delay * 2
					inverted = (def.values.packets % target) >= delay
	
					local chokedcommands = globals.chokedcommands()
					if chokedcommands == 0 then
						def.values.spin = def.values.spin + 25
					end
					if def.values.spin > 180 then
						def.values.spin = -180
					end	
	
					if yaw_modifier == 'Center' then
						yawmodofs = inverted and yawmodofs or -yawmodofs
					elseif yaw_modifier == 'Offset' then
						yawmodofs = inverted and yawmodofs or 0
					elseif yaw_modifier == 'Original' then
						yawmodofs = def.values.packets % 3 == 1 and -yawmodofs or def.values.packets % 3 == 2 and yawmodofs or 0
					elseif yaw_modifier == 'Hidden' then
						yawmodofs = def.values.spin / 4
					else
						yawmodofs = 0
					end
				end
				ui.set(software.antiaim.angles.desync[1], desync)
				ui.set(software.antiaim.angles.desync[2], body_yaw_value)
				ui.set(software.antiaim.angles.freestanding_body_yaw, freestanding_body_yaw)
				ui.set(software.antiaim.angles.yaw_base, yaw_base)
				ui.set(software.antiaim.angles.yaw[1], yaw)
				ui.set(software.antiaim.angles.yaw[2], yoffset + yawmodofs + yaw_value)
			end
		end,	
		yaw_jitter = function()
			ui.set(software.antiaim.angles.yaw_jitter[1], 'off')
			ui.set(software.antiaim.angles.yaw_jitter[2], 0)
		end,
		roll = function()
			ctx.state = get_state()
			if not ui.get(gui.conditions[ctx.state].override) then
				ctx.state = 'Shared'
			end
			local roll = ui.get(gui.conditions[ctx.state].roll_value)
			if ui.get(gui.conditions[ctx.state].roll) then
				ui.set(software.antiaim.angles.roll, roll)
			else
				ui.set(software.antiaim.angles.roll, 0)
			end
			
		end,
		leg_movement = function()
			local leg = ui.get(gui.ot_leg)
			if def.antiaim:off_while() == 0 then
				leg = 'off'
			else			
				leg = ui.get(gui.ot_leg)
			end

			ui.set(software.antiaim.other.leg_movement, leg)
		end,
		fakelag = function()
			ui.set( software.antiaim.fakelag.amount, ui.get( gui.fl_amount ))
			ui.set( software.antiaim.fakelag.variance, ui.get( gui.fl_variance ))
			if ui.get(gui.fl_break) > 1 then
				ui.set( software.antiaim.fakelag.limit,	events.random_int(ui.get( gui.fl_break ), ui.get( gui.fl_limit )))
			else
				ui.set( software.antiaim.fakelag.limit,	ui.get( gui.fl_limit ))
			end
		end,
		clipboard_export = function(string)
			if string then
				set_clipboard_text(VGUI_System, string, #string)
			end
		end,
		export_cfg = function()
			local settings = {}
			pcall(function()
				for key, value in pairs(gui.conditions) do
					if value then
						settings[key] = {}
		
						if type(value) == 'table' then
							for k, v in pairs(value) do
								settings[key][k] = ui.get(v)
							end
						else
							settings[key] = ui.get(value)
						end
					end
				end
		
				def.antiaim.clipboard_export(json.stringify(settings))
				motion.push('Export to buffer', true, true, true, ui.get(gui.menu.cenlogs), 215, 215, 215, 215, ui.get(gui.menu.outputlogs))
				client.log('Export to buffer')
				cvar.play:invoke_callback('ui/csgo_ui_contract_type1')
			end)
		end,
		import_cfg = function()
			pcall(function()
				local num_tbl = {}
				local settings = json.parse(clipboard_import())
		
				for key, value in pairs(settings) do
					if type(value) == 'table' then
						for k, v in pairs(value) do
							if type(k) == 'number' then
								table.insert(num_tbl, v)
								ui.set(gui.conditions[key], num_tbl)
							else
								ui.set(gui.conditions[key][k], v)
							end
						end
					else
						ui.set(gui.conditions[key], value)
					end
				end
		
				motion.push('Import from buffer', true, true, true, ui.get(gui.menu.cenlogs), 215, 215, 215, 215, ui.get(gui.menu.outputlogs))
				client.log('Import from buffer')
				cvar.play:invoke_callback('ui/csgo_ui_contract_type1')
			end)
		end,
		writedfile = function(path, data)
			if not data or type(path) ~= 'string' then
				return
			end
	
			return writefile(path, json.stringify(data))
		end,
		fast_ladder = function(cmd)
			if not ui.get(gui.ladder) then
				return
			end
			local pitch,yaw = events.camera_angles()
			local move_type = entity.get_prop(g_ctx.lp, 'm_MoveType')
			local weapon = entity.get_player_weapon(g_ctx.lp)
			local throw = entity.get_prop(weapon, 'm_fThrowTime')

			if move_type ~= 9 then
				return
			end

			if weapon == nil then
				return
			end

			if throw ~= nil and throw ~= 0 then
				return
			end	

			if cmd.forwardmove > 0 then
				if cmd.pitch < 45 then
					cmd.pitch = 89
					cmd.in_moveright = 1
					cmd.in_moveleft = 0
					cmd.in_forward = 0
					cmd.in_back = 1

					if cmd.sidemove == 0 then
						cmd.yaw = cmd.yaw + 90
					end

					if cmd.sidemove < 0 then
						cmd.yaw = cmd.yaw + 150
					end

					if cmd.sidemove > 0 then
						cmd.yaw = cmd.yaw + 30
					end
				end
			elseif cmd.forwardmove < 0 then
				cmd.pitch = 89
				cmd.in_moveleft = 1
				cmd.in_moveright = 0
				cmd.in_forward = 1
				cmd.in_back = 0

				if cmd.sidemove == 0 then
					cmd.yaw = cmd.yaw + 90
				end

				if cmd.sidemove > 0 then
					cmd.yaw = cmd.yaw + 150
				end

				if cmd.sidemove < 0 then
					cmd.yaw = cmd.yaw + 30
				end
			end
		end,
	}

	function builder.setup_createmove(cmd)
		if not entity.is_alive(g_ctx.lp) then
			return
		end
		def.antiaim:enable(cmd)
		def.antiaim:hideshot()
		def.antiaim:manual()
		def.antiaim:freestand()
		def.antiaim:pitch()
		def.antiaim.desync_and_yaw(cmd)
		def.antiaim:yaw_jitter()
		def.antiaim:roll()
		def.antiaim:leg_movement()
		def.antiaim:fakelag()
		def.antiaim.fast_ladder(cmd)
	end
end

do
	local ctx = {}
	local aspectr = 0
	local cur_state = 0
	local current_state = 'none'

	local function add_bind(name, ref, gradient_fn, enabled_color, disabled_color)
		enabled_color = {
			[1] = 230,
			[2] = 230,
			[3] = 230,
			[4] = 230,
		}
		disabled_color = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0,
		}
		ctx.crosshair_indicator.binds[#ctx.crosshair_indicator.binds + 1] = { name = string.sub(name, 1, 2), full_name = name, ref = ref, color = disabled_color, enabled_color = enabled_color, disabled_color = disabled_color, chars = 0, alpha = 0, gradient_progress = 0, gradient_fn = gradient_fn }
	end

	function indicators.init()
		gui.indicators = {}
		
		ctx.anims = {
			a = 0,
			b = 0,
			c = 0,
			d = 0,
			e = 0,
			f = 0,
			g = 0,
			h = 0,
			i = 0,
			j = 0,
			k = 0,
			l = 0,
			m = 0,
			n = 0,
			o = 0,
			p = 0,
			q = 0,
			r = 0,
			s = 0,
			t = 0,
			u = 0,
			v = 0,
			w = 0,
			x = 0,
			y = 0,
			z = 0,
		}
		gui.indicators.indicator_color = ui.new_color_picker(gui.aa,gui.aaim,'Indicator color', 215, 215, 215)
		gui.indicators.indicator = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Indicator')
		gui.indicators.indicator_font = ui.new_combobox(gui.aa, gui.aaim, '\n Indicator font', 'Small', 'Default', 'Bold')
		gui.indicators.indicator_slider = ui.new_slider(gui.aa, gui.aaim, '\n Indicator offset', 10, 20, 11, true, 'ofs')
		gui.indicators.damage_indicator = ui.new_checkbox(gui.aa, gui.aaim, gui.menuc..'Damage indicator')
		gui.indicators.damage_indicator_color = ui.new_color_picker(gui.aa,gui.aaim,'Damage indicator color', 215, 215, 215)
		gui.indicators.damage_indicator_font = ui.new_combobox(gui.aa, gui.aaim, '\n Damage font', 'Small', 'Default', 'Bold')
		gui.indicators.watermark_style = ui.new_combobox(gui.aa, gui.lag, gui.menuc..'Watermark style', 'Old', 'New')
		gui.indicators.wmaincolor = ui.new_color_picker(gui.aa,gui.lag,'Watermark main color', 215, 215, 215)
		gui.indicators.wbackcolor = ui.new_color_picker(gui.aa,gui.lag,'Watermark back color', 111, 111, 215)
		gui.indicators.watermark_font = ui.new_combobox(gui.aa, gui.lag, '\n Watermark font', 'Small', 'Default', 'Bold')
		gui.indicators.manual2arrows = ui.new_checkbox(gui.aa,gui.aaim,gui.menuc..'Manual arrows')
		gui.indicators.maincolor = ui.new_color_picker(gui.aa,gui.aaim,'Manual main color', 215, 215, 215)
		gui.indicators.backcolor = ui.new_color_picker(gui.aa,gui.aaim,'Manual back color', 5, 5, 5, 0)

		
		ui.set_callback(gui.indicators.indicator, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.indicator_font, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.damage_indicator, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.damage_indicator_font, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.watermark_style, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.watermark_font, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)
		ui.set_callback(gui.indicators.manual2arrows, function()
			cvar.play:invoke_callback(lua.sound)
		end, true)

		ctx.crosshair_indicator = {}
		ctx.crosshair_indicator.binds = {}

		add_bind('antarctica recode', gui.indicators.indicator)
		add_bind('doubletap', software.rage.binds.double_tap[2])
		add_bind('hideshots', software.rage.binds.on_shot_anti_aim[1])
		add_bind('damage', software.rage.binds.minimum_damage_override[2])
		add_bind('state', gui.indicators.indicator)

		gui.indicator_color = def.gui:hex_label({255,0,55})
		gui.indicator_color2 = def.gui:hex_label({215,215,215})
	end

	add_crosshair_text = function(x, y, r, g, b, a, fl, opt, text, alpha)

		if alpha == nil then
			alpha = 1
		end

		if alpha <= 0 then
			return
		end
		
		local offset = 1
		if ctx.crosshair_indicator.scope > 0 then
			offset = offset - ctx.crosshair_indicator.scope
		end
			
		local text_size = render.measure_text(fl, text)
		x = x - text_size * offset / 2 + 5 * ctx.crosshair_indicator.scope
		
		render.text(x, y, r, g, b, a, fl, opt, text)
		
		ctx.crosshair_indicator.y = ctx.crosshair_indicator.y + ui.get(gui.indicators.indicator_slider) * alpha
	end

	local debuy = 10
	def.visuals = {
		interlerpfuncs = function()
			backup.visual = {}
			ctx.anims.f = motion.interp(ctx.anims.f, entity.get_prop(g_ctx.lp, 'm_bIsScoped'), 0.05)--ctx.anims.f = motion.interp(ctx.anims.f, entity.get_prop(entity.get_player_weapon(g_ctx.lp), 'm_zoomLevel') > 0, 0.1)
			ctx.anims.c = motion.interp(ctx.anims.c, entity.get_prop(g_ctx.lp, 'm_bIsScoped'), 0.1)
			ctx.anims.n = motion.interp(ctx.anims.n, entity.get_prop(g_ctx.lp, 'm_bResumeZoom'), 0.1)
			ctx.anims.d = motion.interp(ctx.anims.d, ui.get(software.visuals.effects.thirdperson[2]), 0.1)
			ctx.anims.e = motion.interp(ctx.anims.e, ui.get(gui.indicators.manual2arrows), 0.1)
			ctx.anims.t = motion.interp(ctx.anims.t, ui.get(software.rage.binds.minimum_damage_override[2]), 0.1)
			local state = render.measure_text('d', get_state())
			local gnom = get_state()
			local state_all = gnom
			local asp = ui.get(gui.aspectratio)
			ctx.anims.z = motion.interp(ctx.anims.z, state == cur_state and ui.get(gui.indicators.indicator), 0.05)
			ctx.anims.k = motion.interp(ctx.anims.k, ui.get(gui.indicators.indicator), 0.01)
			ctx.anims.s = motion.interp(ctx.anims.s, asp == aspectr, 0.01)

			if ctx.anims.s < .1 then
				aspectr = asp
			end
			
			backup.visual.fov = ui.get(gui.zoom_on) and ctx.anims.f or entity.get_prop(g_ctx.lp, 'm_bIsScoped') * 1
			backup.visual.state = ctx.anims.z or 1
			backup.visual.ind = ctx.anims.k or 0
			backup.visual.scoped = ctx.anims.c + ctx.anims.n or 0
			backup.visual.thirdperson = ui.get(gui.thirdperson_on) and ctx.anims.d or 1
			backup.visual.aspectratio = aspectr or 1
			cvar.r_aspectratio:set_float(backup.visual.aspectratio * 0.01)
			backup.visual.manualenable = ctx.anims.e or ui.get(gui.indicators.manual2arrows) and 1 or 0

			ui.set(software.visuals.effects.fov, ui.get(gui.fov) - ui.get(gui.zoom) * backup.visual.fov)
			ui.set(software.visuals.effects.zfov, 0)

			if entity.is_alive(g_ctx.lp) then
				cvar.cam_idealdist:set_float(ui.get(gui.thirdperson) * backup.visual.thirdperson)
			end

			if ctx.anims.z < .1 then
				cur_state = state
				current_state = state_all
			end
		end,
		indicator = function()
			
			ctx.crosshair_indicator.y = 15
			ctx.crosshair_indicator.scope = backup.visual.scoped
	
			for index, bind in ipairs(ctx.crosshair_indicator.binds) do
				local alpha = motion.interp(bind.alpha, ui.get(gui.indicators.indicator) and ui.get(bind.ref), 0.07)
				local chars = motion.interp(bind.chars, ui.get(gui.indicators.indicator) and ui.get(bind.ref) and backup.visual.ind > .1, 0.07)
				local name = backup.visual.ind > .1 and string.sub(bind.full_name, 1, math.floor(.5 + #bind.full_name * chars)) or bind.full_name
				local n, y, a, w = ui.get(gui.indicators.indicator_color)
				local r, g, b, a = motion.lerp_color(bind.disabled_color[1], bind.disabled_color[2], bind.disabled_color[3], bind.disabled_color[4], n, y, a, w, alpha)
				local text = name
				local alphaz = alpha
				local opt = '-'
				if ui.get(gui.indicators.indicator_font) == 'Small' then
					opt = '-'
				elseif ui.get(gui.indicators.indicator_font) == 'Default' then
					opt = ''
				elseif ui.get(gui.indicators.indicator_font) == 'Bold' then
					opt = 'b'
				end
				if bind.full_name == 'antarctica' then
					if ui.get(gui.indicators.indicator_font) == 'Small' then
						text = bind.full_name:upper()
					else
						text = bind.full_name
					end
					alphaz = alpha
					clr = {
						[1] = r,
						[2] = g,
						[3] = b,
						[4] = 215 * alphaz,
					}
				elseif bind.full_name == 'state' then
					if ui.get(gui.indicators.indicator_font) == 'Small' then
						text = '`'..string.sub(current_state:upper(), 1, math.floor(.5 + #current_state * backup.visual.state))..'`'
					else
						text = '`'..string.sub(current_state:lower(), 1, math.floor(.5 + #current_state * backup.visual.state))..'`'
					end
					alphaz = backup.visual.state
					clr = {
						[1] = r,
						[2] = g,
						[3] = b,
						[4] = 215 * backup.visual.state,
					}
				else
					if ui.get(gui.indicators.indicator_font) == 'Small' then
						text = name:upper()
					else
						text = name
					end
					alphaz = alpha
					clr = {
						[1] = r,
						[2] = g,
						[3] = b,
						[4] = 215 * alphaz,
					}
				end

				add_crosshair_text(g_ctx.screen[1] / 2, g_ctx.screen[2] / 2 + ctx.crosshair_indicator.y, clr[1], clr[2], clr[3], clr[4], opt, 0, text, alphaz)
				
				ctx.crosshair_indicator.binds[index].alpha = alpha
				ctx.crosshair_indicator.binds[index].name = name
				ctx.crosshair_indicator.binds[index].chars = chars
				ctx.crosshair_indicator.binds[index].color = r, g, b, a
			end	
		end,
		watermark = function()
			local opt = ''
			if ui.get(gui.indicators.watermark_font) == 'Small' then
				opt = '-'
			elseif ui.get(gui.indicators.watermark_font) == 'Default' then
				opt = ''
			elseif ui.get(gui.indicators.watermark_font) == 'Bold' then
				opt = 'b'
			end
			if ui.get(gui.indicators.watermark_style) == 'New' then
				local r, g, b, a = ui.get(gui.indicators.wmaincolor)
				local name = 'antarctica recode'
				local text_size = render.measure_text(opt, name:upper())
				render.text(g_ctx.screen[1] / 2 - text_size / 2, g_ctx.screen[2] - 15, r, g, b, 215, opt, nil, name:upper())
		    else
				local r, g, b, a = ui.get(gui.indicators.wmaincolor)
				local r12, g12, b12, a12 = ui.get(gui.indicators.wbackcolor)
				local version = 'v2 debug'
				local name = 'antarctica'
				local version_size = render.measure_text(opt, version:upper())
				local text_size = render.measure_text(opt, name:upper())
				render.text(g_ctx.screen[1] / 2 - version_size / 2, g_ctx.screen[2] - 30, 215, 215, 215, 255, opt, nil, 
				def.gui.text(r12, g12, b12, a12, r, g, b, a, version:upper(), 2))
				render.text(g_ctx.screen[1] / 2 - text_size / 2, g_ctx.screen[2] - 15, 215, 215, 215, 255, opt, nil, 
				def.gui.text(r12, g12, b12, a12, r, g, b, a, name:upper(), 2))
		    end
		end,
		damage_indicator = function()
			if not ui.get(gui.indicators.damage_indicator) then
				return
			end
			local r, g, b = ui.get(gui.indicators.damage_indicator_color)
			local opt = ''
			if ui.get(gui.indicators.damage_indicator_font) == 'Small' then
				opt = '-'
			elseif ui.get(gui.indicators.damage_indicator_font) == 'Default' then
				opt = ''
			elseif ui.get(gui.indicators.damage_indicator_font) == 'Bold' then
				opt = 'b'
			end
			render.text(g_ctx.screen[1] / 2 + 5, g_ctx.screen[2] / 2 - 15, r, g, b, 255 * ctx.anims.t, opt, nil, math.floor(ui.get(software.rage.binds.minimum_damage_override[3]))) --* ctx.anims.t
		end,
		manual_arrows = function()
			local bodyyaw = def.values.body < 0
			local r, g, b, a = ui.get(gui.indicators.maincolor)
			local r12, g12, b12, a12 = ui.get(gui.indicators.backcolor)

			local le = render.measure_text('+', '⮜')
			local re = render.measure_text('+', '⮞')

			render.text(
			g_ctx.selected_manual == 2 and g_ctx.screen[1] / 2 - re / 2 + 55 or g_ctx.screen[1] / 2 - re / 2 + 55, 
			g_ctx.screen[2] / 2 - re + 2, 
			g_ctx.selected_manual == 2 and r or r12, 
			g_ctx.selected_manual == 2 and g or g12, 
			g_ctx.selected_manual == 2 and b or b12, 
			g_ctx.selected_manual == 2 and a * backup.visual.manualenable or a12 * backup.visual.manualenable,
			'+',
			nil,
			'⮞')
			render.text(
			g_ctx.selected_manual == 1 and g_ctx.screen[1] / 2 - le / 2 - 55 or g_ctx.screen[1] / 2 - le / 2 - 55, 
			g_ctx.screen[2] / 2 - le + 2,
			g_ctx.selected_manual == 1 and r or r12, 
			g_ctx.selected_manual == 1 and g or g12, 
			g_ctx.selected_manual == 1 and b or b12, 
			g_ctx.selected_manual == 1 and a * backup.visual.manualenable or a12 * backup.visual.manualenable,
			'+',
			nil,
			'⮜')
		end
	}

	function indicators.render()
		if not entity.is_alive(g_ctx.lp) then
			return
		end

		def.visuals:interlerpfuncs()
		def.visuals:indicator()
		def.visuals:manual_arrows()
		def.visuals:watermark()
		def.visuals:damage_indicator()
	end
end

do
	local ctx = {}

	def.corr = {
		peeking = function()
			if not entity.is_alive(g_ctx.lp) then
				return
			end
			local enemies = entity.get_players(true)
			if not enemies then
				return false
			end
			local predict_amt = 0.25
			local eye_position = vector(events.eye_position())
			local velocity_prop_local = vector(entity.get_prop(g_ctx.lp, 'm_vecVelocity'))
			local predicted_eye_position = vector(eye_position.x + velocity_prop_local.x * predict_amt, eye_position.y + velocity_prop_local.y * predict_amt, eye_position.z + velocity_prop_local.z * predict_amt)
			for i = 1, #enemies do
				local player = enemies[i]
				local velocity_prop = vector(entity.get_prop(player, 'm_vecVelocity'))
				local origin = vector(entity.get_prop(player, 'm_vecOrigin'))
				local predicted_origin = vector(origin.x + velocity_prop.x * predict_amt, origin.y + velocity_prop.y * predict_amt, origin.z + velocity_prop.z * predict_amt)
				entity.get_prop(player, 'm_vecOrigin', predicted_origin)
				local head_origin = vector(entity.hitbox_position(player, 0))
				local predicted_head_origin = vector(head_origin.x + velocity_prop.x * predict_amt, head_origin.y + velocity_prop.y * predict_amt, head_origin.z + velocity_prop.z * predict_amt)
				local trace_entity, damage = events.trace_bullet(g_ctx.lp, predicted_eye_position.x, predicted_eye_position.y, predicted_eye_position.z, predicted_head_origin.x, predicted_head_origin.y, predicted_head_origin.z)
				entity.get_prop( player, 'm_vecOrigin', origin )
				if damage > 0 then
					return true
				end
			end
			return false
	    end,
		fix_defensive = function(cmd)
			ctx.state = get_state()
			if not ui.get(gui.conditions[ctx.state].override) then
				ctx.state = 'Shared'
			end
			if not ui.get(software.rage.binds.double_tap[2]) then
				return
			end		
			if ui.get(gui.conditions[ctx.state].defensive_on) == 'Always' then
				cmd.force_defensive = true
			elseif def.corr:peeking() and ui.get(gui.conditions[ctx.state].defensive_on) == 'Peek' then
				cmd.force_defensive = true
			else
				cmd.force_defensive = false
			end
		end
	} 

	local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}
	events.set_event_callback('aim_miss', function(e)
		if not ui.get(gui.menu.misslogs) then
			return
		end

		local r, g, b, a = ui.get(gui.menu.misscolor)

		local group = hitgroup_names[e.hitgroup + 1] or '?'
		motion.push(string.format('Miss %s in %s due to %s in %d hitchance', entity.get_player_name(e.target), group, e.reason, math.floor(e.hit_chance + 0.5)), true, true, true, ui.get(gui.menu.cenlogs), r, g, b, a, ui.get(gui.menu.outputlogs))
		client.log(string.format('Miss %s in %s due to %s in %d hitchance', entity.get_player_name(e.target), group, e.reason, math.floor(e.hit_chance + 0.5)))
	end)

	events.set_event_callback('aim_fire', function(e)
		if not ui.get(gui.menu.reglogs) then
			return
		end

		local flags = {
			e.teleported and 'teleported' or '',
			e.interpolated and 'interpolated' or '',
			e.extrapolated and 'extrapolated' or '',
			e.boosted and 'boosted' or '',
			e.high_priority and 'high_priority' or ''
		}

		local r, g, b, a = ui.get(gui.menu.regcolor)
		gui.regcol = def.gui:hex_label({r, g, b, a})
	
		local group = hitgroup_names[e.hitgroup + 1] or '?'
		motion.push(string.format('Registered %s in %s for %d damage in %d hitchance and%2d backtrack (%s)', entity.get_player_name(e.target), group, e.damage,math.floor(e.hit_chance + 0.5), toticks(e.backtrack), table.concat(flags)), true, true, true, ui.get(gui.menu.cenlogs), r, g, b, a, ui.get(gui.menu.outputlogs))
		client.log(string.format('Registered %s in %s for %d damage in %d hitchance and%2d backtrack (%s)', entity.get_player_name(e.target), group, e.damage,math.floor(e.hit_chance + 0.5), toticks(e.backtrack), table.concat(flags)))
	end)

	events.set_event_callback('aim_hit', function(e)
		if not ui.get(gui.menu.hitlogs) then
			return
		end

		local r, g, b, a = ui.get(gui.menu.hitcolor)

		local group = hitgroup_names[e.hitgroup + 1] or '?'
		motion.push(string.format('Hit %s in the %s for %d damage (%d health remaining)', entity.get_player_name(e.target), group, e.damage, entity.get_prop(e.target, 'm_iHealth')), true, true, true, ui.get(gui.menu.cenlogs), r, g, b, a, ui.get(gui.menu.outputlogs))
		client.log(string.format('Hit %s in the %s for %d damage (%d health remaining)', entity.get_player_name(e.target), group, e.damage, entity.get_prop(e.target, 'm_iHealth')))

	end)

	local weapon_to_verb = { knife = 'Knifed', hegrenade = 'Naded', inferno = 'Burned' }

	events.set_event_callback('player_hurt', function(e)
		local attacker_id = client.userid_to_entindex(e.attacker)
			
		if not ui.get(gui.menu.nadelogs) or attacker_id == nil or attacker_id ~= g_ctx.lp then
			return
		end
	
		local group = hitgroup_names[e.hitgroup + 1] or '?'
		local r, g, b, a = ui.get(gui.menu.nadecolor)
		
		if group == 'generic' and weapon_to_verb[e.weapon] ~= nil then
			local target_id = client.userid_to_entindex(e.userid)
			local target_name = entity.get_player_name(target_id)
			if target_id == g_ctx.lp then
				return
			end

			motion.push(string.format('%s %s for %i damage (%i remaining)', weapon_to_verb[e.weapon], target_name, e.dmg_health, e.health), true, true, true, ui.get(gui.menu.cenlogs), r, g, b, a, ui.get(gui.menu.outputlogs))
			client.log(string.format('%s %s for %i damage (%i remaining)', weapon_to_verb[e.weapon], target_name, e.dmg_health, e.health))
		end
	end)

	function corrections.createmove(cmd)
		if not entity.is_alive(g_ctx.lp) then
			return
		end
		def.corr.fix_defensive(cmd)
	end
end

do
	function cwar.createmove()
		cvar.sv_maxusrcmdprocessticks:set_int(18)
		ui.set(software.rage.binds.usercmd, 18)
	end

	function cwar.shutdown()
		cvar.sv_maxusrcmdprocessticks:set_int(16)
		ui.set(software.rage.binds.usercmd, 16)
		cvar.cam_idealdist:set_float(ui.get(gui.thirdperson))
		cvar.r_aspectratio:set_float(0.0)
		ui.set(software.visuals.effects.fov, ui.get(gui.fov))
	end
end

do
	software.init()
	gui.init()
	builder.init()
	indicators.init()

	events.set_event_callback('paint', g_ctx.render)
	events.set_event_callback('paint_ui', motion.logs)
	events.set_event_callback('paint_ui', gui.render)
	events.set_event_callback('paint_ui', indicators.render)
	events.set_event_callback('paint_ui', builder.render)

	events.set_event_callback('run_command', def.values.run)
	events.set_event_callback('setup_command', builder.setup_createmove)
	events.set_event_callback('setup_command', corrections.createmove)
	events.set_event_callback('setup_command', cwar.createmove)
	events.set_event_callback('predict_command', def.values.predict)
	events.set_event_callback('shutdown', gui.shut)
	events.set_event_callback('shutdown', cwar.shutdown)
	events.set_event_callback('net_update_end', def.values.net)
	events.set_event_callback('level_init', function() def.values.check, def.values.defensive = 0, 0 end)
	events.set_event_callback('pre_render', gui.animbuilder)
end

--by qolhoz
do
    local CS_UM_SendPlayerItemFound = 63
    local DispatchUserMessage_t = ffi.typeof [[
        bool(__thiscall*)(void*, int msg_type, int nFlags, int size, const void* msg)
    ]]

    local VClient018 = client.create_interface('client.dll', 'VClient018')
    local pointer = ffi.cast('uintptr_t**', VClient018)
    local vtable = ffi.cast('uintptr_t*', pointer[0])
    local size = 0
    while vtable[size] ~= 0x0 do
       size = size + 1
    end

    local hooked_vtable = ffi.new('uintptr_t[?]', size)
    for i = 0, size - 1 do
        hooked_vtable[i] = vtable[i]
    end

    pointer[0] = hooked_vtable
    local oDispatch = ffi.cast(DispatchUserMessage_t, vtable[38])
    local function hkDispatch(thisptr, msg_type, nFlags, size, msg)
        if msg_type == CS_UM_SendPlayerItemFound then
            return false
        end

        return oDispatch(thisptr, msg_type, nFlags, size, msg)
    end

    client.set_event_callback('shutdown', function()
        hooked_vtable[38] = vtable[38]
        pointer[0] = vtable
    end)
    hooked_vtable[38] = ffi.cast('uintptr_t', ffi.cast(DispatchUserMessage_t, hkDispatch))
end
