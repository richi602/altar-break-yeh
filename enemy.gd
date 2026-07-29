extends CharacterBody3D


# =========================
# MOVEMENT
# =========================

@export var move_speed = 6.0
@export var gravity = 20.0


# =========================
# ATTACK
# =========================

@export var attack_range = 3.0
@export var attack_damage = 20
@export var attack_cooldown = 1.0

var can_attack = true


# =========================
# HEALTH
# =========================

@export var max_health : float = 100
var health : float


# =========================
# PLAYER DETECTION
# =========================

@export var aggroRadius : Area3D

var Player : CharacterBody3D
var aggro = false



# =========================
# START
# =========================

func _ready():

	health = max_health



# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):

	# Gravity

	if not is_on_floor():

		velocity.y -= gravity * delta


	if Player == null:

		move_and_slide()

		return



	# Face player

	look_at(
		Player.global_position,
		Vector3.UP,
		true
	)


	rotation.x = 0
	rotation.z = 0



	# Distance from player

	var distance = global_position.distance_to(
		Player.global_position
	)



	# Chase player

	if distance > attack_range:


		var direction = (
			Player.global_position 
			- global_position
		).normalized()


		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed



	# Attack

	else:

		velocity.x = 0
		velocity.z = 0


		if can_attack:

			attack()



	move_and_slide()



# =========================
# MELEE ATTACK
# =========================

func attack():

	can_attack = false


	print("Enemy attacked!")


	if Player != null:

		Player.take_damage(
			attack_damage
		)


	await get_tree().create_timer(
		attack_cooldown
	).timeout


	can_attack = true



# =========================
# PLAYER DETECTED
# =========================

func _on_aggro_radius_body_entered(body):

	if body.name == "Player":

		Player = body

		aggro = true

		print("Player detected")



# =========================
# DAMAGE
# =========================

func take_damage(amount):

	health -= amount


	print("Enemy Health:", health)


	flash_red()


	# Bigger detection radius after hit

	if aggroRadius:

		aggroRadius.scale *= 4



	if health <= 0:

		die()



# =========================
# FLASH RED
# =========================

func flash_red():

	set_player_color(Color.RED)


	await get_tree().create_timer(0.1).timeout


	remove_flash()



func set_player_color(color):

	var meshes = get_all_meshes(self)


	for mesh in meshes:


		if mesh.mesh == null:

			continue



		for i in range(mesh.mesh.get_surface_count()):


			var material = mesh.get_surface_override_material(i)


			if material == null:


				var original = mesh.mesh.surface_get_material(i)


				if original:

					material = original.duplicate()

				else:

					material = StandardMaterial3D.new()



				mesh.set_surface_override_material(
					i,
					material
				)



			material.albedo_color = color




func remove_flash():

	set_player_color(Color.WHITE)




# =========================
# FIND MESHES
# =========================

func get_all_meshes(node):

	var meshes = []


	for child in node.get_children():


		if child is MeshInstance3D:

			meshes.append(child)



		meshes += get_all_meshes(child)



	return meshes



# =========================
# DEATH
# =========================

func die():

	print("Enemy died")

	queue_free()
