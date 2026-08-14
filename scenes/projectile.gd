extends Area3D


# =========================
# PROJECTILE SETTINGS
# =========================

@export var speed = 80.0
@export var damage = 10.0
@export var projectile_size = 1.0
@export var max_lifetime = 5.0


# =========================
# HOMING
# =========================

@export var homing_strength = 2.5
@export var target_height = 1.2


# =========================
# HIT EFFECT
# =========================

@export var stun_time = 0.12
@export var knockback_strength = 8.0
@export var launch_force = 0.0


# =========================
# VARIABLES
# =========================

var direction = Vector3.ZERO
var target = null

var lifetime = 0.0
var has_hit = false


# =========================
# READY
# =========================

func _ready():

	scale = (
		Vector3.ONE
		* projectile_size
	)


	# =========================
	# GUARANTEE VISIBILITY
	# =========================

	var mesh_instance = get_node_or_null(
		"MeshInstance3D"
	)


	if mesh_instance:

		mesh_instance.visible = true


		# Force projectile onto every
		# possible 3D render layer.
		for layer_number in range(1, 21):

			mesh_instance.set_layer_mask_value(
				layer_number,
				true
			)


		print(
			"NORMAL PROJECTILE MESH FOUND"
		)

	else:

		print(
			"ERROR: NORMAL PROJECTILE MESH MISSING"
		)


# =========================
# MOVEMENT
# =========================

func _physics_process(delta):

	if has_hit:

		return


	# =========================
	# LIFETIME
	# =========================

	lifetime += delta


	if lifetime >= max_lifetime:

		queue_free()

		return


	# =========================
	# HOMING
	# =========================

	if is_instance_valid(target):

		var aim_position = (
			target.global_position
			+
			Vector3.UP * target_height
		)


		var target_direction = (
			aim_position
			- global_position
		).normalized()


		direction = direction.lerp(
			target_direction,
			clamp(
				homing_strength * delta,
				0.0,
				1.0
			)
		).normalized()


	# =========================
	# MOVE
	# =========================

	global_position += (
		direction
		* speed
		* delta
	)


# =========================
# BODY COLLISION
# =========================

func _on_body_entered(body):

	if has_hit:

		return


	# =========================
	# IGNORE PLAYER
	# =========================

	if body.name == "Player":

		return


	# =========================
	# ENEMY
	# =========================

	if body.has_method(
		"take_damage"
	):

		has_hit = true


		body.take_damage(
			damage
		)


		if body.has_method(
			"apply_hit_effect"
		):

			body.apply_hit_effect(
				direction,
				knockback_strength,
				launch_force,
				stun_time
			)


		queue_free()

		return


	# =========================
	# TERRAIN
	# =========================

	has_hit = true

	queue_free()
