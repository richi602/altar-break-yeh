extends Area3D

signal chosen(reward_id: String, picker: Node)

var reward_id := ""
var reward_title := ""
var reward_description := ""
var taken := false

@onready var label: Label3D = get_node_or_null("Label3D")


func _ready():
	monitoring = true

	if not body_entered.is_connected(on_body_entered):
		body_entered.connect(on_body_entered)

	refresh_text()


func configure(id: String, title: String, description: String):
	reward_id = id
	reward_title = title
	reward_description = description
	refresh_text()


func refresh_text():
	if label:
		label.text = "%s\n%s" % [
			reward_title,
			reward_description
		]


func on_body_entered(body: Node):
	if taken:
		return

	if not body.is_in_group("players"):
		return

	# Mark it taken immediately so this reward cannot trigger twice.
	taken = true

	# Godot blocks changing Area3D.monitoring directly while body_entered
	# is being processed, so defer the physics change until the signal ends.
	set_deferred("monitoring", false)

	chosen.emit(reward_id, body)
