extends CharacterBody3D


# =========================
# PLAYER SETTINGS
# =========================

@export var mouse_sensitivity = 0.003

@export var speed = 40.0
@export var jump_force = 25.0
@export var gravity = 50.0


# =========================
# DODGE
# =========================

@export var dodge_speed = 100.0
@export var dodge_duration = 0.10
@export var dodge_cooldown = 0.5


# =========================
# AIR DASH
# =========================

@export var air_dash_speed = 140.0
@export var air_dash_duration = 0.15
@export var air_dash_cooldown = 1.0


# =========================
# HEALTH
# =========================

@export var max_health = 10000
@export var hit_invincibility_time = 0.3


# =========================
# REFERENCES
# =========================

@export var lock_turn_speed = 5.0

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var anim = find_child("AnimationPlayer", true, false)
@onready var projectile_spawn = $ProjectileSpawn
@onready var health_bar = $CanvasLayer/HealthBar

var lock_reticle


# =========================
# HEALTH VARIABLE
# =========================

var health = max_health


# =========================
# LOCK ON
# =========================

var locked_enemy = null
var lock_targets = []
var lock_index = 0

@export var lock_range = 50.0


# =========================
# NORMAL PROJECTILE HOMING
# =========================

@export var normal_projectile_target_range = 35.0


# =========================
# DODGE VARIABLES
# =========================

var is_dodging = false
var dodge_timer = 0.0
var dodge_direction = Vector3.ZERO

var can_dodge = true
var dodge_cooldown_timer = 0.0


# =========================
# I-FRAMES
# =========================

var dodge_invincible = false
var hit_invincible = false


# =========================
# AIR DASH VARIABLES
# =========================

var is_air_dashing = false
var air_dash_timer = 0.0
var air_dash_direction = Vector3.ZERO

var can_air_dash = true
var air_dash_cooldown_timer = 0.0


# =========================
# ATTACK COMBO
# =========================

@export var combo_reset_time = 1.0

@export var projectile_scene: PackedScene
@export var homing_projectile_scene: PackedScene

@export var projectile_damage = 25

@export var secondary_damage = 50
@export var secondary_cooldown = 2.0

var secondary_timer = 0.0

var attacking = false
var combo_step = 0
var combo_timer = 0.0


# =========================
# HOLD ATTACK
# =========================

@export var combo_hold_delay = 0.25
var combo_hold_timer = 0.0


# =========================
# FINISHER
# =========================

@export var finisher_projectile_count = 8

@export var finisher_projectile_damage = 0.3

@export var finisher_setup_launch_force = 7.0

@export var finisher_setup_hold_time = 1.5

@export var finisher_setup_stun_time = 1.5

@export var finisher_target_range = 50.0

var finisher_id_counter = 0


# =========================
# READY
# =========================

func _ready():

	health_bar.max_value = max_health
	health_bar.value = health


	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)


	lock_reticle = get_tree().get_first_node_in_group(
		"lock_reticle"
	)


	if lock_reticle:

		lock_reticle.hide()

	else:

		print("No lock reticle found")


	if anim:

		print("Animations found:")
		print(anim.get_animation_list())

		play_animation("rig_idle")

	else:

		print("No AnimationPlayer found")


# =========================
# INPUT / CAMERA
# =========================

func _unhandled_input(event):

	if event is InputEventMouseMotion:

		rotate_y(
			-event.relative.x
			* mouse_sensitivity
		)


		spring_arm.rotate_x(
			event.relative.y
			* mouse_sensitivity
		)


		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(30)
		)


	if event is InputEventMouseButton:


		if (
			event.button_index == MOUSE_BUTTON_MIDDLE
			and
			event.pressed
		):

			toggle_lock()


		if (
			event.button_index == MOUSE_BUTTON_WHEEL_UP
			and
			event.pressed
		):

			switch_target(1)


		if (
			event.button_index == MOUSE_BUTTON_WHEEL_DOWN
			and
			event.pressed
		):

			switch_target(-1)


# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):

	if combo_hold_timer > 0:

		combo_hold_timer -= delta


	if Input.is_action_pressed("attack"):

		if (
			combo_hold_timer <= 0
			and
			not attacking
		):

			attack()

			combo_hold_timer = combo_hold_delay


	if combo_timer > 0:

		combo_timer -= delta

	else:

		combo_step = 0


	if Input.is_key_pressed(KEY_H):

		take_damage(10)


	if not is_on_floor():

		velocity.y -= gravity * delta

	elif velocity.y < 0:

		velocity.y = 0


	if (
		Input.is_action_just_pressed("jump")
		and
		is_on_floor()
	):

		velocity.y = jump_force


	var direction = get_movement_direction()


	update_dodge_cooldown(delta)


	if (
		Input.is_action_just_pressed("dodge")
		and
		can_dodge
	):

		start_dodge(direction)


	if is_dodging:

		velocity.x = (
			dodge_direction.x
			* dodge_speed
		)

		velocity.z = (
			dodge_direction.z
			* dodge_speed
		)


		dodge_timer -= delta


		if dodge_timer <= 0:

			end_dodge()


	else:

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed


	update_animation(direction)

	move_and_slide()

	update_lock_camera(delta)

	update_lock_reticle()


# =========================
# LOCK CAMERA
# =========================

func update_lock_camera(delta):

	if not is_instance_valid(locked_enemy):

		return


	var target_position = (
		locked_enemy.global_position
		+
		Vector3.UP * 1.5
	)


	var direction = (
		target_position
		- global_position
	)


	direction.y = 0


	if direction.length() > 0:

		var target_rotation = atan2(
			direction.x,
			direction.z
		)


		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			lock_turn_speed * delta
		)


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
		forward * input_dir.y
		+
		right * input_dir.x
	).normalized()


# =========================
# LOCK ON
# =========================

func toggle_lock():

	if is_instance_valid(locked_enemy):

		locked_enemy = null


		if lock_reticle:

			lock_reticle.hide()


		print("Lock OFF")


	else:

		find_targets()


		if lock_targets.size() > 0:

			lock_index = 0

			locked_enemy = lock_targets[0]


			if lock_reticle:

				lock_reticle.show()


			print(
				"Locked:",
				locked_enemy.name
			)


func find_targets():

	lock_targets.clear()


	var enemies = get_tree().get_nodes_in_group(
		"enemies"
	)


	for enemy in enemies:

		if not is_instance_valid(enemy):

			continue


		if enemy is Node3D:

			var distance = global_position.distance_to(
				enemy.global_position
			)


			if distance <= lock_range:

				lock_targets.append(enemy)


func switch_target(direction):

	for enemy in lock_targets.duplicate():

		if not is_instance_valid(enemy):

			lock_targets.erase(enemy)


	if lock_targets.size() == 0:

		locked_enemy = null


		if lock_reticle:

			lock_reticle.hide()


		return


	lock_index += direction


	if lock_index >= lock_targets.size():

		lock_index = 0


	if lock_index < 0:

		lock_index = lock_targets.size() - 1


	locked_enemy = lock_targets[lock_index]


	if is_instance_valid(locked_enemy):

		print(
			"Switched to:",
			locked_enemy.name
		)


# =========================
# NORMAL PROJECTILE TARGET
# =========================

func get_normal_projectile_target():

	if is_instance_valid(locked_enemy):

		return locked_enemy


	var enemies = get_tree().get_nodes_in_group(
		"enemies"
	)


	var nearest_enemy = null

	var nearest_distance = (
		normal_projectile_target_range
	)


	for enemy in enemies:

		if not is_instance_valid(enemy):

			continue


		if not enemy is Node3D:

			continue


		var distance = global_position.distance_to(
			enemy.global_position
		)


		if distance < nearest_distance:

			nearest_distance = distance

			nearest_enemy = enemy


	return nearest_enemy


# =========================
# AUTO FINISHER TARGET
# =========================

func get_nearest_enemy():

	var enemies = get_tree().get_nodes_in_group(
		"enemies"
	)


	var nearest_enemy = null

	var nearest_distance = (
		finisher_target_range
	)


	for enemy in enemies:

		if not is_instance_valid(enemy):

			continue


		if not enemy is Node3D:

			continue


		var distance = global_position.distance_to(
			enemy.global_position
		)


		if distance < nearest_distance:

			nearest_distance = distance

			nearest_enemy = enemy


	return nearest_enemy


# =========================
# ATTACK COMBO
# =========================

func attack():

	print("ATTACK PRESSED")


	combo_step += 1


	if combo_step > 3:

		combo_step = 1


	attacking = true

	combo_timer = combo_reset_time


	match combo_step:


		1:

			shoot_projectile(1)


		2:

			shoot_projectile(2)


		3:

			var finisher_target = null


			if is_instance_valid(locked_enemy):

				finisher_target = locked_enemy

			else:

				finisher_target = get_nearest_enemy()


			if is_instance_valid(finisher_target):

				finisher_id_counter += 1


				print(
					"Finisher target:",
					finisher_target.name
				)


				if finisher_target.has_method(
					"begin_finisher_setup"
				):

					finisher_target.begin_finisher_setup(
						finisher_id_counter,
						finisher_setup_launch_force,
						finisher_setup_hold_time,
						finisher_setup_stun_time
					)


				shoot_projectile(
					finisher_projectile_count,
					finisher_id_counter,
					finisher_target
				)


			else:

				print(
					"No enemy found for finisher!"
				)


	print(
		"Projectile combo:",
		combo_step
	)


	await get_tree().create_timer(
		0.2
	).timeout


	attacking = false


# =========================
# SHOOT PROJECTILES
# =========================

func shoot_projectile(
	amount,
	current_finisher_id = -1,
	finisher_target = null
):

	for i in range(amount):

		var projectile

		if combo_step == 3:
			if homing_projectile_scene == null:
				print(
					"ERROR: Homing projectile scene is not assigned!"
				)
				return


			projectile = (
				homing_projectile_scene.instantiate()
			)
		else:

			if projectile_scene == null:

				print(
					"ERROR: Projectile scene is not assigned!"
				)

				return


			projectile = (
				projectile_scene.instantiate()
			)


			projectile.target = (
				get_normal_projectile_target()
			)


		if projectile == null:

			print(
				"ERROR: Projectile failed to instantiate!"
			)

			return


		if combo_step == 1:

			projectile.projectile_size = 2.0
			projectile.damage = 10


		elif combo_step == 2:

			projectile.projectile_size = 2.0
			projectile.damage = 10


		elif combo_step == 3:

			projectile.projectile_size = 1.0

			projectile.damage = (
				finisher_projectile_damage
			)

			projectile.is_finisher_projectile = true

			projectile.finisher_id = (
				current_finisher_id
			)

			projectile.finisher_hit_count = (
				amount
			)

			projectile.target = (
				finisher_target
			)

			projectile.orbit_index = i
			projectile.orbit_count = amount


		get_tree().current_scene.add_child(
			projectile
		)


		var camera_forward = (
			-camera.global_transform
				.basis.z
				.normalized()
		)


		var camera_right = (
			camera.global_transform
				.basis.x
				.normalized()
		)


		var camera_up = (
			camera.global_transform
				.basis.y
				.normalized()
		)


		projectile.global_position = (
			camera.global_position
			+
			camera_forward * 4.0
			+
			camera_right * 0.8
			-
			camera_up * 0.4
		)


		projectile.direction = camera_forward


		print(
			"PROJECTILE CAMERA SPAWN = ",
			projectile.global_position
		)


		print(
			"PROJECTILE CAMERA FORWARD = ",
			camera_forward
		)


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

	dodge_direction = (
		dodge_direction.normalized()
	)


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
# DAMAGE
# =========================

func _on_hurtbox_body_entered(body):

	if dodge_invincible or hit_invincible:

		return


func take_damage(amount):

	if dodge_invincible or hit_invincible:

		return


	hit_invincible = true


	health -= amount


	health_bar.value = health


	print(
		"Health:",
		health
	)


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

		if (
			anim.current_animation
			!= animation_name
		):

			anim.play(animation_name)


# =========================
# FLASH
# =========================

func flash_red():

	set_player_color(Color.RED)


	await get_tree().create_timer(
		0.1
	).timeout


	if not dodge_invincible:

		remove_flash()


func flash_blue():

	set_player_color(Color.CYAN)


func set_player_color(color):

	var meshes = get_all_meshes(self)


	for mesh in meshes:

		if mesh.mesh == null:

			continue


		var surfaces = (
			mesh.mesh.get_surface_count()
		)


		for i in range(surfaces):

			var material = (
				mesh.get_surface_override_material(i)
			)


			if material == null:

				var original = (
					mesh.mesh.surface_get_material(i)
				)


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


		var surfaces = (
			mesh.mesh.get_surface_count()
		)


		for i in range(surfaces):

			var material = (
				mesh.get_surface_override_material(i)
			)


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
# LOCK RETICLE
# =========================

func update_lock_reticle():

	if not lock_reticle:

		return


	if (
		locked_enemy == null
		or
		not is_instance_valid(locked_enemy)
	):

		lock_reticle.hide()

		locked_enemy = null

		return


	lock_reticle.show()


	var enemy_position = (
		locked_enemy.global_position
		+
		Vector3.UP * 2.5
	)


	var screen_position = (
		camera.unproject_position(
			enemy_position
		)
	)


	lock_reticle.position = screen_position


# =========================
# DEATH
# =========================

func die():

	print("Player Died")

	queue_free()
