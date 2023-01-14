local S = minetest.get_translator("liteworks")
local data
-- see after end of data table for other use of these variables
local name_base = "liteworks:nodebreaker"
local wield_inv_name = "pick"
data = {
    name_base = name_base,
    description = S("Node Breaker"),
    texture_base = "liteworks_nodebreaker",
    texture_stateful = { top = true, bottom = true, side2 = true, side1 = true, front = true },
    tube_connect_sides = { top=1, bottom=1, left=1, right=1, back=1 },
    tube_permit_anteroposterior_insert = false,
    wield_inv_name = wield_inv_name,
    wield_inv_width = 1,
    wield_inv_height = 1,
    can_dig_nonempty_wield_inv = true,
    ghost_inv_name = "ghost_pick",
    ghost_tool = ":",    -- hand by default
    fixup_node = function (pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        -- Node breakers predating the visible pick slot
        -- may have been partially updated.  This code
        -- fully updates them.    Some have been observed
        -- to have no pick slot at all; first add one.
        if inv:get_size("pick") ~= 1 then
            inv:set_size("pick", 1)
        end
        -- Originally, they had a ghost pick in a "pick"
        -- inventory, no other inventory, and no form.
        -- The partial update of early with-form node
        -- breaker code gives them "ghost_pick" and "main"
        -- inventories, but leaves the old ghost pick in
        -- the "pick" inventory, and doesn't add a form.
        -- First perform that partial update.
        if inv:get_size("ghost_pick") ~= 1 then
            inv:set_size("ghost_pick", 1)
            inv:set_size("main", 100)
        end
        -- If the node breaker predates the visible pick
        -- slot, which we can detect by it not having a
        -- form, then the pick slot needs to be cleared
        -- of the old ghost pick.
        if (meta:get_string("formspec") or "") == "" then
            inv:set_stack("pick", 1, ItemStack(""))
        end
        -- Finally, unconditionally set the formspec
        -- and infotext.  This not only makes the
        -- pick slot visible for node breakers where
        -- it wasn't before; it also updates the form
        -- for node breakers that had an older version
        -- of the form, and sets infotext where it was
        -- missing for early with-form node breakers.
        liteworks.set_wielder_formspec(data, meta)
    end,
    fixup_oldmetadata = function (oldmetadata)
        -- Node breakers predating the visible pick slot,
        -- with node form, kept their ghost pick in an
        -- inventory named "pick", the same name as the
        -- later visible pick slot.  The pick must be
        -- removed to avoid spilling it.
        if not oldmetadata.fields.formspec then
            return { inventory = { pick = {} }, fields = oldmetadata.fields }
        else
            return oldmetadata
        end
    end,
    masquerade_as_owner = true,
    sneak = false,
    act = function(virtplayer, pointed_thing)
        --local dname = "nodebreaker.act() "
        local wieldstack = virtplayer:get_wielded_item()
        local oldwieldstack = ItemStack(wieldstack)
        local on_use = (minetest.registered_items[wieldstack:get_name()] or {}).on_use
        if on_use then
            --liteworks.logger(dname.."invoking on_use "..tostring(on_use))
            wieldstack = on_use(wieldstack, virtplayer, pointed_thing) or wieldstack
            virtplayer:set_wielded_item(wieldstack)
        else
            local under_node = minetest.get_node(pointed_thing.under)
            local def = minetest.registered_nodes[under_node.name]
            if not def then
                -- do not dig an unknown node
                return
            end
            -- check that the current tool is capable of destroying the
            -- target node.
            -- if we can't, don't dig, and leave the wield stack unchanged.
            -- note that wieldstack:get_tool_capabilities() returns hand
            -- properties if the item has none of it's own.
            if liteworks.can_tool_dig_node(under_node.name,
                    wieldstack:get_tool_capabilities(),
                    wieldstack:get_name()) then
                    def.on_dig(pointed_thing.under, under_node, virtplayer)
                    local sound = def.sounds and def.sounds.dug
                    if sound then
                        minetest.sound_play(sound.name,
                            {pos=pointed_thing.under, gain=sound.gain})
                    end
                    wieldstack = virtplayer:get_wielded_item()
                --~ else
                --liteworks.logger(dname.."couldn't dig node!")
            end
        end
        local wieldname = wieldstack:get_name()
        if wieldname == oldwieldstack:get_name() then
            -- don't mechanically wear out tool
            if wieldstack:get_count() == oldwieldstack:get_count() and
                    wieldstack:get_metadata() == oldwieldstack:get_metadata() and
                    ((minetest.registered_items[wieldstack:get_name()] or {}).wear_represents or "mechanical_wear") == "mechanical_wear" then
                virtplayer:set_wielded_item(oldwieldstack)
            end
        elseif wieldname ~= "" then
            -- tool got replaced by something else:
            -- treat it as a drop
            virtplayer:get_inventory():add_item("main", wieldstack)
            virtplayer:set_wielded_item(ItemStack(""))
        end
    end,
    eject_drops = true,
}
liteworks.register_wielder(data)
minetest.register_craft({
    output = "liteworks:nodebreaker_off",
    recipe = {
        { "basic_materials:gear_steel", "basic_materials:gear_steel",   "basic_materials:gear_steel"    },
        { "default:stone", "mesecons:piston",   "default:stone" },
        { "group:wood",    "mesecons:mesecon",  "group:wood" },
    }
})
