# Cataclysm-BN Lua Mission API Research Report

## 1. Can Lua Create Missions Dynamically?

**YES - Missions can be created dynamically through Lua**

### Mission Creation Functions (Static Methods on Mission Class):

#### `Mission.reserve_new(mission_type_id, character_id) -> Mission`

- Creates a new mission of the given type
- Assigns it to the specified NPC (mission_giver)
- Returns a pointer to the newly created mission
- Location: `src/catalua_bindings_mission.cpp:88-92`
- Implementation: `src/mission.cpp:64-70`

**Example Usage:**

```lua
local mission_type_id = game.MissionTypeIdRaw.new("mission_id_string")
local npc_id = npc:get_id() -- Get character_id from an NPC
local new_mission = game.Mission.reserve_new(mission_type_id, npc_id)
```

#### `Mission.reserve_random(mission_origin, tripoint, character_id) -> Mission`

- Creates a random mission at a specific origin and position
- Assigns it to the specified NPC
- Returns a pointer to the newly created mission, or nil if no suitable type found
- Location: `src/catalua_bindings_mission.cpp:94-98`
- Implementation: `src/mission.cpp:210-217`

**Example Usage:**

```lua
local origin = game.MissionOrigin.ORIGIN_ANY_NPC
local position = game.Tripoint.new(100, 100, 0)
local npc_id = npc:get_id()
local mission = game.Mission.reserve_random(origin, position, npc_id)
```

---

## 2. Can Lua Assign Missions to Players?

**YES - Missions can be assigned to players**

### Mission Assignment Function:

#### `Mission:assign(avatar) -> void`

- Assigns a mission to the given avatar (player character)
- Can only assign unassigned missions (is_assigned() must return false)
- Initializes mission deadlines and kill counters if needed
- Calls mission start callback
- Sets mission status to in_progress
- Location: `src/catalua_bindings_mission.cpp:82-86`
- Implementation: `src/mission.cpp:227-267`

**Example Usage:**

```lua
local mission = game.Mission.reserve_new(mission_type_id, npc_id)
local avatar = gapi.get_avatar()
mission:assign(avatar)
```

**Important Notes:**

- Mission must not be assigned to another player (debugmsg warning if already assigned)
- Assignment initializes kill counters for monster-killing missions
- Sets deadline based on mission type's deadline_low and deadline_high
- Calls `type->start(this)` to execute mission start callback

### Accessing Player's Missions:

#### `Avatar:get_active_missions() -> Vector(Mission)`

- Returns list of currently active missions assigned to the player
- Location: `src/catalua_bindings_creature.cpp:991`

#### `Avatar:get_completed_missions() -> Vector(Mission)`

- Returns list of successfully completed missions
- Location: `src/catalua_bindings_creature.cpp:992`

#### `Avatar:get_failed_missions() -> Vector(Mission)`

- Returns list of failed missions
- Location: `src/catalua_bindings_creature.cpp:993`

---

## 3. Can Lua Remove or Complete Missions?

**YES - Missions can be manipulated**

### Mission Completion/Failure Functions:

#### `Mission:wrap_up() -> void`

- Marks mission as successfully completed (status = mission_status::success)
- Calls avatar's on_mission_finished() callback
- Handles mission-specific cleanup based on goal type:
  - MGOAL_FIND_ITEM_GROUP: Removes items from inventory
  - MGOAL_FIND_ITEM: Removes specific item count
  - MGOAL_FIND_ANY_ITEM: Removes mission items
- Calls mission end callback (type->end)
- Location: `src/catalua_bindings_mission.cpp:73-74`
- Implementation: `src/mission.cpp:280-347`

#### `Mission:fail() -> void`

- Marks mission as failed (status = mission_status::failure)
- Calls avatar's on_mission_finished() callback
- Calls mission fail callback (type->fail)
- Location: `src/catalua_bindings_mission.cpp:71-72`
- Implementation: `src/mission.cpp:289-295`

#### `Mission:step_complete(step_index) -> void`

- Marks a mission step as complete
- Used for multi-step missions (e.g., kill count progression)
- Location: `src/catalua_bindings_mission.cpp:79-80`
- Implementation: `src/mission.cpp:355-358`

### Mission Status Queries:

#### `Mission:has_failed() -> bool`

- Returns true if mission has failed
- Location: `src/catalua_bindings_mission.cpp:76`

#### `Mission:in_progress() -> bool`

- Returns true if mission is started but not failed or succeeded
- Location: `src/catalua_bindings_mission.cpp:78`

#### `Mission:is_assigned() -> bool`

- Returns true if mission is currently assigned to a player
- Location: `src/catalua_bindings_mission.cpp:70`

---

## 4. Mission-Related Types and Functions Exposed to Lua

### Mission Class

**Constructors:**

- `Mission.new()` - Create empty mission (not typically used, use reserve_new instead)

**Getter Methods:**

- `Mission:name() -> string` - Mission name
- `Mission:mission_id() -> MissionTypeIdRaw` - Mission type ID
- `Mission:has_deadline() -> bool` - Has deadline
- `Mission:get_deadline() -> TimePoint` - Deadline timestamp
- `Mission:get_description() -> string` - Mission description
- `Mission:has_target() -> bool` - Has target location
- `Mission:get_target_point() -> Tripoint` - Target coordinates (overmap)
- `Mission:get_type() -> MissionType` - Mission type object
- `Mission:has_follow_up() -> bool` - Has follow-up mission
- `Mission:get_follow_up() -> MissionTypeIdRaw` - Follow-up mission type ID
- `Mission:get_value() -> int` - Reward value
- `Mission:get_id() -> int` - Mission unique ID (uid)
- `Mission:get_item_id() -> ItypeId` - Associated item ID
- `Mission:get_npc_id() -> CharacterId` - Mission giver NPC ID
- `Mission:get_likely_rewards() -> Vector(Pair(int, ItypeId))` - Likely rewards
- `Mission:has_generic_rewards() -> bool` - Has generic rewards

**Setter/Action Methods:**

- `Mission:assign(avatar) -> void` - Assign to player
- `Mission:fail() -> void` - Fail mission
- `Mission:wrap_up() -> void` - Complete mission successfully
- `Mission:step_complete(int) -> void` - Mark step complete
- `Mission:serialize(JsonOut) -> void` - Serialize to JSON
- `Mission:deserialize(JsonIn) -> void` - Deserialize from JSON

**Static Methods:**

- `Mission.reserve_new(mission_type_id, character_id) -> Mission*` - Create new mission
- `Mission.reserve_random(mission_origin, tripoint, character_id) -> Mission*` - Random mission

### MissionType Class

**Getter Properties:**

- `MissionType.description` - Description (translation)
- `MissionType.goal` - Goal type (MissionGoal enum)
- `MissionType.difficulty` - Difficulty level (int)
- `MissionType.value` - Reward value (int)
- `MissionType.deadline_low` - Min deadline (TimeDuration)
- `MissionType.deadline_high` - Max deadline (TimeDuration)
- `MissionType.urgent` - Is urgent (bool)
- `MissionType.has_generic_rewards` - Has generic rewards (bool)
- `MissionType.likely_rewards` - Likely rewards (Vector of pairs)
- `MissionType.origins` - Mission origins (Vector(MissionOrigin))
- `MissionType.item_id` - Main item target (ItypeId)
- `MissionType.remove_container` - Remove container on complete (bool)
- `MissionType.empty_container` - Empty container requirement (ItypeId)
- `MissionType.item_count` - Item count needed (int)
- `MissionType.target_npc_id` - Target NPC ID (CharacterId)
- `MissionType.monster_type` - Monster type to kill (MtypeId)
- `MissionType.monster_kill_goal` - Kill count needed (int)
- `MissionType.follow_up` - Follow-up mission (MissionTypeIdRaw)
- `MissionType.dialogue` - Associated dialogue (Map)

**Methods:**

- `MissionType.get_all() -> Vector(MissionType)` - Get all mission types
- `MissionType.get_random_mission_id(mission_origin, tripoint) -> MissionTypeIdRaw` - Random mission type at location
- `MissionType:tname() -> string` - Translated mission type name

### MissionTypeIdRaw Class

**Constructors:**

- `MissionTypeIdRaw.new(string)` - Create from mission ID string

### Enums

#### MissionOrigin

```
ORIGIN_NULL = 0
ORIGIN_GAME_START = 1
ORIGIN_OPENER_NPC = 2
ORIGIN_ANY_NPC = 3
ORIGIN_SECONDARY = 4
ORIGIN_COMPUTER = 5
```

#### MissionGoal

```
MGOAL_NULL = 0
MGOAL_GO_TO = 1
MGOAL_GO_TO_TYPE = 2
MGOAL_FIND_ITEM = 3
MGOAL_FIND_ANY_ITEM = 4
MGOAL_FIND_ITEM_GROUP = 5
MGOAL_FIND_MONSTER = 6
MGOAL_FIND_NPC = 7
MGOAL_ASSASSINATE = 8
MGOAL_KILL_MONSTER = 9
MGOAL_KILL_MONSTER_TYPE = 10
MGOAL_RECRUIT_NPC = 11
MGOAL_RECRUIT_NPC_CLASS = 12
MGOAL_COMPUTER_TOGGLE = 13
MGOAL_KILL_MONSTER_SPEC = 14
MGOAL_TALK_TO_NPC = 15
MGOAL_CONDITION = 16
```

---

## 5. Example Mods Using Mission System

**Current Status:** No example mods in the codebase currently demonstrate mission system usage through Lua.

However, mods found at `/Users/gchao/code/Cataclysm-BN/data/mods/`:

- smart_house_remotes/
- rpg_system/
- change_hairstyle/
- Test_for_Lua_hooks/ (demonstrates hook system, not missions)
- speedydex/
- teleportation_mod/
- saveload_lua_test/
- ebook_lua/
- resurrection_mod/

None of these currently use the mission API based on grep search.

---

## 6. API Capabilities and Limitations

### Capabilities

**Dynamic Mission Creation:**
✓ Create missions at runtime with specific mission types
✓ Create random missions for specific NPCs and locations
✓ Assign missions to players dynamically

**Mission Manipulation:**
✓ Complete missions successfully (wrap_up)
✓ Fail missions
✓ Mark mission steps as complete
✓ Query mission status
✓ Unassign missions by failing them

**Mission Information Access:**
✓ Read all mission properties
✓ Access mission type information
✓ Get player's active/completed/failed missions
✓ Query mission deadlines and targets

**Serialization:**
✓ Serialize missions to JSON
✓ Deserialize missions from JSON

### Limitations and Gaps

1. **No Mission Modification After Creation:**
   - Cannot modify mission target location after creation
   - Cannot change mission deadline after assignment
   - Cannot modify reward values
   - Cannot change mission description or dialogue

2. **Limited Mission Type Access:**
   - Cannot create new mission types from Lua (only existing types can be used)
   - Cannot modify mission type properties
   - Mission types must be defined in JSON

3. **No Mission Removal:**
   - Cannot delete missions from world_missions map directly
   - Can only fail or complete missions
   - No way to cleanly remove unassigned missions

4. **Mission Processing:**
   - Cannot manually trigger mission::process() from Lua
   - Deadline checking happens automatically but not directly controllable

5. **No Advanced Goal Creation:**
   - Cannot create custom mission goals (MGOAL_CONDITION exists but no Lua binding for goal_condition callback)
   - Cannot dynamically set mission-specific callbacks

6. **Inventory/Item Handling:**
   - wrap_up() automatically handles inventory removal, but only for predefined goal types
   - Limited control over mission item tracking

---

## Complete API Summary Table

| Feature          | Available | Method                     | Notes                        |
| ---------------- | --------- | -------------------------- | ---------------------------- |
| Dynamic Creation | ✓         | Mission.reserve_new()      | Use existing mission types   |
| Random Creation  | ✓         | Mission.reserve_random()   | For specific origin/location |
| Assignment       | ✓         | Mission:assign(avatar)     | Only unassigned missions     |
| Completion       | ✓         | Mission:wrap_up()          | Handles item removal         |
| Failure          | ✓         | Mission:fail()             | Triggers fail callback       |
| Step Progress    | ✓         | Mission:step_complete(int) | For multi-step missions      |
| Status Query     | ✓         | Mission:in_progress(), etc | Multiple query methods       |
| Property Read    | ✓         | Mission getters            | All properties readable      |
| Property Write   | ✗         | N/A                        | Cannot modify after creation |
| Serialization    | ✓         | serialize/deserialize      | JSON format                  |
| Unassignment     | ✓         | Fail mission               | Only way to unassign         |
| Type Creation    | ✗         | N/A                        | JSON-only                    |
| Callback Hooks   | ~         | Limited                    | Only standard callbacks      |

---

## Binding Files Reference

- Mission class bindings: `/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_mission.cpp`
- Mission type implementation: `/Users/gchao/code/Cataclysm-BN/src/mission.h` and `.cpp`
- Avatar/Creature bindings: `/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_creature.cpp`
- Documentation: `/Users/gchao/code/Cataclysm-BN/docs/en/mod/lua/reference/lua.md`
