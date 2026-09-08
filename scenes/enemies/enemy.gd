extends CharacterBody3D


# =============================================================================
# REFERENCES
# =============================================================================

@onready var health_bar = $EnemyHealthBar
@onready var attack_telegraph = $AttackTelegraph


# =============================================================================
# MOVEMENT
# =============================================================================

@export_category("Movement")

@export var move_speed = 30.0
@export var gravity = 20.0
@export var turn_speed = 10.0
@export var movement_acceleration = 60.0

@export_group("Enemy Separation")
@export var separation_radius = 5.0
@export var separation_strength = 0.75


# =============================================================================
# FALL DAMAGE
# =============================================================================

@export_category("Fall Damage")

@export var safe_fall_distance = 6.0
@export var fall_damage_per_unit = 5.0

var highest_air_position = 0.0


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
# MELEE ATTACK
# =============================================================================

@export_category("Melee Attack")

@export var attack_range = 3.0
@export var attack_damage = 20

@export var attack_windup = 0.35
@export var attack_recovery = 0.25
@export var attack_cooldown = 1.0

@export_group("Hound Moveset")
@export var swipe_radius: float = 7.5
@export var swipe_side_offset: float = 3.2
@export var swipe_windup: float = 0.55
@export var bite_range: float = 6.0
@export var bite_windup: float = 0.42
@export var pounce_min_distance: float = 10.0
@export var pounce_range: float = 22.0
@export var pounce_windup: float = 0.72
@export var pounce_speed: float = 48.0
@export var pounce_duration: float = 0.32
@export var circle_chance: float = 0.32
@export var circle_duration: float = 0.55
@export var circle_speed: float = 24.0
@export var decision_pause_min: float = 0.16
@export var decision_pause_max: float = 0.42
@export var attack_flash_color: Color = Color(1.0, 0.16, 0.06)
@export var warning_sound: AudioStream = preload("res://assets/audio/enemies/robot_jump.wav")
@export var strike_sound: AudioStream = preload("res://assets/audio/enemies/robot_land.wav")

var combat_role: int = 0
@export_range(-1, 2, 1) var forced_combat_role: int = -1
var decision_timer := 0.0
var circle_timer := 0.0
var circle_direction := 1.0
var attack_audio: AudioStreamPlayer3D

@export_group("Normal Enemy Reactions")
@export var light_stagger_time: float = 0.12
@export var heavy_hit_threshold: float = 18.0
@export var guard_crumple_hits: int = 3
@export var guard_crumple_window: float = 3.0
@export var guard_crumple_duration: float = 1.0
@export var hit_stop_seconds: float = 0.035
@export var ally_reaction_stagger: float = 0.25
@export var death_ragdoll_time: float = 1.4
@export var ragdoll_collision_stagger: float = 0.22
var heavy_hit_count := 0
var heavy_hit_timer := 0.0
var dying := false
var ragdoll_hit_ids: Dictionary = {}


# =============================================================================
# RANGED MELEE ATTACK
# =============================================================================

@export_category("Ranged Melee")

# How far the giant cleave reaches.
@export var ranged_melee_range = 18.0

# Width of the danger lane.
@export var ranged_melee_width = 4.0

# Vertical reach.
# This lets the attack threaten Lucian in the air.
@export var ranged_melee_height = 8.0

@export var ranged_melee_damage = 24

# Total warning time.
@export var ranged_melee_windup = 0.85

# Enemy follows Lucian with the warning for this long.
# After this, the warning LOCKS in place.
@export var ranged_melee_tracking_time = 0.45

@export var ranged_melee_recovery = 0.35
@export var ranged_melee_cooldown = 1.25

# Tiny visual flash when the attack actually fires.
@export var ranged_melee_strike_flash = 0.08


# =============================================================================
# ATTACK STATE
# =============================================================================

var can_attack = true
var attack_in_progress = false
var attack_cancelled = false

var ranged_attack_direction = Vector3.ZERO

var ranged_telegraph: MeshInstance3D
var ranged_telegraph_material: StandardMaterial3D


# =============================================================================
# HEALTH
# =============================================================================

@export_category("Health")

@export var max_health: float = 100.0

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

	attack_telegraph.hide()

	health = max_health
	health_bar.set_health(health, max_health)
	combat_role = forced_combat_role if forced_combat_role >= 0 else randi_range(0, 2)
	configure_combat_role()

	highest_air_position = global_position.y

	create_ranged_melee_telegraph()
	attack_audio = AudioStreamPlayer3D.new()
	attack_audio.max_distance = 55.0
	add_child(attack_audio)


func configure_combat_role():
	match combat_role:
		0: # Bruiser: broad, heavy lane that forces an early dodge.
			move_speed = 27.0
			attack_damage = 26
			ranged_melee_width = 5.5
			ranged_melee_damage = 28
			ranged_melee_windup = 1.0
			attack_telegraph.text = "HEAVY"
		1: # Pursuer: reaches the player quickly with narrower fast swings.
			move_speed = 40.0
			attack_range = 4.2
			attack_damage = 18
			attack_windup = 0.25
			attack_cooldown = 0.72
			ranged_melee_width = 3.0
			ranged_melee_windup = 0.62
			attack_telegraph.text = "RUSH"
		2: # Reaper: controls a long lane but leaves a clear punish window.
			move_speed = 32.0
			ranged_melee_range = 23.0
			ranged_melee_width = 4.2
			ranged_melee_damage = 22
			ranged_melee_windup = 0.78
			ranged_melee_recovery = 0.62
			attack_telegraph.text = "CLEAVE"


# =============================================================================
# MAIN LOOP
# =============================================================================

func _physics_process(delta):
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

	# Knockback owns movement.
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

	# Stun owns movement.
	if stun_timer > 0.0:
		brake_horizontal(delta)
		move_enemy()
		return

	# No target.
	if not is_instance_valid(Player):
		Player = null

		brake_horizontal(delta)
		move_enemy()
		return

	face_player(delta)
	if circle_timer > 0.0 and not attack_in_progress:
		circle_timer -= delta
		circle_player(delta)
		move_enemy()
		return

	# Enemy stands still while committing to an attack.
	if attack_in_progress:
		brake_horizontal(delta)
		move_enemy()
		return

	var distance = global_position.distance_to(
		Player.global_position
	)

	# ---------------------------------------------------------
	# TOO FAR AWAY
	# Chase until the enemy reaches ranged-melee distance.
	# ---------------------------------------------------------

	if distance > ranged_melee_range:
		chase_player(delta)

	# ---------------------------------------------------------
	# ATTACK RANGE
	# ---------------------------------------------------------

	else:
		brake_horizontal(delta)

		if can_attack and decision_timer <= 0.0:
			attack()

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
			current_gravity *= juggle_gravity_multiplier

		velocity.y -= current_gravity * delta


func update_hit_timers(delta):
	if stun_timer > 0.0:
		stun_timer -= delta

	if knockback_timer > 0.0:
		knockback_timer -= delta


# =============================================================================
# MOVEMENT
# =============================================================================

func chase_player(delta):
	var chase_direction = (
		Player.global_position
		- global_position
	)

	chase_direction.y = 0.0

	if chase_direction.length() > 0.01:
		chase_direction = chase_direction.normalized()

	var separation = get_enemy_separation()

	var final_direction = (
		chase_direction
		+ separation * separation_strength
	)

	if final_direction.length() > 0.01:
		final_direction = final_direction.normalized()

	velocity.x = move_toward(
		velocity.x,
		final_direction.x * move_speed,
		movement_acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		final_direction.z * move_speed,
		movement_acceleration * delta
	)


func brake_horizontal(delta):
	velocity.x = move_toward(
		velocity.x,
		0.0,
		movement_acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		0.0,
		movement_acceleration * delta
	)


func get_enemy_separation():
	var separation = Vector3.ZERO

	for enemy in get_tree().get_nodes_in_group("enemies"):
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
			var damaging_distance = (
				fall_distance
				- safe_fall_distance
			)

			var fall_damage = (
				damaging_distance
				* fall_damage_per_unit
			)

			take_damage(fall_damage)

		highest_air_position = global_position.y

	elif is_on_floor():
		highest_air_position = global_position.y


# =============================================================================
# ATTACK CHOICE
# =============================================================================

func attack():
	if (
		attack_in_progress
		or not can_attack
		or not is_instance_valid(Player)
	):
		return

	if not get_node("/root/EnemyCombatDirector").request_attack(self):
		decision_timer = randf_range(decision_pause_min, decision_pause_max)
		return
	hound_attack()

func circle_player(delta: float) -> void:
	if not is_instance_valid(Player):
		return
	var radial := Player.global_position - global_position
	radial.y = 0.0
	if radial.length_squared() < 0.01:
		return
	var tangent := Vector3(-radial.z, 0.0, radial.x).normalized() * circle_direction
	var correction := radial.normalized() * clampf((radial.length() - 7.0) * 0.18, -0.6, 0.6)
	var desired: Vector3 = (tangent + correction + get_enemy_separation() * separation_strength).normalized()
	velocity.x = move_toward(velocity.x, desired.x * circle_speed, movement_acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z * circle_speed, movement_acceleration * delta)

func hound_attack() -> void:
	attack_in_progress = true
	can_attack = false
	attack_cancelled = false
	if randf() < circle_chance:
		get_node("/root/EnemyCombatDirector").release_attack(self, 0.0)
		attack_in_progress = false
		circle_direction = -1.0 if randf() < 0.5 else 1.0
		circle_timer = circle_duration
		decision_timer = circle_duration + randf_range(decision_pause_min, decision_pause_max)
		return
	var distance := global_position.distance_to(Player.global_position)
	if distance >= pounce_min_distance:
		await perform_hound_move("POUNCE", pounce_windup, 0)
	elif distance <= bite_range and absf(direction_to_player().dot(global_transform.basis.x)) < 0.72 and randf() < 0.42:
		await perform_hound_move("BITE", bite_windup, 1)
	else:
		await perform_hound_move("LEFT CLAW" if randf() < 0.5 else "RIGHT CLAW", swipe_windup, 2)

func perform_hound_move(move_name: String, windup: float, move_kind: int) -> void:
	attack_telegraph.text = move_name
	attack_telegraph.modulate = attack_flash_color
	attack_telegraph.show()
	play_attack_cue(warning_sound, 0.78)
	await get_tree().create_timer(windup).timeout
	if attack_cancelled or not is_instance_valid(Player):
		finish_attack()
		return
	attack_telegraph.modulate = Color.WHITE
	play_attack_cue(strike_sound, 1.18)
	var forward: Vector3 = direction_to_player()
	if move_kind == 0:
		var elapsed := 0.0
		while elapsed < pounce_duration and not attack_cancelled:
			velocity.x = forward.x * pounce_speed
			velocity.z = forward.z * pounce_speed
			move_and_slide()
			elapsed += get_physics_process_delta_time()
			await get_tree().physics_frame
		if is_instance_valid(Player) and global_position.distance_to(Player.global_position) <= swipe_radius:
			Player.take_damage(attack_damage + 6)
	else:
		var right := global_transform.basis.x.normalized()
		var center: Vector3 = global_position + forward * (3.7 if move_kind == 1 else 3.0)
		if move_kind == 2:
			center += right * (-swipe_side_offset if move_name.begins_with("LEFT") else swipe_side_offset)
		var radius := bite_range * 0.55 if move_kind == 1 else swipe_radius
		if Player.global_position.distance_to(center) <= radius:
			Player.take_damage(attack_damage + (5 if move_kind == 1 else 0))
	spawn_attack_impact(move_kind, forward)
	await get_tree().create_timer(attack_recovery).timeout
	await get_tree().create_timer(attack_cooldown).timeout
	finish_attack()

func spawn_attack_impact(move_kind: int, forward: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = attack_flash_color
	flash.light_energy = 8.0
	flash.omni_range = swipe_radius if move_kind == 2 else bite_range
	add_child(flash)
	flash.position = forward * 3.0 + Vector3.UP
	get_tree().create_timer(0.1).timeout.connect(flash.queue_free)

func play_attack_cue(stream: AudioStream, pitch: float) -> void:
	if attack_audio and stream:
		attack_audio.stream = stream
		attack_audio.pitch_scale = pitch
		attack_audio.play()


# =============================================================================
# NORMAL MELEE
# =============================================================================

func melee_attack():
	attack_in_progress = true
	can_attack = false
	attack_cancelled = false

	hide_ranged_telegraph()

	attack_telegraph.show()

	await get_tree().create_timer(
		attack_windup
	).timeout

	if attack_cancelled:
		finish_attack()
		return

	attack_telegraph.hide()

	if is_instance_valid(Player):
		var distance = global_position.distance_to(
			Player.global_position
		)

		if distance <= attack_range:
			Player.take_damage(
				attack_damage
			)

	await get_tree().create_timer(
		attack_recovery
	).timeout

	if attack_cancelled:
		finish_attack()
		return

	await get_tree().create_timer(
		attack_cooldown
	).timeout

	finish_attack()


# =============================================================================
# RANGED MELEE
# =============================================================================

func ranged_melee_attack():
	attack_in_progress = true
	can_attack = false
	attack_cancelled = false

	attack_telegraph.hide()

	if not is_instance_valid(Player):
		finish_attack()
		return

	ranged_attack_direction = direction_to_player()

	if ranged_attack_direction == Vector3.ZERO:
		ranged_attack_direction = -global_transform.basis.z

	ranged_telegraph.show()

	var elapsed = 0.0

	# ---------------------------------------------------------
	# WARNING PHASE
	# ---------------------------------------------------------

	while elapsed < ranged_melee_windup:
		if attack_cancelled:
			hide_ranged_telegraph()
			finish_attack()
			return

		if not is_instance_valid(Player):
			hide_ranged_telegraph()
			finish_attack()
			return

		# During the first part of the warning,
		# the attack follows Lucian.
		if elapsed < ranged_melee_tracking_time:
			var new_direction = direction_to_player()

			if new_direction != Vector3.ZERO:
				ranged_attack_direction = new_direction

		# After tracking time ends, the lane is LOCKED.
		var progress = clamp(
			elapsed / ranged_melee_windup,
			0.0,
			1.0
		)

		update_ranged_telegraph(
			ranged_attack_direction,
			progress
		)

		await get_tree().physics_frame

		elapsed += get_physics_process_delta_time()

	if attack_cancelled:
		hide_ranged_telegraph()
		finish_attack()
		return

	# ---------------------------------------------------------
	# STRIKE
	# ---------------------------------------------------------

	update_ranged_telegraph(
		ranged_attack_direction,
		1.0
	)

	perform_ranged_melee_hit(
		ranged_attack_direction
	)

	flash_ranged_telegraph()

	await get_tree().create_timer(
		ranged_melee_strike_flash
	).timeout

	hide_ranged_telegraph()

	await get_tree().create_timer(
		ranged_melee_recovery
	).timeout

	if attack_cancelled:
		finish_attack()
		return

	await get_tree().create_timer(
		ranged_melee_cooldown
	).timeout

	finish_attack()


# =============================================================================
# RANGED MELEE HIT DETECTION
# =============================================================================

func perform_ranged_melee_hit(direction):
	if not is_instance_valid(Player):
		return

	var origin = global_position

	var to_player = (
		Player.global_position
		- origin
	)

	# Distance forward along the slash.
	var forward_distance = (
		to_player.dot(direction)
	)

	# Player is behind enemy.
	if forward_distance < 0.0:
		return

	# Player is beyond attack range.
	if forward_distance > ranged_melee_range:
		return

	# Horizontal sideways distance from the slash line.
	var horizontal_offset = (
		to_player
		- direction * forward_distance
	)

	horizontal_offset.y = 0.0

	var side_distance = (
		horizontal_offset.length()
	)

	if side_distance > ranged_melee_width * 0.5:
		return

	# Vertical danger volume.
	var player_height = (
		Player.global_position.y
		- global_position.y
	)

	if player_height < -1.5:
		return

	if player_height > ranged_melee_height:
		return

	# Lucian is inside the warned area.
	Player.take_damage(
		ranged_melee_damage
	)


func direction_to_player():
	if not is_instance_valid(Player):
		return Vector3.ZERO

	var direction = (
		Player.global_position
		- global_position
	)

	direction.y = 0.0

	if direction.length() <= 0.01:
		return Vector3.ZERO

	return direction.normalized()


# =============================================================================
# RANGED TELEGRAPH VISUAL
# =============================================================================

func create_ranged_melee_telegraph():
	ranged_telegraph = MeshInstance3D.new()
	ranged_telegraph.name = "RangedMeleeTelegraph"

	var mesh = BoxMesh.new()

	mesh.size = Vector3(
		ranged_melee_width,
		ranged_melee_height,
		ranged_melee_range
	)

	ranged_telegraph.mesh = mesh

	ranged_telegraph_material = (
		StandardMaterial3D.new()
	)

	ranged_telegraph_material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	ranged_telegraph_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	ranged_telegraph_material.albedo_color = Color(
		1.0,
		0.05,
		0.05,
		0.18
	)

	ranged_telegraph_material.emission_enabled = true

	ranged_telegraph_material.emission = Color(
		1.0,
		0.02,
		0.02
	)

	ranged_telegraph_material.emission_energy_multiplier = 1.0

	ranged_telegraph.material_override = (
		ranged_telegraph_material
	)

	add_child(
		ranged_telegraph
	)

	ranged_telegraph.hide()


func update_ranged_telegraph(
	direction,
	progress
):
	if not is_instance_valid(ranged_telegraph):
		return

	if direction.length() <= 0.01:
		return

	direction.y = 0.0
	direction = direction.normalized()

	# Put the warning volume halfway down the attack.
	var center = (
		global_position
		+ direction
		* ranged_melee_range
		* 0.5
		+ Vector3.UP
		* ranged_melee_height
		* 0.5
	)

	var basis = Basis.looking_at(
		direction,
		Vector3.UP
	)

	ranged_telegraph.global_transform = Transform3D(
		basis,
		center
	)

	# Warning becomes brighter as impact approaches.
	var alpha = lerp(
		0.12,
		0.55,
		progress
	)

	var energy = lerp(
		0.8,
		5.0,
		progress
	)

	# Extra urgency during the final 20%.
	if progress > 0.80:
		var pulse = (
			sin(
				Time.get_ticks_msec()
				* 0.045
			)
			* 0.5
			+ 0.5
		)

		alpha = lerp(
			0.40,
			0.75,
			pulse
		)

		energy = lerp(
			4.0,
			8.0,
			pulse
		)

	ranged_telegraph_material.albedo_color = Color(
		1.0,
		0.03,
		0.03,
		alpha
	)

	ranged_telegraph_material.emission_energy_multiplier = (
		energy
	)


func flash_ranged_telegraph():
	if not is_instance_valid(
		ranged_telegraph_material
	):
		return

	ranged_telegraph_material.albedo_color = Color(
		1.0,
		0.9,
		0.9,
		0.9
	)

	ranged_telegraph_material.emission = Color.WHITE

	ranged_telegraph_material.emission_energy_multiplier = 12.0


func hide_ranged_telegraph():
	if is_instance_valid(ranged_telegraph):
		ranged_telegraph.hide()

	if is_instance_valid(ranged_telegraph_material):
		ranged_telegraph_material.emission = Color(
			1.0,
			0.02,
			0.02
		)


# =============================================================================
# ATTACK CLEANUP / CANCELLING
# =============================================================================

func finish_attack():
	attack_telegraph.hide()
	hide_ranged_telegraph()

	attack_in_progress = false
	attack_cancelled = false
	can_attack = true
	decision_timer = randf_range(decision_pause_min, decision_pause_max)
	get_node("/root/EnemyCombatDirector").release_attack(self)


func cancel_current_attack():
	attack_cancelled = true
	get_node("/root/EnemyCombatDirector").release_attack(self)

	attack_telegraph.hide()
	hide_ranged_telegraph()


# =============================================================================
# PLAYER DETECTION
# =============================================================================

func _on_aggro_radius_body_entered(body):
	if body.name == "Player":
		Player = body
		aggro = true

		print("Player detected")


# =============================================================================
# DAMAGE
# =============================================================================

func take_damage(amount):
	if dying:
		return
	health -= amount

	health_bar.set_health(
		health,
		max_health
	)

	# Getting hit instantly aggroes the enemy.
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
			attack_telegraph.text = "CRUMPLE"
			attack_telegraph.modulate = Color(0.72, 0.45, 1.0)
			attack_telegraph.show()
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
# NORMAL HIT EFFECT
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
		tween.tween_property(visual, "rotation", Vector3.ZERO, 0.14)

func spawn_hit_impact() -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.2, 0.12)
	flash.light_energy = 5.0
	flash.omni_range = 4.5
	add_child(flash)
	flash.position = Vector3.UP
	get_tree().create_timer(hit_stop_seconds + 0.03).timeout.connect(flash.queue_free)

func react_to_ally_event(source_position: Vector3, incoming_force: Vector3, duration: float) -> void:
	if dying or attack_in_progress:
		return
	stun_timer = maxf(stun_timer, maxf(duration, ally_reaction_stagger))
	decision_timer = maxf(decision_timer, duration + randf_range(0.08, 0.25))
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

	# Final actual impact.
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

	# Normal juggle impact.
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
	set_player_color(Color.RED)

	await get_tree().create_timer(
		0.1
	).timeout

	remove_flash()


func remove_flash():
	set_player_color(Color.WHITE)


func set_player_color(color):
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
	cancel_current_attack()
	get_node("/root/EnemyCombatDirector").notify_ally_disrupted(self, velocity)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if velocity.length_squared() < 1.0:
		velocity = -direction_to_player() * 12.0 + Vector3.UP * 7.0
	rotation.z = clampf(velocity.x * 0.035, -1.1, 1.1)
	var tween := create_tween()
	tween.tween_interval(death_ragdoll_time)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.22)
	tween.tween_callback(queue_free)
