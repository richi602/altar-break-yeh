class_name Player extends RigidBody3D

const MAP_BOTTOM := -10

const SPEED := 100
const JUMP_FORCE := 100

const KICK_FORCE := 80

@export var head: Node3D

@export var grounded: Area3D
@export var jump_delay: Timer

@export var fleft: Node3D
@export var fkick: FootKick

@export var raycast_camera: RaycastCamera

@export var anim: AnimationPlayer

var spawn_pos: Vector3


func _ready() -> void:
	spawn_pos = global_position

func _input(event: InputEvent) -> void:
	if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_rotate(event.relative)

func _process(delta: float) -> void:
	if Input.is_action_pressed("Jump"):
		_jump()
	if Input.is_action_pressed("Kick"):
		_kick()
	
	if _check_grounded():
		if linear_velocity.length_squared() > 0.1:
			anim.play("Run")
		else:
			anim.play("Idle")
	else:
		anim.play("Jump")
	
		if global_position.y < MAP_BOTTOM:
			global_position = spawn_pos

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("Left"):
		_move(Vector2.LEFT)
	if Input.is_action_pressed("Right"):
		_move(Vector2.RIGHT)
	if Input.is_action_pressed("Forward"):
		_move(Vector2.UP)
	if Input.is_action_pressed("Backward"):
		_move(Vector2.DOWN)


func _check_grounded() -> bool:
	var bods := grounded.get_overlapping_bodies()
	if bods == [self] or bods.is_empty(): return false
	else: return true


func _move(vel: Vector2) -> void:
	apply_central_force(transform.basis.x * vel.x * SPEED)
	apply_central_force(transform.basis.z * vel.y * SPEED)

func _jump() -> void:
	if _check_grounded() and jump_delay.is_stopped():
		apply_central_impulse(Vector3.UP * JUMP_FORCE)
		jump_delay.start()

func _rotate(rot: Vector2) -> void:
	angular_velocity.y -= rot.x * 2
	head.rotation_degrees.x = clamp(head.rotation_degrees.x - rot.y, -75, 75)
	await get_tree().process_frame
	angular_velocity.y = 0


func _kick() -> void:
	if fkick._kick(head.rotation_degrees.x):
		fleft.hide()
		var result := raycast_camera._get_result(3)
		
		if not result.is_empty():
			var obj = result.collider
			
			if obj is AI:
				obj._pushed(-fkick.global_transform.basis.y * KICK_FORCE)


func _on_kick_finish_anim() -> void:
	fleft.show()
