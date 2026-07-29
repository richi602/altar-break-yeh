extends CharacterBody3D

# =========================
# PLAYER SETTINGS
# =========================





@export var mouse_sensitivity = 0.003

@export var speed = 40.0
@export var jump_force = 25.0
@export var gravity = 50.0


# Dodge
@export var dodge_speed = 100.0
@export var dodge_duration = 0.10
@export var dodge_cooldown = 0.5

# Air Dash
@export var air_dash_speed = 140.0
@export var air_dash_duration = 0.15
@export var air_dash_cooldown = 1.0

# Health
@export var max_health = 100
@export var hit_invincibility_time = 0.3



# =========================
# REFERENCES
# =========================


@onready var spring_arm = $SpringArm3D
@onready var anim = find_child("AnimationPlayer", true, false)
@onready var projectile_spawn = $ProjectileSpawn



# =========================
# VARIABLES
# =========================

var health = max_health
# Lock On System

var locked_enemy = null
var lock_targets = []
var lock_index = 0

@export var lock_range = 50.0

# Dodge
var is_dodging = false
var dodge_timer = 0.0
var dodge_direction = Vector3.ZERO

var can_dodge = true
var dodge_cooldown_timer = 0.0


# I-FRAMES
var dodge_invincible = false
var hit_invincible = false

# Air Dash
var is_air_dashing = false
var air_dash_timer = 0.0
var air_dash_direction = Vector3.ZERO

var can_air_dash = true
var air_dash_cooldown_timer = 0.0

## Attack Combo

@export var combo_reset_time = 1.0

@export var projectile_scene: PackedScene
@export var projectile_damage = 25

@export var secondary_damage = 50
@export var secondary_cooldown = 2.0

var secondary_timer = 0.0

var attacking = false
var combo_step = 0
var combo_timer = 0.0




# =========================
# READY
# =========================

func _ready():

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



	if anim:

		print("Animations found:")
		print(anim.get_animation_list())

		play_animation("rig_idle")

	else:

		print("No AnimationPlayer found")



# =========================
# CAMERA
# =========================

func _unhandled_input(event):

	if event is InputEventMouseMotion:

		rotate_y(-event.relative.x * mouse_sensitivity)


		spring_arm.rotate_x(
			event.relative.y * mouse_sensitivity
		)


		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(30)
		)

	# =========================
	# LOCK ON INPUT
	# =========================

	if event is InputEventMouseButton:


		# Middle mouse button = lock/unlock

		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:

			toggle_lock()



		# Scroll wheel = switch target

		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:

			switch_target(1)



		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:

			switch_target(-1)


# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):

	# Attack

	if Input.is_action_just_pressed("attack"):

		attack()


	if combo_timer > 0:

		combo_timer -= delta

	else:

		combo_step = 0


	# TEST DAMAGE
	if Input.is_key_pressed(KEY_H):

		take_damage(10)



	# Gravity

	if not is_on_floor():

		velocity.y -= gravity * delta

	elif velocity.y < 0:

		velocity.y = 0



	# Jump

	if Input.is_action_just_pressed("jump") and is_on_floor():

		velocity.y = jump_force



	var direction = get_movement_direction()
	



	update_dodge_cooldown(delta)



	if Input.is_action_just_pressed("dodge") and can_dodge:

		start_dodge(direction)



	if is_dodging:

		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed


		dodge_timer -= delta


		if dodge_timer <= 0:

			end_dodge()


	else:

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed



	update_animation(direction)


	move_and_slide()



# =========================
# MOVEMENT
# =========================

func get_movement_direction():

	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)


	var forward = -transform.basis.z
	var right = -transform.basis.x


	forward.y = 0
	right.y = 0


	forward = forward.normalized()
	right = right.normalized()


	return (
		forward * input_dir.y +
		right * input_dir.x
	).normalized()
	

# =========================
# LOCK ON SYSTEM
# =========================

func toggle_lock():

	if is_instance_valid(locked_enemy):

		locked_enemy = null

		print("Lock OFF")


	else:

		find_targets()


		if lock_targets.size() > 0:

			lock_index = 0

			locked_enemy = lock_targets[0]

			print("Locked:", locked_enemy.name)



func find_targets():

	lock_targets.clear()


	var enemies = get_tree().get_nodes_in_group("enemies")


	for enemy in enemies:

		# Only accept 3D objects

		if enemy is Node3D:

			var distance = global_position.distance_to(
				enemy.global_position
			)


			if distance <= lock_range:

				lock_targets.append(enemy)



func switch_target(direction):

	# Remove dead enemies

	for enemy in lock_targets:

		if not is_instance_valid(enemy):

			lock_targets.erase(enemy)



	if lock_targets.size() == 0:

		locked_enemy = null

		return



	lock_index += direction



	if lock_index >= lock_targets.size():

		lock_index = 0



	if lock_index < 0:

		lock_index = lock_targets.size() - 1



	locked_enemy = lock_targets[lock_index]


	if is_instance_valid(locked_enemy):

		print("Switched to:", locked_enemy.name)

# =========================
# ATTACK COMBO
# =========================

func attack():

	print("ATTACK PRESSED")

	if attacking:

		combo_step += 1

	else:

		combo_step = 2


	if combo_step > 2:

		combo_step = 3


	attacking = true

	combo_timer = combo_reset_time


	match combo_step:

		1:

			shoot_projectile(1)


		2:

			shoot_projectile(2)


		3:

			shoot_projectile(3)


	print("Projectile combo:", combo_step)


	await get_tree().create_timer(0.2).timeout


	attacking = false



func shoot_projectile(amount):

	for i in range(amount):

		var projectile = projectile_scene.instantiate()


		# Set size BEFORE adding to scene
		if combo_step == 1:

			projectile.projectile_size = 1.0
			projectile.damage = 25


		elif combo_step == 2:

			projectile.projectile_size = 4
			projectile.damage = 40


		elif combo_step == 3:

			projectile.projectile_size = 8
			projectile.damage = 75



		get_tree().current_scene.add_child(projectile)


		projectile.global_position = projectile_spawn.global_position


		var direction = -projectile_spawn.global_transform.basis.z


		projectile.direction = direction.normalized()

# =========================
# DODGE
# =========================

func start_dodge(direction):

	is_dodging = true

	can_dodge = false

	dodge_invincible = true


	flash_blue()


	dodge_timer = dodge_duration

	dodge_cooldown_timer = dodge_cooldown



	if direction != Vector3.ZERO:

		dodge_direction = direction

	else:

		dodge_direction = -transform.basis.z



	dodge_direction.y = 0

	dodge_direction = dodge_direction.normalized()



func end_dodge():

	is_dodging = false

	dodge_invincible = false

	remove_flash()



func update_dodge_cooldown(delta):

	if not can_dodge:

		dodge_cooldown_timer -= delta


		if dodge_cooldown_timer <= 0:

			can_dodge = true



# =========================
# DAMAGE SYSTEM
# =========================

func _on_hurtbox_body_entered(body):

	if dodge_invincible or hit_invincible:

		return





func take_damage(amount):

	if dodge_invincible or hit_invincible:

		return


	hit_invincible = true


	health -= amount


	print("Health:", health)


	flash_red()



	if health <= 0:

		die()



	await get_tree().create_timer(
		hit_invincibility_time
	).timeout


	hit_invincible = false


	if not dodge_invincible:

		remove_flash()



# =========================
# ANIMATION
# =========================

func update_animation(direction):

	if not anim:

		return


	if is_dodging:

		play_animation("rig_dodge")


	elif direction.length() > 0.1:

		play_animation("rig_run")


	else:

		play_animation("rig_idle")



func play_animation(animation_name):

	if not anim:

		return


	if anim.has_animation(animation_name):

		if anim.current_animation != animation_name:

			anim.play(animation_name)



# =========================
# FLASH SYSTEM
# =========================

func flash_red():

	set_player_color(Color.RED)


	await get_tree().create_timer(0.1).timeout


	if not dodge_invincible:

		remove_flash()



func flash_blue():

	set_player_color(Color.CYAN)



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

	print("Player Died")

	queue_free()
