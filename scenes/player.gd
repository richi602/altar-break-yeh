extends CharacterBody3D

@export var dodge_speed = 60.0
@export var dodge_duration = 0.2
@export var dodge_cooldown = 0.5

@export var mouse_sensitivity = 0.005
@export var speed = 40.0
@export var jump_force = 8.0
@export var gravity = 20.0

var is_dodging = false
var dodge_timer = 0.0
var dodge_direction = Vector3.ZERO
var can_dodge = true
var dodge_cooldown_timer = 0.0

@onready var spring_arm = $SpringArm3D


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)

		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(30)
		)


func _physics_process(delta):

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0


	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force


	# Movement input
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

	var direction = (forward * input_dir.y + right * input_dir.x).normalized()


	# Dodge cooldown
	if not can_dodge:
		dodge_cooldown_timer -= delta

		if dodge_cooldown_timer <= 0:
			can_dodge = true


	# Start dodge
	if Input.is_action_just_pressed("dodge") and can_dodge:
		start_dodge(direction)


	# Dodge movement
	if is_dodging:
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed

		dodge_timer -= delta

		if dodge_timer <= 0:
			is_dodging = false

	else:
		# Normal movement
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed


	move_and_slide()



func start_dodge(direction):
	is_dodging = true
	can_dodge = false

	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown

	# Dodge where moving, otherwise dodge forward
	if direction != Vector3.ZERO:
		dodge_direction = direction
	else:
		dodge_direction = -transform.basis.z

	dodge_direction.y = 0
	dodge_direction = dodge_direction.normalized()
