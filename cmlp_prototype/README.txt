CMLP (Claudette MacKay-Lassonde Pavilion) - two separate builds in one world
Source: Western Facilities Management plan SEB.pdf (sheet 02 ground floor, sheet 01 lower level).
1 block = 1 m; dimensions estimated from the drawings (+/- 1 m).

Ground floor  - Rooms 1309, 1316, 1317, 1327 + corridors TA.131-133, TA.51, entrance EX.11 (POIs 1-4)
Lower level   - Room 63 (atrium), Room 67, Room 67A, Room 55 + corridor TA.54, ST.25 lobby, entrance EX.13 (POIs 5-8)
Assumed: Room 63 is double height (9 m) with a skylight; the plan shows no heights.

1. Copy this folder (cmlp_test1) into Luanti's "worlds" folder.
2. In Luanti, select Minetest Game, pick "cmlp_test1", press Play Game (Host Server off).
3. Press T and type /cmlp_build        -> builds the ground floor, puts you at EX.11
4. Walk/fly well away from it (about 100 blocks), then type /cmlp_lower_build
                                       -> builds the lower level, puts you at EX.13
   (Each build clears the area around where you stand, so do not run it next to the other one.)
5. Later: /cmlp_go (ground floor), /cmlp_lower_go (lower level), /cmlp_info (list of spaces).
6. Right-click purple POIs or room signs for information. To rename rooms, edit ROOM_INFO
   (ground floor) or LOWER_INFO (lower level) in worldmods/seb_cmlp_rooms/init.lua before building.

Creative mode is off and the model blocks cannot be dug.
