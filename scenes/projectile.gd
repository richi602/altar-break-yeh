extends Node3D

@export var speed = 10.
@export var damage = 10.



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += Vector3.FORWARD * speed * delta
	


func _on_area_3d_body_entered(body: Node3D) -> void:
	print(body.name)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
