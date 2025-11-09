# Cataclysm-BN Mission Lua API Research - Complete Index

## Research Overview

This directory contains a comprehensive analysis of the Cataclysm-BN Lua API for the mission system. The research was completed on 2025-11-02 and covers all aspects of mission creation, assignment, manipulation, and querying through Lua.

**Key Finding:** The Cataclysm-BN Lua mission API is **fully functional and production-ready** for dynamic mission creation and management.

## Research Documents

### 1. MISSION_LUA_API_RESEARCH.md (Primary Document)

**Size:** 338 lines | **Format:** Markdown

The most comprehensive research document containing:

- Detailed answers to all 5 research questions
- Complete API function reference
- Source code locations with line numbers
- Implementation details and code snippets
- Capabilities and limitations analysis
- Complete API summary table
- Binding file references

**Best for:** Detailed technical reference and understanding the complete mission API architecture.

### 2. MISSION_API_SUMMARY.txt (Executive Summary)

**Size:** 288 lines | **Format:** Plain Text

High-level overview including:

- Executive summary with key findings
- Core API functions listed
- Key binding file locations
- Mission system architecture explanation
- Limitations and workarounds
- Mission goal types (16 total)
- Mission origin types (5 total)
- Practical usage patterns
- Conclusion and recommendations

**Best for:** Quick understanding of what's possible and limitations without deep technical details.

### 3. MISSION_API_QUICK_REFERENCE.txt (Cheat Sheet)

**Size:** 279 lines | **Format:** Plain Text

Quick lookup reference containing:

- All API functions with signature and usage examples
- All enums (MissionOrigin, MissionGoal)
- Common code patterns
- Limitations at a glance
- Error handling information
- Binding file locations
- Property access information

**Best for:** Quick lookup while coding, syntax reference, pattern examples.

### 4. mission_api_examples.lua (Practical Examples)

**Size:** 329 lines | **Format:** Lua Code

10 complete Lua examples demonstrating:

1. Create and assign mission dynamically
2. Create random mission at location
3. Monitor and complete missions
4. Complete or fail a mission
5. Query mission status
6. Handle multi-step missions
7. List available missions
8. Get mission history
9. Create mission with random origin/location
10. Query mission type information

**Best for:** Learning how to use the API with real Lua code examples.

## Research Scope

The research covered:

### Files Analyzed

- `/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_mission.cpp` - Mission bindings (204 lines)
- `/Users/gchao/code/Cataclysm-BN/src/mission.h` - Mission header (480 lines)
- `/Users/gchao/code/Cataclysm-BN/src/mission.cpp` - Mission implementation (728 lines)
- `/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_creature.cpp` - Avatar bindings (mission methods)
- `/Users/gchao/code/Cataclysm-BN/docs/en/mod/lua/reference/lua.md` - Lua API documentation (3600+ lines)

### Locations Searched

- src/catalua_bindings*.cpp - All binding files for mission references
- docs/en/mod/lua/ - Complete Lua documentation
- data/mods/ - All example mods for mission usage
- src/mission.* - Mission system implementation

## Key Findings

### YES - Can Do

- Create missions dynamically at runtime
- Assign missions to players
- Complete or fail missions
- Query mission status and properties
- Get player's active/completed/failed missions
- Access all mission information
- Serialize/deserialize missions

### NO - Cannot Do

- Create new mission types from Lua (JSON-only)
- Modify missions after creation
- Delete missions directly
- Create custom mission goals dynamically
- Override mission callbacks from Lua

### API Statistics

- **Total API Functions:** 35+
- **Mission Classes:** 3 (Mission, MissionType, MissionTypeIdRaw)
- **Mission Goals:** 16 types
- **Mission Origins:** 5 types
- **Property Getters:** 20+
- **Status Checks:** 3 main functions
- **Mutation Functions:** 3 (assign, wrap_up, fail)

## How to Use These Documents

### For Understanding the API

1. Start with `MISSION_LUA_API_RESEARCH.md` for comprehensive overview
2. Check `MISSION_API_SUMMARY.txt` for architecture understanding
3. Use `MISSION_API_QUICK_REFERENCE.txt` as lookup reference

### For Writing Code

1. Check `mission_api_examples.lua` for patterns
2. Reference `MISSION_API_QUICK_REFERENCE.txt` for function signatures
3. Cross-reference `MISSION_LUA_API_RESEARCH.md` for detailed behavior

### For Quick Lookup

1. Use `MISSION_API_QUICK_REFERENCE.txt` for function signatures
2. Check common patterns section
3. Verify limitations and error handling

## API Usage Example

```lua
-- Create a mission
local mission = game.Mission.reserve_new(
  game.MissionTypeIdRaw.new("MISSION_BRING_ITEM"),
  npc:get_id()
)

-- Assign to player
mission:assign(gapi.get_avatar())

-- Check status
if mission:in_progress() then
  gapi.add_msg(MsgType.good, mission:name())
end

-- Complete mission
mission:wrap_up()
```

## Binding Locations

All mission API bindings are located in:

```
/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_mission.cpp
  - Lines 16-103: Mission class binding
  - Lines 105-204: MissionType class binding

/Users/gchao/code/Cataclysm-BN/src/catalua_bindings_creature.cpp
  - Lines 991-993: Avatar mission functions
```

## Recommendations

### For Mod Development

- Use `Mission.reserve_new()` with pre-defined mission types from JSON
- Assign missions using `mission:assign(avatar)`
- Complete or fail missions using `wrap_up()` and `fail()`
- Query player missions with `avatar:get_active_missions()`

### For Advanced Use

- Chain missions using the follow_up field
- Create random missions with `Mission.reserve_random()`
- Query mission types with `MissionType.get_all()`
- Handle multi-step missions with `step_complete()`

### What NOT to Do

- Do not attempt to create new mission types from Lua
- Do not try to modify missions after creation
- Do not override mission callbacks from Lua
- Do not access internal mission state directly

## Next Steps

To use this research:

1. **Read** `MISSION_LUA_API_RESEARCH.md` for complete understanding
2. **Review** `mission_api_examples.lua` for practical patterns
3. **Reference** `MISSION_API_QUICK_REFERENCE.txt` while coding
4. **Consult** `MISSION_API_SUMMARY.txt` for architectural questions

## File Locations

All files are located in the Cataclysm-BN repository root:

- `/Users/gchao/code/Cataclysm-BN/MISSION_LUA_API_RESEARCH.md`
- `/Users/gchao/code/Cataclysm-BN/MISSION_API_SUMMARY.txt`
- `/Users/gchao/code/Cataclysm-BN/MISSION_API_QUICK_REFERENCE.txt`
- `/Users/gchao/code/Cataclysm-BN/mission_api_examples.lua`
- `/Users/gchao/code/Cataclysm-BN/MISSION_LUA_API_INDEX.md` (this file)

## Research Metadata

- **Research Date:** 2025-11-02
- **Repository:** Cataclysm-BN (main branch)
- **Analysis Depth:** Very Thorough
- **Files Analyzed:** 5 source files, 8+ binding files
- **Functions Documented:** 35+ API functions
- **Code Examples:** 10 complete Lua examples
- **Total Documentation:** 1,234 lines across 4 documents
