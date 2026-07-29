extends Area3D


@export var speed = 80.0
@export var damage = 10
@export var projectile_size = 1.0


var direction = Vector3.ZERO



func _ready():

	scale = Vector3.ONE * projectile_size



func _physics_process(delta):

	global_position += direction * speed * delta



func _on_area_3d_body_entered(body):

	print("Hit:", body.name)


	if body.has_method("take_damage"):

		body.take_damage(damage)


	queue_free()
