extends CharacterBody3D


# =============================================================================
# REFERENCES
# =============================================================================

@onready var health_bar = $EnemyHealthBar


# =============================================================================
# MOVEMENT
# =============================================================================

@export_category("Movement")

@export var move_speed = 18.0
@export var gravity = 20.0
@export var turn_speed = 8.0
@export var acceleration = 45.0

# The ranged enemy tries to stay around this distance.
@export var preferred_distance = 16.0

# Too close = back away.
@export var retreat_distance = 9.0

# Too far = chase.
@export var chase_distance = 24.0


# =============================================================================
# ENEMY SEPARATION
# =============================================================================

@export_category("Separation")

@export var separation_radius = 5.0
@export var separation_strength = 0.8


# =============================================================================
# RANGED ATTACK
# =============================================================================

@export_category("Projectile Attack")

@export var projectile_scene: PackedScene

@export var attack_range = 30.0
@export var attack_cooldown = 1.4

# Total warning duration.
@export var attack_windup = 0.9

# Warning follows Lucian for this amount of time.
@export var tracking_time = 0.50

# Projectile spawn position.
@export var projectile_height = 1.5
@export var projectile_forward_offset = 1.3

# Telegraph size.
@export var telegraph_length = 30.0
@export var telegraph_width = 0.35
@export var telegraph_height = 0.35


# =============================================================================
# ATTACK STATE
# =============================================================================

var can_attack = true
var attack_in_progress = false
var attack_cancelled = false

var locked_shot_direction = Vector3.ZERO

var aim_telegraph: MeshInstance3D
var aim_material: StandardMaterial3D


# =============================================================================
# HIT REACTION
# =============================================================================

@export_category("Hit Reaction")

@export var knockback_drag = 30.0
@export var knockback_duration = 0.18

var stun_timer = 0.0
var knockback_timer = 0.0


# =============================================================================
# FINISHER / JUGGLE
# =============================================================================

@export_category("Finisher")

@export var juggle_gravity_multiplier = 0.35
@export var juggle_gravity_duration = 0.30

var juggle_gravity_timer = 0.0
var active_finishers = {}


# =============================================================================
# FALL DAMAGE
# =============================================================================

@export_category("Fall Damage")

@export var safe_fall_distance = 6.0
@export var fall_damage_per_unit = 5.0

var highest_air_position = 0.0


# =============================================================================
# HEALTH
# =============================================================================

@export_category("Health")

@export var max_health: float = 80.0

var health: float


# =============================================================================
# PLAYER DETECTION
# =============================================================================

@export_category("Detection")

@export var aggroRadius: Area3D

var Player: CharacterBody3D
var aggro = false


# =============================================================================
# READY
# =============================================================================

func _ready():
	add_to_group("enemies")

	health = max_health

	if health_bar:
		health_bar.set_health(
			health,
			max_health
		)

	highest_air_position = global_position.y

	create_aim_telegraph()


# =============================================================================
# MAIN LOOP
# =============================================================================

func _physics_process(delta):
	update_gravity(delta)
	update_hit_timers(delta)

	# Knockback controls movement.
	if knockback_timer > 0.0:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			knockback_drag * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			knockback_drag * delta
		)

		move_enemy()
		return

	# Stunned.
	if stun_timer > 0.0:
		stop_horizontal(delta)
		move_enemy()
		return

	if not is_instance_valid(Player):
		Player = null

		stop_horizontal(delta)
		move_enemy()
		return

	face_player(delta)

	# Freeze horizontal movement while attacking.
	if attack_in_progress:
		stop_horizontal(delta)
		move_enemy()
		return

	var distance = global_position.distance_to(
		Player.global_position
	)

	# ---------------------------------------------------------
	# POSITIONING
	# ---------------------------------------------------------

	if distance > chase_distance:
		move_toward_player(delta)

	elif distance < retreat_distance:
		move_away_from_player(delta)

	else:
		stop_horizontal(delta)

	# ---------------------------------------------------------
	# ATTACK
	# ---------------------------------------------------------

	if (
		distance <= attack_range
		and can_attack
	):
		ranged_attack()

	move_enemy()


# =============================================================================
# GRAVITY / TIMERS
# =============================================================================

func update_gravity(delta):
	if juggle_gravity_timer > 0.0:
		juggle_gravity_timer -= delta

	if not is_on_floor():
		var current_gravity = gravity

		if juggle_gravity_timer > 0.0:
			current_gravity *= (
				juggle_gravity_multiplier
			)

		velocity.y -= (
			current_gravity * delta
		)


func update_hit_timers(delta):
	if stun_timer > 0.0:
		stun_timer -= delta

	if knockback_timer > 0.0:
		knockback_timer -= delta


# =============================================================================
# MOVEMENT
# =============================================================================

func move_toward_player(delta):
	var direction = (
		Player.global_position
		- global_position
	)

	direction.y = 0.0

	if direction.length() > 0.01:
		direction = direction.normalized()

	direction += (
		get_separation()
		* separation_strength
	)

	if direction.length() > 0.01:
		direction = direction.normalized()

	set_horizontal_velocity(
		direction,
		delta
	)


func move_away_from_player(delta):
	var direction = (
		global_position
		- Player.global_position
	)

	direction.y = 0.0

	if direction.length() > 0.01:
		direction = direction.normalized()

	direction += (
		get_separation()
		* separation_strength
	)

	if direction.length() > 0.01:
		direction = direction.normalized()

	set_horizontal_velocity(
		direction,
		delta
	)


func set_horizontal_velocity(
	direction,
	delta
):
	velocity.x = move_toward(
		velocity.x,
		direction.x * move_speed,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		direction.z * move_speed,
		acceleration * delta
	)


func stop_horizontal(delta):
	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		0.0,
		acceleration * delta
	)


func get_separation():
	var separation = Vector3.ZERO

	for enemy in get_tree().get_nodes_in_group(
		"enemies"
	):
		if enemy == self:
			continue

		if not is_instance_valid(enemy):
			continue

		if not (enemy is Node3D):
			continue

		var away = (
			global_position
			- enemy.global_position
		)

		away.y = 0.0

		var distance = away.length()

		if (
			distance > 0.01
			and distance < separation_radius
		):
			var closeness = (
				1.0
				- distance / separation_radius
			)

			closeness *= closeness

			separation += (
				away.normalized()
				* closeness
			)

	return separation


func face_player(delta):
	if not is_instance_valid(Player):
		return

	var direction = (
		Player.global_position
		- global_position
	)

	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	var target_rotation = atan2(
		-direction.x,
		-direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_rotation,
		turn_speed * delta
	)


# =============================================================================
# MOVEMENT + FALL DAMAGE
# =============================================================================

func move_enemy():
	var was_on_floor = is_on_floor()

	move_and_slide()

	if not is_on_floor():
		highest_air_position = max(
			highest_air_position,
			global_position.y
		)

	if (
		not was_on_floor
		and is_on_floor()
	):
		var fall_distance = (
			highest_air_position
			- global_position.y
		)

		if fall_distance > safe_fall_distance:
			var fall_damage = (
				fall_distance
				- safe_fall_distance
			) * fall_damage_per_unit

			take_damage(
				fall_damage
			)

		highest_air_position = global_position.y

	elif is_on_floor():
		highest_air_position = global_position.y


# =============================================================================
# RANGED ATTACK
# =============================================================================

func ranged_attack():
	if (
		attack_in_progress
		or not can_attack
		or not is_instance_valid(Player)
	):
		return

	attack_in_progress = true
	can_attack = false
	attack_cancelled = false

	aim_telegraph.show()

	var elapsed = 0.0

	locked_shot_direction = (
		get_direction_to_player()
	)

	# ---------------------------------------------------------
	# TELEGRAPH
	# ---------------------------------------------------------

	while elapsed < attack_windup:
		if attack_cancelled:
			finish_attack()
			return

		if not is_instance_valid(Player):
			finish_attack()
			return

		# Follow Lucian during the first part.
		if elapsed < tracking_time:
			var direction = (
				get_direction_to_player()
			)

			if direction != Vector3.ZERO:
				locked_shot_direction = direction

		# After tracking_time, the aim is committed.
		var progress = clamp(
			elapsed / attack_windup,
			0.0,
			1.0
		)

		update_aim_telegraph(
			locked_shot_direction,
			progress
		)

		await get_tree().physics_frame

		elapsed += (
			get_physics_process_delta_time()
		)

	# ---------------------------------------------------------
	# FIRE
	# ---------------------------------------------------------

	if attack_cancelled:
		finish_attack()
		return

	fire_projectile(
		locked_shot_direction
	)

	hide_telegraph()

	await get_tree().create_timer(
		attack_cooldown
	).timeout

	finish_attack()


# =============================================================================
# PROJECTILE SPAWN
# =============================================================================

func fire_projectile(direction):
	if projectile_scene == null:
		push_warning(
			"Ranged enemy has no projectile_scene assigned!"
		)

		return

	if direction.length() <= 0.01:
		return

	var projectile = (
		projectile_scene.instantiate()
	)

	get_tree().current_scene.add_child(
		projectile
	)

	var spawn_position = (
		global_position
		+ Vector3.UP * projectile_height
		+ direction * projectile_forward_offset
	)

	projectile.global_position = (
		spawn_position
	)

	projectile.direction = (
		direction.normalized()
	)


func get_direction_to_player():
	if not is_instance_valid(Player):
		return Vector3.ZERO

	var target_position = (
		Player.global_position
		+ Vector3.UP * 1.0
	)

	var spawn_position = (
		global_position
		+ Vector3.UP * projectile_height
	)

	var direction = (
		target_position
		- spawn_position
	)

	if direction.length() <= 0.01:
		return Vector3.ZERO

	return direction.normalized()


# =============================================================================
# TELEGRAPH VISUAL
# =============================================================================

func create_aim_telegraph():
	aim_telegraph = MeshInstance3D.new()

	aim_telegraph.name = (
		"ProjectileTelegraph"
	)

	var mesh = BoxMesh.new()

	mesh.size = Vector3(
		telegraph_width,
		telegraph_height,
		telegraph_length
	)

	aim_telegraph.mesh = mesh

	aim_material = (
		StandardMaterial3D.new()
	)

	aim_material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	aim_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	aim_material.albedo_color = Color(
		1.0,
		0.05,
		0.05,
		0.20
	)

	aim_material.emission_enabled = true
	aim_material.emission = Color(
		1.0,
		0.02,
		0.02
	)

	aim_material.emission_energy_multiplier = 1.0

	aim_telegraph.material_override = (
		aim_material
	)

	add_child(
		aim_telegraph
	)

	aim_telegraph.hide()


func update_aim_telegraph(
	direction,
	progress
):
	if not is_instance_valid(
		aim_telegraph
	):
		return

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	var start = (
		global_position
		+ Vector3.UP * projectile_height
	)

	var center = (
		start
		+ direction
		* telegraph_length
		* 0.5
	)

	var basis = Basis.looking_at(
		direction,
		Vector3.UP
	)

	aim_telegraph.global_transform = (
		Transform3D(
			basis,
			center
		)
	)

	var alpha = lerp(
		0.15,
		0.55,
		progress
	)

	var energy = lerp(
		1.0,
		6.0,
		progress
	)

	# Fast pulse immediately before firing.
	if progress > 0.80:
		var pulse = (
			sin(
				Time.get_ticks_msec()
				* 0.05
			)
			* 0.5
			+ 0.5
		)

		alpha = lerp(
			0.35,
			0.80,
			pulse
		)

		energy = lerp(
			4.0,
			10.0,
			pulse
		)

	aim_material.albedo_color = Color(
		1.0,
		0.03,
		0.03,
		alpha
	)

	aim_material.emission_energy_multiplier = (
		energy
	)


func hide_telegraph():
	if is_instance_valid(
		aim_telegraph
	):
		aim_telegraph.hide()


# =============================================================================
# ATTACK CANCELLING
# =============================================================================

func cancel_current_attack():
	attack_cancelled = true

	hide_telegraph()


func finish_attack():
	hide_telegraph()

	attack_in_progress = false
	attack_cancelled = false
	can_attack = true


# =============================================================================
# PLAYER DETECTION
# =============================================================================

func _on_aggro_radius_body_entered(body):
	if body.name == "Player":
		Player = body
		aggro = true


# =============================================================================
# DAMAGE
# =============================================================================

func take_damage(amount):
	health -= amount

	if health_bar:
		health_bar.set_health(
			health,
			max_health
		)

	if Player == null:
		var found_player = (
			get_tree()
			.current_scene
			.find_child(
				"Player",
				true,
				false
			)
		)

		if found_player is CharacterBody3D:
			Player = found_player
			aggro = true

	else:
		aggro = true

	flash_red()

	if health <= 0.0:
		die()


# =============================================================================
# FINISHER SETUP
# =============================================================================

func begin_finisher_setup(
	incoming_finisher_id: int,
	setup_launch_force: float,
	setup_hold_time: float,
	setup_stun_time: float
):
	if not active_finishers.has(
		incoming_finisher_id
	):
		active_finishers[
			incoming_finisher_id
		] = 0

	cancel_current_attack()

	stun_timer = max(
		stun_timer,
		setup_stun_time
	)

	juggle_gravity_timer = max(
		juggle_gravity_timer,
		setup_hold_time
	)

	velocity.x = 0.0
	velocity.z = 0.0

	velocity.y = max(
		velocity.y,
		setup_launch_force
	)

	knockback_timer = max(
		knockback_timer,
		0.25
	)


# =============================================================================
# HIT EFFECT
# =============================================================================

func apply_hit_effect(
	hit_direction: Vector3,
	knockback_strength: float,
	launch_force: float,
	stun_time: float,
	is_juggle_hit: bool = false
):
	cancel_current_attack()

	if is_juggle_hit:
		juggle_gravity_timer = max(
			juggle_gravity_timer,
			juggle_gravity_duration
		)

	stun_timer = max(
		stun_timer,
		stun_time
	)

	var push_direction = hit_direction

	push_direction.y = 0.0

	if push_direction.length() > 0.01:
		push_direction = (
			push_direction.normalized()
		)

	velocity.x = (
		push_direction.x
		* knockback_strength
	)

	velocity.z = (
		push_direction.z
		* knockback_strength
	)

	velocity.y = launch_force

	knockback_timer = knockback_duration


# =============================================================================
# FINISHER HIT COUNTER
# =============================================================================

func receive_finisher_hit(
	incoming_finisher_id: int,
	total_hits: int,
	hit_direction: Vector3,

	juggle_knockback: float,
	juggle_launch: float,
	juggle_stun: float,

	final_knockback: float,
	final_launch: float,
	final_stun: float
):
	if not active_finishers.has(
		incoming_finisher_id
	):
		active_finishers[
			incoming_finisher_id
		] = 0

	active_finishers[
		incoming_finisher_id
	] += 1

	var current_hits = active_finishers[
		incoming_finisher_id
	]

	if current_hits >= total_hits:
		apply_hit_effect(
			hit_direction,
			final_knockback,
			final_launch,
			final_stun,
			false
		)

		active_finishers.erase(
			incoming_finisher_id
		)

	else:
		apply_hit_effect(
			hit_direction,
			juggle_knockback,
			juggle_launch,
			juggle_stun,
			true
		)


# =============================================================================
# DAMAGE FLASH
# =============================================================================

func flash_red():
	set_enemy_color(Color.RED)

	await get_tree().create_timer(
		0.1
	).timeout

	remove_flash()


func remove_flash():
	set_enemy_color(Color.WHITE)


func set_enemy_color(color):
	for mesh in get_all_meshes(self):
		if mesh.mesh == null:
			continue

		for i in range(
			mesh.mesh.get_surface_count()
		):
			var material = (
				mesh.get_surface_override_material(i)
			)

			if material == null:
				var original = (
					mesh.mesh.surface_get_material(i)
				)

				material = (
					original.duplicate()
					if original
					else StandardMaterial3D.new()
				)

				mesh.set_surface_override_material(
					i,
					material
				)

			if material is StandardMaterial3D:
				material.albedo_color = color


func get_all_meshes(node):
	var meshes = []

	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)

		meshes += get_all_meshes(child)

	return meshes


# =============================================================================
# DEATH
# =============================================================================

func die():
	cancel_current_attack()

	queue_free()
