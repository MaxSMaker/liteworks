local S = minetest.get_translator("liteworks")

liteworks.register_wielder({
    name_base = "liteworks:deployer",
    description = S("Deployer"),
    texture_base = "liteworks_deployer",
    texture_stateful = { front = true },
    tube_connect_sides = { back=1 },
    tube_permit_anteroposterior_insert = true,
    wield_inv_name = "main",
    wield_inv_width = 3,
    wield_inv_height = 3,
    can_dig_nonempty_wield_inv = false,
    masquerade_as_owner = true,
    sneak = false,
    act = function(virtplayer, pointed_thing)
        local wieldstack = virtplayer:get_wielded_item()
        virtplayer:set_wielded_item((minetest.registered_items[wieldstack:get_name()] or {on_place=minetest.item_place}).on_place(wieldstack, virtplayer, pointed_thing) or wieldstack)
    end,
    eject_drops = false,
})

minetest.register_craft({
	output = "liteworks:deployer_off",
	recipe = {
		{ "group:wood",    "default:chest",    "group:wood"    },
		{ "default:stone", "mesecons:piston",  "default:stone" },
		{ "default:stone", "mesecons:mesecon", "default:stone" },
	}
})
