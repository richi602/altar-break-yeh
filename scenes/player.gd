extends CharacterBody3D

# ============================================================
# MOVEMENT
# ============================================================

@export var speed = 40.0
@export var jump_force = 25.0
@export var gravity = 50.0
@export var dodge_speed = 100.0
@export var dodge_duration = 0.10
@export var dodge_cooldown = 0.5

var is_dodging = false
var dodge_timer = 0.0
var dodge_cooldown_timer = 0.0
var dodge_direction = Vector3.ZERO
var can_dodge = true


# ============================================================
# CAMERA / HEALTH / REFERENCES
# ============================================================

@export var mouse_sensitivity = 0.003
@export var vertical_mouse_sensitivity = 0.002
@export var camera_pitch_min = -45.0
@export var camera_pitch_max = 35.0
@export var camera_pitch_smooth_speed = 20.0
@export var camera_distance = 6.0
@export var camera_collision_margin = 0.25

@export var max_health = 10000
@export var hit_invincibility_time = 0.3

@onready var camera_pivot = find_child("CameraPivot", true, false)
@onready var spring_arm = find_child("SpringArm3D", true, false)
@onready var camera = find_child("Camera3D", true, false)
@onready var health_bar = find_child("HealthBar", true, false)
@onready var anim = find_child("AnimationPlayer", true, false)

var camera_pitch = 0.0
var camera_pitch_target = 0.0
var health = max_health
var dodge_invincible = false
var hit_invincible = false


# ============================================================
# LOCK ON
# ============================================================

@export var lock_range = 65.0
@export var lock_turn_speed = 5.0

var locked_enemy = null
var lock_targets = []
var lock_index = 0
var lock_reticle = null


# ============================================================
# WALK OF EMO BAND
# ============================================================

@export var teleport_range = 100.0
@export var teleport_cooldown = 0.35
@export var teleport_side_offset = 2.0
@export var teleport_height_offset = 0.5

@export var teleport_target_screen_radius = 0.30
@export var teleport_center_priority = 3.5
@export var teleport_distance_priority = 0.15

@export var teleport_position_checks = 8
@export var teleport_use_fallback = true

@export var teleport_camera_duration = 0.45
@export var teleport_camera_vertical_strength = 12.0

@export var teleport_low_gravity_duration = 0.65
@export var teleport_gravity_multiplier = 0.20

@export var teleport_followup_window = 0.70

var teleport_cooldown_timer = 0.0
var teleport_camera_timer = 0.0
var teleport_followup_timer = 0.0
var low_gravity_timer = 0.0

var teleport_focus_target = null
var teleport_camera_target = null


# ============================================================
# GLASS
# ============================================================

# SPACE — big arena
@export var big_pane_width = 24.0
@export var big_pane_depth = 24.0
@export var big_pane_thickness = 0.22
@export var big_pane_lifetime = 5.0
@export var big_pane_vertical_offset = 1.35
@export var big_pane_player_lift = 2.0
@export var big_pane_enemy_lift = 1.5

# SHIFT — movement panes
@export var glass_walk_gravity_multiplier = 0.12
@export var glass_walk_max_fall_speed = -3.0

@export var glass_pane_spawn_interval = 0.10
@export var glass_pane_lifetime = 2.5
@export var glass_pane_max_count = 24

@export var glass_pane_forward_offset = 0.75
@export var glass_pane_vertical_offset = 1.15

@export var glass_pane_width = 3.2
@export var glass_pane_depth = 3.2
@export var glass_pane_thickness = 0.14

# Shatter
@export var pane_impact_arm_delay = 0.10
@export var pane_shatter_shard_count = 12
@export var pane_shatter_distance = 5.0
@export var pane_shatter_duration = 0.35

@export var small_pane_ult_charge = 10.0
@export var big_pane_ult_charge = 30.0

var glass_walk_active = false
var glass_walk_needs_initial_pane = false
var glass_pane_spawn_timer = 0.0

var active_glass_panes = []

var small_glass_material
var big_glass_material

var shard_materials = []
var ult_wave_materials = []


# ============================================================
# ULT — NO ONE UNDERSTANDS MY ART
# ============================================================

@export var ult_max_charge = 100.0

# MUCH bigger than before.
@export var ult_radius = 55.0
@export var ult_visual_radius = 65.0

@export var ult_weak_enemy_health = 100.0

# Enemies rise before exploding.
@export var ult_lift_speed = 11.0
@export var ult_lift_time = 0.24

# Elite / boss hit.
@export var ult_strong_enemy_damage = 80.0
@export var ult_knockback = 26.0
@export var ult_launch_force = 12.0
@export var ult_stun_time = 0.85

# Explosion insanity.
@export var ult_enemy_shard_count = 28
@export var ult_enemy_piece_distance = 12.0
@export var ult_center_shard_count = 64
@export var ult_screen_flash_time = 0.22

var ult_charge = 0.0
var ult_ready = false

var ult_ui
var ult_label
var ult_bar


# ============================================================
# SLAM
# ============================================================

@export var slam_windup_time = 0.12
@export var slam_recovery_time = 0.16

@export var slam_down_force = 85.0
@export var slam_stun_time = 0.35

@export var slam_aoe_radius = 8.0
@export var slam_aoe_damage = 30.0
@export var slam_aoe_knockback = 28.0
@export var slam_aoe_launch_force = 8.0
@export var slam_aoe_stun_time = 0.35

@export var slam_impact_arm_delay = 0.08

@export var slam_popup_projectile_count = 8
@export var slam_popup_projectile_radius = 2.5
@export var slam_popup_projectile_height = 0.20
@export var slam_popup_projectile_size = 0.60
@export var slam_popup_projectile_damage = 2.0
@export var slam_popup_delay = 0.06

@export var slam_popup_gravity_reference = 20.0
@export var slam_popup_min_height = 2.0
@export var slam_popup_max_up_speed = 32.0

var slam_target = null
var pending_slam_target = null
var slam_impact_target = null

var slam_windup_timer = 0.0
var slam_recovery_timer = 0.0
var slam_impact_arm_timer = 0.0


# ============================================================
# PROJECTILES / COMBO
# ============================================================

@export var projectile_scene: PackedScene
@export var homing_projectile_scene: PackedScene

@export var projectile_spawn_height = 1.5
@export var projectile_spawn_forward = 1.5
@export var projectile_spawn_side = 0.0

@export var normal_projectile_target_range = 65.0

@export var combo_reset_time = 1.0
@export var combo_hold_delay = 0.10

@export var finisher_projectile_count = 8
@export var finisher_projectile_damage = 0.3

@export var finisher_setup_launch_force = 7.0
@export var finisher_setup_hold_time = 1.5
@export var finisher_setup_stun_time = 1.5
@export var finisher_target_range = 90.0

var attacking = false
var combo_step = 0
var combo_timer = 0.0
var combo_hold_timer = 0.0
var finisher_id_counter = 0

var followup_ui
var followup_bar


# ============================================================
# READY / INPUT / MAIN LOOP
# ============================================================

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if camera_pivot:
		camera_pitch = camera_pivot.rotation.x
		camera_pitch_target = camera_pitch

	if spring_arm:
		spring_arm.spring_length = camera_distance
		spring_arm.margin = camera_collision_margin
		spring_arm.add_excluded_object(get_rid())

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	lock_reticle = get_tree().get_first_node_in_group("lock_reticle")

	if lock_reticle:
		lock_reticle.hide()

	small_glass_material = make_material(
		Color(0.55, 0.72, 1.0, 0.32),
		1.5
	)

	big_glass_material = make_material(
		Color(0.45, 0.85, 1.0, 0.45),
		3.0
	)

	shard_materials = [
		make_material(
			Color(0.35, 0.85, 1.0, 1.0),
			6.0
		),
		make_material(
			Color(1.0, 1.0, 1.0, 1.0),
			8.0
		),
		make_material(
			Color(1.0, 0.2, 0.75, 1.0),
			7.0
		)
	]

	ult_wave_materials = [
		make_material(
			Color(0.35, 0.85, 1.0, 0.16),
			8.0
		),
		make_material(
			Color(1.0, 1.0, 1.0, 0.12),
			10.0
		),
		make_material(
			Color(1.0, 0.2, 0.75, 0.14),
			9.0
		)
	]

	setup_followup_ui()
	setup_ult_ui()

	if anim:
		play_animation("rig_idle")


func _unhandled_input(event):

	if event is InputEventMouseMotion:

		rotate_y(
			-event.relative.x
			* mouse_sensitivity
		)

		camera_pitch_target = clamp(
			camera_pitch_target
			+
			event.relative.y
			*
			vertical_mouse_sensitivity,
			deg_to_rad(camera_pitch_min),
			deg_to_rad(camera_pitch_max)
		)


	if (
		event is InputEventMouseButton
		and
		event.pressed
	):

		match event.button_index:

			MOUSE_BUTTON_RIGHT:
				try_airborne_teleport()

			MOUSE_BUTTON_MIDDLE:
				toggle_lock()

			MOUSE_BUTTON_WHEEL_UP:
				switch_target(1)

			MOUSE_BUTTON_WHEEL_DOWN:
				switch_target(-1)


	# Q = ULT
	if (
		event is InputEventKey
		and
		event.pressed
		and
		not event.echo
		and
		event.keycode == KEY_Q
	):

		try_activate_ult()


func _physics_process(delta):

	update_timers(delta)
	update_slam_windup(delta)

	var move_direction = (
		get_movement_direction()
	)

	update_glass_walk_state()

	var used_followup_jump = (
		update_followup_input()
	)

	update_attack_input()
	update_gravity(delta)
	update_jump(used_followup_jump)

	update_dodge(
		move_direction,
		delta
	)

	update_glass_walk(
		move_direction
	)

	update_animation(
		move_direction
	)

	move_and_slide()

	update_slam_impact(delta)

	update_lock_camera(delta)
	update_teleport_camera(delta)
	update_camera(delta)

	update_lock_reticle()
	update_followup_ui()


func update_timers(delta):

	teleport_cooldown_timer = max(
		teleport_cooldown_timer - delta,
		0.0
	)

	low_gravity_timer = max(
		low_gravity_timer - delta,
		0.0
	)

	glass_pane_spawn_timer = max(
		glass_pane_spawn_timer - delta,
		0.0
	)

	combo_hold_timer = max(
		combo_hold_timer - delta,
		0.0
	)

	slam_recovery_timer = max(
		slam_recovery_timer - delta,
		0.0
	)


	if teleport_followup_timer > 0.0:

		teleport_followup_timer -= delta

		if teleport_followup_timer <= 0.0:
			clear_teleport_followup()


	if combo_timer > 0.0:

		combo_timer -= delta

	else:

		combo_step = 0


	if not can_dodge:

		dodge_cooldown_timer -= delta

		if dodge_cooldown_timer <= 0.0:
			can_dodge = true


# ============================================================
# MOVEMENT / CAMERA
# ============================================================

func get_movement_direction():

	var input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var forward = -transform.basis.z
	var right = -transform.basis.x

	forward.y = 0.0
	right.y = 0.0

	return (
		forward.normalized() * input.y
		+
		right.normalized() * input.x
	).normalized()


func update_gravity(delta):

	if is_on_floor():

		if velocity.y < 0.0:
			velocity.y = 0.0

		return


	var gravity_scale = 1.0


	if low_gravity_timer > 0.0:

		gravity_scale = min(
			gravity_scale,
			teleport_gravity_multiplier
		)


	if glass_walk_active:

		gravity_scale = min(
			gravity_scale,
			glass_walk_gravity_multiplier
		)


	velocity.y -= (
		gravity
		*
		gravity_scale
		*
		delta
	)


	if glass_walk_active:

		velocity.y = max(
			velocity.y,
			glass_walk_max_fall_speed
		)


func update_jump(followup_used_jump):

	if (
		not followup_used_jump
		and
		Input.is_action_just_pressed("jump")
		and
		is_on_floor()
	):

		velocity.y = jump_force


func update_dodge(
	direction,
	delta
):

	if (
		Input.is_action_just_pressed("dodge")
		and
		can_dodge
	):

		start_dodge(direction)


	if is_dodging:

		velocity.x = (
			dodge_direction.x
			*
			dodge_speed
		)

		velocity.z = (
			dodge_direction.z
			*
			dodge_speed
		)

		dodge_timer -= delta

		if dodge_timer <= 0.0:
			end_dodge()

	else:

		velocity.x = (
			direction.x
			*
			speed
		)

		velocity.z = (
			direction.z
			*
			speed
		)


func start_dodge(direction):

	is_dodging = true
	can_dodge = false
	dodge_invincible = true

	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown

	if direction != Vector3.ZERO:

		dodge_direction = direction

	else:

		dodge_direction = (
			-transform.basis.z
		)

	dodge_direction.y = 0.0

	dodge_direction = (
		dodge_direction.normalized()
	)

	flash_blue()


func end_dodge():

	is_dodging = false
	dodge_invincible = false

	remove_flash()


func update_camera(delta):

	if camera_pivot:

		camera_pitch = lerp_angle(
			camera_pitch,
			camera_pitch_target,
			clamp(
				camera_pitch_smooth_speed
				*
				delta,
				0.0,
				1.0
			)
		)

		camera_pivot.rotation.x = (
			camera_pitch
		)


# ============================================================
# FOLLOW-UP / ATTACK INPUT
# ============================================================

func update_followup_input():

	if (
		teleport_followup_timer <= 0.0
		or
		not is_instance_valid(
			teleport_focus_target
		)
	):

		return false


	# SPACE = huge glass arena
	if Input.is_action_just_pressed("jump"):

		create_big_glass_pane()

		return true


	return false


func clear_teleport_followup():

	teleport_followup_timer = 0.0
	slam_target = null


func update_attack_input():

	if (
		slam_windup_timer > 0.0
		or
		slam_recovery_timer > 0.0
	):

		return


	# LMB = slam after teleport
	if (
		teleport_followup_timer > 0.0
		and
		is_instance_valid(slam_target)
		and
		Input.is_action_just_pressed("attack")
	):

		start_air_slam()

		return


	# Normal combo
	if (
		Input.is_action_pressed("attack")
		and
		combo_hold_timer <= 0.0
		and
		not attacking
	):

		attack()

		combo_hold_timer = (
			combo_hold_delay
		)


	# Damage test
	if Input.is_key_pressed(KEY_H):

		take_damage(10)


# ============================================================
# GLASS MOVEMENT / ARENA
# ============================================================

func update_glass_walk_state():

	var was_active = glass_walk_active

	glass_walk_active = (
		Input.is_key_pressed(KEY_SHIFT)
		and
		(
			not is_on_floor()
			or
			is_on_glass()
		)
	)

	if (
		glass_walk_active
		and
		not was_active
	):

		glass_walk_needs_initial_pane = true


func is_on_glass():

	if not is_on_floor():
		return false


	for i in range(
		get_slide_collision_count()
	):

		var collider = (
			get_slide_collision(i)
			.get_collider()
		)

		if (
			collider
			and
			collider.is_in_group(
				"lucian_glass_panes"
			)
		):

			return true


	return false


func update_glass_walk(direction):

	if not glass_walk_active:
		return


	if glass_walk_needs_initial_pane:

		spawn_small_pane(direction)

		glass_walk_needs_initial_pane = false

	elif (
		direction.length() > 0.05
		and
		glass_pane_spawn_timer <= 0.0
	):

		spawn_small_pane(direction)


func spawn_small_pane(direction):

	var offset = Vector3.ZERO

	if direction.length() > 0.05:

		offset = (
			direction.normalized()
			*
			glass_pane_forward_offset
		)


	create_glass_pane(
		global_position
		+
		offset
		+
		Vector3.DOWN
		*
		glass_pane_vertical_offset,

		Vector3(
			glass_pane_width,
			glass_pane_thickness,
			glass_pane_depth
		),

		glass_pane_lifetime,
		small_glass_material,
		"LucianGlassPane",
		small_pane_ult_charge
	)


	glass_pane_spawn_timer = (
		glass_pane_spawn_interval
	)


func create_big_glass_pane():

	if not is_instance_valid(
		teleport_focus_target
	):

		return


	var enemy = teleport_focus_target


	var position = (
		global_position
		+
		enemy.global_position
	) * 0.5


	position.y = (
		min(
			global_position.y,
			enemy.global_position.y
		)
		-
		big_pane_vertical_offset
	)


	create_glass_pane(
		position,

		Vector3(
			big_pane_width,
			big_pane_thickness,
			big_pane_depth
		),

		big_pane_lifetime,
		big_glass_material,
		"LucianGlassArena",
		big_pane_ult_charge
	)


	velocity.y = max(
		velocity.y,
		big_pane_player_lift
	)


	low_gravity_timer = max(
		low_gravity_timer,
		teleport_low_gravity_duration
	)


	if enemy is CharacterBody3D:

		enemy.velocity.y = max(
			enemy.velocity.y,
			big_pane_enemy_lift
		)


	teleport_camera_target = enemy

	teleport_camera_timer = max(
		teleport_camera_timer,
		0.30
	)


	clear_teleport_followup()


# ============================================================
# GLASS CREATION / SHATTER
# ============================================================

func make_material(
	color,
	emission
):

	var material = StandardMaterial3D.new()

	material.albedo_color = color

	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	material.emission_enabled = true

	material.emission = Color(
		color.r,
		color.g,
		color.b
	)

	material.emission_energy_multiplier = emission

	return material


func create_glass_pane(
	position,
	size,
	lifetime,
	material,
	pane_name,
	charge
):

	clean_glass_panes()


	if (
		active_glass_panes.size()
		>=
		glass_pane_max_count
	):

		remove_glass_pane(
			active_glass_panes.pop_front()
		)


	var pane = StaticBody3D.new()

	pane.name = pane_name

	pane.add_to_group(
		"lucian_glass_panes"
	)

	pane.set_meta(
		"shattered",
		false
	)

	pane.set_meta(
		"armed",
		false
	)

	pane.set_meta(
		"ult_charge",
		charge
	)

	pane.set_meta(
		"pane_size",
		size
	)


	get_tree().current_scene.add_child(
		pane
	)

	pane.global_position = position
	pane.rotation.y = rotation.y


	# Solid pane collision
	var shape = BoxShape3D.new()

	shape.size = size


	var collision = CollisionShape3D.new()

	collision.shape = shape

	pane.add_child(
		collision
	)


	# Pane visual
	var mesh = BoxMesh.new()

	mesh.size = size


	var visual = MeshInstance3D.new()

	visual.name = "GlassVisual"
	visual.mesh = mesh

	visual.material_override = material

	pane.add_child(
		visual
	)


	# Enemy impact sensor
	var sensor = Area3D.new()

	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	sensor.monitoring = true


	var sensor_shape = BoxShape3D.new()

	sensor_shape.size = Vector3(
		size.x,
		max(
			size.y + 0.70,
			0.70
		),
		size.z
	)


	var sensor_collision = CollisionShape3D.new()

	sensor_collision.shape = sensor_shape

	sensor.add_child(
		sensor_collision
	)

	pane.add_child(
		sensor
	)


	sensor.body_entered.connect(
		_on_pane_body_entered.bind(
			pane
		)
	)


	active_glass_panes.append(
		pane
	)

	arm_glass_pane(
		pane
	)

	expire_glass_pane(
		pane,
		lifetime
	)


func arm_glass_pane(pane):

	await get_tree().create_timer(
		pane_impact_arm_delay
	).timeout

	if is_instance_valid(pane):

		pane.set_meta(
			"armed",
			true
		)


func _on_pane_body_entered(
	body,
	pane
):

	if (
		is_instance_valid(pane)
		and
		is_instance_valid(body)
		and
		body.is_in_group("enemies")
		and
		pane.get_meta("armed", false)
		and
		not pane.get_meta("shattered", false)
	):

		shatter_glass_pane(
			pane,
			true
		)


func shatter_glass_pane(
	pane,
	give_charge = true
):

	if (
		not is_instance_valid(pane)
		or
		pane.get_meta(
			"shattered",
			false
		)
	):

		return


	pane.set_meta(
		"shattered",
		true
	)


	var size = pane.get_meta(
		"pane_size",
		Vector3.ONE
	)


	var shard_scale = clamp(
		max(
			size.x,
			size.z
		)
		/
		8.0,
		0.55,
		2.2
	)


	spawn_shard_burst(
		pane.global_position,
		pane_shatter_shard_count,
		pane_shatter_distance
		*
		shard_scale,
		shard_scale,
		pane_shatter_duration
	)


	if give_charge:

		add_ult_charge(
			float(
				pane.get_meta(
					"ult_charge",
					0.0
				)
			)
		)


	remove_glass_pane(
		pane
	)


func remove_glass_pane(pane):

	if not is_instance_valid(pane):
		return

	active_glass_panes.erase(
		pane
	)

	pane.queue_free()


func expire_glass_pane(
	pane,
	lifetime
):

	await get_tree().create_timer(
		lifetime
	).timeout

	if is_instance_valid(pane):

		remove_glass_pane(
			pane
		)


func clean_glass_panes():

	for pane in active_glass_panes.duplicate():

		if not is_instance_valid(pane):

			active_glass_panes.erase(
				pane
			)


# ============================================================
# SHARD / EXPLOSION FX
# ============================================================

func spawn_shard_burst(
	position,
	count,
	distance,
	size_scale = 1.0,
	duration = 0.45
):

	if shard_materials.is_empty():
		return


	for i in range(
		max(
			count,
			1
		)
	):

		var shard = MeshInstance3D.new()
		var mesh = BoxMesh.new()


		mesh.size = Vector3(
			randf_range(
				0.12,
				0.42
			),
			randf_range(
				0.05,
				0.16
			),
			randf_range(
				0.35,
				0.95
			)
		) * size_scale


		shard.mesh = mesh

		shard.material_override = (
			shard_materials[
				i
				%
				shard_materials.size()
			]
		)


		get_tree().current_scene.add_child(
			shard
		)


		var angle = (
			TAU
			*
			float(i)
			/
			float(
				max(
					count,
					1
				)
			)
			+
			randf_range(
				-0.18,
				0.18
			)
		)


		var direction = Vector3(
			cos(angle),
			randf_range(
				0.15,
				0.95
			),
			sin(angle)
		).normalized()


		shard.global_position = (
			position
			+
			direction
			*
			randf_range(
				0.1,
				1.2
			)
			*
			size_scale
		)


		shard.rotation = Vector3(
			randf() * PI,
			randf() * PI,
			randf() * PI
		)


		var tween = (
			shard.create_tween()
		)

		tween.set_parallel(
			true
		)


		tween.tween_property(
			shard,
			"global_position",
			shard.global_position
			+
			direction
			*
			distance,
			duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)


		tween.tween_property(
			shard,
			"rotation",
			shard.rotation
			+
			Vector3(
				randf_range(
					2.0,
					6.0
				),
				randf_range(
					2.0,
					6.0
				),
				randf_range(
					2.0,
					6.0
				)
			),
			duration
		)


		tween.tween_property(
			shard,
			"scale",
			Vector3.ZERO,
			duration
		)


		tween.finished.connect(
			Callable(
				shard,
				"queue_free"
			)
		)


func spawn_flash_sphere(
	position,
	radius,
	material,
	duration = 0.28
):

	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()

	mesh.radius = 1.0
	mesh.height = 2.0

	sphere.mesh = mesh

	sphere.material_override = material

	get_tree().current_scene.add_child(
		sphere
	)

	sphere.global_position = position

	sphere.scale = (
		Vector3.ONE * 0.2
	)


	var tween = sphere.create_tween()

	tween.tween_property(
		sphere,
		"scale",
		Vector3.ONE
		*
		radius,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	tween.finished.connect(
		Callable(
			sphere,
			"queue_free"
		)
	)


# ============================================================
# ULT
# ============================================================

func add_ult_charge(amount):

	if ult_ready:
		return


	ult_charge = clamp(
		ult_charge
		+
		amount,
		0.0,
		ult_max_charge
	)


	ult_ready = (
		ult_charge
		>=
		ult_max_charge
	)


	update_ult_ui()


func try_activate_ult():

	if not ult_ready:
		return


	ult_charge = 0.0
	ult_ready = false

	update_ult_ui()

	clear_teleport_followup()


	# Shatter every existing piece of Lucian's glass.
	for pane in active_glass_panes.duplicate():

		if is_instance_valid(pane):

			shatter_glass_pane(
				pane,
				false
			)


	# Giant central explosion.
	create_ult_explosion()


	# Grab everything in the huge ult radius.
	for enemy in get_enemies_near(
		global_position,
		ult_radius
	):

		if can_ult_shatter_enemy(enemy):

			ult_lift_and_shatter(
				enemy
			)

		else:

			ult_hit_strong_enemy(
				enemy
			)


# ============================================================
# ULT — GIANT EXPLOSION
# ============================================================

func create_ult_explosion():

	# Full-screen white flash.
	screen_flash()

	# Quick camera FOV punch.
	camera_fov_pulse()


	# Three huge overlapping energy explosions.
	for i in range(
		ult_wave_materials.size()
	):

		spawn_delayed_ult_wave(
			i * 0.045,
			ult_visual_radius
			*
			(
				0.75
				+
				i * 0.18
			),
			ult_wave_materials[i]
		)


	# Huge explosion of glowing pieces from Lucian.
	spawn_shard_burst(
		global_position
		+
		Vector3.UP * 1.2,
		ult_center_shard_count,
		ult_visual_radius
		*
		0.65,
		1.4,
		0.55
	)


	# Actual world light flash.
	var light = OmniLight3D.new()

	light.light_color = Color(
		0.55,
		0.85,
		1.0
	)

	light.light_energy = 14.0
	light.omni_range = ult_visual_radius


	get_tree().current_scene.add_child(
		light
	)


	light.global_position = (
		global_position
		+
		Vector3.UP * 2.0
	)


	var tween = light.create_tween()

	tween.tween_property(
		light,
		"light_energy",
		0.0,
		0.35
	)


	tween.finished.connect(
		Callable(
			light,
			"queue_free"
		)
	)


func spawn_delayed_ult_wave(
	delay,
	radius,
	material
):

	await get_tree().create_timer(
		delay
	).timeout


	spawn_flash_sphere(
		global_position
		+
		Vector3.UP * 1.2,
		radius,
		material,
		0.34
	)


func screen_flash():

	var layer = CanvasLayer.new()

	layer.layer = 100

	add_child(
		layer
	)


	var flash = ColorRect.new()

	flash.color = Color.WHITE

	flash.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	layer.add_child(
		flash
	)

	flash.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	flash.modulate.a = 0.78


	var tween = flash.create_tween()

	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		ult_screen_flash_time
	)


	tween.finished.connect(
		Callable(
			layer,
			"queue_free"
		)
	)


func camera_fov_pulse():

	if camera == null:
		return


	var base_fov = camera.fov


	camera.fov = (
		base_fov
		+
		8.0
	)


	var tween = camera.create_tween()


	tween.tween_property(
		camera,
		"fov",
		base_fov,
		0.30
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


# ============================================================
# ULT — ENEMY LIFT + SHATTER
# ============================================================

func can_ult_shatter_enemy(enemy):

	if (
		not is_instance_valid(enemy)
		or
		enemy.is_in_group("bosses")
		or
		enemy.is_in_group("elites")
	):

		return false


	var max_hp = get_property_if_exists(
		enemy,
		"max_health"
	)


	if max_hp != null:

		return (
			float(max_hp)
			<=
			ult_weak_enemy_health
		)


	var hp = get_property_if_exists(
		enemy,
		"health"
	)


	return (
		hp != null
		and
		float(hp)
		<=
		ult_weak_enemy_health
	)


func ult_lift_and_shatter(enemy):

	if not is_instance_valid(enemy):
		return


	# ========================================================
	# FIRST: FLOAT THEM UP
	# ========================================================

	if enemy is CharacterBody3D:

		enemy.velocity.x *= 0.25
		enemy.velocity.z *= 0.25

		enemy.velocity.y = max(
			enemy.velocity.y,
			ult_lift_speed
		)


	if enemy.has_method(
		"apply_hit_effect"
	):

		enemy.apply_hit_effect(
			Vector3.ZERO,
			0.0,
			0.0,
			ult_lift_time
			+
			0.12
		)


	# Brief anticipation before the body explodes.
	await get_tree().create_timer(
		ult_lift_time
	).timeout


	if not is_instance_valid(enemy):
		return


	var burst_position = (
		enemy.global_position
		+
		Vector3.UP * 1.0
	)


	# ========================================================
	# THEN: DOUBLE FLASH + MANY PIECES
	# ========================================================

	spawn_flash_sphere(
		burst_position,
		7.0,
		ult_wave_materials[0],
		0.18
	)


	spawn_flash_sphere(
		burst_position,
		5.0,
		ult_wave_materials[2],
		0.14
	)


	spawn_shard_burst(
		burst_position,
		ult_enemy_shard_count,
		ult_enemy_piece_distance,
		0.95,
		0.50
	)


	# Delete the actual enemy only AFTER the flashy pieces spawn.
	if enemy.has_method(
		"take_damage"
	):

		enemy.take_damage(
			999999.0
		)

	else:

		enemy.queue_free()


# ============================================================
# ULT — ELITES / BOSSES
# ============================================================

func ult_hit_strong_enemy(enemy):

	if not is_instance_valid(enemy):
		return


	# They still float a little.
	if enemy is CharacterBody3D:

		enemy.velocity.y = max(
			enemy.velocity.y,
			ult_lift_speed * 0.65
		)


	if enemy.has_method(
		"take_damage"
	):

		enemy.take_damage(
			ult_strong_enemy_damage
		)


	if enemy.has_method(
		"apply_hit_effect"
	):

		var direction = (
			enemy.global_position
			-
			global_position
		)

		direction.y = 0.0


		if direction.length() > 0.01:

			direction = (
				direction.normalized()
			)

		else:

			direction = Vector3.UP


		enemy.apply_hit_effect(
			direction,
			ult_knockback,
			ult_launch_force,
			ult_stun_time
		)


	# Surviving enemies still erupt with glass.
	spawn_shard_burst(
		enemy.global_position
		+
		Vector3.UP,
		10,
		6.0,
		0.55,
		0.35
	)


func get_property_if_exists(
	object,
	property_name
):

	for info in object.get_property_list():

		if String(
			info["name"]
		) == property_name:

			return object.get(
				property_name
			)


	return null


# ============================================================
# TELEPORT
# ============================================================

func try_airborne_teleport():

	if teleport_cooldown_timer > 0.0:
		return


	var target = (
		get_airborne_teleport_target()
	)


	if not is_instance_valid(target):
		return


	teleport_to_enemy(
		target
	)


	teleport_cooldown_timer = (
		teleport_cooldown
	)


func get_airborne_teleport_target():

	if is_usable_enemy(
		locked_enemy,
		teleport_range,
		true
	):

		return locked_enemy


	var target = (
		get_screen_center_airborne_enemy()
	)


	if is_instance_valid(target):
		return target


	return get_nearest_enemy(
		teleport_range,
		true
	)


func get_screen_center_airborne_enemy():

	if camera == null:
		return null


	var size = (
		get_viewport()
		.get_visible_rect()
		.size
	)

	var center = (
		size * 0.5
	)

	var radius = (
		min(
			size.x,
			size.y
		)
		*
		teleport_target_screen_radius
	)


	var best = null
	var best_score = INF


	for enemy in get_enemies():

		if not is_usable_enemy(
			enemy,
			teleport_range,
			true
		):

			continue


		var point = (
			enemy.global_position
			+
			Vector3.UP * 1.2
		)


		if camera.is_position_behind(
			point
		):

			continue


		var screen_distance = (
			camera.unproject_position(
				point
			).distance_to(
				center
			)
		)


		if screen_distance > radius:
			continue


		var world_distance = (
			global_position.distance_to(
				enemy.global_position
			)
		)


		var score = (
			screen_distance
			/
			max(
				radius,
				1.0
			)
			*
			teleport_center_priority
			+
			world_distance
			/
			teleport_range
			*
			teleport_distance_priority
		)


		if score < best_score:

			best_score = score
			best = enemy


	return best


func teleport_to_enemy(enemy):

	if not is_instance_valid(enemy):
		return


	teleport_focus_target = enemy
	teleport_camera_target = enemy
	slam_target = enemy


	var direction = (
		global_position
		-
		enemy.global_position
	)


	direction.y = 0.0


	if direction.length() < 0.01:

		direction = (
			global_transform.basis.x
		)


	direction = (
		direction.normalized()
	)


	global_position = (
		get_safe_teleport_position(
			enemy,
			direction
		)
	)


	velocity = Vector3.ZERO

	low_gravity_timer = (
		teleport_low_gravity_duration
	)

	teleport_followup_timer = (
		teleport_followup_window
	)

	teleport_camera_timer = (
		teleport_camera_duration
	)


	face_enemy(
		enemy
	)


func get_safe_teleport_position(
	enemy,
	preferred_direction
):

	var checks = max(
		teleport_position_checks,
		1
	)


	for i in range(checks):

		var direction = (
			preferred_direction.rotated(
				Vector3.UP,
				TAU
				*
				float(i)
				/
				float(checks)
			)
		)


		var position = (
			enemy.global_position
			+
			direction
			*
			teleport_side_offset
			+
			Vector3.UP
			*
			teleport_height_offset
		)


		if is_teleport_path_clear(
			enemy,
			position
		):

			return position


	if teleport_use_fallback:

		return (
			enemy.global_position
			+
			preferred_direction
			*
			teleport_side_offset
			+
			Vector3.UP
			*
			teleport_height_offset
		)


	return global_position


func is_teleport_path_clear(
	enemy,
	destination
):

	var query = (
		PhysicsRayQueryParameters3D.create(
			enemy.global_position
			+
			Vector3.UP
			*
			teleport_height_offset,
			destination
		)
	)


	query.collide_with_areas = false

	query.exclude = [
		get_rid()
	]


	if enemy is CollisionObject3D:

		query.exclude.append(
			enemy.get_rid()
		)


	return (
		get_world_3d()
		.direct_space_state
		.intersect_ray(
			query
		)
		.is_empty()
	)


func face_enemy(enemy):

	if not is_instance_valid(enemy):
		return


	var target = Vector3(
		enemy.global_position.x,
		global_position.y,
		enemy.global_position.z
	)


	if (
		global_position.distance_to(
			target
		)
		>
		0.01
	):

		look_at(
			target,
			Vector3.UP,
			true
		)


func update_teleport_camera(delta):

	var following = (
		teleport_followup_timer > 0.0
		and
		is_instance_valid(
			teleport_focus_target
		)
	)


	if (
		teleport_camera_timer <= 0.0
		and
		not following
	):

		teleport_camera_target = null
		teleport_focus_target = null

		return


	if following:

		teleport_camera_target = (
			teleport_focus_target
		)


	if not is_instance_valid(
		teleport_camera_target
	):

		return


	teleport_camera_timer = max(
		teleport_camera_timer
		-
		delta,
		0.0
	)


	var to_target = (
		teleport_camera_target.global_position
		+
		Vector3.UP * 1.3
		-
		global_position
	)


	var distance = max(
		Vector2(
			to_target.x,
			to_target.z
		).length(),
		0.01
	)


	var target_pitch = clamp(
		-atan2(
			to_target.y,
			distance
		),
		deg_to_rad(
			camera_pitch_min
		),
		deg_to_rad(
			camera_pitch_max
		)
	)


	var strength = 0.22


	if teleport_camera_timer > 0.0:

		strength = (
			teleport_camera_timer
			/
			teleport_camera_duration
		)


	camera_pitch_target = lerp_angle(
		camera_pitch_target,
		target_pitch,
		clamp(
			teleport_camera_vertical_strength
			*
			strength
			*
			delta,
			0.0,
			1.0
		)
	)


# ============================================================
# SLAM
# ============================================================

func start_air_slam():

	if not is_instance_valid(
		slam_target
	):
		return


	pending_slam_target = slam_target

	clear_teleport_followup()

	slam_windup_timer = (
		slam_windup_time
	)


	combo_hold_timer = max(
		combo_hold_timer,
		slam_windup_time
		+
		slam_recovery_time
	)


func update_slam_windup(delta):

	if slam_windup_timer <= 0.0:
		return


	slam_windup_timer -= delta


	if slam_windup_timer <= 0.0:

		execute_air_slam()


func execute_air_slam():

	if not is_instance_valid(
		pending_slam_target
	):

		pending_slam_target = null

		return


	var enemy = pending_slam_target

	pending_slam_target = null


	if enemy.has_method(
		"apply_hit_effect"
	):

		enemy.apply_hit_effect(
			Vector3.ZERO,
			0.0,
			0.0,
			slam_stun_time
		)


	if enemy is CharacterBody3D:

		enemy.velocity.x *= 0.20
		enemy.velocity.z *= 0.20
		enemy.velocity.y = -slam_down_force


	slam_impact_target = enemy

	slam_impact_arm_timer = (
		slam_impact_arm_delay
	)

	slam_recovery_timer = (
		slam_recovery_time
	)


func update_slam_impact(delta):

	if not is_instance_valid(
		slam_impact_target
	):

		slam_impact_target = null

		return


	if slam_impact_arm_timer > 0.0:

		slam_impact_arm_timer -= delta

		return


	if (
		slam_impact_target
		is CharacterBody3D
		and
		slam_impact_target.is_on_floor()
	):

		trigger_slam_impact(
			slam_impact_target.global_position
		)

		slam_impact_target = null


func trigger_slam_impact(position):

	var nearby = get_enemies_near(
		position,
		slam_aoe_radius
	)


	for enemy in nearby:

		if enemy.has_method(
			"take_damage"
		):

			enemy.take_damage(
				slam_aoe_damage
			)


		if enemy.has_method(
			"apply_hit_effect"
		):

			var direction = (
				enemy.global_position
				-
				position
			)

			direction.y = 0.0


			if direction.length() > 0.01:

				direction = (
					direction.normalized()
				)

			else:

				direction = Vector3.UP


			enemy.apply_hit_effect(
				direction,
				slam_aoe_knockback,
				slam_aoe_launch_force,
				slam_aoe_stun_time
			)


	var targets = get_nearest_targets(
		position,
		nearby,
		slam_popup_projectile_count
	)


	slam_popup_burst(
		position,
		targets
	)


	spawn_flash_sphere(
		position
		+
		Vector3.UP * 0.2,
		slam_aoe_radius,
		ult_wave_materials[2],
		0.18
	)


func slam_popup_burst(
	position,
	targets
):

	if targets.is_empty():
		return


	spawn_slam_projectiles(
		position,
		targets
	)


	await get_tree().create_timer(
		slam_popup_delay
	).timeout


	for enemy in targets:

		if is_instance_valid(enemy):

			pop_enemy_to_lucian(
				enemy
			)


func spawn_slam_projectiles(
	position,
	targets
):

	if homing_projectile_scene == null:
		return


	var count = targets.size()


	for i in range(count):

		var enemy = targets[i]

		if not is_instance_valid(enemy):
			continue


		var projectile = (
			homing_projectile_scene.instantiate()
		)


		get_tree().current_scene.add_child(
			projectile
		)


		var angle = (
			TAU
			*
			float(i)
			/
			float(
				max(
					count,
					1
				)
			)
		)


		projectile.global_position = (
			position
			+
			Vector3(
				cos(angle),
				0.0,
				sin(angle)
			)
			*
			slam_popup_projectile_radius
			+
			Vector3.UP
			*
			slam_popup_projectile_height
		)


		projectile.projectile_size = (
			slam_popup_projectile_size
		)

		projectile.damage = (
			slam_popup_projectile_damage
		)

		projectile.is_finisher_projectile = false

		projectile.target = enemy

		projectile.direction = (
			enemy.global_position
			-
			projectile.global_position
		).normalized()


func pop_enemy_to_lucian(enemy):

	if not enemy is CharacterBody3D:
		return


	var height = max(
		global_position.y
		-
		enemy.global_position.y,
		slam_popup_min_height
	)


	var up_speed = sqrt(
		2.0
		*
		slam_popup_gravity_reference
		*
		height
	)


	enemy.velocity.y = max(
		enemy.velocity.y,
		min(
			up_speed,
			slam_popup_max_up_speed
		)
	)


# ============================================================
# TARGET HELPERS
# ============================================================

func get_enemies():

	return get_tree().get_nodes_in_group(
		"enemies"
	)


func is_enemy_airborne(enemy):

	return (
		enemy is CharacterBody3D
		and
		not enemy.is_on_floor()
	)


func is_usable_enemy(
	enemy,
	max_range,
	airborne_only = false
):

	if (
		not is_instance_valid(enemy)
		or
		not enemy is Node3D
	):

		return false


	if (
		global_position.distance_to(
			enemy.global_position
		)
		>
		max_range
	):

		return false


	return (
		not airborne_only
		or
		is_enemy_airborne(enemy)
	)


func get_nearest_enemy(
	max_range,
	airborne_only = false
):

	var nearest = null
	var nearest_distance = max_range


	for enemy in get_enemies():

		if not is_usable_enemy(
			enemy,
			max_range,
			airborne_only
		):

			continue


		var distance = (
			global_position.distance_to(
				enemy.global_position
			)
		)


		if distance < nearest_distance:

			nearest = enemy
			nearest_distance = distance


	return nearest


func get_enemies_near(
	point,
	radius
):

	var result = []


	for enemy in get_enemies():

		if (
			is_instance_valid(enemy)
			and
			enemy is Node3D
			and
			point.distance_to(
				enemy.global_position
			)
			<=
			radius
		):

			result.append(
				enemy
			)


	return result


func get_nearest_targets(
	point,
	candidates,
	count
):

	var remaining = candidates.duplicate()
	var selected = []


	while (
		not remaining.is_empty()
		and
		selected.size() < count
	):

		var nearest = null
		var nearest_distance = INF


		for enemy in remaining:

			if not is_instance_valid(enemy):
				continue


			var distance = (
				point.distance_squared_to(
					enemy.global_position
				)
			)


			if distance < nearest_distance:

				nearest = enemy
				nearest_distance = distance


		if nearest == null:
			break


		selected.append(
			nearest
		)

		remaining.erase(
			nearest
		)


	return selected


# ============================================================
# LOCK ON
# ============================================================

func toggle_lock():

	if is_instance_valid(
		locked_enemy
	):

		clear_lock()

		return


	lock_targets.clear()


	for enemy in get_enemies():

		if is_usable_enemy(
			enemy,
			lock_range
		):

			lock_targets.append(
				enemy
			)


	if lock_targets.is_empty():
		return


	lock_index = 0

	locked_enemy = (
		lock_targets[0]
	)


	if lock_reticle:
		lock_reticle.show()


func clear_lock():

	locked_enemy = null

	if lock_reticle:
		lock_reticle.hide()


func switch_target(direction):

	var cleaned = []


	for enemy in lock_targets:

		if is_instance_valid(enemy):

			cleaned.append(
				enemy
			)


	lock_targets = cleaned


	if lock_targets.is_empty():

		clear_lock()

		return


	lock_index = wrapi(
		lock_index + direction,
		0,
		lock_targets.size()
	)


	locked_enemy = (
		lock_targets[
			lock_index
		]
	)


func update_lock_camera(delta):

	if not is_instance_valid(
		locked_enemy
	):

		return


	var direction = (
		locked_enemy.global_position
		+
		Vector3.UP * 1.5
		-
		global_position
	)


	direction.y = 0.0


	if direction.length() > 0.01:

		rotation.y = lerp_angle(
			rotation.y,
			atan2(
				direction.x,
				direction.z
			),
			clamp(
				lock_turn_speed
				*
				delta,
				0.0,
				1.0
			)
		)


func update_lock_reticle():

	if lock_reticle == null:
		return


	if (
		not is_instance_valid(
			locked_enemy
		)
		or
		camera == null
	):

		lock_reticle.hide()


		if not is_instance_valid(
			locked_enemy
		):

			locked_enemy = null


		return


	lock_reticle.show()


	lock_reticle.position = (
		camera.unproject_position(
			locked_enemy.global_position
			+
			Vector3.UP * 2.5
		)
	)


# ============================================================
# ATTACK COMBO / PROJECTILES
# ============================================================

func attack():

	if combo_step >= 3:

		combo_step = 1

	else:

		combo_step += 1


	attacking = true
	combo_timer = combo_reset_time


	match combo_step:

		1:
			shoot_projectile(1)

		2:
			shoot_projectile(2)

		3:
			perform_vortex_finisher()


	await get_tree().create_timer(
		0.08
	).timeout


	attacking = false


func perform_vortex_finisher():

	var target = null


	if is_usable_enemy(
		locked_enemy,
		finisher_target_range
	):

		target = locked_enemy

	else:

		target = get_nearest_enemy(
			finisher_target_range
		)


	if not is_instance_valid(target):
		return


	finisher_id_counter += 1


	if target.has_method(
		"begin_finisher_setup"
	):

		target.begin_finisher_setup(
			finisher_id_counter,
			finisher_setup_launch_force,
			finisher_setup_hold_time,
			finisher_setup_stun_time
		)


	shoot_projectile(
		finisher_projectile_count,
		finisher_id_counter,
		target
	)


func shoot_projectile(
	amount,
	finisher_id = -1,
	finisher_target = null
):

	for i in range(amount):

		var projectile = (
			create_projectile()
		)


		if projectile == null:
			return


		configure_projectile(
			projectile,
			i,
			amount,
			finisher_id,
			finisher_target
		)


		spawn_projectile(
			projectile
		)


func create_projectile():

	if combo_step == 3:

		if homing_projectile_scene:

			return (
				homing_projectile_scene.instantiate()
			)

		return null


	if projectile_scene == null:
		return null


	var projectile = (
		projectile_scene.instantiate()
	)


	projectile.target = (
		get_normal_projectile_target()
	)


	return projectile


func get_normal_projectile_target():

	if is_usable_enemy(
		locked_enemy,
		normal_projectile_target_range
	):

		return locked_enemy


	return get_nearest_enemy(
		normal_projectile_target_range
	)


func configure_projectile(
	projectile,
	index,
	amount,
	finisher_id,
	finisher_target
):

	match combo_step:

		1:

			projectile.projectile_size = 0.5
			projectile.damage = 10

		2:

			projectile.projectile_size = 0.5

		3:

			projectile.projectile_size = 1.0

			projectile.damage = (
				finisher_projectile_damage
			)

			projectile.is_finisher_projectile = true

			projectile.finisher_id = (
				finisher_id
			)

			projectile.finisher_hit_count = (
				amount
			)

			projectile.target = (
				finisher_target
			)

			projectile.orbit_index = index
			projectile.orbit_count = amount


func spawn_projectile(projectile):

	get_tree().current_scene.add_child(
		projectile
	)


	var forward = (
		-global_transform.basis.z
	).normalized()


	var right = (
		global_transform.basis.x
	).normalized()


	projectile.global_position = (
		global_position
		+
		Vector3.UP
		*
		projectile_spawn_height
		+
		forward
		*
		projectile_spawn_forward
		+
		right
		*
		projectile_spawn_side
	)


	if camera:

		projectile.direction = (
			-camera.global_transform.basis.z
		).normalized()

	else:

		projectile.direction = forward


# ============================================================
# FOLLOW-UP UI
# ============================================================

func setup_followup_ui():

	var layer = CanvasLayer.new()

	layer.layer = 20

	add_child(
		layer
	)


	followup_ui = VBoxContainer.new()

	layer.add_child(
		followup_ui
	)


	followup_ui.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)


	followup_ui.offset_left = -190.0
	followup_ui.offset_right = 190.0
	followup_ui.offset_top = -115.0
	followup_ui.offset_bottom = -45.0


	var label = Label.new()

	label.text = (
		"[ LMB ] SLAM      [ SPACE ] GLASS ARENA"
	)

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		20
	)


	followup_ui.add_child(
		label
	)


	followup_bar = ProgressBar.new()

	followup_bar.max_value = (
		teleport_followup_window
	)

	followup_bar.show_percentage = false


	followup_bar.custom_minimum_size = Vector2(
		360.0,
		8.0
	)


	followup_ui.add_child(
		followup_bar
	)

	followup_ui.hide()


func update_followup_ui():

	if followup_ui == null:
		return


	var available = (
		teleport_followup_timer > 0.0
		and
		is_instance_valid(
			teleport_focus_target
		)
		and
		slam_windup_timer <= 0.0
	)


	followup_ui.visible = available


	if available:

		followup_bar.max_value = (
			teleport_followup_window
		)

		followup_bar.value = (
			teleport_followup_timer
		)


# ============================================================
# ULT UI
# ============================================================

func setup_ult_ui():

	var layer = CanvasLayer.new()

	layer.layer = 19

	add_child(
		layer
	)


	ult_ui = VBoxContainer.new()

	layer.add_child(
		ult_ui
	)


	ult_ui.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)


	ult_ui.offset_left = 30.0
	ult_ui.offset_right = 350.0
	ult_ui.offset_top = -105.0
	ult_ui.offset_bottom = -35.0


	ult_label = Label.new()

	ult_label.add_theme_font_size_override(
		"font_size",
		18
	)

	ult_ui.add_child(
		ult_label
	)


	ult_bar = ProgressBar.new()

	ult_bar.max_value = ult_max_charge

	ult_bar.show_percentage = false


	ult_bar.custom_minimum_size = Vector2(
		320.0,
		12.0
	)


	ult_ui.add_child(
		ult_bar
	)


	update_ult_ui()


func update_ult_ui():

	if ult_bar == null:
		return


	ult_bar.max_value = ult_max_charge
	ult_bar.value = ult_charge


	if ult_ready:

		ult_label.text = (
			"[ Q ] NO ONE UNDERSTANDS MY ART"
		)

	else:

		ult_label.text = (
			"NO ONE UNDERSTANDS MY ART"
		)


# ============================================================
# HEALTH / ANIMATION / FLASH
# ============================================================

func _on_hurtbox_body_entered(_body):

	if (
		dodge_invincible
		or
		hit_invincible
	):

		return


func take_damage(amount):

	if (
		dodge_invincible
		or
		hit_invincible
	):

		return


	hit_invincible = true

	health -= amount


	if health_bar:

		health_bar.value = health


	if health <= 0:

		die()

		return


	flash_red()


	await get_tree().create_timer(
		hit_invincibility_time
	).timeout


	hit_invincible = false


	if not dodge_invincible:

		remove_flash()


func die():

	print(
		"Player Died"
	)

	queue_free()


func update_animation(direction):

	if anim == null:
		return


	if is_dodging:

		play_animation(
			"rig_dodge"
		)

	elif direction.length() > 0.1:

		play_animation(
			"rig_run"
		)

	else:

		play_animation(
			"rig_idle"
		)


func play_animation(name):

	if (
		anim
		and
		anim.has_animation(name)
		and
		anim.current_animation
		!=
		name
	):

		anim.play(
			name
		)


func flash_red():

	set_player_color(
		Color.RED
	)

	await get_tree().create_timer(
		0.1
	).timeout

	if not dodge_invincible:
		remove_flash()


func flash_blue():

	set_player_color(
		Color.CYAN
	)


func set_player_color(color):

	for mesh in get_all_meshes(self):

		if mesh.mesh == null:
			continue


		for i in range(
			mesh.mesh.get_surface_count()
		):

			var material = (
				mesh.get_surface_override_material(
					i
				)
			)


			if material == null:

				var original = (
					mesh.mesh.surface_get_material(
						i
					)
				)


				if original:

					material = (
						original.duplicate()
					)

				else:

					material = (
						StandardMaterial3D.new()
					)


				mesh.set_surface_override_material(
					i,
					material
				)


			material.albedo_color = color


func remove_flash():

	for mesh in get_all_meshes(self):

		if mesh.mesh == null:
			continue


		for i in range(
			mesh.mesh.get_surface_count()
		):

			var material = (
				mesh.get_surface_override_material(
					i
				)
			)


			if material:

				material.albedo_color = (
					Color.WHITE
				)


func get_all_meshes(node):

	var meshes = []


	for child in node.get_children():

		if child is MeshInstance3D:

			meshes.append(
				child
			)


		meshes.append_array(
			get_all_meshes(
				child
			)
		)


	return meshes
