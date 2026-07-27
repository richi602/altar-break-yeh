extends CharacterBody3D


# =========================
# PLAYER SETTINGS
# =========================

@export var mouse_sensitivity = 0.003

@export var speed = 40.0
@export var jump_force = 8.0
@export var gravity = 20.0


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



# =========================
# VARIABLES
# =========================

var health = max_health


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
# MAIN LOOP
# =========================

func _physics_process(delta):


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


	if body.is_in_group("EnemyAttack"):

		take_damage(10)



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
