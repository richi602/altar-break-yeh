extends Area3D


# =========================
# PROJECTILE
# =========================

@export var speed = 80.0
@export var damage = 10.0
@export var projectile_size = 1.0
@export var max_lifetime = 6.0


# =========================
# NORMAL HOMING
# =========================

@export var homing_strength = 6.0


# =========================
# FINISHER SPHERE
# =========================

@export var orbit_radius = 4.5
@export var orbit_follow_speed = 12.0
@export var orbit_rotation_speed = 3.5

@export var form_time = 0.25
@export var orbit_time = 0.40
@export var strike_delay = 0.055


# =========================
# STRIKE
# =========================

@export var strike_speed = 120.0
@export var strike_homing_strength = 30.0
@export var target_height = 1.5


# =========================
# JUGGLE
# =========================

@export var juggle_stun_time = 0.18
@export var juggle_knockback = 3.0
@export var juggle_launch_force = 4.5


# =========================
# FINAL HIT
# =========================

@export var final_stun_time = 0.30
@export var final_knockback = 45.0
@export var final_launch_force = 8.0


# =========================
# REFERENCES
# =========================

@onready var projectile_mesh: MeshInstance3D = $MeshInstance3D


# =========================
# STATES
# =========================

enum FinisherState {

	NORMAL,

	FORMING,

	ORBITING,

	WAITING_TO_STRIKE,

	STRIKING
}


var finisher_state = FinisherState.NORMAL


# =========================
# VARIABLES
# =========================

var direction = Vector3.ZERO
var target = null

var lifetime = 0.0
var state_timer = 0.0

var has_hit = false


# =========================
# FINISHER DATA
# =========================

var is_finisher_projectile = false

var finisher_id = -1
var finisher_hit_count = 8

var orbit_index = 0
var orbit_count = 8


# =========================
# READY
# =========================

func _ready():
	add_to_group("player_projectiles")

	scale = Vector3.ONE * projectile_size

	make_projectile_visible()


	if is_finisher_projectile:

		finisher_state = FinisherState.FORMING


# =========================
# FORCE VISUAL
# =========================

func make_projectile_visible():

	if projectile_mesh == null:

		print("ERROR: Finisher MeshInstance3D not found!")

		return


	projectile_mesh.visible = true


	if projectile_mesh.mesh == null:

		var sphere = SphereMesh.new()

		sphere.radius = 0.5
		sphere.height = 1.0

		projectile_mesh.mesh = sphere


	var material = StandardMaterial3D.new()


	var finisher_color = Color(
		1.0,
		0.20,
		0.95,
		1.0
	)


	material.albedo_color = finisher_color


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.emission_enabled = true

	material.emission = finisher_color

	material.emission_energy_multiplier = 2.5


	projectile_mesh.material_override = material


# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):

	if has_hit:
		return


	lifetime += delta


	if lifetime >= max_lifetime:

		queue_free()

		return


	if is_finisher_projectile:

		update_finisher(delta)

	else:

		update_normal_homing(delta)


# =========================
# NORMAL HOMING
# =========================

func update_normal_homing(delta):

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


	global_position += (
		direction
		* speed
		* delta
	)


# =========================
# FINISHER
# =========================

func update_finisher(delta):

	if not is_instance_valid(target):

		queue_free()

		return


	state_timer += delta


	match finisher_state:


		FinisherState.FORMING:

			move_to_orbit_position(delta)


			if state_timer >= form_time:

				state_timer = 0.0

				finisher_state = (
					FinisherState.ORBITING
				)


		FinisherState.ORBITING:

			move_to_orbit_position(delta)


			if state_timer >= orbit_time:

				state_timer = 0.0

				finisher_state = (
					FinisherState.WAITING_TO_STRIKE
				)


		FinisherState.WAITING_TO_STRIKE:

			move_to_orbit_position(delta)


			var my_strike_time = (
				strike_delay
				* float(orbit_index)
			)


			if state_timer >= my_strike_time:

				state_timer = 0.0


				var aim_position = (
					target.global_position
					+
					Vector3.UP * target_height
				)


				direction = (
					aim_position
					- global_position
				).normalized()


				finisher_state = (
					FinisherState.STRIKING
				)


		FinisherState.STRIKING:

			strike_target(delta)


# =========================
# SPHERE POSITION
# =========================

func move_to_orbit_position(delta):

	if not is_instance_valid(target):
		return


	var center = (
		target.global_position
		+
		Vector3.UP * target_height
	)


	var safe_orbit_count = max(
		orbit_count,
		1
	)


	var index_ratio = (
		(
			float(orbit_index)
			+ 0.5
		)
		/
		float(safe_orbit_count)
	)


	var phi = acos(
		1.0
		- 2.0 * index_ratio
	)


	var golden_angle = (
		PI
		*
		(
			3.0
			- sqrt(5.0)
		)
	)


	var theta = (
		golden_angle
		* float(orbit_index)
		+
		lifetime
		* orbit_rotation_speed
	)


	var sphere_position = Vector3(

		sin(phi) * cos(theta),

		cos(phi),

		sin(phi) * sin(theta)
	)


	var desired_position = (
		center
		+
		sphere_position * orbit_radius
	)


	global_position = global_position.lerp(
		desired_position,
		clamp(
			orbit_follow_speed * delta,
			0.0,
			1.0
		)
	)


# =========================
# STRIKE
# =========================

func strike_target(delta):

	if not is_instance_valid(target):

		queue_free()

		return


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
			strike_homing_strength * delta,
			0.0,
			1.0
		)
	).normalized()


	global_position += (
		direction
		* strike_speed
		* delta
	)


# =========================
# COLLISION
# =========================

func _on_body_entered(body):

	if has_hit:
		return


	if body.name == "Player":
		return


	# =========================
	# FINISHER
	# =========================

	if is_finisher_projectile:

		if (
			finisher_state
			!= FinisherState.STRIKING
		):

			return


		if body != target:
			return


		if not is_instance_valid(target):

			queue_free()

			return


		has_hit = true


		print(
			"FINISHER STRIKE:",
			orbit_index + 1
		)


		if body.has_method(
			"take_damage"
		):

			body.take_damage(
				damage
			)


		if body.has_method(
			"receive_finisher_hit"
		):

			body.receive_finisher_hit(
				finisher_id,
				finisher_hit_count,
				direction,

				juggle_knockback,
				juggle_launch_force,
				juggle_stun_time,

				final_knockback,
				final_launch_force,
				final_stun_time
			)


		queue_free()

		return


	# =========================
	# NORMAL USE
	# =========================

	if body.has_method(
		"take_damage"
	):

		has_hit = true


		body.take_damage(
			damage
		)


		queue_free()

		return


	has_hit = true

	queue_free()
