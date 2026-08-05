extends Node3D

@export var enemy_scene: PackedScene
@export var respawn_time = 1.0

@onready var spawn_point = $SpawnPoint


func _ready():
	
	add_to_group("enemies")

	print("Spawner Ready")

	spawn_enemy()



func spawn_enemy():

	print("Trying to spawn enemy")


	if enemy_scene == null:

		print("ERROR: No enemy scene assigned")

		return



	var enemy = enemy_scene.instantiate()


	# Add enemy safely
	get_tree().current_scene.call_deferred("add_child", enemy)


	# Wait until enemy is in the scene
	await get_tree().process_frame


	enemy.global_position = spawn_point.global_position


	print("Enemy Spawned")


	# Wait for enemy death
	enemy.tree_exited.connect(enemy_dead)



func enemy_dead():

	print("Enemy died, starting respawn timer")


	await get_tree().create_timer(respawn_time).timeout


	spawn_enemy()
