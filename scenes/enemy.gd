extends CharacterBody3D


# =========================
# REFERENCES
# =========================

@onready var health_bar = $EnemyHealthBar
@onready var attack_telegraph = $AttackTelegraph


# =========================
# MOVEMENT
# =========================

@export var move_speed = 30.0
@export var gravity = 20.0

@export var turn_speed = 10.0
@export var movement_acceleration = 60.0


# =========================
# ENEMY SEPARATION
# =========================

@export var separation_radius = 5.0
@export var separation_strength = 0.75


# =========================
# HIT REACTION
# =========================

@export var knockback_drag = 30.0
@export var knockback_duration = 0.18

var stun_timer = 0.0
var knockback_timer = 0.0

var attack_cancelled = false


# =========================
# FINISHER JUGGLE
# =========================

@export var juggle_gravity_multiplier = 0.35
@export var juggle_gravity_duration = 0.30

var juggle_gravity_timer = 0.0


# =========================
# ACTIVE FINISHERS
# =========================

var active_finishers = {}


# =========================
# ATTACK
# =========================

@export var attack_range = 3.0
@export var attack_damage = 20

@export var attack_cooldown = 1.0
@export var attack_windup = 0.35
@export var attack_recovery = 0.25

var can_attack = true


# =========================
# HEALTH
# =========================

@export var max_health: float = 100.0

var health: float


# =========================
# PLAYER DETECTION
# =========================

@export var aggroRadius: Area3D

var Player: CharacterBody3D
var aggro = false


# =========================
# START
# =========================

func _ready():

	add_to_group("enemies")

	attack_telegraph.hide()

	health = max_health


	health_bar.set_health(
		health,
		max_health
	)


# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):


	if juggle_gravity_timer > 0:

		juggle_gravity_timer -= delta


	if not is_on_floor():

		var current_gravity = gravity


		if juggle_gravity_timer > 0:

			current_gravity *= (
				juggle_gravity_multiplier
			)


		velocity.y -= (
			current_gravity
			* delta
		)


	if stun_timer > 0:

		stun_timer -= delta


	if knockback_timer > 0:

		knockback_timer -= delta


		velocity.x = move_toward(
			velocity.x,
			0,
			knockback_drag * delta
		)


		velocity.z = move_toward(
			velocity.z,
			0,
			knockback_drag * delta
		)


		move_and_slide()

		return


	if stun_timer > 0:

		velocity.x = move_toward(
			velocity.x,
			0,
			movement_acceleration * delta
		)


		velocity.z = move_toward(
			velocity.z,
			0,
			movement_acceleration * delta
		)


		move_and_slide()

		return


	if Player == null:

		velocity.x = move_toward(
			velocity.x,
			0,
			movement_acceleration * delta
		)


		velocity.z = move_toward(
			velocity.z,
			0,
			movement_acceleration * delta
		)


		move_and_slide()

		return


	var distance = global_position.distance_to(
		Player.global_position
	)


	var look_direction = (
		Player.global_position
		- global_position
	)


	look_direction.y = 0


	if look_direction.length() > 0.01:

		var target_rotation = atan2(
			-look_direction.x,
			-look_direction.z
		)


		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			turn_speed * delta
		)


	if distance > attack_range:

		var chase_direction = (
			Player.global_position
			- global_position
		)


		chase_direction.y = 0


		if chase_direction.length() > 0:

			chase_direction = (
				chase_direction.normalized()
			)


		var separation = Vector3.ZERO


		var enemies = get_tree().get_nodes_in_group(
			"enemies"
		)


		for enemy in enemies:

			if enemy == self:
				continue


			if not enemy is Node3D:
				continue


			if not is_instance_valid(enemy):
				continue


			var away = (
				global_position
				- enemy.global_position
			)


			away.y = 0


			var enemy_distance = away.length()


			if (
				enemy_distance > 0.01
				and
				enemy_distance < separation_radius
			):

				var closeness = (
					1.0
					- enemy_distance
					/ separation_radius
				)


				closeness *= closeness


				separation += (
					away.normalized()
					* closeness
				)


		var final_direction = chase_direction


		if separation.length() > 0:

			final_direction += (
				separation
				* separation_strength
			)


		if final_direction.length() > 0:

			final_direction = (
				final_direction.normalized()
			)


		var target_velocity_x = (
			final_direction.x
			* move_speed
		)


		var target_velocity_z = (
			final_direction.z
			* move_speed
		)


		velocity.x = move_toward(
			velocity.x,
			target_velocity_x,
			movement_acceleration * delta
		)


		velocity.z = move_toward(
			velocity.z,
			target_velocity_z,
			movement_acceleration * delta
		)


	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			movement_acceleration * delta
		)


		velocity.z = move_toward(
			velocity.z,
			0,
			movement_acceleration * delta
		)


		if can_attack:

			attack()


	move_and_slide()


# =========================
# MELEE ATTACK
# =========================

func attack():

	can_attack = false
	attack_cancelled = false

	attack_telegraph.show()


	await get_tree().create_timer(
		attack_windup
	).timeout


	if attack_cancelled:

		attack_telegraph.hide()

		can_attack = true

		return


	attack_telegraph.hide()


	if not is_instance_valid(Player):

		can_attack = true

		return


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


	await get_tree().create_timer(
		attack_cooldown
	).timeout


	can_attack = true


# =========================
# PLAYER DETECTED
# =========================

func _on_aggro_radius_body_entered(body):

	if body.name == "Player":

		Player = body

		aggro = true


# =========================
# DAMAGE
# =========================

func take_damage(amount):

	health -= amount


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


	if health <= 0:

		die()


# =========================
# BEGIN FINISHER
# =========================

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


	attack_cancelled = true

	attack_telegraph.hide()


	stun_timer = max(
		stun_timer,
		setup_stun_time
	)


	juggle_gravity_timer = max(
		juggle_gravity_timer,
		setup_hold_time
	)


	velocity.x = 0
	velocity.z = 0


	velocity.y = max(
		velocity.y,
		setup_launch_force
	)


	knockback_timer = max(
		knockback_timer,
		0.25
	)


# =========================
# HIT EFFECT
# =========================

func apply_hit_effect(
	hit_direction: Vector3,
	knockback_strength: float,
	launch_force: float,
	stun_time: float,
	is_juggle_hit: bool = false
):

	attack_cancelled = true

	attack_telegraph.hide()


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

	push_direction.y = 0


	if push_direction.length() > 0:

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


# =========================
# FINISHER HIT COUNTER
# =========================

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


# =========================
# FLASH
# =========================

func flash_red():

	set_player_color(Color.RED)


	await get_tree().create_timer(
		0.1
	).timeout


	remove_flash()


func set_player_color(color):

	var meshes = get_all_meshes(self)


	for mesh in meshes:

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


				if original:

					material = original.duplicate()

				else:

					material = StandardMaterial3D.new()


				mesh.set_surface_override_material(
					i,
					material
				)


			material.albedo_color = color


func remove_flash():

	set_player_color(Color.WHITE)


# =========================
# FIND MESHES
# =========================

func get_all_meshes(node):

	var meshes = []


	for child in node.get_children():

		if child is MeshInstance3D:

			meshes.append(child)


		meshes += get_all_meshes(child)


	return meshes


# =========================
# DEATH
# =========================

func die():

	print("Enemy died")

	queue_free()
