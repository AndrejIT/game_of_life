game_of_life = {}
game_of_life.command = nil


game_of_life.node_step = function(pos)
    local positions = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, 
        {"game_of_life:node", "game_of_life:deleted"})
    local neighbors_count = #positions - 1
    if neighbors_count < 2 or neighbors_count > 3 then
        minetest.set_node(pos, {name="game_of_life:deleted"})
    end
    
    local neighbors = game_of_life.empty_neighbors(pos)
    for _, pos in ipairs(neighbors) do
        local neighbors_of_neighbors = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, 
            {"game_of_life:node", "game_of_life:deleted"})
        if #neighbors_of_neighbors == 3 then
            minetest.set_node(pos, {name="game_of_life:new"})
        end
    end
end

-- give list of empty neighbor nodes
game_of_life.empty_neighbors = function(pos)
    -- for now, just air for simplicity
    local positions = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, 
        {"air"})
    return positions
end

-- define area where game of life operates
-- try to not exceed 10M nodes or search will be too slow
game_of_life.search_field = function(nodes)
    local positions = minetest.find_nodes_in_area({x=-300, y=0, z=-300}, {x=300, y=10, z=300}, nodes)
    return positions
end

minetest.register_chatcommand("gol", {
	params = "start/stop/clean",
	description = "Start, stop or clean game of life",
	func = function(playername, text)
        if text == 'start' then
            game_of_life.command = "start"
        elseif text == 'stop' then
            game_of_life.command = nil
        elseif text == 'clean' then
            local positions = game_of_life.search_field({"game_of_life:node"})
            for _, pos in ipairs(positions) do
                minetest.set_node(pos, {name="air"})
            end
            game_of_life.command = nil
        else
            local player = minetest.get_player_by_name(playername)
            player:get_inventory():add_item("main", "game_of_life:node 99")
            minetest.chat_send_player(playername, 'Please, add nodes to world and use this command with parameters: start/stop/clean')
        end
	end,
})

minetest.register_node("game_of_life:node", {
	tiles = {"gol.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate=2},
})
minetest.register_node("game_of_life:new", {
	tiles = {"gol.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate=2},
})
minetest.register_node("game_of_life:deleted", {
	tiles = {"gol.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate=2},
})

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime;
	if timer >= 0.8 then
		if game_of_life.command == 'start' then
		    local positions = game_of_life.search_field({"game_of_life:node"})
            for _, pos in ipairs(positions) do
                game_of_life.node_step(pos)
            end
            local changed = 0
            positions = game_of_life.search_field({"game_of_life:new"})
            for _, pos in ipairs(positions) do
                minetest.set_node(pos, {name="game_of_life:node"})
            end
            changed = changed + #positions
            positions = game_of_life.search_field({"game_of_life:deleted"})
            for _, pos in ipairs(positions) do
                minetest.set_node(pos, {name="air"})
            end
            changed = changed + #positions
            if changed == 0 then
                game_of_life.command = nil
                minetest.chat_send_all("Game of life stopped.")
            end
		end
		timer = 0
	end
end)

