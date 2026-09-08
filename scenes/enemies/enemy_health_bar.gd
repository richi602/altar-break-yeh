extends Node3D


@onready var fill = $Fill

var starting_fill_scale: Vector3


func _ready():

	# Remember how big YOU made the Fill in the editor.
	starting_fill_scale = fill.scale



func _process(_delta):

	var camera = get_viewport().get_camera_3d()

	if camera:

		look_at(
			camera.global_position,
			Vector3.UP,
			true
		)



func set_health(current_health, max_health):

	if fill == null:
		return


	var percent = current_health / max_health

	percent = clamp(
		percent,
		0.0,
		1.0
	)


	fill.scale.x = starting_fill_scale.x * percent
