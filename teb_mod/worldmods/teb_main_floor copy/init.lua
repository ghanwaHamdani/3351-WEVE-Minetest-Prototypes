-- TEB first-floor-only prototype from TEB.pdf, Sheet 1 (Floor Plans, Levels 01 & 02).
-- Only user's chosen spaces are modeled. Basement and other floors excluded.
-- Position/shape relationships follow Sheet 1; dimensions are estimated from the drawing
-- because the provided plan does not supply readable individual room dimensions.
-- Main layout: west TA.4 -> TA.3 -> TA.2 -> TA.5 -> Room 50.
-- TA.1 lies south of TA.2. EX.1 and EX.2 each have two glass door leaves.
-- All construction coordinates below are relative to the build origin (x=east,z=south).
local mt=minetest
local MOD=mt.get_current_modname()
local store=mt.get_mod_storage()
local function vec(x,y,z) return {x=x,y=y,z=z} end
local function add(a,x,y,z) return {x=a.x+x,y=a.y+y,z=a.z+z} end
local function register_node(id,description,texture,extra)
 local def={description=description,tiles={texture},groups={cracky=2,oddly_breakable_by_hand=2},is_ground_content=false}
 for k,v in pairs(extra or {}) do def[k]=v end
 mt.register_node(MOD..':'..id,def)
end
register_node('brick','TEB warm masonry exterior','teb_brick.png')
register_node('stone','TEB limestone facade trim','teb_stone.png')
register_node('wall','TEB light interior wall','teb_interior.png')
register_node('floor','TEB tiled main floor','teb_floor.png')
register_node('roof','TEB modern ceiling','teb_roof.png')
register_node('frame','TEB aluminum window/door frame','teb_metal.png')
register_node('glass','TEB clear glazed window','teb_glass.png',{
 drawtype='glasslike',paramtype='light',sunlight_propagates=true,use_texture_alpha='blend',
 groups={cracky=3,oddly_breakable_by_hand=3}})
register_node('lamp','TEB ceiling light','teb_lamp.png',{light_source=14,paramtype='light'})
register_node('paving','TEB entrance paving','teb_paving.png')
register_node('table','TEB study/classroom desk','teb_table.png')
register_node('chair','TEB student chair','teb_chair.png')
register_node('workbench','TEB design studio metal bench','teb_workbench.png')
register_node('labbench','TEB laboratory bench','teb_labbench.png')
register_node('whiteboard','TEB whiteboard','teb_board.png')
register_node('computer','TEB reference display','teb_monitor.png',{light_source=2})
-- Glazed, two-block-high visual leaves; passable so entrance is navigable in all Luanti games.
register_node('door','TEB glazed double-door leaf','teb_glass.png',{
 drawtype='nodebox',paramtype='light',paramtype2='facedir',use_texture_alpha='blend',
 sunlight_propagates=true,walkable=false,
 node_box={type='fixed',fixed={{-0.46,-0.5,0.405,0.46,0.5,0.485},
                            {-0.46,-0.5,0.405,-0.39,0.5,0.50},
                            {0.39,-0.5,0.405,0.46,0.5,0.50}}},
 selection_box={type='fixed',fixed={-0.5,-0.5,0.35,0.5,0.5,0.5}},
 groups={cracky=3,oddly_breakable_by_hand=3}})
local function detail(player,title,info)
 if not player or not player:is_player() then return end
 mt.show_formspec(player:get_player_name(),MOD..':detail',
  'formspec_version[4]size[9.4,4.3]'..
  'label[0.5,0.55;'..mt.formspec_escape(title)..']'..
  'textarea[0.5,1.15;8.4,2.3;text;;'..mt.formspec_escape(info)..']'..
  'button_exit[3.5,3.55;2.4,0.55;close;Close]')
end
local function panel(id,texture)
 mt.register_node(MOD..':'..id,{
   description='TEB wall-mounted information sign',drawtype='signlike',tiles={texture},
   inventory_image=texture,wield_image=texture,
   paramtype='light',paramtype2='wallmounted',sunlight_propagates=true,
   walkable=false,groups={choppy=2,dig_immediate=2},
   selection_box={type='wallmounted'},
   on_rightclick=function(pos,node,clicker)
     local m=mt.get_meta(pos)
     detail(clicker,m:get_string('title'),m:get_string('info'))
   end})
end
for _,id in ipairs({'foyer','ta2','ta3','ta4','ta5','40','28','14','18','50a','50b','50d','50'}) do
 panel('sign_'..id,'teb_sign_'..id..'.png')
end
for i=1,5 do panel('poi'..i,'teb_poi'..i..'.png') end

-- Approximate footprints in 1-block units. Directly editable for measured dimensions.
local R={
 TA4 ={x1=2,x2=72,z1=8,z2=13,base=0,h=7,ext=true},
 TA3 ={x1=72,x2=82,z1=8,z2=23,base=0,h=7,ext=true},
 TA2 ={x1=82,x2=94,z1=-3,z2=23,base=0,h=7,ext=true},
 TA1 ={x1=82,x2=94,z1=23,z2=31,base=0,h=9,ext=true},
 TA5 ={x1=94,x2=120,z1=8,z2=13,base=0,h=7,ext=true},
 R28 ={x1=31,x2=72,z1=-11,z2=8,base=0,h=7},
 R18 ={x1=11,x2=24,z1=13,z2=29,base=0,h=7},
 R14 ={x1=24,x2=40,z1=13,z2=29,base=0,h=7},
 R40 ={x1=94,x2=108,z1=-11,z2=8,base=0,h=7},
 R50D={x1=108,x2=120,z1=-1,z2=8,base=0,h=7},
 R50A={x1=101,x2=110,z1=13,z2=23,base=0,h=7},
 R50B={x1=110,x2=120,z1=13,z2=23,base=0,h=7},
 R50 ={x1=120,x2=167,z1=-11,z2=31,base=0,h=13,ext=true}
}
local function build(origin)
 local mn=add(origin,-12,-2,-17)
 local mx=add(origin,175,18,39)
 local vm=mt.get_voxel_manip()
 local emin,emax=vm:read_from_map(mn,mx)
 local area=VoxelArea:new({MinEdge=emin,MaxEdge=emax})
 local data=vm:get_data()
 local C={air=mt.get_content_id('air')}
 for _,id in ipairs({'brick','stone','wall','floor','roof','frame','glass','lamp','paving','table','chair','workbench','labbench','whiteboard','computer','door'}) do
   C[id]=mt.get_content_id(MOD..':'..id)
 end
 -- Reverse left/right wing placement relative to the TA.1 -> TA.2 approach.
 -- Reflection affects placement only; interior furnishing plans stay unchanged.
 local function mirrored_x(x) return 163-x end
 local function put(x,y,z,id)
   local q=add(origin,mirrored_x(x),y,z)
   data[area:index(q.x,q.y,q.z)]=C[id]
 end
 local function fill(x1,y1,z1,x2,y2,z2,id)
   for z=z1,z2 do for y=y1,y2 do for x=x1,x2 do put(x,y,z,id) end end end
 end
 -- Clear only this dedicated demo world's building area.
 fill(-12,0,-17,175,18,39,'air')
 local function shell(r)
   local material=r.ext and 'brick' or 'wall'
   fill(r.x1,r.base,r.z1,r.x2,r.base,r.z2,'floor')
   fill(r.x1,r.base+r.h,r.z1,r.x2,r.base+r.h,r.z2,'roof')
   for y=r.base+1,r.base+r.h-1 do
     fill(r.x1,y,r.z1,r.x2,y,r.z1,material)
     fill(r.x1,y,r.z2,r.x2,y,r.z2,material)
     fill(r.x1,y,r.z1,r.x1,y,r.z2,material)
     fill(r.x2,y,r.z1,r.x2,y,r.z2,material)
   end
 end
 for _,key in ipairs({'R28','R18','R14','R40','R50D','R50A','R50B','R50',
                       'TA4','TA3','TA2','TA1','TA5'}) do shell(R[key]) end
 -- Connections between all specified hallways. Each clear opening is at least 3 wide.
 fill(72,1,9,72,4,12,'air') -- TA4 -> TA3
 fill(82,1,9,82,4,12,'air') -- TA3 -> TA2
 fill(94,1,9,94,4,12,'air') -- TA2 -> TA5
 fill(85,1,23,91,4,23,'air') -- TA1 -> TA2
 fill(120,1,9,120,6,12,'air') -- TA5 -> open common Room 50
 -- New thresholds maintain aligned walkway floor.
 for _,z in ipairs({9,10,11,12}) do put(72,0,z,'floor');put(82,0,z,'floor');put(94,0,z,'floor');put(120,0,z,'floor') end

 -- Glazed double-door function: exactly two leaves, top and lower panel, with frames.
 local function two_doors_x(xleft,z)
   fill(xleft,1,z,xleft+1,3,z,'air')
   fill(xleft,4,z,xleft+1,4,z,'frame')
   for _,x in ipairs({xleft,xleft+1}) do
     put(x,1,z,'door');put(x,2,z,'door');put(x,3,z,'glass')
   end
 end
 local function two_doors_z(x,zfirst)
   fill(x,1,zfirst,x,3,zfirst+1,'air')
   fill(x,4,zfirst,x,4,zfirst+1,'frame')
   for _,z in ipairs({zfirst,zfirst+1}) do put(x,1,z,'door');put(x,2,z,'door');put(x,3,z,'glass') end
 end
 -- TA.1, exterior EX.2 and EX.1 are TWO separate DOUBLE-DOOR entries.
 two_doors_x(84,31) -- EX.2
 two_doors_x(90,31) -- EX.1
 fill(82,0,32,94,0,38,'paving')
 -- Hall-access entrances to only the requested spaces.
 two_doors_x(49,8)  -- Room 28 lab from TA4
 two_doors_x(17,13) -- Room 18 student design from TA4
 two_doors_x(30,13) -- Room 14 student design from TA4
 two_doors_x(99,8)  -- Room 40 from TA5
 two_doors_z(94,1) -- ADDITIONAL direct two-leaf Room 40 entrance from end of TA.2
 two_doors_x(113,8) -- Room 50D from TA5
 two_doors_x(104,13)-- Room 50A from TA5
 two_doors_x(114,13)-- Room 50B from TA5
 -- Main-facade limestone vertical piers and clear glass: photo-inspired aesthetic.
 -- Keep these to exterior faces only; do not remodel excluded rooms.
 for _,r in ipairs({R.R28,R.R40,R.R50D,R.R18,R.R14,R.R50A,R.R50B}) do
   local z=(r.z1<0) and r.z1 or r.z2
   for x=r.x1+2,r.x2-2 do
     if (x-r.x1)%7==0 then fill(x,1,z,x,r.h-1,z,'stone')
     else fill(x,2,z,x,r.h-2,z,'glass') end
   end
 end
 -- Room 50's three glazed outside edges; stone piers every 7 blocks.
 for x=123,164 do
   for _,z in ipairs({-11,31}) do
     if (x-120)%7==0 then fill(x,1,z,x,11,z,'stone')
     else fill(x,2,z,x,10,z,'glass') end
   end
 end
 for z=-8,28 do
   if (z+11)%8==0 then fill(167,1,z,167,11,z,'stone')
   else fill(167,2,z,167,10,z,'glass') end
 end
 -- The TA.1 entrance central glass facade above doors, with stone accents.
 for x=83,93 do
   if x==88 then fill(x,5,31,x,8,31,'stone')
   else fill(x,5,31,x,8,31,'glass') end
 end
 for _,x in ipairs({82,94}) do fill(x,1,30,x,8,30,'stone') end

 -- Room 40 CLASSROOM: far wall whiteboard, central aisle, tables/chairs both sides.
 fill(97,2,-10,104,3,-10,'whiteboard')
 for _,z in ipairs({-6,-1,4}) do
   fill(96,1,z,98,1,z,'table');put(97,1,z+2,'chair')
   fill(103,1,z,105,1,z,'table');put(104,1,z+2,'chair')
 end
 -- Room 28 LAB: benches face north-wall whiteboard.
 fill(47,2,-10,56,3,-10,'whiteboard')
 for _,z in ipairs({-6,-1,4}) do
   for x=36,62,9 do
     fill(x,1,z,x+4,1,z+1,'labbench')
     put(x+2,1,z+3,'chair')
   end
 end
 -- Room 14 and Room 18 separate design spaces: metal benches along edges.
 local function design(r)
   for z=r.z1+4,r.z2-4,5 do
     fill(r.x1+2,1,z,r.x1+4,1,z+1,'workbench')
     fill(r.x2-4,1,z,r.x2-2,1,z+1,'workbench')
   end
   fill(r.x1+4,1,r.z2-3,r.x2-4,1,r.z2-3,'workbench')
 end
 design(R.R14);design(R.R18)
 -- Study cluster 50A 50B 50D: small tables and seats only.
 local function study(r)
   local midx=math.floor((r.x1+r.x2)/2)
   local midz=math.floor((r.z1+r.z2)/2)
   for _,x in ipairs({midx-2,midx+2}) do
     put(x,1,midz,'table')
     put(x,1,midz+2,'chair')
   end
 end
 study(R.R50A);study(R.R50B);study(R.R50D)
 -- Room 50 remains an EMPTY OPEN common space with no furniture or other rooms.

 -- General ceiling lights and perimeter at 4-block intervals, including the large hall.
 local function lights(r)
   local y=r.base+r.h-1
   for x=r.x1+2,r.x2-2,4 do
     put(x,y,r.z1+2,'lamp')
     put(x,y,r.z2-2,'lamp')
   end
   for z=r.z1+2,r.z2-2,4 do
     put(r.x1+2,y,z,'lamp')
     put(r.x2-2,y,z,'lamp')
   end
   if r.x2-r.x1>19 or r.z2-r.z1>16 then
      for x=r.x1+7,r.x2-5,10 do
        for z=r.z1+6,r.z2-5,10 do put(x,y,z,'lamp') end
      end
   end
 end
 for _,key in ipairs({'TA1','TA2','TA3','TA4','TA5','R40','R28','R14','R18','R50A','R50B','R50D','R50'}) do lights(R[key]) end
 vm:set_data(data)
 vm:write_to_map()
 vm:update_map()

 -- Force actual pane facings for directional doors after VoxelManip write.
 local function orient_door(x,z,p2)
   for _,y in ipairs({1,2}) do
     -- Mirroring across X reverses east/west pane facing.
     local facing=(p2==1 and 3) or (p2==3 and 1) or p2
     mt.swap_node(add(origin,163-x,y,z),{name=MOD..':door',param2=facing})
   end
 end
 for _,x in ipairs({84,85,90,91}) do orient_door(x,31,2) end
 for _,entry in ipairs({{49,8,0},{50,8,0},{17,13,2},{18,13,2},
 {30,13,2},{31,13,2},{99,8,0},{100,8,0},{113,8,0},{114,8,0},
 {104,13,2},{105,13,2},{114,13,2},{115,13,2},
 {94,1,1},{94,2,1}}) do
   orient_door(entry[1],entry[2],entry[3])
 end
 local function sign(x,y,z,id,title,info,mount)
   local p=add(origin,163-x,y,z)
   local facing=(mount==2 and 3) or (mount==3 and 2) or mount or 4
   mt.set_node(p,{name=MOD..':'..id,param2=facing})
   local m=mt.get_meta(p)
   m:set_string('title',title);m:set_string('info',info)
   m:set_string('infotext',title..' (right-click)')
 end
 -- Wall-mounted signs: room number/category at entry, never floating cubes.
 sign(83,3,30,'sign_foyer','TA.1 — Main Entrance Foyer','EX.1 and EX.2 are separate glazed two-leaf entrances.',4)
 sign(83,3,5,'sign_ta2','TA.2 — Connecting Corridor','TA.2 links the entrance to TA.3 and TA.5.',3)
 sign(79,3,22,'sign_ta3','TA.3 — Connector','Connects TA.2 to the west hall TA.4.',4)
 sign(5,3,12,'sign_ta4','TA.4 — West Hallway','Hall serving Rooms 28, 18 and 14.',5)
 sign(96,3,12,'sign_ta5','TA.5 — East Hallway','Connects TA.2 to Room 40, study cluster and Room 50.',5)
 sign(96,3,9,'sign_40','Room 40 — Classroom','Whiteboard; central aisle; tables and chairs on either side.',5)
 sign(46,3,9,'sign_28','Room 28 — Laboratory','Lab benches face a whiteboard.',5)
 sign(14,3,12,'sign_18','Room 18 — Student Design','Metal workbenches along the room.',4)
 sign(27,3,12,'sign_14','Room 14 — Student Design','Separate design space with metal workbenches.',4)
 sign(102,3,12,'sign_50a','Room 50A — Study','Tables and chairs in a designated study room.',4)
 sign(111,3,12,'sign_50b','Room 50B — Study','Tables and chairs in a designated study room.',4)
 sign(110,3,9,'sign_50d','Room 50D — Study','Tables and chairs in a designated study room.',5)
 sign(121,4,14,'sign_50','Room 50 — Common Area','Large open common space, deliberately left unfurnished.',3)
 -- Five interactive POIs (not extra rooms): lab, class, design, study, common.
 sign(52,2,-9,'poi1','POI 1: Room 28','Laboratory; lab benches aligned toward the north wall whiteboard.',4)
 sign(101,2,-9,'poi2','POI 2: Room 40','Classroom; open center aisle and desks/chairs on both sides.',4)
 sign(34,2,28,'poi3','POI 3: Design Rooms','Room 14 and Room 18 are separate student design studios.',5)
 sign(116,2,22,'poi4','POI 4: Study Cluster','Study spaces include Rooms 50A, 50B and 50D.',5)
 sign(121,3,21,'poi5','POI 5: Room 50','Large open common area on the east end of the main floor.',3)
end
local building=false
mt.register_chatcommand('teb_build',{
 description='Generate only the specified TEB main-floor spaces (clears area).',
 privs={interact=true},
 func=function(name)
   if not (mt.is_singleplayer() or mt.check_player_privs(name,{server=true})) then
     return false,'Only available in singleplayer or to administrators.'
   end
   if building then return false,'TEB construction is already running.' end
   if store:get_string('origin')~='' then return false,'Already built in this world. Use /teb_go or start a NEW world.' end
   local player=mt.get_player_by_name(name)
   if not player then return false,'Player unavailable.' end
   local p=vector.round(player:get_pos())
   local origin=vec(p.x-88,p.y-1,p.z-37)
   local low=add(origin,-12,-2,-17)
   local high=add(origin,175,18,39)
   building=true
   mt.emerge_area(low,high,function(_,_,remaining)
     if remaining~=0 then return end
     local ok,err=pcall(build,origin)
     building=false
     if not ok then
       mt.log('error','['..MOD..'] '..tostring(err))
       mt.chat_send_player(name,'Build failed: '..tostring(err)..'. Check debug.txt.')
       return
     end
     store:set_string('origin',mt.pos_to_string(origin))
     local current=mt.get_player_by_name(name)
     if current then
       current:set_pos(add(origin,75,2,36))
       mt.chat_send_player(name,'TEB generated: TA.3 and Room 40 wings swapped; Room 40 also has a direct TA.2 door. Five POIs interactive.')
     end
   end)
   return true,'Generating the TEB main-floor prototype. This can take a moment.'
 end
})
mt.register_chatcommand('teb_go',{
 description='Teleport to the TEB main entrance.',
 func=function(name)
   local origin=mt.string_to_pos(store:get_string('origin'))
   if not origin then return false,'Run /teb_build first.' end
   local player=mt.get_player_by_name(name)
   if not player then return false,'Player unavailable.' end
   player:set_pos(add(origin,75,2,36))
   return true,'Returned to EX.1 / EX.2 exterior entry.'
 end
})
mt.register_chatcommand('teb_info',{
 description='List included TEB main floor spaces.',
 func=function()
   return true,'Modeled: TA.1 (EX.1/EX.2), TA.2, TA.3, TA.4, TA.5, room 40, 28, 14, 18, 50A, 50B, 50D and open Room 50. No basement.'
 end
})
