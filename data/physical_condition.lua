local physical_condition_manager = {}
local in_command_pressed = false
local in_command_release = false

local custent_frozen

physical_condition_manager.timers = {
    poison = nil,
    slow = nil,
    confusion = nil,
    frozen = nil,
}

function physical_condition_manager:initialize(game)
    local hero = game:get_hero()
    hero.physical_condition = {
        poison = false,
        slow = false,
        confusion = false,
        frozen = false
    }
    
    function hero:is_physical_condition_active(physical_condition)
        return hero.physical_condition[physical_condition]
    end

    function hero:set_physical_condition(physical_condition, active)
        hero.physical_condition[physical_condition] = active
    end
    
    function game:on_command_pressed(command)
        if not hero:is_physical_condition_active('confusion') or in_command_pressed or game:is_paused() then
            return false
        end
        
        if command == "left" then
            game:simulate_command_released("left")
            in_command_pressed = true
            game:simulate_command_pressed("right")
            in_command_pressed = false
            return true                       
        elseif command == "right" then
            game:simulate_command_released("right")
            in_command_pressed = true
            game:simulate_command_pressed("left")
            in_command_pressed = false
            return true                       
        elseif command == "up" then
            game:simulate_command_released("up")
            in_command_pressed = true
            game:simulate_command_pressed("down")
            in_command_pressed = false
            return true                       
        elseif command == "down" then
            game:simulate_command_released("down")
            in_command_pressed = true
            game:simulate_command_pressed("up")
            in_command_pressed = false
            return true
        end
        
	return false
    end
    
    function game:on_command_released(command)
        if not hero:is_physical_condition_active('confusion') or in_command_release or game:is_paused() then
            return false
        end
        
        if command == "left" then
            in_command_release = true
            game:simulate_command_released("right")
            in_command_release = false
            return true
        elseif command == "right" then
            in_command_release = true
            game:simulate_command_released("left")
            in_command_release = false
            return true
        elseif command == "up" then
            in_command_release = true
            game:simulate_command_released("down")
            in_command_release = false
            return true
        elseif command == "down" then
            in_command_release = true
            game:simulate_command_released("up")
            in_command_release = false
            return true
        end

        return false
    end
    
    function hero:on_taking_damage(in_damage)
        local damage = in_damage
        
        if hero:is_physical_condition_active('frozen') then
            damage = damage * 3
            hero:stop_frozen(true)
        end
        
        if damage == 0 then
            return
        end
        
        local shield_level = game:get_ability('shield')
        local tunic_level = game:get_ability('tunic')
        
        local protection_divider = tunic_level * math.ceil(shield_level / 2)
        damage = math.floor(damage / protection_divider)
        
        if damage < 1 then
            damage = 1
        end
        print(damage,in_damage,protection_divider,tunic_level,shield_level)
        game:remove_life(damage)
    end
        
    function hero:start_confusion(delay)
        local aDirectionPressed = {
            right = false,
            left = false,
            up = false,
            down = false
        }
        local bAlreadyConfused = hero:is_physical_condition_active('confusion')
        
        if hero:is_physical_condition_active('confusion') and physical_condition_manager.timers['confusion'] ~= nil then
            physical_condition_manager.timers['confusion']:stop()
        end
        
        if not bAlreadyConfused then
            for key, value in pairs(aDirectionPressed) do
                if game:is_command_pressed(key) then
                    aDirectionPressed[key] = true
                    game:simulate_command_released(key)
                end
            end
        end
        
        hero:set_physical_condition('confusion', true)
        
        physical_condition_manager.timers['confusion'] = sol.timer.start(hero, delay, function()
            hero:stop_confusion()
        end)
        
        if not bAlreadyConfused then
            for key, value in pairs(aDirectionPressed) do
                if value then
                    game:simulate_command_pressed(key)
                end
            end
        end
    end
    
    function hero:start_frozen(delay)
        if hero:is_physical_condition_active('frozen') then
            return
        end
        
        custent_frozen = hero:get_map():create_custom_entity({x = 0, y = 0, layer = 0, model = 'frozen_state', direction = 0})
        
        hero:set_physical_condition('frozen', true)
        physical_condition_manager.timers['frozen'] = sol.timer.start(hero, delay, function()
            hero:stop_frozen(false)
        end)
    end
    
    function hero:start_poison(damage, delay, max_iteration)
        if hero:is_physical_condition_active('poison') and physical_condition_manager.timers['poison'] ~= nil then
            physical_condition_manager.timers['poison']:stop()
        end
        
        local iteration_poison = 0
        function do_poison()
            if hero:is_physical_condition_active("poison") and iteration_poison < max_iteration then
                sol.audio.play_sound("hero_hurt")
                game:remove_life(damage)
                iteration_poison = iteration_poison + 1
            end
            
            if iteration_poison == max_iteration then
                hero:set_physical_condition('poison', false)
            else
                physical_condition_manager.timers['poison'] = sol.timer.start(hero, delay, do_poison)
            end
        end
        
        hero:set_physical_condition('poison', true)
        do_poison()
    end
    
    function hero:start_slow(delay)
        if hero:is_physical_condition_active('slow') and physical_condition_manager.timers['slow'] ~= nil then
            physical_condition_manager.timers['slow']:stop()
        end
        
        hero:set_physical_condition('slow', true)
        hero:set_walking_speed(48)
        physical_condition_manager.timers['slow'] = sol.timer.start(hero, delay, function()
            hero:stop_slow()
        end)
    end
    
    function hero:stop_confusion()
        local aDirectionPressed = {
            right = {"left", false},
            left = {"right", false},
            up = {"down", false},
            down = {"up", false}
        }
        
        if hero:is_physical_condition_active('confusion') and physical_condition_manager.timers['confusion'] ~= nil then
            physical_condition_manager.timers['confusion']:stop()
        end
        
        for key, value in pairs(aDirectionPressed) do
            if game:is_command_pressed(key) then
                aDirectionPressed[key][2] = true
                game:simulate_command_released(key)
            end
        end
        
        hero:set_physical_condition('confusion', false)
        
        for key, value in pairs(aDirectionPressed) do
            if value[2] then
                game:simulate_command_pressed(value[1])
            end
        end
    end
    
        
    function hero:stop_frozen(shatter)
        if hero:is_physical_condition_active('frozen') and physical_condition_manager.timers['frozen'] ~= nil then
            physical_condition_manager.timers['frozen']:stop()
        end
        
        hero:set_physical_condition('frozen', false)
        if shatter then
            custent_frozen:shatter()
        else
            custent_frozen:melt()
        end
    end
    
    function hero:stop_slow()
        if hero:is_physical_condition_active('slow') and physical_condition_manager.timers['slow'] ~= nil then
            physical_condition_manager.timers['slow']:stop()
        end
        
        hero:set_physical_condition('slow', false)
        hero:set_walking_speed(88)
    end
end

return physical_condition_manager
