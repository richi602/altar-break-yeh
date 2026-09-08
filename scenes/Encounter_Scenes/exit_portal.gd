extends Area3D

@export_file("*.tscn") var next_scene_path := ""

var used := false

@onready var label: Label3D = get_node_or_null("Label3D")


func _ready():
	monitoring = true

	if label:
		label.text = "EXIT ALTAR"

	if not body_entered.is_connected(on_body_entered):
		body_entered.connect(on_body_entered)


func on_body_entered(body: Node):
	if used:
		return

	if not body.is_in_group("players"):
		return

	used = true

	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
		return

	if label:
		label.text = "RUN COMPLETE"

	print("RUN COMPLETE")
