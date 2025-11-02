-- Sky Islands BN Port - Proof of Concept
-- main.lua - Main implementation

local mod = game.mod_runtime[game.current_mod]
local storage = game.mod_storage[game.current_mod]

-- Constants
local WARP_SICKNESS_INTERVAL = TimeDuration.from_minutes(5)
local SICKNESS_STAGES = {
  { threshold = 7, message = "You feel slightly disoriented from the warp.", intensity = 6 },
  { threshold = 8, message = "The warp sickness is getting worse!", intensity = 5 },
  { threshold = 9, message = "You feel very ill from prolonged warping.", intensity = 4 },
  { threshold = 10, message = "Your body is struggling to maintain cohesion!", intensity = 3 },
  { threshold = 11, message = "WARNING: Disintegration imminent!", intensity = 2 },
  { threshold = 12, message = "YOU ARE DISINTEGRATING!", intensity = 1 }
}

-- Initialize storage
local function init_storage()
  if not storage.initialized then
    storage.initialized = true
    storage.home_location = nil
    storage.is_away_from_home = false
    storage.sickness_counter = 0
    storage.raids_total = 0
    storage.raids_won = 0
    storage.raids_lost = 0
    gdebug.log_info("Sky Islands storage initialized")
  end
end

-- Helper: Get player position in OMT coordinates
local function get_player_omt()
  local player = gapi.get_avatar()
  if not player then return nil end

  local pos_ms = player:get_pos_ms()
  local abs_ms = gapi.get_map():get_abs_ms(pos_ms)
  local omt, _ = coords.ms_to_omt(abs_ms)
  return omt
end

-- Helper: Teleport player to OMT coordinates
local function teleport_to_omt(omt)
  gdebug.log_info(string.format("Teleporting to OMT: %s, %s, %s", omt.x, omt.y, omt.z))
  gapi.place_player_overmap_at(omt)
  gapi.add_msg("You feel reality shift around you...")
end

-- Warp sickness timer tick
mod.warp_sickness_tick = function()
  if not storage.is_away_from_home then
    return true  -- Keep hook active
  end

  -- Increment counter
  storage.sickness_counter = (storage.sickness_counter or 0) + 1

  gdebug.log_info(string.format("Warp sickness tick: %d", storage.sickness_counter))

  -- Check sickness stages
  for _, stage in ipairs(SICKNESS_STAGES) do
    if storage.sickness_counter >= stage.threshold then
      gapi.add_msg(stage.message)

      -- Apply warp sickness effect (if we have such an effect defined)
      -- For PoC, just show messages

      -- At max stage, deal damage
      if storage.sickness_counter > 12 then
        local player = gapi.get_avatar()
        if player then
          -- Deal minor disintegration damage
          player:mod_pain(5)
          gapi.add_msg("Your body is coming apart!")
        end
      end
      break
    end
  end

  return true  -- Keep running
end

-- Use warp obelisk - start expedition
mod.use_warp_obelisk = function(who, item, pos)
  if storage.is_away_from_home then
    gapi.add_msg("You are already on an expedition!")
    return 0
  end

  -- Store home location
  local home_omt = get_player_omt()
  if not home_omt then
    gapi.add_msg("ERROR: Could not determine position!")
    return 0
  end

  storage.home_location = { x = home_omt.x, y = home_omt.y, z = home_omt.z }

  -- Show raid type menu
  local ui = UiList.new()
  ui:title(locale.gettext("Select Expedition Type"))
  ui:add(1, locale.gettext("Quick Raid (Test)"))
  ui:add(2, locale.gettext("Cancel"))

  local choice = ui:query()

  if choice == 1 then
    -- Start quick raid
    gapi.add_msg("Initiating warp sequence...")

    -- Teleport to random nearby location (for PoC, just offset by a few OMTs)
    local dest_omt = Tripoint.new(
      home_omt.x + gapi.rng(-5, 5),
      home_omt.y + gapi.rng(-5, 5),
      home_omt.z
    )

    teleport_to_omt(dest_omt)

    -- Set away status
    storage.is_away_from_home = true
    storage.sickness_counter = 0
    storage.raids_total = (storage.raids_total or 0) + 1

    -- Start sickness timer
    gapi.add_on_every_x_hook(WARP_SICKNESS_INTERVAL, function()
      return mod.warp_sickness_tick()
    end)

    gapi.add_msg("You arrive at the raid location!")
    gapi.add_msg("Use the return remote to go back before warp sickness kills you.")

    return 1
  else
    gapi.add_msg("Warp cancelled.")
    return 0
  end
end

-- Use return obelisk - return home
mod.use_return_obelisk = function(who, item, pos)
  if not storage.is_away_from_home then
    gapi.add_msg("You are already home!")
    return 0
  end

  if not storage.home_location then
    gapi.add_msg("ERROR: Home location not set!")
    return 0
  end

  -- Confirmation dialog
  local confirm_ui = UiList.new()
  confirm_ui:title(string.format("Return home? Sickness: %d/12", storage.sickness_counter))
  confirm_ui:add(1, locale.gettext("Yes, return home"))
  confirm_ui:add(2, locale.gettext("No, stay"))
  local confirm = confirm_ui:query()

  if confirm == 1 then
    -- Teleport back home
    local home_omt = Tripoint.new(
      storage.home_location.x,
      storage.home_location.y,
      storage.home_location.z
    )

    teleport_to_omt(home_omt)

    -- Clear away status
    storage.is_away_from_home = false
    storage.sickness_counter = 0
    storage.raids_won = (storage.raids_won or 0) + 1

    gapi.add_msg("You return home safely!")
    gapi.add_msg(string.format(
      "Stats: %d/%d raids completed successfully",
      storage.raids_won,
      storage.raids_total
    ))

    return 1
  else
    gapi.add_msg("Cancelled.")
    return 0
  end
end

-- Game started hook - initialize
mod.on_game_started = function()
  init_storage()
  gdebug.log_info("Sky Islands: New game started")
  gapi.add_msg("Sky Islands PoC loaded! Use warp remote to start.")
end

-- Game load hook - restore state
mod.on_game_load = function()
  init_storage()
  gdebug.log_info("Sky Islands: Game loaded")
  gdebug.log_info(string.format("  Away from home: %s", tostring(storage.is_away_from_home)))
  gdebug.log_info(string.format("  Sickness counter: %d", storage.sickness_counter or 0))

  -- If we were away, restart the sickness timer
  if storage.is_away_from_home then
    gapi.add_msg("Resuming expedition... warp sickness timer restarted.")
    gapi.add_on_every_x_hook(WARP_SICKNESS_INTERVAL, function()
      return mod.warp_sickness_tick()
    end)
  end
end

-- Game save hook
mod.on_game_save = function()
  gdebug.log_info("Sky Islands: Game saving")
  gdebug.log_info(string.format("  Saving state: Away=%s, Sickness=%d",
    tostring(storage.is_away_from_home), storage.sickness_counter or 0))
end

-- Character death hook - resurrection PoC
mod.on_character_death = function()
  gdebug.log_info("Sky Islands: Player died!")

  if storage.is_away_from_home and storage.home_location then
    gapi.add_msg("Using emergency warp to return home...")

    -- Teleport back
    local home_omt = Tripoint.new(
      storage.home_location.x,
      storage.home_location.y,
      storage.home_location.z
    )
    teleport_to_omt(home_omt)

    -- Resurrect with minimal HP
    local player = gapi.get_avatar()
    if player then
      player:set_all_parts_hp_cur(10)
    end

    -- Mark raid as failed
    storage.is_away_from_home = false
    storage.sickness_counter = 0
    storage.raids_lost = (storage.raids_lost or 0) + 1

    gapi.add_msg("You respawn at home, badly wounded!")
  end
end

gdebug.log_info("Sky Islands PoC main.lua loaded")
