-- SEB / Claudette MacKay-Lassonde Pavilion (CMLP) - ground floor, four rooms.
-- Source: Western Facilities Management floor plan SEB.pdf, sheet 02 (ground floor).
-- Modelled rooms: 1309, 1316, 1317, 1327 plus the corridors that connect them
-- (TA.131, TA.132, TA.133, TA.51/TA.50) and exterior entrance EX.11.
-- Scale: 1 block = 1 m. Dimensions were measured from the drawing at about 25 px per metre
-- (150 dpi render), so they are estimates (+/- 1 block). Corridors are kept >= 3 blocks wide.
-- Plan coordinates: px = east, pz = south (as on the drawing). The build flips pz so that
-- plan-north points to +Z in Luanti, which keeps the layout un-mirrored.
-- Rooms not listed above (1301-1308, 1320-1325, 1322, 1329-1337, washrooms, stairs) are
-- deliberately not modelled.

local mt = minetest
local MOD = mt.get_current_modname()
local store = mt.get_mod_storage()

-- Edit names and descriptions here; no other code needs to change.
local ROOM_INFO = {
  ["1309"] = {title = "Room 1309", info = "CMLP ground floor, south-east corner room beside the EX.11 entrance. Room function: to be confirmed (the Facilities plan gives numbers only)."},
  ["1316"] = {title = "Room 1316", info = "CMLP ground floor, central room off corridor TA.132, with a structural column. Room function: to be confirmed."},
  ["1317"] = {title = "Room 1317", info = "CMLP ground floor, south-facing room with exterior windows, opposite Room 1316 across TA.132. Room function: to be confirmed."},
  ["1327"] = {title = "Room 1327", info = "CMLP ground floor, north-west corner room with exterior windows, entered from corridor TA.133. Room function: to be confirmed."},
}

local function reg(id, desc, tex, extra)
  local def = {description = desc, tiles = {"cmlp_" .. tex .. ".png"}, is_ground_content = false,
    diggable = false, groups = {not_in_creative_inventory = 1}}   -- model cannot be broken (defect D-01)
  for k, v in pairs(extra or {}) do def[k] = v end
  mt.register_node(MOD .. ":" .. id, def)
end
reg("floor", "CMLP floor", "floor")
reg("wall", "CMLP interior wall", "wall")
reg("facade", "CMLP brick facade", "facade")
reg("roof", "CMLP ceiling", "roof")
reg("paving", "CMLP paving", "paving")
reg("frame", "CMLP frame", "metal")
reg("column", "CMLP column", "column")
reg("board", "CMLP whiteboard", "board")
reg("table", "CMLP table", "table")
reg("chair", "CMLP chair", "chair")
reg("lamp", "CMLP ceiling light", "lamp", {light_source = 14, paramtype = "light"})
reg("glass", "CMLP window", "glass", {drawtype = "glasslike", paramtype = "light",
  sunlight_propagates = true, use_texture_alpha = "blend"})
reg("door", "CMLP glazed door leaf", "glass", {drawtype = "nodebox", paramtype = "light",
  paramtype2 = "facedir", sunlight_propagates = true, use_texture_alpha = "blend", walkable = false,
  node_box = {type = "fixed", fixed = {-0.46, -0.5, 0.40, 0.46, 0.5, 0.48}},
  selection_box = {type = "fixed", fixed = {-0.5, -0.5, 0.35, 0.5, 0.5, 0.5}}})

local function show(player, title, info)
  if not player or not player:is_player() then return end
  mt.show_formspec(player:get_player_name(), MOD .. ":info",
    "formspec_version[4]size[9.4,4.3]" ..
    "label[0.5,0.55;" .. mt.formspec_escape(title) .. "]" ..
    "textarea[0.5,1.15;8.4,2.3;text;;" .. mt.formspec_escape(info) .. "]" ..
    "button_exit[3.5,3.55;2.4,0.55;close;Close]")
end
local function panel(id)
  local tex = "cmlp_" .. id .. ".png"
  mt.register_node(MOD .. ":" .. id, {
    description = "CMLP wall sign", drawtype = "signlike", tiles = {tex},
    inventory_image = tex, wield_image = tex, paramtype = "light", paramtype2 = "wallmounted",
    sunlight_propagates = true, walkable = false, diggable = false,
    groups = {not_in_creative_inventory = 1}, selection_box = {type = "wallmounted"},
    on_rightclick = function(pos, node, clicker)
      local m = mt.get_meta(pos)
      show(clicker, m:get_string("title"), m:get_string("info"))
    end})
end
for _, id in ipairs({"sign_1309", "sign_1316", "sign_1317", "sign_1327", "sign_ta131", "sign_ta132",
                     "sign_ta133", "sign_ta51", "sign_ex11", "poi1", "poi2", "poi3", "poi4"}) do panel(id) end

-- Footprints in plan blocks (walls on the boundary lines; shared walls overlap).
local H = 5                                  -- 4 m clear height
local ROOMS = {
  R1327 = {x1 = 0,  x2 = 12, z1 = 0,  z2 = 8},
  R1316 = {x1 = 18, x2 = 31, z1 = 12, z2 = 21},
  R1317 = {x1 = 18, x2 = 31, z1 = 25, z2 = 33},
  R1309 = {x1 = 35, x2 = 42, z1 = 24, z2 = 33},
}
local CORRIDORS = {
  TA133 = {x1 = 12, x2 = 16, z1 = 4,  z2 = 25},   -- west corridor
  TA132 = {x1 = 12, x2 = 31, z1 = 21, z2 = 25},   -- south cross corridor
  TA131 = {x1 = 31, x2 = 35, z1 = -3, z2 = 33},   -- central north-south corridor
  TA130 = {x1 = 31, x2 = 46, z1 = -3, z2 = 1},    -- north link (simplified, stair/elevator lobby)
  TA51  = {x1 = 42, x2 = 46, z1 = -3, z2 = 24},   -- east corridor down to TA.50 / EX.11
}
local BOUNDS = {x1 = -4, x2 = 50, z1 = -7, z2 = 38}

local function build(origin)
  local function wpos(x, y, z) return {x = origin.x + x, y = origin.y + y, z = origin.z - z} end
  local a, b = wpos(BOUNDS.x1, -1, BOUNDS.z2), wpos(BOUNDS.x2, H + 2, BOUNDS.z1)
  local vm = mt.get_voxel_manip()
  local emin, emax = vm:read_from_map(a, b)
  local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
  local data = vm:get_data()
  local C = {air = mt.get_content_id("air")}
  for _, id in ipairs({"floor", "wall", "facade", "roof", "paving", "frame", "column", "board",
                       "table", "chair", "lamp", "glass"}) do C[id] = mt.get_content_id(MOD .. ":" .. id) end
  local function put(x, y, z, id) local p = wpos(x, y, z); data[area:index(p.x, p.y, p.z)] = C[id] end
  local function fill(x1, y1, z1, x2, y2, z2, id)
    for z = math.min(z1, z2), math.max(z1, z2) do for y = y1, y2 do for x = math.min(x1, x2), math.max(x1, x2) do
      put(x, y, z, id) end end end
  end
  local function shell(r)
    fill(r.x1, 0, r.z1, r.x2, 0, r.z2, "floor")
    fill(r.x1, H, r.z1, r.x2, H, r.z2, "roof")
    for y = 1, H - 1 do
      fill(r.x1, y, r.z1, r.x2, y, r.z1, "wall"); fill(r.x1, y, r.z2, r.x2, y, r.z2, "wall")
      fill(r.x1, y, r.z1, r.x1, y, r.z2, "wall"); fill(r.x2, y, r.z1, r.x2, y, r.z2, "wall")
    end
  end
  local function carve(r) fill(r.x1 + 1, 1, r.z1 + 1, r.x2 - 1, H - 1, r.z2 - 1, "air") end

  fill(BOUNDS.x1, 0, BOUNDS.z1, BOUNDS.x2, H + 2, BOUNDS.z2, "air")
  for _, r in pairs(ROOMS) do shell(r) end
  for _, r in pairs(CORRIDORS) do shell(r) end
  for _, r in pairs(ROOMS) do carve(r) end
  for _, r in pairs(CORRIDORS) do carve(r) end      -- removes walls where corridors overlap
  fill(31, 1, 22, 31, 3, 24, "air")                 -- TA.132 -> TA.131 junction

  -- Room 1316 is L-shaped: the north-east corner (washrooms 1304/1305) is solid.
  fill(24, 1, 12, 31, H - 1, 15, "wall")

  -- Exterior walls: brick facade with windows.
  local function facade_x(x, z1, z2)
    fill(x, 1, z1, x, H - 1, z2, "facade")
    for z = z1 + 1, z2 - 1 do if (z - z1) % 3 ~= 0 then fill(x, 2, z, x, 3, z, "glass") end end
  end
  local function facade_z(z, x1, x2)
    fill(x1, 1, z, x2, H - 1, z, "facade")
    for x = x1 + 1, x2 - 1 do if (x - x1) % 3 ~= 0 then fill(x, 2, z, x, 3, z, "glass") end end
  end
  facade_x(0, 0, 8);   facade_z(0, 0, 12)          -- 1327 west + north
  facade_z(33, 18, 31)                             -- 1317 south
  facade_z(33, 35, 42)                             -- 1309 south
  facade_x(46, -3, 24)                             -- TA.51 east glazing

  -- Room 1316 column (plan shows one structural column).
  fill(23, 1, 16, 23, H - 1, 16, "column")

  -- Generic furniture (room functions are not on the plan - adjust when confirmed).
  fill(2, 2, 1, 10, 3, 1, "board")                                   -- 1327 board on north wall
  for _, z in ipairs({3, 5}) do for _, x in ipairs({2, 6}) do fill(x, 1, z, x + 2, 1, z, "table"); put(x + 1, 1, z + 1, "chair") end end
  fill(19, 2, 13, 22, 3, 13, "board")                                -- 1316 board
  for _, z in ipairs({16, 18}) do fill(19, 1, z, 21, 1, z, "table"); put(20, 1, z + 1, "chair")
                                  fill(25, 1, z, 29, 1, z, "table"); put(27, 1, z + 1, "chair") end
  fill(20, 2, 32, 29, 3, 32, "board")                                -- 1317 board on south wall
  for _, z in ipairs({27, 29}) do for x = 20, 28, 4 do fill(x, 1, z, x + 2, 1, z, "table"); put(x + 1, 1, z - 1, "chair") end end
  for _, z in ipairs({27, 30}) do fill(37, 1, z, 40, 1, z, "table"); put(38, 1, z + 1, "chair") end   -- 1309

  -- Lights every 4 blocks.
  for _, r in pairs(ROOMS) do
    for x = r.x1 + 2, r.x2 - 2, 4 do for z = r.z1 + 2, r.z2 - 2, 4 do put(x, H - 1, z, "lamp") end end
  end
  for _, r in pairs(CORRIDORS) do
    for x = r.x1 + 2, r.x2 - 2, 4 do for z = r.z1 + 2, r.z2 - 2, 4 do put(x, H - 1, z, "lamp") end end
  end
  fill(43, 0, 25, 47, 0, 28, "paving")                               -- outside EX.11
  fill(42, 1, 24, 46, H - 1, 24, "facade")                           -- EX.11 facade (TA.50)
  facade_x(42, 24, 33)                                               -- 1309 east

  -- Door openings (2 wide, 3 high) with a frame above.
  local function opening_x(x, z) fill(x, 1, z, x, 3, z + 1, "air"); fill(x, 4, z, x, 4, z + 1, "frame") end
  local function opening_z(x, z) fill(x, 1, z, x + 1, 3, z, "air"); fill(x, 4, z, x + 1, 4, z, "frame") end
  opening_x(12, 5)     -- 1327.1 from TA.133
  opening_z(20, 21)    -- 1316.1 from TA.132
  opening_z(20, 25)    -- 1317.1 from TA.132
  opening_x(35, 25)    -- 1309.1 from TA.131
  opening_z(43, 24)    -- EX.11 exterior doors
  vm:set_data(data); vm:write_to_map(); vm:update_map()

  local function door(x, z, p2)
    for _, y in ipairs({1, 2}) do mt.swap_node(wpos(x, y, z), {name = MOD .. ":door", param2 = p2}) end
  end
  door(12, 5, 1); door(12, 6, 1); door(35, 25, 1); door(35, 26, 1)
  door(20, 21, 0); door(21, 21, 0); door(20, 25, 0); door(21, 25, 0); door(43, 24, 0); door(44, 24, 0)

  -- wallmounted param2: 2 = wall on +X, 3 = wall on -X, 4 = wall on plan-north, 5 = wall on plan-south
  local function sign(x, y, z, id, title, info, p2)
    local p = wpos(x, y, z)
    mt.set_node(p, {name = MOD .. ":" .. id, param2 = p2})
    local m = mt.get_meta(p)
    m:set_string("title", title); m:set_string("info", info)
    m:set_string("infotext", title .. " (right-click)")
  end
  local I = ROOM_INFO
  sign(13, 3, 8,  "sign_1327", I["1327"].title, I["1327"].info, 3)
  sign(23, 3, 22, "sign_1316", I["1316"].title, I["1316"].info, 4)
  sign(23, 3, 24, "sign_1317", I["1317"].title, I["1317"].info, 5)
  sign(34, 3, 28, "sign_1309", I["1309"].title, I["1309"].info, 2)
  sign(13, 3, 14, "sign_ta133", "TA.133 - Corridor", "West corridor serving Rooms 1320-1327.", 3)
  sign(17, 3, 22, "sign_ta132", "TA.132 - Corridor", "Links TA.133 and TA.131; Rooms 1316 and 1317 open off it.", 4)
  sign(32, 3, 8,  "sign_ta131", "TA.131 - Corridor", "Central corridor; Room 1309 is at its south end.", 3)
  sign(43, 3, 18, "sign_ta51", "TA.51 / TA.50 - East corridor", "Runs from the EX.11 entrance north to the stair and elevator lobby.", 3)
  sign(45, 3, 25, "sign_ex11", "EX.11 - CMLP entrance", "Exterior entrance to the Claudette MacKay-Lassonde Pavilion ground floor.", 4)
  sign(11, 2, 3,  "poi1", "POI 1: " .. I["1327"].title, I["1327"].info, 2)
  sign(26, 2, 20, "poi2", "POI 2: " .. I["1316"].title, I["1316"].info, 5)
  sign(25, 2, 26, "poi3", "POI 3: " .. I["1317"].title, I["1317"].info, 4)
  sign(36, 2, 29, "poi4", "POI 4: " .. I["1309"].title, I["1309"].info, 3)
end

local function entrance(origin) return {x = origin.x + 45, y = origin.y + 1, z = origin.z - 27} end
local busy = false
mt.register_chatcommand("cmlp_build", {
  description = "Generate the CMLP ground-floor rooms 1309, 1316, 1317 and 1327 (clears the area).",
  privs = {interact = true},
  func = function(name)
    if not (mt.is_singleplayer() or mt.check_player_privs(name, {server = true})) then
      return false, "Only available in singleplayer or to administrators." end
    if busy then return false, "CMLP build already running." end
    if store:get_string("origin") ~= "" then return false, "Already built in this world. Use /cmlp_go." end
    local player = mt.get_player_by_name(name)
    if not player then return false, "Player unavailable." end
    local p = vector.round(player:get_pos())
    local origin = {x = p.x - 45, y = p.y - 1, z = p.z + 27}
    busy = true
    mt.emerge_area({x = origin.x + BOUNDS.x1, y = origin.y - 1, z = origin.z - BOUNDS.z2},
                   {x = origin.x + BOUNDS.x2, y = origin.y + H + 2, z = origin.z - BOUNDS.z1},
      function(_, _, remaining)
        if remaining ~= 0 then return end
        local ok, err = pcall(build, origin)
        busy = false
        if not ok then
          mt.log("error", "[" .. MOD .. "] " .. tostring(err))
          mt.chat_send_player(name, "Build failed: " .. tostring(err)); return
        end
        store:set_string("origin", mt.pos_to_string(origin))
        local pl = mt.get_player_by_name(name)
        if pl then pl:set_pos(entrance(origin)) end
        mt.chat_send_player(name, "CMLP ground floor generated. Enter through EX.11; four POIs are interactive.")
      end)
    return true, "Generating CMLP rooms 1309, 1316, 1317, 1327..."
  end})
mt.register_chatcommand("cmlp_go", {
  description = "Teleport to the CMLP EX.11 entrance.",
  func = function(name)
    local origin = mt.string_to_pos(store:get_string("origin"))
    if not origin then return false, "Run /cmlp_build first." end
    local pl = mt.get_player_by_name(name)
    if not pl then return false, "Player unavailable." end
    pl:set_pos(entrance(origin)); return true, "At EX.11."
  end})
mt.register_chatcommand("cmlp_info", {
  description = "List the modelled CMLP spaces.",
  func = function()
    return true, "Ground floor (/cmlp_go): EX.11, TA.50/51, TA.130-133, Rooms 1309, 1316, 1317, 1327 (POIs 1-4). Lower level (/cmlp_lower_go): EX.13, ST.25, TA.54, Room 63 atrium, 67, 67A, 55 (POIs 5-8)."
  end})

----------------------------------------------------------------------------------------------
-- LOWER LEVEL (SEB.pdf sheet 01): Room 63 (atrium), Room 67, Room 67A (connects 67 to 63),
-- Room 55, corridor TA.54, stair lobby ST.25 and exterior entrance EX.13.
-- Same scale (1 block = 1 m, ~25 px/m at 150 dpi). Plan origin = north-west corner of Room 67.
-- ASSUMPTIONS: Room 63 is given double height (9 m) with a skylight because it is used as an
-- atrium; the plan does not show ceiling heights. ST.25 stairs are shown as a flat lobby.
-- Rooms 63A (inside 63) is shown as an enclosed box; 63B-63E, 54, 66 are not modelled.
----------------------------------------------------------------------------------------------
do
  local LOWER_INFO = {
    ["63"]  = {title = "Room 63 - Atrium", info = "CMLP lower level. Large open space (about 11 m x 20 m) with overhead doors to Room 67A, Room 63E and corridor TA.55. Room 63A is enclosed in its north-east corner. Height shown is assumed."},
    ["67"]  = {title = "Room 67", info = "CMLP lower level. Small room beside the EX.14 loading-dock vestibule; opens south into Room 67A. Room function: to be confirmed."},
    ["67A"] = {title = "Room 67A", info = "CMLP lower level. Large room with an overhead door to the loading dock (west) and an overhead door into the Room 63 atrium (east). Room function: to be confirmed."},
    ["55"]  = {title = "Room 55", info = "CMLP lower level. Small room at the west end of corridor TA.54, south of Room 63. Room function: to be confirmed."},
  }
  reg("ohdoor", "CMLP overhead door", "ohdoor")
  for _, id in ipairs({"sign_63", "sign_67", "sign_67a", "sign_55", "sign_ta54", "sign_ex13",
                       "poi5", "poi6", "poi7", "poi8"}) do panel(id) end

  local HL, HA = 5, 9
  local LR = {
    R67  = {x1 = 0,  x2 = 6,  z1 = 0,  z2 = 3,  h = HL},
    R67A = {x1 = 0,  x2 = 12, z1 = 3,  z2 = 12, h = HL},
    R63  = {x1 = 12, x2 = 23, z1 = 0,  z2 = 21, h = HA},
    R55  = {x1 = 8,  x2 = 12, z1 = 21, z2 = 25, h = HL},
    TA54 = {x1 = 12, x2 = 23, z1 = 21, z2 = 25, h = HL},
    ST25 = {x1 = 15, x2 = 19, z1 = 25, z2 = 34, h = HL},
  }
  local LB = {x1 = -4, x2 = 27, z1 = -4, z2 = 39}

  local function build_lower(origin)
    local function wpos(x, y, z) return {x = origin.x + x, y = origin.y + y, z = origin.z - z} end
    local vm = mt.get_voxel_manip()
    local emin, emax = vm:read_from_map(wpos(LB.x1, -1, LB.z2), wpos(LB.x2, HA + 2, LB.z1))
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    local data = vm:get_data()
    local C = {air = mt.get_content_id("air")}
    for _, id in ipairs({"floor", "wall", "facade", "roof", "paving", "frame", "board", "table",
                         "chair", "lamp", "glass", "ohdoor"}) do C[id] = mt.get_content_id(MOD .. ":" .. id) end
    local function put(x, y, z, id) local p = wpos(x, y, z); data[area:index(p.x, p.y, p.z)] = C[id] end
    local function fill(x1, y1, z1, x2, y2, z2, id)
      for z = math.min(z1, z2), math.max(z1, z2) do for y = y1, y2 do for x = math.min(x1, x2), math.max(x1, x2) do
        put(x, y, z, id) end end end
    end
    local function shell(r)
      fill(r.x1, 0, r.z1, r.x2, 0, r.z2, "floor"); fill(r.x1, r.h, r.z1, r.x2, r.h, r.z2, "roof")
      for y = 1, r.h - 1 do
        fill(r.x1, y, r.z1, r.x2, y, r.z1, "wall"); fill(r.x1, y, r.z2, r.x2, y, r.z2, "wall")
        fill(r.x1, y, r.z1, r.x1, y, r.z2, "wall"); fill(r.x2, y, r.z1, r.x2, y, r.z2, "wall")
      end
    end
    local function carve(r) fill(r.x1 + 1, 1, r.z1 + 1, r.x2 - 1, r.h - 1, r.z2 - 1, "air") end

    fill(LB.x1, 0, LB.z1, LB.x2, HA + 2, LB.z2, "air")
    for _, k in ipairs({"R67", "R67A", "R55", "TA54", "ST25", "R63"}) do shell(LR[k]) end
    for _, k in ipairs({"R67", "R67A", "R55", "TA54", "ST25", "R63"}) do carve(LR[k]) end
    -- TA.54 / 63 / 55 share walls at heights 1-4; the atrium's taller walls stay above them.

    -- Atrium skylight (assumed) and lights.
    for x = 15, 20 do for z = 4, 17 do if (x + z) % 3 ~= 0 then put(x, HA, z, "glass") end end end
    -- Room 63A: enclosed box in the atrium's north-east corner (not part of this request).
    local A = {x1 = 19, x2 = 23, z1 = 0, z2 = 9, h = HL}
    shell(A); fill(A.x1 + 1, 1, A.z1 + 1, A.x2 - 1, A.h - 1, A.z2 - 1, "wall")
    fill(19, 0, 0, 23, 0, 9, "floor")

    -- Exterior: loading-dock wall of 67 / 67A with overhead door 67A.2 (closed).
    fill(0, 1, 0, 0, HL - 1, 12, "facade"); fill(0, 1, 4, 0, 4, 6, "ohdoor")
    -- Overhead doors 63.2 / 63.3 to TA.55 on the atrium's north wall (closed panels).
    fill(14, 1, 0, 15, 4, 0, "ohdoor"); fill(17, 1, 0, 18, 4, 0, "ohdoor")
    -- ST.25 / EX.13 south facade with glazing.
    fill(15, 1, 34, 19, HL - 1, 34, "facade"); fill(18, 2, 34, 18, 3, 34, "glass")
    fill(13, 0, 35, 21, 0, 38, "paving")

    -- Openings.
    fill(4, 1, 3, 5, 3, 3, "air"); fill(4, 4, 3, 5, 4, 3, "frame")          -- 67.2: 67 -> 67A
    fill(12, 1, 4, 12, 3, 6, "air"); fill(12, 4, 4, 12, 4, 6, "ohdoor")     -- 67A.1 overhead door (open)
    fill(13, 1, 21, 14, 3, 21, "air"); fill(13, 4, 21, 14, 4, 21, "frame")  -- TA.54.1: 63 -> TA.54
    fill(12, 1, 23, 12, 3, 24, "air"); fill(12, 4, 23, 12, 4, 24, "frame")  -- 55.2: TA.54 -> 55
    fill(16, 1, 25, 18, 3, 25, "air")                                       -- TA.54 -> ST.25 lobby
    fill(16, 1, 34, 17, 3, 34, "air"); fill(16, 4, 34, 17, 4, 34, "frame")  -- EX.13

    -- Generic furniture (functions not on plan).
    fill(2, 1, 1, 3, 1, 1, "table")                                         -- 67
    for _, z in ipairs({6, 9}) do fill(3, 1, z, 8, 1, z, "table"); put(5, 1, z + 1, "chair") end   -- 67A
    for _, c in ipairs({{14, 10}, {14, 15}, {18, 12}, {18, 16}}) do                                -- 63 seating
      fill(c[1], 1, c[2], c[1] + 2, 1, c[2], "table"); put(c[1] + 1, 1, c[2] + 1, "chair"); put(c[1] + 1, 1, c[2] - 1, "chair")
    end
    fill(9, 1, 22, 10, 1, 22, "table"); put(10, 1, 23, "chair")             -- 55

    for _, k in ipairs({"R67", "R67A", "R55", "TA54", "ST25"}) do
      local r = LR[k]
      for x = r.x1 + 2, r.x2 - 2, 4 do for z = r.z1 + 1, r.z2 - 1, 4 do put(x, r.h - 1, z, "lamp") end end
    end
    for x = 13, 22, 3 do put(x, HA - 1, 1, "lamp"); put(x, HA - 1, 20, "lamp") end
    for z = 2, 19, 3 do put(13, HA - 1, z, "lamp"); put(22, HA - 1, z, "lamp") end
    vm:set_data(data); vm:write_to_map(); vm:update_map()

    local function door(x, z, p2)
      for _, y in ipairs({1, 2}) do mt.swap_node(wpos(x, y, z), {name = MOD .. ":door", param2 = p2}) end
    end
    door(4, 3, 0); door(5, 3, 0); door(13, 21, 0); door(14, 21, 0)
    door(12, 23, 1); door(12, 24, 1); door(16, 34, 0); door(17, 34, 0)

    local function sign(x, y, z, id, title, info, p2)
      local p = wpos(x, y, z)
      mt.set_node(p, {name = MOD .. ":" .. id, param2 = p2})
      local m = mt.get_meta(p)
      m:set_string("title", title); m:set_string("info", info); m:set_string("infotext", title .. " (right-click)")
    end
    local I = LOWER_INFO
    sign(2, 3, 4,   "sign_67",   I["67"].title,  I["67"].info, 4)
    sign(13, 3, 8,  "sign_67a",  I["67A"].title, I["67A"].info, 3)
    sign(16, 3, 22, "sign_63",   I["63"].title,  I["63"].info, 4)
    sign(13, 3, 22, "sign_55",   I["55"].title,  I["55"].info, 3)
    sign(20, 3, 24, "sign_ta54", "TA.54 - Corridor", "Lower-level corridor linking the atrium (63), Room 55 and stair ST.25 / EX.13.", 5)
    sign(15, 3, 35, "sign_ex13", "EX.13 - CMLP lower-level entrance", "Exterior entrance through stair lobby ST.25.", 4)
    sign(13, 2, 15, "poi5", "POI 5: " .. I["63"].title,  I["63"].info, 3)
    sign(1, 2, 1,   "poi6", "POI 6: " .. I["67"].title,  I["67"].info, 3)
    sign(6, 2, 11,  "poi7", "POI 7: " .. I["67A"].title, I["67A"].info, 5)
    sign(9, 2, 24,  "poi8", "POI 8: " .. I["55"].title,  I["55"].info, 5)
  end

  local function lower_entrance(o) return {x = o.x + 17, y = o.y + 1, z = o.z - 37} end
  local busy_lower = false
  mt.register_chatcommand("cmlp_lower_build", {
    description = "Generate the CMLP lower level: Room 63 atrium, 67, 67A, 55 (clears the area).",
    privs = {interact = true},
    func = function(name)
      if not (mt.is_singleplayer() or mt.check_player_privs(name, {server = true})) then
        return false, "Only available in singleplayer or to administrators." end
      if busy_lower then return false, "Lower-level build already running." end
      if store:get_string("origin_lower") ~= "" then return false, "Already built. Use /cmlp_lower_go." end
      local player = mt.get_player_by_name(name)
      if not player then return false, "Player unavailable." end
      local p = vector.round(player:get_pos())
      local o = {x = p.x - 17, y = p.y - 1, z = p.z + 37}
      busy_lower = true
      mt.emerge_area({x = o.x + LB.x1, y = o.y - 1, z = o.z - LB.z2}, {x = o.x + LB.x2, y = o.y + HA + 2, z = o.z - LB.z1},
        function(_, _, remaining)
          if remaining ~= 0 then return end
          local ok, err = pcall(build_lower, o)
          busy_lower = false
          if not ok then
            mt.log("error", "[" .. MOD .. "] " .. tostring(err))
            mt.chat_send_player(name, "Build failed: " .. tostring(err)); return
          end
          store:set_string("origin_lower", mt.pos_to_string(o))
          local pl = mt.get_player_by_name(name)
          if pl then pl:set_pos(lower_entrance(o)) end
          mt.chat_send_player(name, "CMLP lower level generated. Enter through EX.13; POIs 5-8 are interactive.")
        end)
      return true, "Generating the CMLP lower level..."
    end})
  mt.register_chatcommand("cmlp_lower_go", {
    description = "Teleport to the CMLP lower-level entrance EX.13.",
    func = function(name)
      local o = mt.string_to_pos(store:get_string("origin_lower"))
      if not o then return false, "Run /cmlp_lower_build first." end
      local pl = mt.get_player_by_name(name)
      if not pl then return false, "Player unavailable." end
      pl:set_pos(lower_entrance(o)); return true, "At EX.13."
    end})
end
