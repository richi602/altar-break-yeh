extends CharacterBody3D


@export var mouse_sensitivity = 0.005

@export var speed = 40.0
@export var jump_force = 8.0
@export var gravity = 20.0

@export var dodge_speed = 60.0
@export var dodge_duration = 0.2
@export var dodge_cooldown = 0.5

@export var max_health = 100
@export var invincibility_time = 0.3


@onready var spring_arm = $SpringArm3D
@onready var anim = find_child("AnimationPlayer", true, false)


var health = max_health

var is_dodging = false
var dodge_timer = 0.0
var dodge_direction = Vector3.ZERO

var can_dodge = true
var dodge_cooldown_timer = 0.0

var can_take_damage = true



func _ready():

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if anim:

		print("Animations found:")
		print(anim.get_animation_list())

		play_animation("rig_idle")

	else:

		print("No AnimationPlayer found")



func _unhandled_input(event):

	if event is InputEventMouseMotion:

		rotate_y(-event.relative.x * mouse_sensitivity)

		spring_arm.rotate_x(event.relative.y * mouse_sensitivity)

		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(30)
		)



func _physics_process(delta):

	# TEST DAMAGE
	if Input.is_key_pressed(KEY_H) and can_take_damage:
		take_damage(10)


	# Gravity
	if not is_on_floor():

		velocity.y -= gravity * delta

	elif velocity.y < 0:

		velocity.y = 0



	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():

		velocity.y = jump_force



	# Movement
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


	var direction = (
		forward * input_dir.y +
		right * input_dir.x
	).normalized()



	# Dodge cooldown
	if not can_dodge:

		dodge_cooldown_timer -= delta

		if dodge_cooldown_timer <= 0:

			can_dodge = true



	# Dodge
	if Input.is_action_just_pressed("dodge") and can_dodge:

		start_dodge(direction)



	if is_dodging:

		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed

		dodge_timer -= delta


		if dodge_timer <= 0:

			is_dodging = false


	else:

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed



	# Animation
	if anim:

		if is_dodging:

			play_animation("rig_dodge")


		elif direction.length() > 0.1:

			play_animation("rig_run")


		else:

			play_animation("rig_idle")



	move_and_slide()



func play_animation(animation_name):

	if not anim:
		return


	if not anim.has_animation(animation_name):
		return


	if anim.current_animation != animation_name:

		anim.play(animation_name)

		var animation = anim.get_animation(animation_name)

		if animation:

			animation.loop_mode = Animation.LOOP_LINEAR



func start_dodge(direction):

	is_dodging = true

	can_dodge = false

	dodge_timer = dodge_duration

	dodge_cooldown_timer = dodge_cooldown


	if direction != Vector3.ZERO:

		dodge_direction = direction

	else:

		dodge_direction = -transform.basis.z



	dodge_direction.y = 0

	dodge_direction = dodge_direction.normalized()








func take_damage(amount):

	can_take_damage = false

	health -= amount

	print("Health:", health)

	flash_red()


	if health <= 0:

		die()



	await get_tree().create_timer(invincibility_time).timeout

	can_take_damage = true



func flash_red():

	var meshes = get_all_meshes(self)


	for mesh in meshes:

		var material = mesh.get_active_material(0)

		if material:

			var new_material = material.duplicate()

			mesh.set_surface_override_material(0, new_material)

			new_material.albedo_color = Color.RED



	await get_tree().create_timer(0.1).timeout



	for mesh in meshes:

		var material = mesh.get_surface_override_material(0)

		if material:

			material.albedo_color = Color.WHITE



func get_all_meshes(node):

	var meshes = []


	for child in node.get_children():

		if child is MeshInstance3D:

			meshes.append(child)


		meshes += get_all_meshes(child)


	return meshes



func die():

	print("Player Died")

	queue_free()
