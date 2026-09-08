extends Node3D


# =============================================================================
# RANGED ENEMY SPAWNER SETTINGS
# =============================================================================

@export_category("Ranged Enemy Spawner")

@export var ranged_enemy_scene: PackedScene

@export var max_alive_enemies: int = 2
@export var spawn_delay: float = 1.0
@export var respawn_time: float = 3.0


# =============================================================================
# SPAWN POINTS
# =============================================================================

@export_category("Spawn Points")

@export var spawn_points_parent: Node3D

var spawn_points: Array = []


# =============================================================================
# STATE
# =============================================================================

var alive_enemies: int = 0
var next_spawn_index: int = 0


# =============================================================================
# START
# =============================================================================

func _ready():
	if spawn_points_parent == null:
		print("ERROR: Ranged Spawn Points Parent is not assigned!")
		return

	if ranged_enemy_scene == null:
		print("ERROR: Ranged Enemy Scene is not assigned!")
		return

	spawn_points = spawn_points_parent.get_children()

	if spawn_points.is_empty():
		print("ERROR: No ranged enemy spawn points found!")
		return

	print("Ranged Enemy Spawner Ready")

	call_deferred("spawn_starting_enemies")


# =============================================================================
# INITIAL SPAWN
# =============================================================================

func spawn_starting_enemies():
	await get_tree().process_frame

	for i in range(max_alive_enemies):
		await spawn_enemy()

		if i < max_alive_enemies - 1:
			await get_tree().create_timer(spawn_delay).timeout


# =============================================================================
# SPAWN RANGED ENEMY
# =============================================================================

func spawn_enemy():
	if not is_inside_tree():
		return

	if ranged_enemy_scene == null:
		print("ERROR: No ranged enemy scene assigned!")
		return

	if spawn_points.is_empty():
		print("ERROR: No ranged spawn points found!")
		return

	if alive_enemies >= max_alive_enemies:
		return

	var enemy = ranged_enemy_scene.instantiate()

	if enemy == null:
		print("ERROR: Ranged enemy failed to instantiate!")
		return

	var spawn_point = spawn_points[next_spawn_index]

	next_spawn_index += 1

	if next_spawn_index >= spawn_points.size():
		next_spawn_index = 0

	var current_scene = get_tree().current_scene

	if current_scene == null:
		enemy.queue_free()
		return

	current_scene.call_deferred("add_child", enemy)

	await get_tree().process_frame

	if not is_instance_valid(enemy):
		return

	if not enemy.is_inside_tree():
		return

	enemy.global_position = spawn_point.global_position

	alive_enemies += 1

	enemy.tree_exited.connect(enemy_dead)

	print(
		"Ranged enemy spawned: ",
		alive_enemies,
		"/",
		max_alive_enemies
	)


# =============================================================================
# RANGED ENEMY DIED
# =============================================================================

func enemy_dead():
	alive_enemies -= 1
	alive_enemies = max(alive_enemies, 0)

	print(
		"Ranged enemy died. Alive: ",
		alive_enemies
	)

	if not is_inside_tree():
		return

	await get_tree().create_timer(respawn_time).timeout

	if not is_inside_tree():
		return

	await spawn_enemy()
