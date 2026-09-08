# Altar Break Beginner Project Guide

This is the shortest map of the project. Start here before changing anything.

## Run the game

Press **F6** to test the scene currently open in Godot. Press **F5** to run the full game from the character-select screen.

The normal game flow is:

1. `scenes/character_select.tscn`
2. `scenes/level1 testing.tscn`
3. Area 1 normal encounter
4. Area 2 larger normal encounter
5. Area 3 Ashen Hound elite
6. Choose a Godshard and open the exit

## Files you will edit most often

| What you want to change | Open this file |
| --- | --- |
| Level layout and area positions | `scenes/level1 testing.tscn` |
| Lucian scene, model, and attached nodes | `scenes/player.tscn` |
| Lucian movement, attacks, HUD, and abilities | `scenes/player.gd` |
| Character-select screen | `scenes/character_select.tscn` and `.gd` |
| Normal melee enemy | `scenes/enemies/enemy.tscn` and `.gd` |
| Unused heavy melee variant | `scenes/desert_dweller.tscn` |
| Normal ranged enemy | `scenes/enemies/RangedEnemy.tscn` and `ranged_enemy.gd` |
| Shared enemy health and shots | `scenes/enemies/` |
| Ashen Hound elite | `scenes/Encounter_Scenes/ashbound_ravager.tscn` and `.gd` |
| Elite orbiting projectiles | `scenes/Encounter_Scenes/ravager_orbit_projectile.tscn` and `.gd` |
| Wave sizes and spawning rules | `scenes/Encounter_Scenes/encounter_manager.gd` |
| Three-area sequence | `scenes/Encounter_Scenes/area_progression.gd` |
| Sandstorm barriers | `scenes/Encounter_Scenes/sandstorm_gate.tscn` and `.gd` |
| Godshard choices | `scenes/Encounter_Scenes/reward_choice.tscn` and `.gd` |

## Folder map

```text
scenes/
  character_select.*       Game startup menu
  level1 testing.tscn      Main playable level
  player.*                 Lucian
  projectile.*             Lucian normal shot
  HomingProjectile.tscn    Lucian finisher shot
  enemies/                 Normal enemies and their shared parts
  Encounter_Scenes/        Waves, gates, rewards, and elite content

maps/                      Environment art
models/                    Current character and enemy art
textures/                  UI and effect textures
assets/audio/enemies/      Enemy sound effects
scripts/autoload/          Small scripts available everywhere
addons/                    Godot editor plugins; do not edit for gameplay
```

Duplicate tutorial projects are still on disk as backups, but `.gdignore` hides them from Godot so the FileSystem dock stays readable.

## Current controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Space | Jump or teleport follow-up arena |
| Left mouse held | Repeat Lucian's 1-2-3 projectile combo |
| Right mouse | Airborne teleport when allowed |
| Shift | Dodge roll |
| Middle mouse | Lock target |
| Mouse wheel | Change locked target |
| F | Rift Cleave — huge close-range shockwave |
| E | Ruin Volley — seven fast homing shots |
| Q | Ultimate |
| Ctrl K | Kill the active encounter for testing |

## How Level 1 is organized

`level1 testing.tscn` contains three sibling nodes named `Area1`, `Area2`, and `Area3`.

Each area owns:

- an `EncounterManager`;
- a `SpawnPoints` node containing markers;
- a sandstorm gate leading out of that area.

To move an encounter, select its `SpawnPoints` markers. To move a barrier, select the entire gate instance. Do not move individual particle or collision children inside a gate.

Area 1 alternates four ranged and four melee enemies. Area 2 alternates six melee and six ranged enemies. Area 3 spawns the Ashen Hound and then three Godshard choices.

## Enemy roles

Ranged enemies randomly become flankers, suppressors, or hunters. Melee enemies randomly become bruisers, pursuers, or reapers. Their scenes and scripts are together in `scenes/enemies/`.

## Safe beginner workflow

1. Open the scene you want to change.
2. Save before editing.
3. Change one exported value in the Inspector.
4. Press F6 and test it.
5. Stop the game and save again if it feels correct.

Values marked with `@export` appear in Godot's Inspector and are the safest tuning points. Prefer those over rewriting functions.

## Important rules

- Keep `scripts/autoload/events.gd`; Godot loads it when the game starts.
- Do not edit `.godot`; Godot generates it automatically.
- Do not edit `addons/godot_ai` for game features.
- The main startup scene is `scenes/character_select.tscn`.
- The final elite is not a boss. Boss systems are reserved for later.
- Godshards appear only after the elite is defeated.

## Fast testing

Open `scenes/Encounter_Scenes/elite_test_arena.tscn` to test the Ashen Hound without playing the whole level. In Level 1, use **Ctrl K** to clear the active encounter quickly.
