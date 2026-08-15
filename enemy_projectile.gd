extends Area3D


# =============================================================================
# PROJECTILE SETTINGS
# =============================================================================

@export var speed = 55.0
@export var damage = 20.0
@export var lifetime = 6.0

var direction = Vector3.ZERO
var already_hit = false


# =============================================================================
# START
# =============================================================================

func _ready():
	# This is important:
	# Lucian's F glass wall looks for this group.
	add_to_group("enemy_projectiles")

	body_entered.connect(_on_body_entered)

	# Delete projectile if it flies around too long.
	await get_tree().create_timer(lifetime).timeout

	if is_instance_valid(self):
		queue_free()


# =============================================================================
# MOVEMENT
# =============================================================================

func _physics_process(delta):
	if direction.length() <= 0.01:
		return

	global_position += direction.normalized() * speed * delta


# =============================================================================
# COLLISION
# =============================================================================

func _on_body_entered(body):
	if already_hit:
		return

	# Don't hit enemies.
	if body.is_in_group("enemies"):
		return

	# Hit Lucian / anything with take_damage().
	if body.has_method("take_damage"):
		already_hit = true
		body.take_damage(damage)
		queue_free()
		return

	# Destroy projectile when it hits the world.
	if body is StaticBody3D:
		already_hit = true
		queue_free()
