local modpath = minetest.get_modpath("liteworks")
liteworks = {}
local S = minetest.get_translator("liteworks")

function liteworks.may_configure(pos, player)
	local name = player:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner ~= "" and owner == name then -- wielders and filters
		return true
	end
	return not minetest.is_protected(pos, name)
end

function liteworks.string_startswith(str, substr)
	return str:sub(1, substr:len()) == substr
end

liteworks.button_off   = {text="", texture="liteworks_button_off.png", addopts="false;false;liteworks_button_interm.png"}
liteworks.button_on    = {text="", texture="liteworks_button_on.png",  addopts="false;false;liteworks_button_interm.png"}
liteworks.button_base  = "image_button[0,4.3;1,0.6"
liteworks.button_label = "label[0.9,4.31;"..S("Allow splitting incoming stacks from tubes").."]"

local fs_helpers = {}
liteworks.fs_helpers = fs_helpers
function fs_helpers.on_receive_fields(pos, fields)
	local meta = minetest.get_meta(pos)
	for field in pairs(fields) do
		if liteworks.string_startswith(field, "fs_helpers_cycling:") then
			local l = field:split(":")
			local new_value = tonumber(l[2])
			local meta_name = l[3]
			meta:set_int(meta_name, new_value)
		end
	end
end

function fs_helpers.cycling_button(meta, base, meta_name, values)
	local current_value = meta:get_int(meta_name)
	local new_value = (current_value + 1) % (#values)
	local val = values[current_value + 1]
	local text
	local texture_name = nil
	local addopts = nil
	--when we get a table, we know the caller wants an image_button
	if type(val) == "table" then
		text = val["text"]
		texture_name = val["texture"]
		addopts = val["addopts"]
	else
		text = val
	end
	local field = "fs_helpers_cycling:"..new_value..":"..meta_name
	return base..";"..(texture_name and texture_name..";" or "")..field..";"..minetest.formspec_escape(text)..(addopts and ";"..addopts or "").."]"
end

local function delay(...)
	local args = {...}
	return (function() return unpack(args) end)
end

local function get_set_wrap(name, is_dynamic)
	return (function(self)
		return self["_" .. name]
	end), (function(self, value)
		if is_dynamic then
			self["_" .. name] = type(value) == "table"
				and table.copy(value) or value
		end
	end)
end

function liteworks.create_fake_player(def, is_dynamic)
	local wielded_item = ItemStack("")
	if def.inventory and def.wield_list then
		wielded_item = def.inventory:get_stack(def.wield_list, def.wield_index or 1)
	end
	local p = {
		get_player_name = delay(def.name),
		is_player = delay(true),
		is_fake_player = true,

		_formspec = def.formspec or default.gui_survival_form,
		_hp = def.hp or 20,
		_breath = 11,
		_pos = def.position and table.copy(def.position) or vector.new(),
		_properties = def.properties or { eye_height = def.eye_height or 1.47 },
		_inventory = def.inventory,
		_wield_index = def.wield_index or 1,
		_wielded_item = wielded_item,

		-- Model and view
		_eye_offset1 = vector.new(),
		_eye_offset3 = vector.new(),
		set_eye_offset = function(self, first, third)
			self._eye_offset1 = table.copy(first)
			self._eye_offset3 = table.copy(third)
		end,
		get_eye_offset = function(self)
			return self._eye_offset1, self._eye_offset3
		end,
		get_look_dir = delay(def.look_dir or {x=0, y=0, z=1}),
		get_look_pitch = delay(def.look_pitch or 0),
		get_look_yaw = delay(def.look_yaw or 0),
		get_look_horizontal = delay(def.look_yaw or 0),
		get_look_vertical = delay(-(def.look_pitch or 0)),
		set_animation = delay(),

		-- Controls
		get_player_control = delay({
			jump=false, right=false, left=false, LMB=false, RMB=false,
			sneak=def.sneak, aux1=false, down=false, up=false
		}),
		get_player_control_bits = delay(def.sneak and 64 or 0),

		-- Inventory and ItemStacks
		get_inventory = delay(def.inventory),
		set_wielded_item = function(self, item)
			if self._inventory and def.wield_list then
				return self._inventory:set_stack(def.wield_list,
					self._wield_index, item)
			end
			self._wielded_item = ItemStack(item)
		end,
		get_wielded_item = function(self, item)
			if self._inventory and def.wield_list then
				return self._inventory:get_stack(def.wield_list,
					self._wield_index)
			end
			return ItemStack(self._wielded_item)
		end,
		get_wield_list = delay(def.wield_list),

		punch = delay(),
		remove = delay(),
		right_click = delay(),
		set_attach = delay(),
		set_detach = delay(),
		set_bone_position = delay(),
		hud_change = delay(),
	}
	-- Getter & setter functions
	p.get_inventory_formspec, p.set_inventory_formspec
		= get_set_wrap("formspec", is_dynamic)
	p.get_breath, p.set_breath = get_set_wrap("breath", is_dynamic)
	p.get_hp, p.set_hp = get_set_wrap("hp", is_dynamic)
	p.get_pos, p.set_pos = get_set_wrap("pos", is_dynamic)
	p.get_wield_index, p.set_wield_index = get_set_wrap("wield_index", true)
	p.get_properties, p.set_properties = get_set_wrap("properties", false)

	-- For players, move_to and get_pos do the same
	p.move_to = p.get_pos

	-- Backwards compatibilty
	p.getpos = p.get_pos
	p.setpos = p.set_pos
	p.moveto = p.move_to

	-- TODO "implement" all these
	-- set_armor_groups
	-- get_armor_groups
	-- get_animation
	-- get_bone_position
	-- get_player_velocity
	-- set_look_pitch
	-- set_look_yaw
	-- set_physics_override
	-- get_physics_override
	-- hud_add
	-- hud_remove
	-- hud_get
	-- hud_set_flags
	-- hud_get_flags
	-- hud_set_hotbar_itemcount
	-- hud_get_hotbar_itemcount
	-- hud_set_hotbar_image
	-- hud_get_hotbar_image
	-- hud_set_hotbar_selected_image
	-- hud_get_hotbar_selected_image
	-- hud_replace_builtin
	-- set_sky
	-- get_sky
	-- override_day_night_ratio
	-- get_day_night_ratio
	-- set_local_animation
	return p
end

----------------------
-- Vector functions --
----------------------

function liteworks.vector_cross(a, b)
	return {
		x = a.y * b.z - a.z * b.y,
		y = a.z * b.x - a.x * b.z,
		z = a.x * b.y - a.y * b.x
	}
end

function liteworks.vector_dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

-----------------------
-- Facedir functions --
-----------------------

function liteworks.facedir_to_top_dir(facedir)
	return 	({[0] = {x =  0, y =  1, z =  0},
	                {x =  0, y =  0, z =  1},
	                {x =  0, y =  0, z = -1},
	                {x =  1, y =  0, z =  0},
	                {x = -1, y =  0, z =  0},
	                {x =  0, y = -1, z =  0}})
		[math.floor(facedir / 4)]
end

function liteworks.facedir_to_right_dir(facedir)
	return liteworks.vector_cross(
		liteworks.facedir_to_top_dir(facedir),
		minetest.facedir_to_dir(facedir)
	)
end

liteworks.assumed_eye_pos = vector.new(0, 1.5, 0)

function liteworks.set_wielder_formspec(data, meta)
	meta:set_string("formspec",
			"size[8,"..(6+data.wield_inv_height)..";]"..
			"item_image[0,0;1,1;"..data.name_base.."_off]"..
			"label[1,0;"..minetest.formspec_escape(data.description).."]"..
			"list[current_name;"..minetest.formspec_escape(data.wield_inv_name)..";"..((8-data.wield_inv_width)*0.5)..",1;"..data.wield_inv_width..","..data.wield_inv_height..";]"..
			"list[current_player;main;0,"..(2+data.wield_inv_height)..";8,4;]" ..
			"listring[]")
	meta:set_string("infotext", data.description)
end

function liteworks.inject_item(topos, tonode, item, dir)
    local todef = minetest.registered_nodes[tonode.name]
    todef.tube.insert_object(topos, tonode, item, dir)
end

liteworks.can_tool_dig_node = function(nodename, toolcaps, toolname)
	--liteworks.logger("liteworks.can_tool_dig_node() STUB nodename="..tostring(nodename).." toolname="..tostring(toolname).." toolcaps: "..dump(toolcaps))
	-- brief documentation of minetest.get_dig_params() as it's not yet documented in lua_api.txt:
	-- takes two arguments, a node's block groups and a tool's capabilities,
	-- both as they appear in their respective definitions.
	-- returns a table with the following fields:
	-- diggable: boolean, can this tool dig this node at all
	-- time: float, time needed to dig with this tool
	-- wear: int, number of wear points to inflict on the item
	local nodedef = minetest.registered_nodes[nodename]
	-- don't explode due to nil def in event of unknown node!
	if (nodedef == nil) then return false end

	local nodegroups = nodedef.groups
	local diggable = minetest.get_dig_params(nodegroups, toolcaps).diggable
	if not diggable then
		-- a pickaxe can't actually dig leaves based on it's groups alone,
		-- but a player holding one can - the game seems to fall back to the hand.
		-- fall back to checking the hand's properties if the tool isn't the correct one.
		local hand_caps = minetest.registered_items[""].tool_capabilities
		diggable = minetest.get_dig_params(nodegroups, hand_caps).diggable
	end
	return diggable
end

function liteworks.wielder_on(data, wielder_pos, wielder_node)
	data.fixup_node(wielder_pos, wielder_node)
	if wielder_node.name ~= data.name_base.."_off" then return end
	wielder_node.name = data.name_base.."_on"
	minetest.swap_node(wielder_pos, wielder_node)
	minetest.check_for_falling(wielder_pos)
	local wielder_meta = minetest.get_meta(wielder_pos)
	local inv = wielder_meta:get_inventory()
	local wield_inv_name = data.wield_inv_name
	local wieldindex
	for i, stack in ipairs(inv:get_list(wield_inv_name)) do
		if not stack:is_empty() then
			wieldindex = i
			break
		end
	end
	if not wieldindex then
		if not data.ghost_inv_name then return end
		wield_inv_name = data.ghost_inv_name
		inv:set_stack(wield_inv_name, 1, ItemStack(data.ghost_tool))
		wieldindex = 1
	end
	local dir = minetest.facedir_to_dir(wielder_node.param2)
	-- under/above is currently intentionally left switched
	-- even though this causes some problems with deployers and e.g. seeds
	-- as there are some issues related to nodebreakers otherwise breaking 2 nodes afar.
	-- solidity would have to be checked as well,
	-- but would open a whole can of worms related to difference in nodebreaker/deployer behavior
	-- and the problems of wielders acting on themselves if below is solid
	local under_pos = vector.subtract(wielder_pos, dir)
	local above_pos = vector.subtract(under_pos, dir)
	local pitch
	local yaw
	if dir.z < 0 then
		yaw = 0
		pitch = 0
	elseif dir.z > 0 then
		yaw = math.pi
		pitch = 0
	elseif dir.x < 0 then
		yaw = 3*math.pi/2
		pitch = 0
	elseif dir.x > 0 then
		yaw = math.pi/2
		pitch = 0
	elseif dir.y > 0 then
		yaw = 0
		pitch = -math.pi/2
	else
		yaw = 0
		pitch = math.pi/2
	end
	local virtplayer = liteworks.create_fake_player({
		name = data.masquerade_as_owner and wielder_meta:get_string("owner")
			or ":liteworks:" .. minetest.pos_to_string(wielder_pos),
		formspec = wielder_meta:get_string("formspec"),
		look_dir = vector.multiply(dir, -1),
		look_pitch = pitch,
		look_yaw = yaw,
		sneak = data.sneak,
		position = vector.subtract(wielder_pos, liteworks.assumed_eye_pos),
		inventory = inv,
		wield_index = wieldindex,
		wield_list = wield_inv_name
	})
	
	local pointed_thing = { type="node", under=under_pos, above=above_pos }
	data.act(virtplayer, pointed_thing)
	if data.eject_drops then
		for i, stack in ipairs(inv:get_list("main")) do
			if not stack:is_empty() then
				local topos = vector.add(wielder_pos, dir)
				local tonode = minetest.get_node(topos)
				local todef = minetest.registered_nodes[tonode.name]
				if not todef
	                or not (minetest.get_item_group(tonode.name, "tube") == 1
					or minetest.get_item_group(tonode.name, "tubedevice") == 1
			        or minetest.get_item_group(tonode.name, "tubedevice_receiver") == 1)
			        or not todef.tube.can_insert(topos, tonode, item, dir) then
		            minetest.add_item(topos, stack)
				else
				    liteworks.inject_item(topos, tonode, stack, dir)
				end
				inv:set_stack("main", i, ItemStack(""))
			end
		end
	end
end

function liteworks.wielder_off(data, pos, node)
	if node.name == data.name_base.."_on" then
		node.name = data.name_base.."_off"
		minetest.swap_node(pos, node)
		minetest.check_for_falling(pos)
	end
end

function liteworks.register_wielder(data)
	data.fixup_node = data.fixup_node or function (pos, node) end
	data.fixup_oldmetadata = data.fixup_oldmetadata or function (m) return m end
	for _, state in ipairs({ "off", "on" }) do
		local groups = { snappy=2, choppy=2, oddly_breakable_by_hand=2, mesecon=2, tubedevice=1, tubedevice_receiver=1 }
		if state == "on" then groups.not_in_creative_inventory = 1 end
		local tile_images = {}
		for _, face in ipairs({ "top", "bottom", "side2", "side1", "back", "front" }) do
			table.insert(tile_images, data.texture_base.."_"..face..(data.texture_stateful[face] and "_"..state or "")..".png")
		end
		minetest.register_node(data.name_base.."_"..state, {
			description = data.description,
			tiles = tile_images,
			mesecons = {
				effector = {
					rules = liteworks.rules_all,
					action_on = function (pos, node)
						liteworks.wielder_on(data, pos, node)
					end,
					action_off = function (pos, node)
						liteworks.wielder_off(data, pos, node)
					end,
				},
			},
			tube = {
				can_insert = function(pos, node, stack, tubedir)
					if not data.tube_permit_anteroposterior_insert then
						local nodedir = minetest.facedir_to_dir(node.param2)
						if vector.equals(tubedir, nodedir) or vector.equals(tubedir, vector.multiply(nodedir, -1)) then
							return false
						end
					end
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:room_for_item(data.wield_inv_name, stack)
				end,
				insert_object = function(pos, node, stack, tubedir)
					if not data.tube_permit_anteroposterior_insert then
						local nodedir = minetest.facedir_to_dir(node.param2)
						if vector.equals(tubedir, nodedir) or vector.equals(tubedir, vector.multiply(nodedir, -1)) then
							return stack
						end
					end
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:add_item(data.wield_inv_name, stack)
				end,
				input_inventory = data.wield_inv_name,
				connect_sides = data.tube_connect_sides,
				can_remove = function(pos, node, stack, tubedir)
					return stack:get_count()
				end,
			},
			is_ground_content = true,
			paramtype2 = "facedir",
			tubelike = 1,
			groups = groups,
			sounds = default.node_sound_stone_defaults(),
			drop = data.name_base.."_off",
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)
				liteworks.set_wielder_formspec(data, meta)
				local inv = meta:get_inventory()
				inv:set_size(data.wield_inv_name, data.wield_inv_width*data.wield_inv_height)
				if data.ghost_inv_name then
					inv:set_size(data.ghost_inv_name, 1)
				end
				if data.eject_drops then
					inv:set_size("main", 100)
				end
			end,
			after_place_node = function (pos, placer)
				local placer_pos = placer:get_pos()
				if placer_pos and placer:is_player() then placer_pos = vector.add(placer_pos, liteworks.assumed_eye_pos) end
				if placer_pos then
					local dir = vector.subtract(pos, placer_pos)
					local node = minetest.get_node(pos)
					node.param2 = minetest.dir_to_facedir(dir, true)
					minetest.set_node(pos, node)
					minetest.log("action", "real (6d) facedir: " .. node.param2)
				end
				minetest.get_meta(pos):set_string("owner", placer:get_player_name())
			end,
			can_dig = (data.can_dig_nonempty_wield_inv and delay(true) or function(pos, player)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:is_empty(data.wield_inv_name)
			end),
			after_dig_node = function(pos, oldnode, oldmetadata, digger)
				-- The legacy-node fixup is done here in a
				-- different form from the standard fixup,
				-- rather than relying on a standard fixup
				-- in an on_dig callback, because some
				-- non-standard diggers (such as technic's
				-- mining drill) don't respect on_dig.
				oldmetadata = data.fixup_oldmetadata(oldmetadata)
				for _, stack in ipairs(oldmetadata.inventory[data.wield_inv_name] or {}) do
					if not stack:is_empty() then
						minetest.add_item(pos, stack)
					end
				end
			end,
			on_rotate = liteworks.on_rotate,
			on_punch = data.fixup_node,
			allow_metadata_inventory_put = function(pos, listname, index, stack, player)
				if not liteworks.may_configure(pos, player) then return 0 end
				return stack:get_count()
			end,
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				if not liteworks.may_configure(pos, player) then return 0 end
				return stack:get_count()
			end,
			allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
				if not liteworks.may_configure(pos, player) then return 0 end
				return count
			end
		})
	end
end

dofile(modpath.."/autocrafter.lua")

dofile(modpath.."/chest.lua")

dofile(modpath.."/furnace.lua")

dofile(modpath.."/injector.lua")

dofile(modpath.."/deployer.lua")

dofile(modpath.."/dispenser.lua")

dofile(modpath.."/breaker.lua")
