local enemy = ...
local sprite

local duration = 0
local finish_with_animation = true
local breed_to_create
local max_number_monster = 1

-- A settable summoning sprite, when animation is done or when a timer is done, an enemy appear at its place.
-- Sprite must have "spinning" and "infinite_spinning" animations.

function enemy:on_created()
    enemy:set_life(1)
    enemy:set_damage(0)
    enemy:set_size(16, 16)
    enemy:set_origin(8, 8)
    enemy:set_invincible()
end

function enemy:summon()
    local prefix = "summoned_" .. breed_to_create .. '_'
    local nb = enemy:get_map():get_entities_count(prefix)
    -- if at the end of the cast we can create another enemy, we do.
    if nb < max_number_monster then
        local x, y, l = enemy:get_position()
        local i = 1
        local name = prefix .. i
        
        while enemy:get_map():has_entity(name) do
            i = i + 1
            name = prefix .. i
        end
        
        enemy:get_map():create_enemy({name = name, x = x, y = y, layer = l, breed = breed_to_create, direction = 3})
    end
    
    enemy:remove()
end

function enemy:set_properties(prop)
    -- Must be set.
    if prop.breed_to_create == nil or prop.sprite == nil then
        return false
    end
    
    sprite = enemy:create_sprite(prop.sprite)
    
    breed_to_create = prop.breed_to_create
    
    if prop.duration ~= nil then
        duration = prop.duration
    end
    
    if prop.finish_with_animation ~= nil then
        finish_with_animation = prop.finish_with_animation
    end
    
    if finish_with_animation or duration == 0 then
        sprite:set_animation("spinning")
        function sprite:on_animation_finished()
            enemy:summon()
        end
    else
        sprite:set_animation("infinite_spinning")
        sol.timer.start(duration, enemy.summon)
    end
    
    if prop.max_number_monster ~= nil then
        max_number_monster = prop.max_number_monster
    end
    
    return true
end

-- Don't hurt the hero if he touch the summoning circle...
function enemy:on_attacking_hero()
    
end