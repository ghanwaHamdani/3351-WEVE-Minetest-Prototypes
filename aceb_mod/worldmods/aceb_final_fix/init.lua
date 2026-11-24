local mt = minetest
local MOD = mt.get_current_modname()
local store = mt.get_mod_storage()
local function v(x,y,z) return {x=x,y=y,z=z} end
local function plus(o,x,y,z) return v(o.x+x,o.y+y,o.z+z) end

local function register(id,desc,texture,options)
  local def={description=desc,tiles={texture},groups={cracky=2,oddly_breakable_by_hand=2},is_ground_content=false}
  for k,val in pairs(options or {}) do def[k]=val end
  mt.register_node(MOD..':'..id,def)
end
register('floor','ACEB floor','aceb_tile.png')
register('wall','ACEB wall','aceb_wall.png')
register('facade','ACEB facade','aceb_facade.png')
register('frame','ACEB frame','aceb_metal.png')
register('glass','ACEB glass','aceb_glass.png',{
  drawtype='glasslike',paramtype='light',sunlight_propagates=true,use_texture_alpha='blend',
  groups={cracky=3,oddly_breakable_by_hand=3}
})
register('roof','ACEB roof','aceb_roof.png')
register('path','ACEB path','aceb_paving.png')
register('lamp','ACEB LED','aceb_light.png',{light_source=14,paramtype='light'})
register('desk','ACEB desk','aceb_wood.png')
register('bench','ACEB bench','aceb_bench.png')
register('chair','ACEB chair','aceb_seat.png')
register('worktop','ACEB worktop','aceb_worktop.png')
register('computer','ACEB computer','aceb_computer.png',{light_source=3})
register('board','ACEB board','aceb_board.png')
register('plant','ACEB plant','aceb_plant.png')
register('rail','ACEB rail','aceb_metal.png')
register('stair','ACEB stair','aceb_stair.png')
register('door','ACEB glass door','aceb_glass.png',{
  drawtype='nodebox',paramtype='light',paramtype2='facedir',sunlight_propagates=true,use_texture_alpha='blend',walkable=false,
  node_box={type='fixed',fixed={-0.45,-0.5,0.42,0.45,0.5,0.5}},
  selection_box={type='fixed',fixed={-0.5,-0.5,0.35,0.5,0.5,0.5}},
  groups={cracky=3,oddly_breakable_by_hand=3}
})

-- WEVE POI/sign text standard (shared by ACEB, TEB and SEB; see docs/POI_STANDARD.md).
--   Wall sign title: "<Space ID> — <Space type>"
--   POI title:       "POI <n> — <Space ID> — <Space type>"
--   Description:     1-2 sentences: what/where the space is, then what is in it.
-- All sign text lives in this table, so editing it updates every sign, including
-- signs in worlds that were built before the change (see the LBM below).
local BUILDING='ACEB — Amit Chakma Engineering Building'
local SIGN_TEXT={
  label_entrance={'TA.140 / EX.23 — Main Entrance',
    'Main entrance vestibule of the ACEB first floor, with double glass doors. Staircase ST.B is directly ahead as you enter.'},
  label_stairs={'ST.B — Staircase',
    'Staircase located directly ahead of the main entrance TA.140 / EX.23.'},
  label_corridor={'TA.141 — Corridor and Study Space',
    'Main first-floor corridor connecting the entrance to Rooms 1400, 1420 and 1440. Windows line the corridor, with a long bench and study tables.'},
  label_1400={'Room 1400 — Computer Lab',
    'Computer lab off corridor TA.141. A whiteboard faces a centre aisle, with tables and chairs on both sides.'},
  label_1420={'Room 1420 — Classroom',
    'Classroom off corridor TA.141. Rows of long tables face the whiteboard.'},
  label_1440={'Room 1440 — Workshop',
    'Workshop and design-project space off corridor TA.141. Metal benches serve as workstations.'},
  label_atrium={'TA.144 — Atrium / Common Space',
    'Large open atrium on the north side of the raised landing at the end of corridor TA.141. The exit is opposite, on the south side.'},
  poi1={'POI 1 — Room 1400 — Computer Lab',
    'Purpose: Computer-based learning and practical work space.\n'..
    'Student Activities: Students can complete assignments and practice programming.'},
  poi2={'POI 2 — Room 1420 — Classroom',
    'Purpose: Teaching environment for lectures and presentations.\n'..
    'Student Activities: Students can attend lectures and engage in discussions.'},
  poi3={'POI 3 — Room 1440 — Workshop',
    'Purpose: A hands-on workspace for engineering design, development, and project activities.\n'..
    'Student Activities: Students can collaborate on engineering projects.'},
  poi4={'POI 4 — TA.141 — Study Spaces',
    'Purpose: Informal study spaces for individual or collaborative learning.\n'..
    'Student Activities: Students can study, complete coursework, or work on group projects.'},
  poi5={'POI 5 — TA.144 — Atrium',
    'Purpose: Common area, often used for club meetings.\n'..
    'Student Activities: Students can socialize, relax between classes, and participate in informal discussions.'},
}

-- Hand-placed wooden signs in the saved world (placed in Sprint 1). Each rule
-- matches the original text and rewrites it to the standard; text that already
-- matches the standard is left alone, so this is safe to run on every load.
local WOOD_SIGNS={
  {'^Room 1400','poi1'}, {'^Room 1420','poi2'}, {'^Room 1440','poi3'},
  {'^TA%.141','poi4'}, {'^TA%.144','poi5'},
  {'^EX%.23','EX.23 — Entrance'},
  {'^ST%.B','ST.B — Stairs to Floor 2'},
  {'^Path to SEB','Path to SEB — Spencer Engineering Building'},
  {'^ACEB Digital Twin',BUILDING..' (Digital Twin)'},
}

-- Where /poi places the player (origin-relative), and the POI sign it should face.
local POI_STAND={
  {stand=v(18,1,-10), sign=v(12,2,-6)},
  {stand=v(53,1,-10), sign=v(47,2,-6)},
  {stand=v(84,1,-10), sign=v(78,2,-6)},
  {stand=v(42,1,6),   sign=v(42,2,11)},
  {stand=v(120,5,-14),sign=v(116,5,-8)},
}

-- Standard read-only information popup, shared by the custom signs and the
-- wooden signs so every sign looks the same when right-clicked.
local function info_formspec(title,body)
  return 'formspec_version[4]size[10,5.2]'..
    'label[0.5,0.45;'..mt.formspec_escape(BUILDING)..']'..
    'style_type[label;font=bold]'..
    'label[0.5,0.95;'..mt.formspec_escape(title)..']'..
    'textarea[0.5,1.4;9,2.8;;;'..mt.formspec_escape(body or '')..']'..
    'button_exit[4,4.4;2,0.6;close;Close]'
end

local function show_info(player,key)
  local text=SIGN_TEXT[key]
  if not text or not player or not player:is_player() then return end
  mt.show_formspec(player:get_player_name(), MOD..':poi_info', info_formspec(text[1],text[2]))
end

local function key_of(nodename) return nodename:sub(#MOD+2) end

local function apply_text(pos,key)
  local text=SIGN_TEXT[key]
  if not text then return end
  local meta=mt.get_meta(pos)
  meta:set_string('infotext',text[1]..'\n(right-click for details)')
  meta:set_string('formspec','')
end

local SIGN_NODES={}
local function register_panel(id,desc,texture)
  SIGN_NODES[#SIGN_NODES+1]=MOD..':'..id
  mt.register_node(MOD..':'..id,{
    description=desc,
    drawtype='signlike',
    tiles={texture}, inventory_image=texture, wield_image=texture,
    sunlight_propagates=true, paramtype='light', paramtype2='wallmounted',
    walkable=false, groups={choppy=2,dig_immediate=2},
    selection_box={type='wallmounted'},
    on_rightclick=function(pos,node,player)
      show_info(player,key_of(node.name))
    end
  })
end
for _,id in ipairs({'entrance','stairs','corridor','1400','1420','1440','atrium'}) do
  register_panel('label_'..id, 'ACEB wall sign', 'aceb_label_'..id..'.png')
end
for n=1,5 do register_panel('poi'..n, 'ACEB POI '..n, 'aceb_poi'..n..'.png') end
-- Legacy single POI node from worlds built before the standard; converted by the LBM.
register_panel('poi','ACEB POI (legacy)','aceb_poi.png')

mt.register_lbm({
  label='Apply WEVE POI/sign text standard',
  name=MOD..':apply_sign_standard',
  nodenames=SIGN_NODES,
  run_at_every_load=true,
  action=function(pos,node)
    local key=key_of(node.name)
    if key=='poi' then
      local n=tonumber(mt.get_meta(pos):get_string('title'):match('POI (%d)'))
      if not n then return end
      key='poi'..n
      mt.swap_node(pos,{name=MOD..':'..key,param2=node.param2})
    end
    apply_text(pos,key)
  end
})

-- Wooden signs: the hover text shows only the title, because Luanti cuts off
-- long hover text; right-click opens the read-only popup with the full text.
local function wood_parts(target)
  local t=SIGN_TEXT[target]
  if t then return t[1],t[2] end
  return target,nil
end
local function wood_text(target)
  local title,body=wood_parts(target)
  return body and (title..'\n'..body) or title
end
local WOOD_STANDARD={}
for _,rule in ipairs(WOOD_SIGNS) do WOOD_STANDARD[wood_text(rule[2])]=rule[2] end
mt.register_lbm({
  label='Apply WEVE POI/sign text standard to wooden signs',
  name=MOD..':apply_wood_sign_standard',
  nodenames={'default:sign_wall_wood'},
  run_at_every_load=true,
  action=function(pos)
    local meta=mt.get_meta(pos)
    local old=meta:get_string('text')
    local target=WOOD_STANDARD[old]
    if not target then
      for _,rule in ipairs(WOOD_SIGNS) do
        if old:find(rule[1]) then target=rule[2]; break end
      end
    end
    if not target then return end
    local title,body=wood_parts(target)
    meta:set_string('text',wood_text(target))
    meta:set_string('infotext',body and (title..'\n(right-click for details)') or title)
    -- Read-only popup: it has no "text" field, so visitors cannot overwrite the sign.
    meta:set_string('formspec',info_formspec(title,body))
  end
})

local AREA={
  entrance={x1=-12,x2=0,z1=0,z2=12,by=0,h=7},
  corridor={x1=0,x2=104,z1=0,z2=12,by=0,h=13},
  room1400={x1=8,x2=28,z1=-30,z2=0,by=0,h=7},
  room1420={x1=43,x2=63,z1=-30,z2=0,by=0,h=7},
  room1440={x1=74,x2=94,z1=-30,z2=0,by=0,h=7},
  landing={x1=104,x2=118,z1=0,z2=12,by=4,h=7},
  atrium={x1=104,x2=150,z1=-40,z2=0,by=4,h=9}
}

local function authorized(name)
  return mt.is_singleplayer() or mt.check_player_privs(name,{server=true})
end

local function build(origin)
  local low=plus(origin,-22,-2,-44)
  local high=plus(origin,156,18,58)
  local vm=mt.get_voxel_manip()
  local emin,emax=vm:read_from_map(low,high)
  local area=VoxelArea:new({MinEdge=emin,MaxEdge=emax})
  local data=vm:get_data()
  local ids={air=mt.get_content_id('air')}
  for _,id in ipairs({'floor','wall','facade','frame','glass','roof','path','lamp','desk','bench','chair','worktop','computer','board','plant','rail','stair','door'}) do ids[id]=mt.get_content_id(MOD..':'..id) end
  local function put(x,y,z,id)
    local p=plus(origin,x,y,z)
    data[area:index(p.x,p.y,p.z)] = ids[id]
  end
  local function fill(x1,y1,z1,x2,y2,z2,id)
    for z=z1,z2 do for y=y1,y2 do for x=x1,x2 do put(x,y,z,id) end end end
  end
  fill(-22,0,-44,156,18,58,'air')

  local function shell(r, exterior)
    local w=exterior and 'facade' or 'wall'
    fill(r.x1,r.by,r.z1,r.x2,r.by,r.z2,'floor')
    fill(r.x1,r.by+r.h,r.z1,r.x2,r.by+r.h,r.z2,'roof')
    for y=r.by+1,r.by+r.h-1 do
      fill(r.x1,y,r.z1,r.x2,y,r.z1,w)
      fill(r.x1,y,r.z2,r.x2,y,r.z2,w)
      fill(r.x1,y,r.z1,r.x1,y,r.z2,w)
      fill(r.x2,y,r.z1,r.x2,y,r.z2,w)
    end
  end
  for _,k in ipairs({'entrance','corridor','room1400','room1420','room1440','landing','atrium'}) do
    shell(AREA[k], k~='room1400' and k~='room1420' and k~='room1440')
  end

  -- Entrance to corridor
  fill(0,1,4,0,4,8,'air')
  fill(0,5,4,0,5,8,'frame')

  -- Main west entrance: double glass doors
  fill(-12,1,5,-12,4,7,'air')
  fill(-12,5,5,-12,5,7,'frame')
  fill(-18,0,4,-13,0,8,'path')

  -- Staircase directly ahead after entering (not left or right)
  for i=0,7 do
    fill(18+i,1+i,4,18+i,1+i,8,'stair')
  end
  fill(26,8,4,28,8,8,'stair')
  for y=2,9 do
    put(17,y,4,'rail'); put(17,y,8,'rail')
    put(27,y,4,'rail'); put(27,y,8,'rail')
  end
  for x=18,27 do put(x,9,3,'rail'); put(x,9,9,'rail') end
  fill(26,9,4,28,10,8,'rail')

  -- Swapped per feedback: glass wall on SOUTH side of the corridor, rooms NORTH.
  fill(34,1,12,98,5,12,'air')
  for x=34,98 do
    if x%8==0 then fill(x,1,12,x,5,12,'frame')
    else fill(x,2,12,x,5,12,'glass'); put(x,1,12,'frame') end
  end

  -- Room fronts now on the NORTH side, with the same simple two-door entrances.
  local function doorway(cx)
    fill(cx-1,1,0,cx,4,0,'air')
    fill(cx-1,5,0,cx,5,0,'frame')
  end
  doorway(18)
  doorway(53)
  doorway(84)

  -- Study spaces stay under the moved windows, now on the SOUTH side.
  fill(40,1,10,95,1,10,'bench')
  for x=42,90,10 do
    fill(x,1,7,x+2,1,8,'desk')
    put(x+1,1,6,'chair')
  end

  -- Room 1400 contents
  fill(13,2,-30,23,3,-30,'board')
  for _,z in ipairs({-6,-13,-20,-26}) do
    fill(10,1,z-1,13,1,z,'desk'); put(11,1,z-3,'chair')
    fill(22,1,z-1,25,1,z,'desk'); put(23,1,z-3,'chair')
  end

  -- Room 1420 contents
  fill(48,2,-30,58,3,-30,'board')
  for _,z in ipairs({-6,-13,-20,-26}) do
    fill(46,1,z,60,1,z,'desk')
    for x=47,59,3 do put(x,1,z-2,'chair') end
  end

  -- Room 1440 contents
  for _,c in ipairs({{77,-6},{85,-6},{77,-16},{85,-16},{77,-25},{85,-25},{89,-11},{89,-21}}) do
    fill(c[1],1,c[2]-1,c[1]+4,1,c[2],'worktop')
  end

  -- Room exterior glazing moved to the NORTH (far) wall.
  for _,r in ipairs({AREA.room1400,AREA.room1420,AREA.room1440}) do
    fill(r.x1+3,2,r.z1,r.x2-3,5,r.z1,'glass')
    for x=r.x1+3,r.x2-3,6 do fill(x,1,r.z1,x,5,r.z1,'frame') end
  end

  -- Flat incline ramp on the LEFT and 4-step stairs on the RIGHT
  for step=0,3 do
    local x1=96 + step*2
    local x2=x1+1
    fill(x1,1+step,0,x2,1+step,5,'floor')
  end
  fill(104,4,0,118,4,5,'floor')
  for step=1,4 do
    local x1=95 + step*2
    local x2=x1+1
    fill(x1,1,7,x2,step,12,'stair')
  end
  fill(104,4,7,118,4,12,'floor')

  -- Exit door moved to SOUTH side of the raised landing (opposite TA.144).
  fill(110,5,12,112,8,12,'air')
  fill(110,9,12,112,9,12,'frame')

  -- Keep the approach from the ramp and four stairs into the landing unobstructed.
  fill(104,5,1,104,9,11,'air')
  -- Atrium is now NORTH of the landing, opposite the exit on the south.
  -- Remove the north dividing wall; TA.144 remains doorless and open concept.
  fill(106,5,0,117,9,0,'air')
  fill(106,4,0,117,4,0,'floor')
  -- East glass wall and north exterior glass of relocated atrium.
  fill(150,6,-36,150,10,-4,'glass')
  fill(108,6,-40,146,10,-40,'glass')
  for z=-36,-4,7 do fill(150,5,z,150,10,z,'frame') end
  for x=108,146,8 do fill(x,5,-40,x,10,-40,'frame') end

  -- Lighting
  for x=-8,-2,4 do put(x,6,6,'lamp') end
  for x=6,96,10 do put(x,12,6,'lamp') end
  for _,r in ipairs({AREA.room1400,AREA.room1420,AREA.room1440}) do
    for x=r.x1+4,r.x2-3,8 do for z=r.z1+7,r.z2-4,10 do put(x,6,z,'lamp') end end
  end
  for x=108,146,12 do for z=-34,-6,12 do put(x,12,z,'lamp') end end

  -- Additional perimeter ceiling lights, spaced every 4 blocks.
  -- These supplement, rather than replace, the original ceiling fixtures.
  local function edge_lights(r)
    local ceiling_y = r.by+r.h-1
    for x=r.x1+2,r.x2-2,4 do
      put(x,ceiling_y,r.z1+2,'lamp')
      put(x,ceiling_y,r.z2-2,'lamp')
    end
    for z=r.z1+2,r.z2-2,4 do
      put(r.x1+2,ceiling_y,z,'lamp')
      put(r.x2-2,ceiling_y,z,'lamp')
    end
  end
  for _,r in ipairs({AREA.entrance,AREA.corridor,AREA.room1400,AREA.room1420,AREA.room1440,AREA.landing,AREA.atrium}) do
    edge_lights(r)
  end
  -- More illumination along the central staircase and ramp, while leaving walkways clear.
  for x=18,26,4 do put(x,12,2,'lamp') end

  vm:set_data(data)
  vm:write_to_map()
  vm:update_map()

  local function setnode(x,y,z,name,param2)
    mt.set_node(plus(origin,x,y,z), {name=name, param2=param2 or 0})
  end
  -- Place actual doors
  setnode(-12,1,5,MOD..':door',1); setnode(-12,1,7,MOD..':door',1)
  setnode(17,1,0,MOD..':door',0); setnode(18,1,0,MOD..':door',0)
  setnode(52,1,0,MOD..':door',0); setnode(53,1,0,MOD..':door',0)
  setnode(83,1,0,MOD..':door',0); setnode(84,1,0,MOD..':door',0)
  setnode(110,5,12,MOD..':door',2); setnode(111,5,12,MOD..':door',2)

  local function sign(x,y,z,id,param2)
    local pos=plus(origin,x,y,z)
    mt.set_node(pos,{name=MOD..':'..id,param2=param2 or 0})
    apply_text(pos,id)
  end

  -- Wall signs beside rooms / spaces (text: SIGN_TEXT at the top of this file)
  sign(-11,3,3,'label_entrance',2)
  sign(16,3,1,'label_stairs',5)
  sign(35,3,1,'label_corridor',5)
  sign(14,3,1,'label_1400',4)
  sign(49,3,1,'label_1420',4)
  sign(80,3,1,'label_1440',4)
  sign(120,7,-1,'label_atrium',5)

  -- Exactly 5 POIs
  sign(12,2,-6,'poi1',4)
  sign(47,2,-6,'poi2',4)
  sign(78,2,-6,'poi3',4)
  sign(42,2,11,'poi4',5)
  sign(116,5,-8,'poi5',5)
end

mt.register_chatcommand('poi',{
  params='<1-5>',
  description='Teleport to an ACEB POI and show its information.',
  func=function(name,param)
    local n=tonumber(param)
    if not n or n<1 or n>5 then return false,'Usage: /poi <1-5>' end
    local origin=mt.string_to_pos(store:get_string('origin'))
    if not origin then return false,'Run /aceb_build first.' end
    local player=mt.get_player_by_name(name)
    if not player then return false,'Player missing.' end
    local p=POI_STAND[n]
    player:set_pos(plus(origin,p.stand.x,p.stand.y,p.stand.z))
    player:set_look_horizontal(math.atan2(-(p.sign.x-p.stand.x), p.sign.z-p.stand.z))
    player:set_look_vertical(0)
    show_info(player,'poi'..n)
    return true,SIGN_TEXT['poi'..n][1]
  end
})

local creating=false
mt.register_chatcommand('aceb_build',{
  description='Construct the corrected ACEB first-floor model.',
  privs={interact=true},
  func=function(name)
    if not authorized(name) then return false,'Available only in singleplayer or to administrators.' end
    if creating then return false,'ACEB build is already loading.' end
    if store:get_string('origin') ~= '' then return false,'Already built. Use /aceb_go or make a NEW world for this corrected layout.' end
    local player=mt.get_player_by_name(name)
    if not player then return false,'Player is offline.' end
    local p=vector.round(player:get_pos())
    local origin=v(p.x+23,p.y-1,p.z-8)
    local low=plus(origin,-22,-2,-44)
    local high=plus(origin,156,18,58)
    creating=true
    mt.emerge_area(low,high,function(_,_,remaining)
      if remaining ~= 0 then return end
      local ok,err=pcall(build,origin)
      creating=false
      if not ok then
        mt.log('error','['..MOD..'] '..tostring(err))
        mt.chat_send_player(name,'Build failed; check debug.txt: '..tostring(err))
        return
      end
      store:set_string('origin', mt.pos_to_string(origin))
      local current=mt.get_player_by_name(name)
      if current then
        current:set_pos(plus(origin,-18,2,6))
        mt.chat_send_player(name,'ACEB generated. Corridor roof is level with TA.144; atrium and exit are on opposite sides of the raised landing.')
      end
    end)
    return true,'Loading the corrected ACEB first-floor build.'
  end
})
mt.register_chatcommand('aceb_go',{
  description='Return to the ACEB entrance',
  func=function(name)
    local origin=mt.string_to_pos(store:get_string('origin'))
    if not origin then return false,'Run /aceb_build first.' end
    local player=mt.get_player_by_name(name)
    if not player then return false,'Player missing.' end
    player:set_pos(plus(origin,-18,2,6))
    return true,'Teleported to TA.140 / EX.23.'
  end
})
mt.register_chatcommand('aceb_info',{
  description='List modeled spaces',
  func=function()
    return true,'Modeled: TA.140/EX.23 entrance, ST.B, TA.141 corridor + study, 1400, 1420, 1440, TA.144 atrium, exit door, ramp, 4-step stairs, and 5 POIs.'
  end
})
