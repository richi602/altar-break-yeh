extends CharacterBody3D

@export var mouse_sensitivity = 0.005
@export var speed = 5.0
@export var jump_force = 8.0
@export var gravity = 20.0

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

    var direction = (forward * input_dir.y + right * input_dir.x).normalized()

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed


    move_and_slide()
