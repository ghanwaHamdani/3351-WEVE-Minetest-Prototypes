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

local function show_info(player,title,info)
  if not player or not player:is_player() then return end
  mt.show_formspec(player:get_player_name(), MOD..':info',
    'formspec_version[4]size[10,5]'..
    'label[0.5,0.5;'..mt.formspec_escape(title)..']'..
    'textarea[0.5,1.1;9,3.0;text;;'..mt.formspec_escape(info)..']'..
    'button_exit[4,4.2;2,0.6;close;Close]')
end

local function register_panel(id,desc,texture)
  mt.register_node(MOD..':'..id,{
    description=desc,
    drawtype='signlike',
    tiles={texture}, inventory_image=texture, wield_image=texture,
    sunlight_propagates=true, paramtype='light', paramtype2='wallmounted',
    walkable=false, groups={choppy=2,dig_immediate=2},
    selection_box={type='wallmounted'},
    on_rightclick=function(pos,node,player)
      local meta=mt.get_meta(pos)
      show_info(player, meta:get_string('title'), meta:get_string('info'))
    end
  })
end
for _,id in ipairs({'entrance','stairs','corridor','1400','1420','1440','atrium'}) do
  register_panel('label_'..id, 'ACEB wall sign', 'aceb_label_'..id..'.png')
end
register_panel('poi','ACEB POI','aceb_poi.png')

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

  local function sign(x,y,z,id,title,info,param2)
    local pos=plus(origin,x,y,z)
    mt.set_node(pos,{name=MOD..':'..id,param2=param2 or 0})
    local meta=mt.get_meta(pos)
    meta:set_string('title',title)
    meta:set_string('info',info)
    meta:set_string('infotext',title..' (right-click)')
  end

  -- Wall signs beside rooms / spaces
  sign(-11,3,3,'label_entrance','TA.140 / EX.23 — ENTRANCE','Main entrance vestibule with double glass doors.',2)
  sign(16,3,1,'label_stairs','ST.B — STAIRCASE','Staircase located directly ahead as you enter.',5)
  sign(35,3,1,'label_corridor','TA.141 — CORRIDOR + STUDY','Main corridor with windows, a long bench, and study tables.',5)
  sign(14,3,1,'label_1400','ROOM 1400 — COMPUTER LAB','Computer lab with whiteboard, centre aisle, and tables with chairs on both sides.',4)
  sign(49,3,1,'label_1420','ROOM 1420 — CLASSROOM','Classroom with whiteboard and rows of long tables facing the board.',4)
  sign(80,3,1,'label_1440','ROOM 1440 — WORKSHOP','Workshop / design-project space with metal benches as workstations.',4)
  sign(120,7,-1,'label_atrium','TA.144 — ATRIUM / COMMON SPACE','Large empty atrium on the north side of the raised landing. The exit is opposite, on the south side.',5)

  -- Exactly 5 POIs
  sign(12,2,-6,'poi','POI 1 — ROOM 1400','Room 1400 computer lab.',4)
  sign(47,2,-6,'poi','POI 2 — ROOM 1420','Room 1420 classroom.',4)
  sign(78,2,-6,'poi','POI 3 — ROOM 1440','Room 1440 workshop.',4)
  sign(42,2,11,'poi','POI 4 — STUDY SPACES','Bench seating and study tables along the corridor windows.',5)
  sign(116,5,-8,'poi','POI 5 — TA.144 ATRIUM','Open common area / atrium.',5)
end

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
