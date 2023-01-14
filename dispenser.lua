local S = minetest.get_translator("liteworks")
liteworks.register_wielder({
	name_base = "liteworks:dispenser",
	description = S("Dispenser"),
	texture_base = "liteworks_dispenser",
	texture_stateful = { front = true },
	tube_connect_sides = { back=1 },
	tube_permit_anteroposterior_insert = true,
	wield_inv_name = "main",
	wield_inv_width = 3,
	wield_inv_height = 3,
	can_dig_nonempty_wield_inv = false,
	masquerade_as_owner = false,
	sneak = true,
	act = function(virtplayer, pointed_thing)
		local wieldstack = virtplayer:get_wielded_item()
		virtplayer:set_wielded_item((minetest.registered_items[wieldstack:get_name()] or
			{on_drop=minetest.item_drop}).on_drop(wieldstack, virtplayer, virtplayer:get_pos()) or
			wieldstack)
	end,
	eject_drops = false,
})
minetest.register_craft({
	output = "liteworks:dispenser_off",
	recipe = {
		{ "default:desert_sand", "default:chest",    "default:desert_sand" },
		{ "default:stone",       "mesecons:piston",  "default:stone"       },
		{ "default:stone",       "mesecons:mesecon", "default:stone"       },
	}
})
