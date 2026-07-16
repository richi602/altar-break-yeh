class_name Main extends Node3D

@export var player: Player
@export var ai: Array[AI]


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	for ai_ in ai:
		ai_._set_dest(player.head.global_position)
	
	if Input.is_action_just_pressed("ui_cancel"):
		match DisplayServer.mouse_get_mode():
			DisplayServer.MOUSE_MODE_VISIBLE:
				DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
			DisplayServer.MOUSE_MODE_CAPTURED:
				DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
