
    -- SEB Digital Twin - scaled Spencer Engineering Building route prototype.
    --
    -- /build_seb builds from the issuing player's current facing direction.
    -- Local +Z is forward into EX.2, and local +X is the player's right.
    -- All room dimensions below describe walkable interior floor nodes.

    local BATCH_SIZE = 256
    local BATCH_DELAY = 0.01
    local WALL_HEIGHT = 4
    local CEILING_LEVEL = WALL_HEIGHT + 1

    -- Prefer the requested node IDs when a game provides them.  Current
    -- Minetest Game uses the compatible meselamp and sign_wall_wood IDs.
    local FLOOR_NODE = minetest.registered_nodes["default:silver_sandstone_block"]
        and "default:silver_sandstone_block" or "default:silver_sandstone_block"
    local CEILING_NODE = FLOOR_NODE
    local EXTERIOR_WALL = "default:stonebrick"
    local INTERIOR_WALL = minetest.registered_nodes["default:sandstonebrick"]
        and "default:sandstonebrick" or "default:sandstone"
    local LAMP_NODE = minetest.registered_nodes["default:meshlamp"]
        and "default:meshlamp"
        or (minetest.registered_nodes["default:meselamp"]
            and "default:meselamp" or "default:torch")
    local SIGN_NODE = minetest.registered_nodes["default:sign_wall"]
        and "default:sign_wall"
        or "default:sign_wall_wood"

    -- doors:door_wood is the requested wooden-door item.  Its direct-place
    -- node variants are required because this generator intentionally uses
    -- minetest.set_node rather than an item-placement callback.
    local DOOR_ITEM = "doors:door_wood"
    local DOOR_A = DOOR_ITEM .. "_a"
    local DOOR_B = DOOR_ITEM .. "_b"
    local DOOR_HIDDEN = "doors:hidden"

    if not minetest.registered_nodes[DOOR_A] then
        error("seb_digital_twin requires the Minetest Game doors mod")
    end

    -- The simplified route is laid out in local X/Z coordinates.  The player
    -- enters EX.2 at local z = 1 and walks forward (+Z) toward ST.1.
    -- Width/depth are exact walkable interior dimensions in nodes.
    local SPACES = {
        {key = "EX2", label = "Exit EX.2", x = -1, z = 2, w = 3, d = 3},
        {key = "ST1", label = "Stairs ST.1", x = -2, z = 6, w = 4, d = 6},
        {key = "TA101", label = "Hallway TA.101", x = 3, z = 6, w = 3, d = 30},

        -- Each lab is 10 x 8 internally, the requested 8 x 10 footprint
        -- rotated so the four lab entrances fit along TA.101's 30-node run.
        {key = "1077A", label = "Lab 1077A", x = 7, z = 6, w = 10, d = 8},
        {key = "1077", label = "Lab 1077", x = 7, z = 14, w = 10, d = 8},
        {key = "1079", label = "Lab 1079", x = 7, z = 22, w = 10, d = 8},
        {key = "1061", label = "Lab 1061", x = 7, z = 30, w = 10, d = 8},

        -- TA.103 turns left from the north end of TA.101.  TA.105 continues
        -- through the next left-hand connection to the TA.106 foyer.
        {key = "TA103", label = "Hallway TA.103", x = -8, z = 33, w = 10, d = 3},
        {key = "TA105", label = "Hallway TA.105", x = -24, z = 33, w = 15, d = 3},
        {key = "TA106", label = "Foyer TA.106", x = -35, z = 27, w = 10, d = 15},

        -- On entering TA.106 from the east, travel is toward local -X.  The
        -- classroom is on the right (+Z) and UES 1001 is on the left (-Z).
        {key = "1059", label = "Classroom 1059", x = -40, z = 43, w = 15, d = 20},
        {key = "1001", label = "UES Study Area 1001", x = -45, z = 1, w = 20, d = 25},
    }

    local active_jobs = {}

    local function local_to_world(ctx, lx, y, lz)
        return {
            x = ctx.origin.x + ctx.right.x * lx + ctx.forward.x * lz,
            y = ctx.y0 + y,
            z = ctx.origin.z + ctx.right.z * lx + ctx.forward.z * lz,
        }
    end

    local function local_direction(ctx, lx, lz)
        return {
            x = ctx.right.x * lx + ctx.forward.x * lz,
            y = 0,
            z = ctx.right.z * lx + ctx.forward.z * lz,
        }
    end

    local function is_inside_space(lx, lz)
        for _, space in ipairs(SPACES) do
            if lx >= space.x and lx < space.x + space.w
                    and lz >= space.z and lz < space.z + space.d then
                return space
            end
        end
        return nil
    end

    local function wall_node_for(lx, lz, outward_x, outward_z)
        -- A room across a one-node wall makes that wall an interior partition;
        -- otherwise it is a grey exterior wall.
        if is_inside_space(lx + outward_x, lz + outward_z) then
            return INTERIOR_WALL
        end
        return EXTERIOR_WALL
    end

    local function push_world_node(actions, pos, name, param2)
        actions[#actions + 1] = {
            kind = "node",
            pos = pos,
            node = {name = name, param2 = param2 or 0},
        }
    end

    local function push_node(actions, ctx, lx, y, lz, name, param2)
        push_world_node(actions, local_to_world(ctx, lx, y, lz), name, param2)
    end

    local function push_vertical_wall(actions, ctx, lx, lz, node_name)
        for y = 1, WALL_HEIGHT do
            push_node(actions, ctx, lx, y, lz, node_name)
        end
    end

    local function add_space_shell(actions, ctx, space)
        -- Floor and ceiling.
        for lx = space.x, space.x + space.w - 1 do
            for lz = space.z, space.z + space.d - 1 do
                push_node(actions, ctx, lx, 0, lz, FLOOR_NODE)
                push_node(actions, ctx, lx, CEILING_LEVEL, lz, CEILING_NODE)
            end
        end

        -- Four walls plus closed corner nodes.  Shared walls naturally use the
        -- sandstone-like interior material; exposed boundaries use stonebrick.
        for lz = space.z, space.z + space.d - 1 do
            push_vertical_wall(actions, ctx, space.x - 1, lz,
                wall_node_for(space.x - 1, lz, -1, 0))
            push_vertical_wall(actions, ctx, space.x + space.w, lz,
                wall_node_for(space.x + space.w, lz, 1, 0))
        end
        for lx = space.x, space.x + space.w - 1 do
            push_vertical_wall(actions, ctx, lx, space.z - 1,
                wall_node_for(lx, space.z - 1, 0, -1))
            push_vertical_wall(actions, ctx, lx, space.z + space.d,
                wall_node_for(lx, space.z + space.d, 0, 1))
        end

        push_vertical_wall(actions, ctx, space.x - 1, space.z - 1, EXTERIOR_WALL)
        push_vertical_wall(actions, ctx, space.x - 1, space.z + space.d, EXTERIOR_WALL)
        push_vertical_wall(actions, ctx, space.x + space.w, space.z - 1, EXTERIOR_WALL)
        push_vertical_wall(actions, ctx, space.x + space.w, space.z + space.d, EXTERIOR_WALL)
    end

    local function push_door_action(actions, pos, param2, state)
        actions[#actions + 1] = {
            kind = "door",
            pos = pos,
            param2 = param2,
            state = state,
        }
    end

    local function add_single_door(actions, ctx, lx, lz, normal)
        local pos = local_to_world(ctx, lx, 1, lz)
        local facedir = minetest.dir_to_facedir(
            local_direction(ctx, normal.x, normal.z), false)
        push_node(actions, ctx, lx, 0, lz, FLOOR_NODE)
        push_node(actions, ctx, lx, CEILING_LEVEL, lz, CEILING_NODE)
        -- State 0 / _a is the left-hinged, closed Minetest Game door form.
        push_door_action(actions, pos, facedir, 0)
    end

    local function add_double_door(actions, ctx, lx, lz, normal)
        local pos = local_to_world(ctx, lx, 1, lz)
        local facedir = minetest.dir_to_facedir(
            local_direction(ctx, normal.x, normal.z), false)
        -- This is the doors mod's sibling direction for double doors.
        local sibling_offsets = {
            {x = -1, z = 0}, {x = 0, z = 1},
            {x = 1, z = 0}, {x = 0, z = -1},
        }
        local side = sibling_offsets[facedir + 1]
        local sibling = {x = pos.x + side.x, y = pos.y, z = pos.z + side.z}

        push_node(actions, ctx, lx, 0, lz, FLOOR_NODE)
        push_node(actions, ctx, lx, CEILING_LEVEL, lz, CEILING_NODE)
        push_world_node(actions, {x = sibling.x, y = ctx.y0, z = sibling.z}, FLOOR_NODE)
        push_world_node(actions, {x = sibling.x, y = ctx.y0 + CEILING_LEVEL, z = sibling.z}, CEILING_NODE)

        -- State 2 / _b is the mirrored closed leaf used by the doors mod.
        push_door_action(actions, pos, facedir, 0)
        push_door_action(actions, sibling, facedir, 2)
    end

    local function add_sign(actions, ctx, lx, lz, support, text)
        actions[#actions + 1] = {
            kind = "sign",
            pos = local_to_world(ctx, lx, 2, lz),
            param2 = minetest.dir_to_wallmounted(
                local_direction(ctx, support.x, support.z)),
            text = text,
        }
    end

    local function add_lamps(actions, ctx, space)
        -- ST.1 has masonry stair treads along its west side, so its lamp uses
        -- the clear east-side lane.  Every other area gets a 4-node ceiling grid.
        if space.key == "ST1" then
            push_node(actions, ctx, 1, WALL_HEIGHT, 9, LAMP_NODE)
            return
        end

        local first_x = space.x + math.floor((space.w - 1) / 2)
        local first_z = space.z + 1
        for lx = first_x, space.x + space.w - 1, 4 do
            for lz = first_z, space.z + space.d - 2, 4 do
                push_node(actions, ctx, lx, WALL_HEIGHT, lz, LAMP_NODE)
            end
        end
    end

    local function add_stair_treads(actions, ctx)
        -- A 4 x 6 ST.1 stairwell block.  The west two columns form the four
        -- ascending stone treads and the east lane stays clear to TA.101.
        for step = 0, 3 do
            for lx = -2, -1 do
                for y = 1, step + 1 do
                    push_node(actions, ctx, lx, y, 7 + step, INTERIOR_WALL)
                end
            end
        end
    end

    local function add_clear_volume(actions, ctx)
        -- This is the compact bounding volume of the prototype, including the
        -- exterior wall ring but excluding the protected entrance standing pad.
        for lx = -46, 17 do
            for lz = 1, 63 do
                for y = 0, CEILING_LEVEL do
                    push_node(actions, ctx, lx, y, lz, "air")
                end
            end
        end
    end

    local function make_plan(ctx)
        local actions = {}
        add_clear_volume(actions, ctx)

        for _, space in ipairs(SPACES) do
            add_space_shell(actions, ctx, space)
        end
        add_stair_treads(actions, ctx)

        -- EX.2's outward double doors; the player starts immediately outside.
        add_double_door(actions, ctx, 0, 1, {x = 0, z = 1})
        -- Route connections in the order given by the walkthrough.
        add_single_door(actions, ctx, 0, 5, {x = 0, z = 1})       -- EX.2 -> ST.1
        add_single_door(actions, ctx, 2, 8, {x = 1, z = 0})       -- ST.1 -> TA.101
        add_single_door(actions, ctx, 6, 9, {x = 1, z = 0})       -- 1077A
        add_single_door(actions, ctx, 6, 17, {x = 1, z = 0})      -- 1077
        add_single_door(actions, ctx, 6, 25, {x = 1, z = 0})      -- 1079
        add_single_door(actions, ctx, 6, 33, {x = 1, z = 0})      -- 1061
        add_single_door(actions, ctx, 2, 34, {x = -1, z = 0})     -- TA.103
        add_single_door(actions, ctx, -9, 34, {x = -1, z = 0})    -- TA.105
        add_single_door(actions, ctx, -25, 34, {x = -1, z = 0})   -- TA.106
        add_single_door(actions, ctx, -30, 42, {x = 0, z = 1})    -- Classroom 1059
        add_single_door(actions, ctx, -30, 26, {x = 0, z = -1})   -- UES 1001

        -- Wall-mounted signs: each text is written through node metadata after
        -- minetest.set_node has placed the physical sign.
        add_sign(actions, ctx, 1, 2, {x = 1, z = 0}, "EX.2 - Exit")
        add_sign(actions, ctx, 1, 4, {x = 0, z = 1}, "ST.1 - Stairs")
        add_sign(actions, ctx, 1, 9, {x = 1, z = 0}, "TA.101")
        add_sign(actions, ctx, 5, 10, {x = 1, z = 0}, "1077A")
        add_sign(actions, ctx, 5, 18, {x = 1, z = 0}, "1077")
        add_sign(actions, ctx, 5, 26, {x = 1, z = 0}, "1079")
        add_sign(actions, ctx, 5, 32, {x = 1, z = 0}, "1061")
        add_sign(actions, ctx, 3, 33, {x = -1, z = 0}, "TA.103")
        add_sign(actions, ctx, -8, 33, {x = -1, z = 0}, "TA.105")
        add_sign(actions, ctx, -24, 33, {x = -1, z = 0}, "TA.106 - Foyer")
        add_sign(actions, ctx, -31, 41, {x = 0, z = 1}, "Classroom 1059")
        add_sign(actions, ctx, -31, 27, {x = 0, z = -1}, "UES Study Area 1001")

        for _, space in ipairs(SPACES) do
            add_lamps(actions, ctx, space)
        end

        return actions
    end

    local function run_action(action)
        if action.kind == "node" then
            minetest.set_node(action.pos, action.node)
            return
        end

        if action.kind == "door" then
            local node_name = action.state >= 2 and DOOR_B or DOOR_A
            minetest.set_node(action.pos, {name = node_name, param2 = action.param2})
            local upper_param2 = action.state >= 2
                and (action.param2 + 3) % 4 or action.param2
            minetest.set_node({x = action.pos.x, y = action.pos.y + 1, z = action.pos.z}, {
                name = DOOR_HIDDEN,
                param2 = upper_param2,
            })
            minetest.get_meta(action.pos):set_int("state", action.state)
            return
        end

        if action.kind == "sign" then
            minetest.set_node(action.pos, {name = SIGN_NODE, param2 = action.param2})
            local meta = minetest.get_meta(action.pos)
            meta:set_string("formspec", "field[text;;${text}]")
            meta:set_string("text", action.text)
            meta:set_string("infotext", action.text)
        end
    end

    local function run_job(job)
        local last = math.min(job.index + BATCH_SIZE - 1, #job.actions)
        for i = job.index, last do
            run_action(job.actions[i])
        end
        job.index = last + 1

        if job.index <= #job.actions then
            minetest.after(BATCH_DELAY, run_job, job)
            return
        end

        active_jobs[job.player_name] = nil
        if minetest.get_player_by_name(job.player_name) then
            minetest.chat_send_player(job.player_name,
                "SEB digital twin complete. Start at EX.2 and follow the signs.")
        end
    end

    local function make_context(player)
        local p = player:get_pos()
        local origin = {
            x = math.floor(p.x + 0.5),
            y = math.floor(p.y),
            z = math.floor(p.z + 0.5),
        }
        local look = player:get_look_dir()
        local facedir = minetest.dir_to_facedir({x = look.x, y = 0, z = look.z}, false)
        local forward = minetest.facedir_to_dir(facedir)
        local right = {x = forward.z, y = 0, z = -forward.x}

        return {
            origin = origin,
            y0 = origin.y - 1,
            forward = {x = forward.x, z = forward.z},
            right = right,
        }
    end

    local function prepare_entrance_pad(player, ctx)
        -- Keep a small clear, solid pad under the issuing player while the
        -- remaining building is constructed in asynchronous batches.
        for lx = -2, 2 do
            for lz = -1, 0 do
                minetest.set_node(local_to_world(ctx, lx, 0, lz), {name = FLOOR_NODE})
                for y = 1, CEILING_LEVEL do
                    minetest.set_node(local_to_world(ctx, lx, y, lz), {name = "air"})
                end
            end
        end
        player:set_pos({x = ctx.origin.x, y = ctx.y0 + 1, z = ctx.origin.z})
    end

    minetest.register_chatcommand("build_seb", {
        params = "",
        description = "Build the SEB digital twin route in front of you.",
        privs = {server = true},
        func = function(name)
            if active_jobs[name] then
                return false, "An SEB build is already running for you."
            end

            local player = minetest.get_player_by_name(name)
            if not player then
                return false, "This command must be run by a player."
            end

            local ctx = make_context(player)
            prepare_entrance_pad(player, ctx)
            local job = {
                player_name = name,
                actions = make_plan(ctx),
                index = 1,
            }
            active_jobs[name] = job
            minetest.after(BATCH_DELAY, run_job, job)
            return true, "Building the SEB digital twin in front of you..."
        end,
    })
