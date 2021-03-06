local item = ...

function item:on_created()

  self:set_savegame_variable("item_apples_counter")
  self:set_assignable(true)
  self:set_amount_savegame_variable("item_apple")
  self:set_max_amount(10)
end

function item:on_using()

  if self:get_amount() == 0 then
    sol.audio.play_sound("wrong")
  else
    self:remove_amount(1)
    self:get_game():add_life(4)
    item:get_game():get_hero():set_physical_condition("poison", false)
  end
  self:set_finished()
end

