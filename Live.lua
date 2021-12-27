local anti_aim = require "gamesense/antiaim_funcs"
local client_random_int, client_userid_to_entindex, entity_get_classname, entity_get_player_weapon, entity_is_enemy, globals_tickcount, ui_new_button = client.random_int, client.userid_to_entindex, entity.get_classname, entity.get_player_weapon, entity.is_enemy, globals.tickcount, ui.new_button
local client_update_player_list, globals_curtime, math_random, ui_new_slider = client.update_player_list, globals.curtime, math.random, ui.new_slider
local client_latency, client_set_event_callback, entity_get_local_player, entity_is_alive, math_floor, renderer_indicator, renderer_text, ui_get, ui_new_checkbox, ui_new_combobox, ui_new_hotkey, ui_new_label, ui_reference, ui_set, ui_set_visible = client.latency, client.set_event_callback, entity.get_local_player, entity.is_alive, math.floor, renderer.indicator, renderer.text, ui.get, ui.new_checkbox, ui.new_combobox, ui.new_hotkey, ui.new_label, ui.reference, ui.set, ui.set_visible
--------------------------- References ---------------------------
local ref = {
    pitch = ui_reference("AA", "Anti-aimbot angles", "Pitch"),
    yawbase = ui_reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {ui_reference("AA", "Anti-aimbot angles", "Yaw")},
    bodyyaw = {ui_reference("AA", "Anti-aimbot angles", "Body yaw")},
    fakeyawlimit = ui_reference("AA", "Anti-aimbot angles", "Fake yaw limit"),
    jitter = {ui_reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    freestandingbodyyaw = ui_reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
    freestanding = {ui_reference("AA", "Anti-aimbot angles", "Freestanding")},
    edgeyaw = ui_reference("AA", "Anti-aimbot angles", "Edge yaw"),
    doubletap  = {ui_reference("Rage","Other","Double tap")},
    dtmode = ui_reference("Rage", "Other", "Double tap mode"),
    prefer = ui_reference("Rage", "Aimbot", "Prefer safe point"),
    force = ui_reference("Rage", "Aimbot", "Force safe point"),
    baim = ui_reference("Rage", "Other", "Force body aim"),
    onshot = {ui_reference("AA", "Other", "On shot anti-aim")},
    dtlimit = ui_reference("Rage","Other","Double tap fake lag limit"),
    fakeducking = ui_reference("RAGE", "Other", "Duck peek assist"),
    fakelag = ui.reference("AA", "Fake lag", "Enabled"),
    fakelag_limit = ui_reference("AA", "Fake lag", "Limit"),
    quickpeek = {ui_reference( "Rage", "Other", "Quick peek assist")},
    slowwalk = {ui_reference("AA", "Other", "slow motion")},
    sv_maxusrcmdprocessticks = ui_reference("MISC", "Settings", "sv_maxusrcmdprocessticks"),
}  
--------------------------- Anti Aim Stuff ---------------------------  
local aa = {
    antiaim = ui_new_combobox("AA", "Anti-aimbot angles", "Anti-Aim Options", {"Gamesense", "Bullet Detection", "Detect Missed Side"}),
    mode = ui.new_slider("AA", "Anti-aimbot angles", "Detection Type ", 1, 5, 1, true, " ", 1, {[1] = "Default", [2] = "Passive", [3] = "Aggressive", [4] = "Dangerous", [5] = "Custom"}),
    detectmode = ui.new_slider("AA", "Anti-aimbot angles", "Detection Type", 1, 3, 1, true, " ", 1, {[1] = "Missed Side", [2] = "Opposite Side", [3] = "Custom"}),
    bullet_range = ui.new_slider("AA", "Anti-aimbot angles", "Bullet Detection Range", 1, 100, 1, true, "%", 1, {[50] = "Default"}),
    textbox_thing = ui.new_label("AA", "Anti-aimbot angles", "Custom Angles [Separate With ,]"),
    builder = ui.new_textbox("AA", "Anti-aimbot angles", "Bruteforce Thing"),
    detect_text = ui.new_label("AA", "Anti-aimbot angles", "Missed Angle > 0°"),
    detectleft = ui.new_textbox("AA", "Anti-aimbot angles", "Detect Left"),
    detect_text2 = ui.new_label("AA", "Anti-aimbot angles", "Missed Angle < 0°"),
    detectright = ui.new_textbox("AA", "Anti-aimbot angles", "Detect Right"),
    pitch = ui_new_combobox("AA", "Anti-aimbot angles", "Pitch", {"Off", "Default", "Up", "Down", "Minimal", "Random"}),
    yawbase = ui_new_combobox("AA", "Anti-aimbot angles", "Yaw Base", {"Local View", "At Targets"}),
    yaw = ui_new_combobox("AA", "Anti-aimbot angles", "Yaw", {"Off", "180", "Spin", "Static", "180 Z", "Crosshair"}),
    yaw_slider = ui_new_slider("AA", "Anti-aimbot angles", "\nYaw Offset", -180, 180, 0, true, "°"),
    jitter = ui_new_combobox("AA", "Anti-aimbot angles", "Yaw Jitter", {"Off", "Offset","Center","Random", "Dynamic"}),
    player_state_jitter = ui_new_combobox("AA", "Anti-aimbot angles", "Player State", {"Standing", "Moving", "In Air", "Crouching", "Slow Walking"}),
    jitter_air = ui_new_combobox("AA", "Anti-aimbot angles", "Jitter Type\n1", {"Off", "Offset", "Center","Random"}),
    jitter_crouching = ui_new_combobox("AA", "Anti-aimbot angles", "Jitter Type\n2", {"Off", "Offset","Center","Random"}),
    jitter_standing = ui_new_combobox("AA", "Anti-aimbot angles", "Jitter Type\n3", {"Off", "Offset","Center","Random"}),
    jitter_moving = ui_new_combobox("AA", "Anti-aimbot angles", "Jitter Type\n4", {"Off", "Offset","Center","Random"}),
    jitter_slowwalk = ui_new_combobox("AA", "Anti-aimbot angles", "Jitter Type\n5", {"Off", "Offset","Center","Random"}),
    air_limit_jitter = ui_new_slider("AA", "Anti-aimbot angles", "Yaw Jitter Add\n1", -180, 180, 0, true, "°"),
    crouching_limit_jitter = ui_new_slider("AA", "Anti-aimbot angles", "Yaw Jitter Add\n2", -180, 180, 0, true, "°"),
    standing_limit_jitter = ui_new_slider("AA", "Anti-aimbot angles", "Yaw Jitter Add\n3", -180, 180, 0, true, "°"),
    moving_limit_jitter = ui_new_slider("AA", "Anti-aimbot angles", "Yaw Jitter Add\n4", -180, 180, 0, true, "°"),
    slowwalk_limit_jitter = ui_new_slider("AA", "Anti-aimbot angles", "Yaw Jitter Add\n5", -180, 180, 0, true, "°"),
    jitter_slider = ui_new_slider("AA", "Anti-aimbot angles", "\nJitter Slider", -180, 180, 0, true, "°"),
    bodyyaw = ui_new_combobox("AA", "Anti-aimbot angles", "Body Yaw", {"Off", "Opposite", "Static", "Jitter"}),
    bodyyaw_slider = ui_new_slider("AA", "Anti-aimbot angles", "\nBody Yaw Offset", -180, 180, 0, true, "°"),
    freestandingbodyyaw = ui_new_checkbox("AA", "Anti-aimbot angles", "Freestanding Body Yaw"),
    fake_type = ui_new_combobox("AA", "Anti-aimbot angles", "Lower Body Yaw Target", {"Off", "Static", "Dynamic", "On Hit", "Randomize"}),
    player_state = ui_new_combobox("AA", "Anti-aimbot angles", "Player State", {"Standing", "Moving", "In Air", "Crouching", "Slow Walking"}),
    air_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit\n1", 0, 60, 0, true, "°"),
    crouching_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit\n2", 0, 60, 0, true, "°"),
    standing_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit\n3", 0, 60, 0, true, "°"),
    moving_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit\n4", 0, 60, 0, true, "°"),
    slowwalk_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit\n5", 0, 60, 0, true, "°"),
    fake_limit = ui_new_slider("AA", "Anti-aimbot angles", "Fake Yaw Limit", 0, 60, 0, true, "°"),
    randomize = ui.new_multiselect("AA", "Anti-aimbot angles", "Randomize Fake Yaw Limit", {"Always On", "Static", "On Ground", "Moving On Ground", "Sprinting", "In Air", "Crouching", "Crouching In Air", "Fake Duck", "Slow Motion"}),
    randomize_min = ui_new_slider("AA", "Anti-aimbot angles", "Minimum Limit", 0, 60, 0, true, "°"),
    randomize_max = ui_new_slider("AA", "Anti-aimbot angles", "Maximum Limit", 0, 60, 60, true, "°"),
    edgeyaw = ui_new_hotkey("AA", "Anti-aimbot angles", "Edge Yaw"),
    freestanding = ui_new_hotkey("AA", "Anti-aimbot angles", "Freestanding"),
    legit = ui_new_checkbox("AA", "Anti-aimbot angles", "Legit Anti-Aim On Use"),
    killsay = ui_new_checkbox("AA", "Other", "Killsay"),
    clantag = ui_new_checkbox("AA", "Other", "Clantag"), 
    quickpeek_adjustments = ui.new_multiselect("AA", "Fake Lag", "Quick Peek Adjustments", {"Freestanding", "Edge Yaw", "Disable Pitch", "Disable Fake Lag"}),
    health_slider = ui_new_slider("AA", "Fake Lag", "Only Disable Pitch If Less Than", 0, 100, 0, true, "HP", 1, {[100] = "Always On"}),
    triggers = ui.new_multiselect("AA", "Fake Lag", "Lag Compensation Triggers", {"In Air", "On Key", "Crouching In Air"}),
    exploits = ui.new_multiselect("AA", "Fake Lag", "Exploits", {"Anti-AX", "Force DT Recharge"}),
    trigger_key = ui_new_hotkey("AA", "Fake Lag", "Lag Compensation Hotkey"),
}


local visual = {
    indicators = ui_new_checkbox("AA", "Other", "Crosshair Indicators"),
    type = ui_new_combobox("AA", "Other", "Indicator Style", {"Recode", "Original",  "Old", "Basic"}),
    label_recode = ui.new_label("AA", "Other", "Indicator Color"),
    color_recode = ui.new_color_picker("AA", "Other", "Indicator color", 130, 170, 225, 255),
    label = ui.new_label("AA", "Other", "Primary Color"),
    primary_color = ui.new_color_picker("AA", "Other", " ", 0, 255, 255, 255),
    label2 = ui.new_label("AA", "Other", "Secondary Color"),
    secondary_color = ui.new_color_picker("AA", "Other", "  ", 255, 255, 255, 255),
    label3 = ui.new_label("AA", "Other", "Name Color"),
    name_color = ui.new_color_picker("AA", "Other", "  ", 255, 255, 255, 255),
}

local references = {ref.pitch, ref.yawbase, ref.yaw[1], ref.yaw[2], ref.bodyyaw[1], ref.bodyyaw[2], ref.fakeyawlimit, ref.jitter[1], ref.jitter[2], ref.freestandingbodyyaw, ref.freestanding[1], ref.freestanding[2], ref.edgeyaw}
local flip = false
local detected_angle = 0
local ab = 0
local aa_state = 0
local time = 1
local choke = 0
local choke1 = 0
local choke2 = 0
local choke3 = 0
local choke4 = 0
local choke5 = 0

local default = {-95, 95}
local passive = {26, 0, -15}
local agressive = {60, 0, 90}
local aggressive_jitter = {-18, 27, 35}
local dangerous = {-60, 32, -20, 8}

client.exec("playvol \"survival/buy_item_01.wav\" 1")

local function split(string, symbol)
    local options = {}
    for word in string.gmatch(string, "([^"..symbol.."]+)") do
        options[#options+1] = word
    end
    return options
end

local function SetTableVisibility(table, state)
    for i = 1, #table do
        ui_set_visible(table[i], state)
    end
end

function round(num, numDecimalPlaces)
local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function clamp(num, min, max)
    if num < min then
        num = min
    elseif num > max then
        num = max
    end
    return num
end

local function map(n, start, stop, new_start, new_stop)
    local value = (n - start) / (stop - start) * (new_stop - new_start) + new_start

    return new_start < new_stop and math.max(math.min(value, new_stop), new_start) or math.max(math.min(value, new_start), new_stop)
end
    

local function SetTable(bool_tbl, item, state)
    for k, v in pairs(bool_tbl) do
        if bool_tbl[k] then
            ui_set(item, state)
            break
        end
    end
end

local function contains(item, val)
table = ui.get(item)
    for i=1,#table do
        if table[i] == val then
            return true
        end
    end
    return false
end

local function calculate_stage(len, speed)
    return math_floor((globals_curtime() * speed / 10) % len + 1)
end


local function GetClosestPoint(A, B, P)
local a_to_p = { P[1] - A[1], P[2] - A[2] }
local a_to_b = { B[1] - A[1], B[2] - A[2] }

local atb2 = a_to_b[1]^2 + a_to_b[2]^2

local atp_dot_atb = a_to_p[1]*a_to_b[1] + a_to_p[2]*a_to_b[2]
local t = atp_dot_atb / atb2

return { A[1] + a_to_b[1]*t, A[2] + a_to_b[2]*t }
end

-- 3d line distance detection from ts
local function dist_from_3dline(shooter, e)
local x, y, z = entity.hitbox_position(shooter, 0)
local x1, y1, z1 = client.eye_position()

local p = {x1,y1,z1}

local a = {x,y,z}
local b = {e.x,e.y,e.z}

local ab = {b[1] - a[1], b[2] - a[2], b[3] - a[3]}
local len = math.sqrt(ab[1]^2 + ab[2]^2 + ab[3]^2)
local d  = {ab[1] / len, ab[2] / len, ab[3] / len}
local ap = {p[1] - a[1], p[2] - a[2], p[3] - a[3]}
local d2 = d[1]*ap[1] + d[2]*ap[2] + d[3]*ap[3]

bp = {a[1] + d2 * d[1], a[2] + d2 * d[2], a[3] + d2 * d[3]}

return (bp[1]-x1) + (bp[2]-y1) + (bp[3]-z1)
end

local skip = false
client_set_event_callback("bullet_impact", function(c)
    if ((ui_get(aa.antiaim) == "Bullet Detection" or ui_get(aa.antiaim) == "Detect Missed Side") and entity.is_alive(entity.get_local_player())) and not skip then
        local ent = client.userid_to_entindex(c.userid)
        if not entity.is_dormant(ent) and entity.is_enemy(ent) then
            local ent_pos = { entity.get_prop(ent, "m_vecOrigin") }
            local loc_pos = { entity.get_prop(ent, "m_vecOrigin") }

            local delta = dist_from_3dline(ent, c)

            if ui_get(aa.antiaim) == "Bullet Detection" then
                if math.abs(delta) < ui_get(aa.bullet_range) / 1.6666667 then
                    ab = ab + 1
                    flip = true
                end
            elseif ui_get(aa.antiaim) == "Detect Missed Side" then
                local ent_pos = { entity.get_prop(ent, "m_vecOrigin") }
                local loc_pos = { entity.hitbox_position(entity.get_local_player(), 0) }
                local end_pos = {loc_pos[1] - ent_pos[1], loc_pos[2] - ent_pos[2], loc_pos[3] - ent_pos[3]}
            
                if math.abs(delta) < ui_get(aa.bullet_range) / 1.6666667 then
                    local direciton = 1
                    if end_pos[1] >= 0 and end_pos[2] < 0 then
                        direciton = 1
                    elseif end_pos[1] <= 0 and end_pos[2] < 0 then
                        direciton = 1
                    elseif end_pos[1] <= 0 and end_pos[2] > 0 then
                        direciton = -1
                    elseif end_pos[1] >= 0 and end_pos[2] > 0  then
                        direciton = -1
                    end

                    detected_angle = delta * direciton
                    flip = true
                end
            end
        end
    end

    local mode = ui_get(aa.mode)

    --add jitter anti brute
    if flip then
        if ui_get(aa.antiaim) == "Bullet Detection" then 
            if mode == 1 then
                ui_set(aa.bodyyaw_slider, default[(ab%2)+1])
                ui_set(aa.bodyyaw, "Static")
            elseif mode == 2 then
                ui_set(aa.bodyyaw_slider, passive[(ab%3)+1])
                ui_set(aa.bodyyaw, "Static")
            elseif mode == 3 then
                ui_set(aa.bodyyaw_slider, agressive[(ab%3)+1])
                ui_set(aa.bodyyaw, "Jitter")
            elseif mode == 4 and static then
                ui_set(aa.bodyyaw_slider, dangerous[(ab%4)+1])
                ui_set(aa.bodyyaw, "Static")
            elseif mode == 5 then --thx ally
                local settings = split(ui_get(aa.builder), ",")
                aa_state = clamp((aa_state + 1) % (#settings+1), 1, (#settings+1))
                ui_set(aa.bodyyaw_slider, settings[aa_state])
            end

            elseif ui_get(aa.antiaim) == "Detect Missed Side" and ui_get(aa.detectmode) == 1 then
                print(detected_angle)
                ui_set(aa.bodyyaw, "Static")
            if detected_angle > 0 then
                ui_set(aa.bodyyaw_slider, -180)
            else
                ui_set(aa.bodyyaw_slider, 180)
            end

            elseif ui_get(aa.antiaim) == "Detect Missed Side" and ui_get(aa.detectmode) == 2 then
                print(detected_angle)
                ui_set(aa.bodyyaw, "Static")
            if detected_angle > 0 then
                ui_set(aa.bodyyaw_slider, 180)
            else
                ui_set(aa.bodyyaw_slider, -180)
            end

    
        elseif ui_get(aa.antiaim) == "Detect Missed Side" and ui_get(aa.detectmode) == 3 then
            if detected_angle > 0 then
                local settings = split(ui_get(aa.detectleft), ",")
                aa_state = clamp((aa_state + 1) % (#settings+1), 1, (#settings+1))
                ui_set(aa.bodyyaw_slider, settings[aa_state])  
            else
                local settings = split(ui_get(aa.detectright), ",")
                aa_state = clamp((aa_state + 1) % (#settings+1), 1, (#settings+1))
                ui_set(aa.bodyyaw_slider, settings[aa_state])
            end
        end
        ui_set(ref.bodyyaw[2], ui_get(aa.bodyyaw_slider))
        flip = false
    end
    skip = false
end)

client_set_event_callback("player_hurt", function(e)
    local attacker_entindex = client_userid_to_entindex(e.attacker)
    local victim_entindex = client_userid_to_entindex(e.userid)
    if ui_get(aa.antiaim) == "Detect Missed Side" and entity.is_alive(entity.get_local_player()) then
        if victim_entindex == entity_get_local_player() and entity_is_enemy(attacker_entindex) then
            local by = ui_get(aa.bodyyaw_slider)
            ui_set(aa.bodyyaw_slider, by * -1)
            skip = true
        end
    end

    if ui_get(aa.fake_type) == "On Hit" and entity.is_alive(entity.get_local_player()) then
        if victim_entindex == entity_get_local_player() and entity_is_enemy(attacker_entindex) then
            ui_set(aa.fake_limit, math.random(0, 60))
        end
    end
end)

client_set_event_callback("setup_command", function(cmd)
            
if ui_get(aa.mode) == 2 and ui_get(aa.bodyyaw_slider) == 90 then
    ui_set(aa.fake_limit, 60)
end

local x, y = entity.get_prop( entity.get_local_player(), "m_vecVelocity")
local speed = x ~= nil and math.floor(math.sqrt( x * x + y * y + 0.5 )) or 0

local local_player = entity.get_local_player()
local health = entity.get_prop(local_player, "m_iHealth")

local in_air = entity.get_prop(entity.get_local_player(), "m_fFlags") == 256
local on_ground = entity.get_prop(entity.get_local_player(), "m_fFlags") == 257
local fake_duck = entity.get_prop(entity.get_local_player(), "m_fFlags") == 261
local crouching_in_air = entity.get_prop(entity.get_local_player(), "m_fFlags") == 262
local crouching = entity.get_prop(entity.get_local_player(), "m_fFlags") == 263
local quickpeek = ui_get(ref.quickpeek[2]) and "Always on" or "On hotkey"

local fake_conditions = {
    contains(aa.randomize, "Always On"),
    contains(aa.randomize, "In Air") and in_air,
    contains(aa.randomize, "Static") and speed == 1,
    contains(aa.randomize, "Crouching") and crouching,
    contains(aa.randomize, "On Ground") and on_ground,
    contains(aa.randomize, "Crouching In Air") and crouching_in_air,
    contains(aa.randomize, "Fake Duck") and ui_get(ref.fakeducking),
    contains(aa.randomize, "Slow Motion") and ui_get(ref.slowwalk[2]) and speed > 1,
    contains(aa.randomize, "Sprinting") and not in_air and not crouching_in_air and not crouching and speed > 100 and speed <= 250,
}
SetTable(fake_conditions, aa.fake_limit, math_random(ui_get(aa.randomize_min), ui_get(aa.randomize_max)))

if contains(aa.quickpeek_adjustments, "Edge Yaw") then
    ui_set(aa.edgeyaw, (quickpeek))
end
if contains(aa.quickpeek_adjustments, "Freestanding") then
    ui_set(aa.freestanding, (quickpeek))
end
if contains(aa.quickpeek_adjustments, "Disable Fake Lag") then
    ui_set(ref.fakelag, not ui_get(ref.quickpeek[2]))
end

if contains(aa.exploits, "Anti-AX") then
    if ui_get(ref.quickpeek[2]) then
        ui_set(ref.dtlimit, 2)
        ui_set(ref.fakelag_limit, 14)
    else
        ui_set(ref.dtlimit, 1)
        ui_set(ref.fakelag_limit, 14)
    end
end

if contains(aa.quickpeek_adjustments, "Disable Pitch") then
    if health <= ui_get(aa.health_slider) and ui_get(ref.quickpeek[2]) then
        ui_set(aa.pitch, (ui_get(ref.quickpeek[2])) and "Off" or "Default")
        elseif health <= ui_get(aa.health_slider) and not ui_get(ref.quickpeek[2]) or health >= ui_get(aa.health_slider)then
            ui_set(aa.pitch, "Default")
        end
    end

local lag_conditions = {
    ui_get(aa.trigger_key),
    contains(aa.triggers, "In Air") and in_air,
    contains(aa.triggers, "Crouching In Air" ) and crouching_in_air,
}

ui_set(ref.doubletap[1], true)
ui_set(ref.onshot[1], true)

SetTable(lag_conditions, ref.doubletap[1], false, ref.onshot[1], false)

if ui_get(aa.fake_type) == "Dynamic" then
    if in_air then
        ui_set(aa.fake_limit, ui_get(aa.air_limit))
    elseif crouching then
        ui_set(aa.fake_limit, ui_get(aa.crouching_limit))
    elseif speed == 1 then 
        ui_set(aa.fake_limit, ui_get(aa.standing_limit))
    elseif not in_air and not crouching_in_air and not crouching and speed > 1 and not ui_get(ref.slowwalk[2]) then
        ui_set(aa.fake_limit, ui_get(aa.moving_limit))
    elseif ui_get(ref.slowwalk[2]) then
        ui_set(aa.fake_limit, ui_get(aa.slowwalk_limit))
    end
end

if ui_get(aa.jitter) == "Dynamic" then
    if in_air or crouching_in_air then
        ui_set(aa.jitter_slider, ui_get(aa.air_limit_jitter))
        ui_set(ref.jitter[1], ui_get(aa.jitter_air))
    elseif crouching then
        ui_set(aa.jitter_slider, ui_get(aa.crouching_limit_jitter))
        ui_set(ref.jitter[1], ui_get(aa.jitter_crouching))
    elseif speed == 1 then 
        ui_set(aa.jitter_slider, ui_get(aa.standing_limit_jitter))
        ui_set(ref.jitter[1], ui_get(aa.jitter_standing))
    elseif not in_air and not crouching_in_air and not crouching and speed > 1 and not ui_get(ref.slowwalk[2]) then
        ui_set(aa.jitter_slider, ui_get(aa.moving_limit_jitter))
        ui_set(ref.jitter[1], ui_get(aa.jitter_moving))
    elseif ui_get(ref.slowwalk[2]) then
        ui_set(aa.jitter_slider, ui_get(aa.slowwalk_limit_jitter))
        ui_set(ref.jitter[1], ui_get(aa.jitter_slowwalk))
    end
end

if ui_get(aa.fake_type) == "Off" then
    ui_set(aa.fake_limit, 0)
elseif ui_get(aa.fake_type) == "Static" then
    ui_set(aa.randomize, "-")
end


    if ui_get(ref.fakelag) then
        if not cached then
            cached_ticks = ui_get(ref.sv_maxusrcmdprocessticks)
            cached = true
        end

        if contains(aa.exploits, "Force DT Recharge") then
            if not anti_aim.get_double_tap() then
                ui_set(ref.sv_maxusrcmdprocessticks, 20)
            elseif anti_aim.get_double_tap() then
                ui_set(ref.sv_maxusrcmdprocessticks, 16)
            end
        end

        elseif not contains(aa.exploits, "Force DT Recharge") and cached then
            ui_set(ref.sv_maxusrcmdprocessticks, cached_ticks)
            cached = false
        end

--credits to kez
local weapon = entity_get_player_weapon()
if ui_get(aa.legit) then
    if weapon ~= nil and entity_get_classname(weapon) == "CC4" then
        if cmd.in_attack == 1 then
            cmd.in_attack = 0
            cmd.in_use = 1
            ui_set(ref.fakeyawlimit, 58)
        end
    else
        if cmd.chokedcommands == 0 then
            cmd.in_use = 0
            ui_set(ref.fakeyawlimit, ui_get(aa.fake_limit))
        end
    end
end

    if ui_get(aa.jitter) == "Off" or ui_get(aa.jitter) == "Center" or ui_get(aa.jitter) == "Offset" or ui_get(aa.jitter) == "Random" then
        ui_set(ref.jitter[1], ui_get(aa.jitter))
    end

    if cmd.chokedcommands < choke then
        choke1 = choke2
        choke2 = choke3
        choke3 = choke4
        choke4 = choke5
        choke5 = choke
    end
    choke = cmd.chokedcommands    

    ui_set(ref.pitch, ui_get(aa.pitch))
    ui_set(ref.yawbase, ui_get(aa.yawbase))
    ui_set(ref.yaw[1], ui_get(aa.yaw))
    ui_set(ref.yaw[2], ui_get(aa.yaw_slider))
    ui_set(ref.jitter[2], ui_get(aa.jitter_slider))
    ui_set(ref.bodyyaw[1], ui_get(aa.bodyyaw))
    ui_set(ref.bodyyaw[2], ui_get(aa.bodyyaw_slider))
    ui_set(ref.fakeyawlimit, ui_get(aa.fake_limit))
    ui_set(ref.edgeyaw, ui_get(aa.edgeyaw) and true or false)
    ui_set(ref.freestandingbodyyaw, ui_get(aa.freestandingbodyyaw) and true or false)
    ui_set(ref.freestanding[1], "Default")
    ui_set(ref.freestanding[2], ui_get(aa.freestanding) and "Always on" or "On hotkey")
end)

local function player_death(e)
    local killsay = {
        "(◣_◢)DISCOMBOBULATED(◣_◢)",
        "ABSOLUTELY DISCOMBOBULATED!!!",
        "Get Good, Get Discombobulation.",
        "Get Discombobulated You Fucking Donut!",
        "Omfg, I Think You Just Got Discombobulated LOL!",
        "Omg Thats Embarassing! You Really Just Got Discombobulated LOL",
        "You Silly Little Sausage! Get Good, Get Discombobulation",
        "Fuckin Actual Mongoloid. Get Owned By Discombobulation.lua",
        "Bozo Eliminated! L Kid + Ratio. Your Mom Has A Penis. Sit Down. Get Real.",
        "You Fuckin Baboon! You Can't Resolve Me You Fucking Donut! Owned By Discombobulation.",
        "Nice Hack, Ape! Get Cracked Like An Egg By Discombobulation.lua",
    }
    if ui_get(aa.killsay) then
        local attacker_entindex = client_userid_to_entindex(e.attacker)
        local victim_entindex = client_userid_to_entindex(e.userid)
            if attacker_entindex ~= entity_get_local_player() then
                return
            end
        client.exec("say " .. killsay[math.random(1, #killsay)])
    end
end

local function indicators()
    local x, y = client.screen_size()
    local x1, y1 = entity.get_prop( entity.get_local_player(), "m_vecVelocity")
    local speed = x ~= nil and math.floor(math.sqrt( x1 * x1 + y1 * y1 + 0.5 )) or 0
    local in_air = entity.get_prop(entity_get_local_player(), "m_fFlags") == 256
    local crouching_in_air = entity.get_prop(entity.get_local_player(), "m_fFlags") == 262
    local crouching = entity.get_prop(entity.get_local_player(), "m_fFlags") == 263

    local alpha = math.sin(math.abs((math.pi * -1) + (globals_curtime() * 1.5) % (math.pi * 2))) * 255
    local body_yaw = math.max(-60, math.min(60, round((entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) or 0)*120-60+0.5, 1)))
    local angle = ui_get(ref.bodyyaw[2])

    local clr = {ui_get(visual.primary_color)}
    local clr2 = {ui_get(visual.secondary_color)}
    local clr3 = {ui_get(visual.name_color)}
    local clr4 = {ui_get(visual.color_recode)}

    local chokedcommands = globals.chokedcommands()
    local body_yaw_solaris = 0
    local fake_lag_limit = ui.get(ref.fakelag_limit)
    local players = entity.get_players(true)

    local local_player = entity.get_local_player()

    if chokedcommands then
        chokedcommands = chokedcommands / fake_lag_limit
    end


    local local_player = entity.get_local_player()
    local bodyyaw = entity.get_prop(local_player, "m_flPoseParameter", 11)
        if bodyyaw then
            bodyyaw = math.abs(map(bodyyaw, 0, 1, -60, 60))
            bodyyaw = math.max(0, math.min(57, bodyyaw))
            body_yaw_solaris = bodyyaw / 57
        end
    

if entity_is_alive(entity_get_local_player()) then
    if ui_get(visual.indicators) and ui_get(visual.type) == "Recode" then
        renderer.rectangle(x/2 - 32, y/2 + 30, 63, 4, 0, 0, 0, 150)
        renderer.rectangle(x/2 - 31, y/2 + 31, 61 * body_yaw_solaris, 2, clr4[1], clr4[2], clr4[3], clr4[4], true)
        renderer_text(x/2 - 38, y/2 + 20, 255, 255, 255, 255, "-", nil,"DISCOMBOBULATION")
        renderer_text(x/2 - 22, y/2 + 33, clr4[1], clr4[2], clr4[3], clr4[4], "-", nil,"FAKE YAW: ")
        
        if body_yaw > 0 then
            renderer_text(x/2 + 16, y/2 + 33, 255, 255, 255, 255, "-", nil,"L")
        else
            renderer_text(x/2 + 16, y/2 + 33, 255, 255, 255, 255, "-", nil,"R")
        end

    
    if ui_get(ref.doubletap[2]) and anti_aim.get_double_tap() then
        renderer_text(x/2 - 26, y/2 + 46, clr4[1], clr4[2], clr4[3], clr4[4], "-c", nil, "DT")
    elseif ui_get(ref.fakeducking) or not ui_get(ref.doubletap[2]) or not anti_aim.get_double_tap() then
        renderer_text(x/2 - 26, y/2 + 46, 170, 170, 170, 210, "-c", nil," DT")
    end

    if ui_get(ref.onshot[1]) and ui_get(ref.onshot[2]) then
        renderer_text(x/2 - 14, y/2 + 46, clr4[1], clr4[2], clr4[3], clr4[4], "-c", nil,"OS")
    else
        renderer_text(x/2 - 14, y/2 + 46, 170, 170, 170, 210, "-c", nil,"OS")
    end

    if ui_get(ref.baim) then
        renderer_text(x/2 - 2, y/2 + 46, clr4[1], clr4[2], clr4[3], clr4[4], "-c", nil,"SP")
    else
        renderer_text(x/2 - 2, y/2 + 46, 170, 170, 170, 210, "-c", nil,"SP")
    end

    if ui_get(ref.freestanding[2]) then
        renderer_text(x/2 + 9, y/2 + 46, clr4[1], clr4[2], clr4[3], clr4[4], "-c", nil,"FS")
    else
        renderer_text(x/2 + 9, y/2 + 46, 170, 170, 170, 210, "-c", nil,"FS")
    end

    if ui_get(ref.quickpeek[2]) then
        renderer_text(x/2 + 21, y/2 + 46, clr4[1], clr4[2], clr4[3], clr4[4], "-c", nil,"QP")
    else
        renderer_text(x/2 + 21, y/2 + 46, 170, 170, 170, 210, "-c", nil,"QP")
    end
end

    if ui_get(visual.indicators) and ui_get(visual.type) == "Old" then
        renderer_text(x/2 - 3, y/2 + 25, clr3[1], clr3[2], clr3[3], clr3[4], "-c", nil, "DISCOMBOBULATION")
            --deync line
        renderer.gradient(x/2 - 1, y/2 + 40,-body_yaw * 1.5, 3, clr[1], clr[2], clr[3], clr[4], clr[1], clr[2], clr[3], 0, 0, 0, 0, 0,  true)
        renderer.gradient(x/2 - 1, y/2 + 40, body_yaw * 1.5, 3, clr[1], clr[2], clr[3], clr[4], clr[1], clr[2], clr[3], 0, 0, 0, 0, 0,  true)
        renderer_text(x/2 - 2, y/2 + 41, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "DESYNC")
            --fake lag line
        renderer.gradient(x/2 + 16, y/2 + 48, chokedcommands * 64, 3, clr[1], clr[2], clr[3], clr[4], clr[1], clr[2], clr[3], 0, 0, 0, 0, 0,  true)
        renderer.gradient(x/2 - 18, y/2 + 48, -chokedcommands * 64, 3, clr[1], clr[2], clr[3], clr[4], clr[1], clr[2], clr[3], 0, 0, 0, 0, 0,  true)
        renderer_text(x/2 - 3, y/2 + 49, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "FAKE LAG")

        if ui_get(ref.doubletap[2]) and anti_aim.get_double_tap() then
            renderer_text(x/2 - 22, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "DT")
        elseif ui_get(ref.fakeducking) or not ui_get(ref.doubletap[2]) or not anti_aim.get_double_tap() then
            renderer_text(x/2 - 22, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil," DT")
        end

        if ui_get(ref.onshot[1]) and ui_get(ref.onshot[2]) then
            renderer_text(x/2 - 9, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil,"OS")
        else
            renderer_text(x/2 - 9, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil,"OS")
        end

        if ui_get(ref.force) then
            renderer_text(x/2 + 4, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "SP")
        else
            renderer_text(x/2 + 4, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "SP")
        end

        if ui_get(ref.fakeducking) then
            renderer_text(x/2 + 16, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "FD")
        else
            renderer_text(x/2 + 16, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "FD")
        end

        if ui_get(ref.bodyyaw[1]) == "Jitter" then
            renderer_text(x/2 - 3, y/2 + 57, 255, 255, 255, 255, "-c", nil, "[JITTER AA]")
        elseif ui_get(ref.bodyyaw[1]) == "Static" then
            renderer_text(x/2 - 3, y/2 + 57, 255, 255, 255, 255, "-c", nil, "[ANTI-BRUTE]")
        elseif ui_get(ref.bodyyaw[1]) == "Opposite" then
            renderer_text(x/2 - 3, y/2 + 57, 255, 255, 255, 255, "-c", nil, "[FREESTANDING]")    
        end
    end

    if ui_get(visual.indicators) and ui_get(visual.type) == "Basic" then
        renderer_text(x/2 - 2, y/2 + 19, 255, 255, 255, 255, "-c", nil, "DISCOMBOBULATION")
        renderer.rectangle(x/2 - 38, y/2 + 25, 76, 4, 0, 0, 0, 75)
        renderer.rectangle(x/2 - 38, y/2 + 25, 75 * body_yaw_solaris, 3, clr4[1], clr4[2], clr4[3], clr4[4], true)
    end



    if ui_get(visual.indicators) and ui_get(visual.type) == "Original" then
        renderer_text(x/2 - 11, y/2 + 41, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "FAKE : ")
        renderer_text(x/2 - 4, y/2 + 49, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "LAG : ", string.format("%i-%i-%i-%i-%i",choke5,choke4,choke3,choke2,choke1))
    

        if ui_get(ref.doubletap[2]) and anti_aim.get_double_tap() then
            renderer_text(x/2 - 22, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "DT")
        elseif ui_get(ref.fakeducking) or not ui_get(ref.doubletap[2]) or not anti_aim.get_double_tap() then
            renderer_text(x/2 - 22, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil," DT")
        end

        if ui_get(ref.onshot[1]) and ui_get(ref.onshot[2]) then
            renderer_text(x/2 - 9, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil,"OS")
        else
            renderer_text(x/2 - 9, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil,"OS")
        end

        if ui_get(ref.force) then
            renderer_text(x/2 + 4, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "SP")
        else
            renderer_text(x/2 + 4, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "SP")
        end

        if ui_get(ref.fakeducking) then
            renderer_text(x/2 + 16, y/2 + 33, clr[1], clr[2], clr[3], clr[4], "-c", nil, "FD")
        else
            renderer_text(x/2 + 16, y/2 + 33, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, "FD")
        end
    
        renderer_text(x/2 - 3, y/2 + 22, clr3[1], clr3[2], clr3[3], clr3[4], "-c", nil, "DISCOMBOBULATION")
    
        renderer.gradient(x/2 - 1, y/2 + 27, -body_yaw, 2,  0, 0, 0, 20, clr[1], clr[2], clr[3], clr[4], true)
        renderer.gradient(x/2 - 1, y/2 + 27, body_yaw, 2, 0, 0, 0 , 20, clr2[1], clr2[2], clr2[3], clr2[4],  true)
        renderer_text(x/2 + 8, y/2 + 41, clr2[1], clr2[2], clr2[3], clr2[4], "-c", nil, body_yaw)
        end
    end
end

local tags = {
    " ",
    " ",
    " ",
    "D",
    "Di",
    "Dis",
    "Disc", 
    "Disco",
    "Discom",
    "Discomb",
    "Discombo", 
    "Discombobu",
    "Discombobul",
    "iscombobula",
    "scombobulat",
    "combobulati",
    "ombobulation",
    "mbobulation",
    "bobulation",
    "obulation",
    "bulation",
    "ulation",
    "lation",
    "ation",
    "tion", 
    "ion", 
    "on", 
    "n", 
    " ",
    " ",
    " ",
}

local function clantag_changer()
   if ui_get(aa.clantag) then
       local tag = tags[calculate_stage(#tags, 30)]

       if clantag_old ~= tag then
           client.set_clan_tag(" ".. tag)
           clantag_old = tag
           clantag_override = true
       end
   else
       if clantag_override then
           client.delay_call(0.1, function() client.set_clan_tag(" ") end)
           clantag_override = false
       end
   end
end

----------------------------- Load Good Settings Button -----------------------------
local function settings()
    
    ui_set(aa.antiaim, "Bullet Detection")
    ui_set(aa.mode, 1)
    ui_set(aa.bullet_range, 50)
    ui_set(aa.yaw, "180")
    ui_set(aa.pitch, "Default")
    ui_set(aa.yawbase, "At Targets")
    ui_set(aa.jitter, "Dynamic")

    ui_set(aa.jitter_air, "Random")
    ui_set(aa.jitter_crouching, "Center")
    ui_set(aa.jitter_standing, "Center") 
    ui_set(aa.jitter_moving, "Center")
    ui_set(aa.jitter_slowwalk, "Center") 

    ui_set(aa.air_limit_jitter, -37)
    ui_set(aa.crouching_limit_jitter, 63)
    ui_set(aa.standing_limit_jitter, 24) 
    ui_set(aa.moving_limit_jitter, 60)
    ui_set(aa.slowwalk_limit_jitter, 17) 

    ui_set(aa.bodyyaw, "Static")
    ui_set(aa.bodyyaw_slider, 90)
    ui_set(aa.fake_type, "Static")    
    ui_set(aa.fake_limit, 58)
    ui_set(aa.legit, true)
end

local function update_log()
    client.color_log(255, 255, 255, " ")
    client.color_log(255, 255, 255, "----------------Discombobulation Update Log----------------")
    client.color_log(255, 255, 255, "|[+] Reworked Bullet Detection                            |")
    client.color_log(255, 255, 255, "|[+] Updated Bullet Detection Angles & Names              |")
    client.color_log(255, 255, 255, "|[+] Added Anti-AX (Makes It Harder To Be Anti-Exploited) |")
    client.color_log(255, 255, 255, "|[+] Added In Jitter Player States                        |")
    client.color_log(255, 255, 255, "|[+] Added A Bunch Of Indicator Options                   |")
    client.color_log(255, 255, 255, "|[+] Added A Button To Show Update Log                    |")
    client.color_log(255, 255, 255, "|[-] Removed Health Based Jitter                          |")
    client.color_log(255, 255, 255, "|[-] Removed Directional Offset                           |")
    client.color_log(255, 255, 255, "|[-] Removed Manual Anti-Aim                              |")
    client.color_log(255, 255, 255, "-----------------------------------------------------------")
    client.color_log(255, 255, 255, " ")
end
----------------------------- Visible Stuff -----------------------------
local function hide_shit()

    local player_state = ui_get(aa.player_state)
    local player_state_jitter = ui_get(aa.player_state_jitter)
    local dynamic_fake = ui_get(aa.fake_type) == "Dynamic"
    local dynamic_jitter = ui_get(aa.jitter) == "Dynamic"

    SetTableVisibility(references, false)
    SetTableVisibility({aa.randomize_min, aa.randomize_max}, ui_get(aa.fake_type) == "Randomize")
    SetTableVisibility({aa.builder, aa.textbox_thing}, ui_get(aa.antiaim) == "Bullet Detection" and ui_get(aa.mode) == 5)
    SetTableVisibility({aa.detect_text, aa.detect_text2, aa.detectleft, aa.detectright}, ui_get(aa.antiaim) == "Detect Missed Side" and ui_get(aa.detectmode) == 3)
    SetTableVisibility({visual.label_recode, visual.color_recode}, ui_get(visual.indicators) and ui.get(visual.type) == "Recode" or ui.get(visual.type) == "Basic")


    ui_set_visible(visual.type, ui_get(visual.indicators))
    ui_set_visible(aa.trigger_key, contains(aa.triggers, "On Key"))
    ui_set_visible(aa.mode, ui_get(aa.antiaim) == "Bullet Detection")
    ui_set_visible(aa.randomize, ui_get(aa.fake_type) == "Randomize")
    ui_set_visible(aa.detectmode, ui_get(aa.antiaim) == "Detect Missed Side")
    ui_set_visible(aa.health_slider, contains(aa.quickpeek_adjustments, "Disable Pitch"))
    ui_set_visible(aa.fake_limit, ui_get(aa.fake_type) == "Static" or ui_get(aa.fake_type) == "On Hit")
    ui_set_visible(aa.bodyyaw_slider, ui_get(aa.bodyyaw) == "Static" or ui_get(aa.bodyyaw) == "Jitter")
    ui_set_visible(aa.jitter_slider, ui_get(aa.jitter) == "Center" or ui_get(aa.jitter) == "Offset" or ui_get(aa.jitter) == "Random")
    ui_set_visible(aa.fake_limit, ui_get(aa.antiaim) == "Gamesense" or ui_get(aa.antiaim) == "Detect Missed Side" or ui_get(aa.mode) == 5 and fake_stuff)

    ui_set_visible(aa.player_state, dynamic_fake)
    ui_set_visible(aa.air_limit, player_state == "In Air" and dynamic_fake)
    ui_set_visible(aa.moving_limit, player_state == "Moving" and dynamic_fake)
    ui_set_visible(aa.standing_limit, player_state == "Standing" and dynamic_fake)
    ui_set_visible(aa.crouching_limit, player_state == "Crouching" and dynamic_fake)
    ui_set_visible(aa.slowwalk_limit, player_state == "Slow Walking" and dynamic_fake)

    ui_set_visible(aa.player_state_jitter, dynamic_jitter)
    SetTableVisibility({aa.air_limit_jitter, aa.jitter_air}, player_state_jitter == "In Air" and dynamic_jitter)
    SetTableVisibility({aa.moving_limit_jitter, aa.jitter_moving}, player_state_jitter == "Moving" and dynamic_jitter)
    SetTableVisibility({aa.standing_limit_jitter, aa.jitter_standing}, player_state_jitter == "Standing" and dynamic_jitter)
    SetTableVisibility({aa.crouching_limit_jitter, aa.jitter_crouching}, player_state_jitter == "Crouching" and dynamic_jitter)
    SetTableVisibility({aa.slowwalk_limit_jitter, aa.jitter_slowwalk}, player_state_jitter == "Slow Walking" and dynamic_jitter)

    ui_set_visible(aa.bullet_range, ui_get(aa.antiaim) == "Detect Missed Side" or ui_get(aa.antiaim) == "Bullet Detection" or ui_get(aa.mode) == 5)
    ui_set_visible(aa.yaw_slider, ui_get(aa.yaw) == "180" or ui_get(aa.yaw) == "Spin" or ui_get(aa.yaw) == "Static" or ui_get(aa.yaw) == "180 Z" or ui_get(aa.yaw) == "Crosshair")
end
    
local function on_shutdown()
    SetTableVisibility(references, true)
end

client_set_event_callback("shutdown", on_shutdown)
client_set_event_callback("setup command", settings)
client_set_event_callback("paint_ui", hide_shit)
client_set_event_callback("paint", indicators)
client_set_event_callback("player_death", player_death)
client_set_event_callback("paint", clantag_changer)

local load = ui_new_button("AA", "Anti-aimbot angles", "Load Good Settings", settings)
local log = ui_new_button("AA", "Anti-aimbot angles", "Update Log", update_log)
