class_name AI extends RigidBody3D

const MAP_BOTTOM := -10

const SPEED := 50
const JUMP_HEIGHT_TRIGGER := 10
const JUMP_FORCE := 100

@export var head: Node3D

@export var grounded: Area3D
@export var jump_delay: Timer

@export var nav: NavigationAgent3D

@export var anim: AnimationPlayer

var spawn_pos: Vector3

var target_pos: Vector3


func _ready() -> void:
	spawn_pos = global_position

func _process(delta: float) -> void:
	if _check_grounded():
		if linear_velocity.length_squared() > 0.1:
			anim.play("Run")
		else:
			anim.play("Idle")
	else:
		anim.play("Jump")
	
		if global_position.y < MAP_BOTTOM:
			global_position = spawn_pos

func _check_grounded() -> bool:
	var bods := grounded.get_overlapping_bodies()
	if bods == [self] or bods.is_empty(): return false
	else: return true

func _physics_process(delta: float) -> void:
	_navigation()
	_rotate(target_pos)

func _navigation() -> void:
	if nav.is_navigation_finished():
		return
	
	var pos := nav.get_next_path_position()
	var dir := global_position.direction_to(pos)
	
	apply_central_force(dir * SPEED)

func _rotate(to: Vector3) -> void:
	look_at(Vector3(to.x, global_position.y, to.z))
	var head_pos := head.global_position
	head.look_at(target_pos)


func _set_dest(pos: Vector3) -> void:
	target_pos = pos
	nav.target_position = target_pos
	
	if target_pos.y > global_position.y + JUMP_HEIGHT_TRIGGER:
		_jump()


func _jump() -> void:
	if _check_grounded() and jump_delay.is_stopped():
		apply_central_impulse(Vector3.UP * JUMP_FORCE)
		jump_delay.start()


func _pushed(vel: Vector3) -> void:
	apply_central_impulse(vel)
