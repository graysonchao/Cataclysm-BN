-- Cataclysm-BN Lua Mission API Usage Examples

-- ============================================================================
-- Example 1: Create and Assign a Mission Dynamically
-- ============================================================================

local function create_mission_from_npc()
    local avatar = gapi.get_avatar()
    
    -- Get an NPC to act as mission giver (example: find nearby NPC)
    local npc_position = avatar:pos()
    local nearby_npc = gapi.get_npc_at(npc_position)
    
    if nearby_npc == nil then
        gapi.add_msg(MsgType.bad, "No NPC found nearby!")
        return
    end
    
    -- Get the NPC's character ID
    local npc_id = nearby_npc:get_id()
    
    -- Create a mission of a specific type
    -- (Mission types must exist in JSON first)
    local mission_type = game.MissionTypeIdRaw.new("MISSION_BRING_ITEM")
    
    -- Reserve a new mission (create it, assign to NPC as giver)
    local new_mission = game.Mission.reserve_new(mission_type, npc_id)
    
    if new_mission == nil then
        gapi.add_msg(MsgType.bad, "Failed to create mission!")
        return
    end
    
    -- Now assign the mission to the player
    new_mission:assign(avatar)
    
    gapi.add_msg(MsgType.good, string.format("Mission '%s' assigned!", new_mission:name()))
    
    return new_mission
end

-- ============================================================================
-- Example 2: Create a Random Mission at a Location
-- ============================================================================

local function create_random_mission()
    local avatar = gapi.get_avatar()
    
    -- Get a nearby NPC as mission giver
    local nearby_npc = gapi.get_npc_at(avatar:pos())
    if nearby_npc == nil then
        return nil
    end
    
    local npc_id = nearby_npc:get_id()
    
    -- Create a random mission of ANY_NPC origin at player's current location
    local position = avatar:global_omt_location()
    local mission = game.Mission.reserve_random(
        game.MissionOrigin.ORIGIN_ANY_NPC,
        position,
        npc_id
    )
    
    if mission == nil then
        gapi.add_msg(MsgType.bad, "No suitable mission found!")
        return nil
    end
    
    -- Assign it to player
    mission:assign(avatar)
    
    gapi.add_msg(MsgType.good, string.format(
        "Random mission created: %s",
        mission:get_type():tname()
    ))
    
    return mission
end

-- ============================================================================
-- Example 3: Monitor and Complete Missions
-- ============================================================================

local function manage_missions()
    local avatar = gapi.get_avatar()
    
    -- Get all active missions
    local active_missions = avatar:get_active_missions()
    
    gapi.add_msg(MsgType.neutral, string.format(
        "You have %d active missions",
        #active_missions
    ))
    
    for i, mission in ipairs(active_missions) do
        local mission_name = mission:name()
        local mission_desc = mission:get_description()
        
        gapi.add_msg(MsgType.neutral, string.format(
            "Mission %d: %s - %s",
            mission:get_id(),
            mission_name,
            mission_desc
        ))
        
        -- Check if mission has deadline
        if mission:has_deadline() then
            local deadline = mission:get_deadline()
            gapi.add_msg(MsgType.warning, "Mission has deadline!")
        end
        
        -- Check mission target
        if mission:has_target() then
            local target = mission:get_target_point()
            gapi.add_msg(MsgType.neutral, string.format(
                "Target location: (%d, %d, %d)",
                target.x, target.y, target.z
            ))
        end
    end
end

-- ============================================================================
-- Example 4: Complete or Fail a Mission
-- ============================================================================

local function complete_mission(mission)
    if mission == nil then
        return
    end
    
    -- Check if mission is in progress
    if not mission:in_progress() then
        gapi.add_msg(MsgType.warning, "Mission is not in progress!")
        return
    end
    
    -- Complete it successfully
    mission:wrap_up()
    
    gapi.add_msg(MsgType.good, string.format(
        "Mission '%s' completed!",
        mission:name()
    ))
end

local function fail_mission(mission)
    if mission == nil then
        return
    end
    
    -- Fail the mission
    mission:fail()
    
    gapi.add_msg(MsgType.bad, string.format(
        "Mission '%s' failed!",
        mission:name()
    ))
end

-- ============================================================================
-- Example 5: Query Mission Status
-- ============================================================================

local function check_mission_status(mission)
    if mission == nil then
        return
    end
    
    local status_lines = {
        string.format("Mission: %s", mission:name()),
        string.format("ID: %d", mission:get_id()),
        string.format("Value: %d", mission:get_value()),
        string.format("In Progress: %s", mission:in_progress() and "Yes" or "No"),
        string.format("Assigned: %s", mission:is_assigned() and "Yes" or "No"),
        string.format("Failed: %s", mission:has_failed() and "Yes" or "No"),
    }
    
    if mission:has_deadline() then
        table.insert(status_lines, "Has deadline: Yes")
    end
    
    if mission:has_follow_up() then
        table.insert(status_lines, string.format(
            "Follow-up: %s",
            mission:get_follow_up()
        ))
    end
    
    for _, line in ipairs(status_lines) do
        gapi.add_msg(MsgType.neutral, line)
    end
end

-- ============================================================================
-- Example 6: Handle Multi-Step Missions
-- ============================================================================

local function progress_mission_step(mission, step_num)
    if mission == nil or not mission:in_progress() then
        return
    end
    
    -- Mark a step as complete
    mission:step_complete(step_num)
    
    gapi.add_msg(MsgType.good, string.format(
        "Mission step %d completed!",
        step_num
    ))
end

-- ============================================================================
-- Example 7: Get All Available Mission Types and Create from Type
-- ============================================================================

local function list_available_missions()
    local all_mission_types = game.MissionType.get_all()
    
    gapi.add_msg(MsgType.neutral, string.format(
        "Total available mission types: %d",
        #all_mission_types
    ))
    
    -- Show first 10 mission types
    for i = 1, math.min(10, #all_mission_types) do
        local mission_type = all_mission_types[i]
        local difficulty = mission_type.difficulty
        local value = mission_type.value
        local name = mission_type:tname()
        
        gapi.add_msg(MsgType.neutral, string.format(
            "%s (Difficulty: %d, Value: %d)",
            name, difficulty, value
        ))
    end
end

-- ============================================================================
-- Example 8: Get Mission History
-- ============================================================================

local function show_mission_history()
    local avatar = gapi.get_avatar()
    
    -- Completed missions
    local completed = avatar:get_completed_missions()
    gapi.add_msg(MsgType.good, string.format(
        "Completed missions: %d",
        #completed
    ))
    
    -- Failed missions
    local failed = avatar:get_failed_missions()
    gapi.add_msg(MsgType.bad, string.format(
        "Failed missions: %d",
        #failed
    ))
    
    -- Active missions
    local active = avatar:get_active_missions()
    gapi.add_msg(MsgType.neutral, string.format(
        "Active missions: %d",
        #active
    ))
end

-- ============================================================================
-- Example 9: Create Mission with Random Origin/Location
-- ============================================================================

local function create_mission_random_location()
    local avatar = gapi.get_avatar()
    local nearby_npc = gapi.get_npc_at(avatar:pos())
    
    if nearby_npc == nil then
        return nil
    end
    
    local npc_id = nearby_npc:get_id()
    
    -- Get a random mission type at a specific location and origin
    local position = avatar:global_omt_location()
    local random_type = game.MissionType.get_random_mission_id(
        game.MissionOrigin.ORIGIN_GAME_START,
        position
    )
    
    if random_type == nil then
        gapi.add_msg(MsgType.bad, "No random mission found!")
        return nil
    end
    
    -- Create mission from this type
    local mission = game.Mission.reserve_new(random_type, npc_id)
    mission:assign(avatar)
    
    return mission
end

-- ============================================================================
-- Example 10: Query Mission Type Information
-- ============================================================================

local function show_mission_type_info(mission_type_id)
    local all_types = game.MissionType.get_all()
    
    for _, mission_type in ipairs(all_types) do
        -- In actual code, would need to compare by ID
        -- This is a simplified example
        
        local info = {
            string.format("Name: %s", mission_type:tname()),
            string.format("Goal: %d (MissionGoal enum)", mission_type.goal),
            string.format("Difficulty: %d", mission_type.difficulty),
            string.format("Value: %d", mission_type.value),
            string.format("Urgent: %s", mission_type.urgent and "Yes" or "No"),
            string.format("Generic Rewards: %s", mission_type.has_generic_rewards and "Yes" or "No"),
        }
        
        for _, line in ipairs(info) do
            gapi.add_msg(MsgType.neutral, line)
        end
        
        break -- Just show first one in this example
    end
end

