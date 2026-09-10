extends CharacterBody3D


# =============================================================================
# REFERENCES
# =============================================================================

@onready var health_bar = $EnemyHealthBar


# =============================================================================
# MOVEMENT
# =============================================================================

@export_category("Movement")

@export var move_speed = 28.0
@export var gravity = 20.0
@export var turn_speed = 13.0
@export var acceleration = 76.0
@export var strafe_speed = 24.0
@export var strafe_switch_min = 0.55
@export var strafe_switch_max = 1.35

# The ranged enemy tries to stay around this distance.
@export var preferred_distance = 14.0

# Too close = back away.
@export var retreat_distance = 7.0

# Too far = chase.
@export var chase_distance = 32.0


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
@export var attack_cooldown = 0.85

# Total warning duration.
@export var attack_windup = 0.62

# Warning follows Lucian for this amount of time.
@export var tracking_time = 0.32

# Projectile spawn position.
@export var projectile_height = 1.5
@export var projectile_forward_offset = 1.3

# Telegraph size.
@export var telegraph_length = 30.0
@export var telegraph_width = 0.35
@export var telegraph_height = 0.35
@export var prediction_seconds: float = 0.32
@export var decision_pause_min: float = 0.08
@export var decision_pause_max: float = 0.24
@export var warning_sound: AudioStream = preload("res://assets/audio/enemies/robot_land.wav")
@export var fire_sound: AudioStream = preload("res://assets/audio/enemies/robot_jump.wav")


# =============================================================================
# ATTACK STATE
# =============================================================================

var can_attack = true
var attack_in_progress = false
var attack_cancelled = false

var locked_shot_direction = Vector3.ZERO
var combat_role: int = 0
var strafe_direction: float = 1.0
var strafe_switch_timer: float = 0.0
var decision_timer := 0.0
var attack_audio: AudioStreamPlayer3D

var aim_telegraph: MeshInstance3D
var aim_material: StandardMaterial3D


# =============================================================================
# HIT REACTION
# =============================================================================

@export_category("Hit Reaction")

@export var knockback_drag = 30.0
@export var knockback_duration = 0.18
@export var light_stagger_time: float = 0.10
@export var heavy_hit_threshold: float = 18.0
@export var guard_crumple_hits: int = 3
@export var guard_crumple_window: float = 3.0
@export var guard_crumple_duration: float = 1.0
@export var hit_stop_seconds: float = 0.035
@export var ally_reaction_stagger: float = 0.25
@export var death_ragdoll_time: float = 1.4
@export var ragdoll_collision_stagger: float = 0.22
@export var aerial_spin_knockback_threshold: float = 35.0
@export var aerial_spin_launch_threshold: float = 10.0
@export var aerial_spin_speed: Vector3 = Vector3(19.0, 25.0, 17.0)

var stun_timer = 0.0
var knockback_timer = 0.0
var heavy_hit_count := 0
var heavy_hit_timer := 0.0
var dying := false
var ragdoll_hit_ids: Dictionary = {}
var aerial_spin_active := false
var aerial_spin_direction := Vector3.ONE
var visual_base_rotation := Vector3.ZERO


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

@export var max_health: float = 95.0

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
	var visual := get_node_or_null("CollisionShape3D/MeshInstance3D") as Node3D
	if visual:
		visual_base_rotation = visual.rotation
	add_to_group("enemies")

	health = max_health
	combat_role = randi_range(0, 2)
	strafe_direction = -1.0 if randf() < 0.5 else 1.0
	strafe_switch_timer = randf_range(strafe_switch_min, strafe_switch_max)
	configure_combat_role()

	if health_bar:
		health_bar.set_health(
			health,
			max_health
		)

	highest_air_position = global_position.y

	create_aim_telegraph()
	attack_audio = AudioStreamPlayer3D.new()
	attack_audio.max_distance = 65.0
	add_child(attack_audio)


# =============================================================================
# MAIN LOOP
# =============================================================================

func _physics_process(delta):
	update_aerial_spin(delta)
	if dying:
		update_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
		move_and_slide()
		check_ragdoll_enemy_impacts()
		return
	update_gravity(delta)
	update_hit_timers(delta)
	decision_timer = maxf(0.0, decision_timer - delta)
	heavy_hit_timer = maxf(0.0, heavy_hit_timer - delta)
	if heavy_hit_timer <= 0.0:
		heavy_hit_count = 0
	strafe_switch_timer -= delta
	if strafe_switch_timer <= 0.0:
		strafe_direction *= -1.0
		strafe_switch_timer = randf_range(strafe_switch_min, strafe_switch_max)

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

	# Keep repositioning during the windup and recovery so a group naturally
	# builds crossfire instead of becoming a stationary firing line.
	if attack_in_progress:
		strafe_around_player(delta)
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
		strafe_around_player(delta)

	# ---------------------------------------------------------
	# ATTACK
	# ---------------------------------------------------------

	if (
		distance <= attack_range
		and can_attack
		and decision_timer <= 0.0
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


func strafe_around_player(delta):
	var radial: Vector3 = Player.global_position - global_position
	radial.y = 0.0
	if radial.length_squared() <= 0.01:
		return
	var tangent := Vector3(-radial.z, 0.0, radial.x).normalized() * strafe_direction
	var distance := radial.length()
	var correction := radial.normalized() * clampf((distance - preferred_distance) * 0.12, -0.65, 0.65)
	var direction: Vector3 = (tangent + correction + get_separation() * separation_strength).normalized()
	var role_speed: float = float(strafe_speed) * (1.25 if combat_role == 0 else (0.82 if combat_role == 1 else 1.05))
	velocity.x = move_toward(velocity.x, direction.x * role_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * role_speed, acceleration * delta)


func configure_combat_role():
	match combat_role:
		0: # Flanker: wide, fast orbit and quick single shots.
			preferred_distance = 16.0
			attack_cooldown = 0.58
			attack_windup = 0.44
		1: # Suppressor: holds the back line and fires a broad pair.
			preferred_distance = 21.0
			retreat_distance = 10.0
			attack_cooldown = 0.98
			attack_windup = 0.72
		2: # Hunter: closes distance and commits to a rapid burst.
			preferred_distance = 10.0
			chase_distance = 28.0
			attack_cooldown = 0.72
			attack_windup = 0.52


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
	if not get_node("/root/EnemyCombatDirector").request_attack(self):
		decision_timer = randf_range(decision_pause_min, decision_pause_max)
		return

	attack_in_progress = true
	can_attack = false
	attack_cancelled = false

	aim_telegraph.show()
	play_attack_cue(warning_sound, 1.35)

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

	await fire_attack_pattern(locked_shot_direction)
	play_attack_cue(fire_sound, 0.92)

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
	if "damage" in projectile:
		projectile.damage = 34.0 if combat_role == 0 else (28.0 if combat_role == 1 else 26.0)
	if "speed" in projectile:
		projectile.speed = 68.0 if combat_role == 0 else (52.0 if combat_role == 1 else 62.0)


func fire_attack_pattern(base_direction: Vector3):
	match combat_role:
		0:
			fire_projectile(base_direction)
		1:
			fire_projectile(base_direction.rotated(Vector3.UP, -0.085))
			fire_projectile(base_direction.rotated(Vector3.UP, 0.085))
		2:
			for angle in [-0.06, 0.0, 0.06]:
				if attack_cancelled:
					return
				fire_projectile(base_direction.rotated(Vector3.UP, float(angle)))
				await get_tree().create_timer(0.11).timeout


func get_direction_to_player():
	if not is_instance_valid(Player):
		return Vector3.ZERO

	var predicted_velocity := Vector3.ZERO
	if Player is CharacterBody3D:
		predicted_velocity = Player.velocity
	var target_position = (
		Player.global_position + predicted_velocity * prediction_seconds
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
	get_node("/root/EnemyCombatDirector").release_attack(self)

	hide_telegraph()


func finish_attack():
	hide_telegraph()

	attack_in_progress = false
	attack_cancelled = false
	can_attack = true
	decision_timer = randf_range(decision_pause_min, decision_pause_max)
	get_node("/root/EnemyCombatDirector").release_attack(self)

func play_attack_cue(stream: AudioStream, pitch: float) -> void:
	if attack_audio and stream:
		attack_audio.stream = stream
		attack_audio.pitch_scale = pitch
		attack_audio.play()


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
	if dying:
		return
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
	spawn_hit_impact()
	if float(amount) >= heavy_hit_threshold:
		heavy_hit_count += 1
		heavy_hit_timer = guard_crumple_window
		if heavy_hit_count >= guard_crumple_hits:
			heavy_hit_count = 0
			stun_timer = maxf(stun_timer, guard_crumple_duration)
	else:
		stun_timer = maxf(stun_timer, light_stagger_time)

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
	if dying:
		velocity = hit_direction.normalized() * knockback_strength + Vector3.UP * launch_force
		return
	cancel_current_attack()
	play_directional_hit_reaction(hit_direction, knockback_strength, launch_force)

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
	if knockback_strength >= aerial_spin_knockback_threshold or launch_force >= aerial_spin_launch_threshold:
		aerial_spin_active = true
		aerial_spin_direction = Vector3(1.0 if randf() > 0.5 else -1.0, 1.0 if randf() > 0.5 else -1.0, 1.0 if randf() > 0.5 else -1.0)

	knockback_timer = knockback_duration
	if knockback_strength >= 12.0 or launch_force >= 5.0:
		get_node("/root/EnemyCombatDirector").notify_ally_disrupted(self, velocity)

func play_directional_hit_reaction(hit_direction: Vector3, strength: float, launch: float) -> void:
	var local_hit := global_transform.basis.inverse() * hit_direction.normalized()
	var target_tilt := Vector3(clampf(-launch * 0.015, -0.22, 0.0), 0.0, clampf(-local_hit.x * strength * 0.012, -0.28, 0.28))
	var visual := get_node_or_null("CollisionShape3D/MeshInstance3D")
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "rotation", target_tilt, hit_stop_seconds)
		tween.tween_property(visual, "rotation", visual_base_rotation, 0.14)

func update_aerial_spin(delta: float) -> void:
	if not aerial_spin_active:
		return
	var visual := get_node_or_null("CollisionShape3D/MeshInstance3D") as Node3D
	if not visual:
		aerial_spin_active = false
		return
	if is_on_floor() and velocity.y <= 0.0:
		aerial_spin_active = false
		visual.rotation = visual_base_rotation
		return
	visual.rotation += aerial_spin_speed * aerial_spin_direction * delta

func spawn_hit_impact() -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.35, 0.65, 1.0)
	flash.light_energy = 5.0
	flash.omni_range = 4.0
	add_child(flash)
	flash.position = Vector3.UP
	get_tree().create_timer(hit_stop_seconds + 0.03).timeout.connect(flash.queue_free)

func react_to_ally_event(source_position: Vector3, incoming_force: Vector3, duration: float) -> void:
	if dying or attack_in_progress:
		return
	stun_timer = maxf(stun_timer, maxf(duration, ally_reaction_stagger))
	decision_timer = maxf(decision_timer, duration + randf_range(0.1, 0.3))
	var away := global_position - source_position
	away.y = 0.0
	if away.length_squared() > 0.01 and incoming_force.length() > 8.0:
		velocity += away.normalized() * 2.5

func check_ragdoll_enemy_impacts() -> void:
	if velocity.length() < 8.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		var id := enemy.get_instance_id()
		if ragdoll_hit_ids.has(id) or global_position.distance_to(enemy.global_position) > 2.6:
			continue
		ragdoll_hit_ids[id] = true
		if enemy.has_method("react_to_ally_event"):
			enemy.react_to_ally_event(global_position, velocity, ragdoll_collision_stagger)


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
	if dying:
		return
	dying = true
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("on_enemy_killed"):
			player.on_enemy_killed()
	cancel_current_attack()
	get_node("/root/EnemyCombatDirector").notify_ally_disrupted(self, velocity)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if velocity.length_squared() < 1.0:
		velocity = -get_direction_to_player() * 10.0 + Vector3.UP * 6.0
	rotation.z = clampf(velocity.x * 0.035, -1.0, 1.0)
	var tween := create_tween()
	tween.tween_interval(death_ragdoll_time)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.22)
	tween.tween_callback(queue_free)
