extends CharacterBody3D


@export var max_health : float = 100
var health : float

@export var aggroRadius : Area3D
var Player : CharacterBody3D
var aggro := false

func _ready() -> void:
	health = max_health
	#print(aggro)
	
func _physics_process(delta: float) -> void:
	if Player != null:
		var lastRotation = rotation
		look_at(Player.position,Vector3.UP, true)
		rotation = Vector3(0, rotation.y, 0)
	

func _on_aggro_radius_body_entered(body: Node3D) -> void:
	
	if body.name == "Player":
		Player = body
		aggro = true
		print(aggro)
	
func get_all_meshes(node):

	var meshes = []


	for child in node.get_children():

		if child is MeshInstance3D:

			meshes.append(child)


		meshes += get_all_meshes(child)


	return meshes

func set_player_color(color):

	var meshes = get_all_meshes(self)


	for mesh in meshes:

		if mesh.mesh == null:

			continue


		var surfaces = mesh.mesh.get_surface_count()


		for i in range(surfaces):

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

	var meshes = get_all_meshes(self)


	for mesh in meshes:

		if mesh.mesh == null:

			continue


		var surfaces = mesh.mesh.get_surface_count()


		for i in range(surfaces):

			var material = mesh.get_surface_override_material(i)


			if material:

				material.albedo_color = Color.WHITE
	
func flash_red():
	set_player_color(Color.RED)
	await get_tree().create_timer(0.1).timeout
	remove_flash()

func take_damage(amount):

	health -= amount
	print("Health:", health)
	flash_red()
	aggroRadius.scale *= 4

	if health <= 0:
		queue_free()


#const SPEED = 5.0
#const JUMP_VELOCITY = 4.5


#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#move_and_slide()
