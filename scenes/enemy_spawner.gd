extends Node3D


# =========================
# SPAWNER SETTINGS
# =========================

@export var enemy_scene: PackedScene

@export var max_alive_enemies = 5
@export var spawn_delay = 0.5
@export var respawn_time = 2.0


# =========================
# REFERENCES
# =========================

@export var spawn_points_parent: Node3D

var spawn_points = []


# =========================
# VARIABLES
# =========================

var alive_enemies = 0
var next_spawn_index = 0


# =========================
# START
# =========================

func _ready():

	if spawn_points_parent == null:

		print(
			"ERROR: Spawn Points Parent is not assigned!"
		)

		return


	spawn_points = (
		spawn_points_parent.get_children()
	)


	if spawn_points.size() == 0:

		print(
			"ERROR: No spawn points found!"
		)

		return


	print("Spawner Ready")


	call_deferred(
		"spawn_starting_enemies"
	)


# =========================
# INITIAL SPAWN
# =========================

func spawn_starting_enemies():

	await get_tree().process_frame


	for i in range(
		max_alive_enemies
	):

		await spawn_enemy()


		if i < max_alive_enemies - 1:

			await get_tree().create_timer(
				spawn_delay
			).timeout


# =========================
# SPAWN ENEMY
# =========================

func spawn_enemy():

	if not is_inside_tree():
		return


	if enemy_scene == null:

		print(
			"ERROR: No enemy scene assigned"
		)

		return


	if spawn_points.size() == 0:

		print(
			"ERROR: No spawn points found"
		)

		return


	if alive_enemies >= max_alive_enemies:
		return


	var enemy = enemy_scene.instantiate()


	if enemy == null:

		print(
			"ERROR: Enemy failed to instantiate"
		)

		return


	var spawn_point = (
		spawn_points[
			next_spawn_index
		]
	)


	next_spawn_index += 1


	if next_spawn_index >= spawn_points.size():

		next_spawn_index = 0


	var current_scene = (
		get_tree().current_scene
	)


	if current_scene == null:

		enemy.queue_free()

		return


	current_scene.call_deferred(
		"add_child",
		enemy
	)


	await get_tree().process_frame


	if not is_instance_valid(enemy):
		return


	if not enemy.is_inside_tree():
		return


	enemy.global_position = (
		spawn_point.global_position
	)


	alive_enemies += 1


	enemy.tree_exited.connect(
		enemy_dead
	)


# =========================
# ENEMY DIED
# =========================

func enemy_dead():

	alive_enemies -= 1


	if alive_enemies < 0:

		alive_enemies = 0


	if not is_inside_tree():
		return


	await get_tree().create_timer(
		respawn_time
	).timeout


	if not is_inside_tree():
		return


	await spawn_enemy()
