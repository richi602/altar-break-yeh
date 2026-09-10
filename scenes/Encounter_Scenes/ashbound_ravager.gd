extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal break_changed(current: float, maximum: float, locked: bool)
signal broken_started(duration: float)
signal desperation_state(active: bool, counters: int)

@export_category("Elite Combat")
@export var max_health := 650.0
@export var move_speed := 38.0
@export var enraged_move_speed := 52.0
@export var acceleration := 150.0
@export var turn_speed := 22.0
@export var attack_range := 16.0
@export var melee_spacing := 10.0
@export var melee_strafe_speed := 34.0
@export var attack_damage := 28.0
@export var combo_damage := 18.0
@export var combo_final_damage := 34.0
@export var combo_final_knockback := 38.0
@export var claw_attack_radius := 30.0
@export var bite_attack_radius := 22.0
@export var attack_cooldown := 0.65
@export var pounce_range := 30.0
@export var pounce_speed := 78.0
@export var pounce_damage := 38.0
@export var gravity := 28.0

@export_category("Orbit Barrage")
@export var orbit_projectile_scene: PackedScene
@export var orbit_barrage_cooldown := 16.0
@export var orbit_duration := 0.9
@export var orbit_radius := 10.5
@export var orbit_speed := 20.94395
@export var orbit_projectile_count := 15
@export var orbit_projectile_damage := 16.0
@export var initial_barrage_delay := 8.0
@export var orbit_exit_slide_speed := 34.0
@export var orbit_exit_slide_duration := 0.18
@export var orbit_exit_slide_drag := 190.0

@export_category("Desperation: Endless Hunt")
@export var desperation_health_ratio := 0.45
@export var desperation_duration := 11.5
@export var desperation_projectile_count := 48
@export var desperation_shot_interval := 0.19
@export var desperation_charge_interval := 1.35
@export var desperation_charge_windup := 0.42
@export var desperation_charge_duration := 0.34
@export var desperation_charge_speed := 175.0
@export var desperation_jump_clearance := 3.2

@export_category("Break System")
@export var max_break := 720.0
@export var break_decay_delay := 2.75
@export var break_decay_per_second := 12.0
@export var broken_duration := 4.5
@export var broken_damage_multiplier := 1.2
@export var break_resistance_duration := 8.0

@onready var health_bar = $EnemyHealthBar
@onready var telegraph: Label3D = $AttackTelegraph
@onready var rage_aura: GPUParticles3D = $RageAura
@onready var warning_sfx: AudioStreamPlayer3D = $WarningSFX
@onready var impact_sfx: AudioStreamPlayer3D = $ImpactSFX

var health := 0.0
var player: CharacterBody3D
var attacking := false
var can_attack := true
var enraged := false
var dead := false
var pounce_timer := 0.0
var pounce_direction := Vector3.ZERO
var barrage_cooldown_timer := 3.0
var orbiting := false
var orbit_elapsed := 0.0
var orbit_spawned := 0
var orbit_direction_sign := 1.0
var orbit_exit_slide_timer := 0.0
var desperation_triggered := false
var desperation_active := false
var invulnerable := false
var desperation_elapsed := 0.0
var desperation_shot_timer := 0.0
var desperation_charge_timer := 0.0
var desperation_charge_cooldown := 0.0
var desperation_charge_direction := Vector3.ZERO
var desperation_charge_hit := false
var desperation_windup_timer := 0.0
var desperation_shot_index := 0
var charge_indicator: MeshInstance3D
var charge_indicator_material: StandardMaterial3D
var body_base_scale := Vector3.ONE
var dm_world_environment: WorldEnvironment
var dm_original_environment: Environment
var dm_focus_light: OmniLight3D
var dm_vignette_layer: CanvasLayer
var break_value := 0.0
var break_decay_timer := 0.0
var break_resistance_timer := 0.0
var broken := false
var break_locked := false
var desperation_counters := 0
var elite_hud_layer: CanvasLayer
var elite_health_bar: ProgressBar
var elite_break_bar: ProgressBar
var elite_name_label: Label
var elite_state_label: Label


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("elite_enemies")
	health = max_health
	telegraph.hide()
	rage_aura.emitting = false
	barrage_cooldown_timer = initial_barrage_delay
	body_base_scale = $Body.scale
	update_health_bar()
	setup_elite_hud()
	acquire_player()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	if not is_instance_valid(player):
		acquire_player()
	if not is_instance_valid(player):
		brake(delta)
		move_and_slide()
		return
	barrage_cooldown_timer = max(0.0, barrage_cooldown_timer - delta)
	update_break_system(delta)
	if broken:
		brake(delta)
		move_and_slide()
		return

	face_player(delta)
	if desperation_active:
		update_endless_hunt(delta)
		move_and_slide()
		return
	if orbiting:
		update_orbit_barrage(delta)
		move_and_slide()
		return
	if orbit_exit_slide_timer > 0.0:
		orbit_exit_slide_timer = maxf(0.0, orbit_exit_slide_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, orbit_exit_slide_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, orbit_exit_slide_drag * delta)
		move_and_slide()
		if orbit_exit_slide_timer <= 0.0:
			velocity.x = 0.0
			velocity.z = 0.0
		return
	if pounce_timer > 0.0:
		pounce_timer -= delta
		velocity.x = pounce_direction.x * pounce_speed
		velocity.z = pounce_direction.z * pounce_speed
		move_and_slide()
		return
	if attacking:
		maintain_combat_spacing(delta)
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)
	if can_attack and barrage_cooldown_timer <= 0.0 and distance > attack_range + 2.0 and distance <= pounce_range:
		start_orbit_barrage()
		move_and_slide()
		return
	if distance > attack_range:
		chase_player(delta)
	else:
		brake(delta)
		if can_attack:
			combo_attack()
	move_and_slide()


func acquire_player() -> void:
	var candidate := get_tree().current_scene.find_child("Player", true, false)
	if candidate is CharacterBody3D:
		player = candidate


func face_player(delta: float) -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)


func chase_player(delta: float) -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
	var speed := enraged_move_speed if enraged else move_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	var distance := global_position.distance_to(player.global_position)
	if can_attack and distance <= pounce_range and distance > attack_range * 1.5:
		pounce_attack(direction)


func brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)


func maintain_combat_spacing(delta: float) -> void:
	if not is_instance_valid(player):
		brake(delta)
		return
	var offset := player.global_position - global_position
	offset.y = 0.0
	if offset.length_squared() <= 0.01:
		return
	var distance := offset.length()
	var inward := offset.normalized()
	var tangent := Vector3(-inward.z, 0.0, inward.x) * orbit_direction_sign
	var direction := tangent * 0.42
	if distance > melee_spacing + 0.6:
		direction += inward
	elif distance < melee_spacing - 0.6:
		direction -= inward * 0.8
	else:
		direction += inward * 0.28
	direction = direction.normalized()
	var pressure_speed := melee_strafe_speed * (1.25 if enraged else 1.0)
	velocity.x = move_toward(velocity.x, direction.x * pressure_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * pressure_speed, acceleration * delta)


func start_orbit_barrage() -> void:
	if orbit_projectile_scene == null:
		barrage_cooldown_timer = orbit_barrage_cooldown
		return
	orbiting = true
	attacking = true
	can_attack = false
	orbit_elapsed = 0.0
	orbit_spawned = 0
	orbit_direction_sign = -1.0 if randf() < 0.5 else 1.0
	telegraph.text = "ORBIT BARRAGE"
	telegraph.modulate = Color(1.0, 0.12, 0.02, 1.0)
	telegraph.show()


func update_orbit_barrage(delta: float) -> void:
	orbit_elapsed += delta
	var offset := global_position - player.global_position
	offset.y = 0.0
	if offset.length_squared() < 0.1:
		offset = Vector3.RIGHT * orbit_radius
	var radial := offset.normalized()
	var tangent := Vector3(-radial.z, 0.0, radial.x) * orbit_direction_sign
	var radius_error := offset.length() - orbit_radius
	var move_direction := (tangent - radial * radius_error * 0.4).normalized()
	# orbit_speed is radians/second, so tangential speed scales with radius.
	var circle_speed := orbit_speed * orbit_radius * (1.25 if enraged else 1.0)
	velocity.x = move_direction.x * circle_speed
	velocity.z = move_direction.z * circle_speed

	var spawn_interval := orbit_duration / float(max(orbit_projectile_count, 1))
	while orbit_spawned < orbit_projectile_count and orbit_elapsed >= spawn_interval * orbit_spawned:
		spawn_orbit_projectile(orbit_spawned)
		orbit_spawned += 1

	if orbit_elapsed >= orbit_duration:
		orbiting = false
		attacking = false
		telegraph.hide()
		var exit_direction := Vector3(velocity.x, 0.0, velocity.z).normalized()
		velocity.x = exit_direction.x * orbit_exit_slide_speed
		velocity.z = exit_direction.z * orbit_exit_slide_speed
		orbit_exit_slide_timer = orbit_exit_slide_duration
		barrage_cooldown_timer = orbit_barrage_cooldown * (0.75 if enraged else 1.0)
		await get_tree().create_timer(0.35).timeout
		can_attack = true


func spawn_orbit_projectile(index: int) -> void:
	var projectile := orbit_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	# Each projectile owns a stable slot in a raised ring around the player.
	var slot_angle := TAU * float(index) / float(max(orbit_projectile_count, 1))
	var slot_radius := 7.5
	var slot_height := 7.5 + float(index % 3) * 1.2
	projectile.global_position = player.global_position + Vector3(
		cos(slot_angle) * slot_radius,
		slot_height,
		sin(slot_angle) * slot_radius
	)
	# Shots launch in groups of three. Each group creates a clean dodge beat.
	var segment: int = index / 3
	var remaining_orbit_time: float = maxf(0.0, orbit_duration - orbit_elapsed)
	var launch_delay: float = remaining_orbit_time + 0.9 + float(segment) * 0.38
	projectile.arm(player, launch_delay, orbit_projectile_damage, slot_angle, slot_radius, slot_height)
	# Forward or lateral movement carries the player out of the shot path.
	projectile.set_trailing_target(4.5)
	projectile.set_meta("volley_segment", segment + 1)


func pounce_attack(direction: Vector3) -> void:
	attacking = true
	can_attack = false
	telegraph.text = "POUNCE"
	telegraph.modulate = Color(1.0, 0.25, 0.05, 1.0)
	telegraph.show()
	await get_tree().create_timer(0.32 if enraged else 0.48).timeout
	if dead or not is_instance_valid(player):
		finish_attack()
		return
	telegraph.hide()
	pounce_direction = direction
	pounce_timer = 0.24
	await get_tree().create_timer(0.24).timeout
	if is_instance_valid(player) and player.has_method("break_panes_in_enemy_attack"):
		player.break_panes_in_enemy_attack(global_position, attack_range + 2.0)
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range + 2.0:
		player.take_damage(pounce_damage)
	await get_tree().create_timer(0.18).timeout
	finish_attack()


func combo_attack() -> void:
	attacking = true
	can_attack = false
	await perform_claw_swipe($LeftBlade, true)
	if dead:
		return
	if randf() < 0.72:
		await perform_claw_swipe($RightBlade, false)
		if dead:
			return
		if randf() < 0.62:
			await perform_lunging_bite()
	finish_attack()


func perform_claw_swipe(claw: MeshInstance3D, left_side: bool) -> void:
	telegraph.text = "LEFT CLAW" if left_side else "RIGHT CLAW"
	telegraph.modulate = Color(1.0, 0.72, 0.08, 1.0)
	telegraph.show()
	var base_rotation := claw.rotation
	var windup_rotation := base_rotation + Vector3(0.0, 0.0, -1.15 if left_side else 1.15)
	var tween := create_tween()
	tween.tween_property(claw, "rotation", windup_rotation, 0.36 if enraged else 0.52)
	await tween.finished
	claw.scale = Vector3.ONE * 1.28
	warning_sfx.play()
	await get_tree().create_timer(0.16).timeout
	telegraph.hide()
	var strike := create_tween()
	strike.tween_property(claw, "rotation", base_rotation + Vector3(0.0, 0.0, 1.7 if left_side else -1.7), 0.065)
	spawn_slash_vfx(left_side)
	impact_sfx.play()
	if is_instance_valid(player) and player.has_method("break_panes_in_enemy_attack"):
		player.break_panes_in_enemy_attack(global_position, claw_attack_radius)
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= claw_attack_radius:
		player.take_damage(attack_damage)
	await strike.finished
	claw.scale = Vector3.ONE
	var recover := create_tween()
	recover.tween_property(claw, "rotation", base_rotation, 0.1)
	await recover.finished


func perform_lunging_bite() -> void:
	telegraph.text = "BITE — DODGE"
	telegraph.modulate = Color(1.0, 0.12, 0.03, 1.0)
	telegraph.show()
	$Body.scale = body_base_scale * Vector3(1.18, 0.78, 1.18)
	warning_sfx.play()
	await get_tree().create_timer(0.68 if not enraged else 0.46).timeout
	$Body.scale = body_base_scale
	telegraph.hide()
	if not is_instance_valid(player):
		return
	var bite_direction := player.global_position - global_position
	bite_direction.y = 0.0
	if bite_direction.length_squared() > 0.01:
		bite_direction = bite_direction.normalized()
		global_position += bite_direction * 5.5
	if player.has_method("break_panes_in_enemy_attack"):
		player.break_panes_in_enemy_attack(global_position, bite_attack_radius)
	if global_position.distance_to(player.global_position) <= bite_attack_radius:
		player.take_damage(combo_final_damage)
		if player.has_method("apply_enemy_knockback"):
			player.apply_enemy_knockback(bite_direction, combo_final_knockback, 0.32)
	spawn_bite_vfx()
	impact_sfx.play()
	await get_tree().create_timer(0.28).timeout


func spawn_slash_vfx(left_side: bool) -> void:
	# Three enormous tapered trails read unmistakably as claw marks and show
	# the full damaging width.
	for mark_index in range(3):
		var slash := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.25, 2.4, 34.0)
		slash.mesh = mesh
		var side_sign := -1.0 if left_side else 1.0
		var offset := Vector3(side_sign * (float(mark_index) - 1.0) * 3.2, 4.0 + float(mark_index) * 0.9, -16.0)
		spawn_attack_vfx(slash, Color(1.0, 0.18, 0.008, 0.95), offset, Vector3(1.35, 1.35, 1.15), side_sign * (0.5 + float(mark_index) * 0.07))


func spawn_bite_vfx() -> void:
	# Two closing rows of spectral teeth visualize the narrower bite hitbox.
	for jaw_value in [-1.0, 1.0]:
		var jaw: float = float(jaw_value)
		for tooth_index in range(5):
			var tooth := MeshInstance3D.new()
			var mesh := PrismMesh.new()
			mesh.size = Vector3(2.5, 7.5, 2.8)
			tooth.mesh = mesh
			var x_offset: float = (float(tooth_index) - 2.0) * 3.0
			var y_offset: float = 5.0 + jaw * 4.0
			spawn_attack_vfx(tooth, Color(1.0, 0.045, 0.005, 0.95), Vector3(x_offset, y_offset, -13.0), Vector3(1.3, 1.3, 1.3), 0.0)


func spawn_attack_vfx(effect: MeshInstance3D, color: Color, local_offset: Vector3, target_scale: Vector3, yaw: float) -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 8.0
	effect.material_override = material
	get_tree().current_scene.add_child(effect)
	effect.global_transform = global_transform
	effect.position += global_transform.basis * local_offset
	effect.rotation.y += yaw
	effect.scale = Vector3.ONE * 0.15
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", target_scale, 0.18)
	tween.tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.22)
	tween.chain().tween_callback(effect.queue_free)


func finish_attack() -> void:
	attacking = false
	telegraph.hide()
	await get_tree().create_timer(attack_cooldown * (0.55 if enraged else 1.0)).timeout
	can_attack = true


func take_damage(amount) -> void:
	if dead or invulnerable:
		return
	health -= float(amount) * (broken_damage_multiplier if broken else 1.0)
	update_health_bar()
	health_changed.emit(health, max_health)
	flash_hit()
	if health <= 0.0:
		die()
		return
	if not desperation_triggered and health <= max_health * desperation_health_ratio:
		desperation_triggered = true
		call_deferred("begin_endless_hunt")


func update_health_bar() -> void:
	if health_bar:
		health_bar.set_health(max(health, 0.0), max_health)
	if elite_health_bar:
		elite_health_bar.value = maxf(health, 0.0)


func enrage() -> void:
	enraged = true
	rage_aura.emitting = true
	attack_damage *= 1.25
	combo_damage *= 1.25
	pounce_damage *= 1.2


func begin_endless_hunt() -> void:
	if dead or desperation_active:
		return
	desperation_active = true
	break_locked = true
	break_changed.emit(break_value, max_break, true)
	desperation_state.emit(true, desperation_counters)
	invulnerable = true
	if not enraged:
		enrage()
	attacking = true
	can_attack = false
	telegraph.text = "THE ENDLESS HUNT"
	telegraph.modulate = Color(1.0, 0.02, 0.02, 1.0)
	telegraph.show()
	begin_dm_focus()
	if is_instance_valid(player) and player.has_method("apply_enemy_knockback"):
		player.apply_enemy_knockback(player.global_position - global_position, 65.0, 0.45)
	desperation_elapsed = -0.85
	desperation_shot_timer = 0.0
	desperation_charge_cooldown = 1.0
	desperation_charge_timer = 0.0
	desperation_windup_timer = 0.0
	desperation_shot_index = 0
	await get_tree().create_timer(desperation_duration + 0.85).timeout
	velocity = Vector3.ZERO
	telegraph.text = "EXHAUSTED"
	telegraph.show()
	await get_tree().create_timer(2.0).timeout
	telegraph.hide()
	desperation_active = false
	break_locked = false
	break_changed.emit(break_value, max_break, false)
	desperation_state.emit(false, desperation_counters)
	invulnerable = false
	attacking = false
	can_attack = true
	end_dm_focus()


func update_endless_hunt(delta: float) -> void:
	desperation_elapsed += delta
	if desperation_elapsed < 0.0:
		brake(delta)
		return
	if desperation_elapsed >= desperation_duration:
		brake(delta)
		return

	desperation_shot_timer -= delta
	if desperation_shot_timer <= 0.0 and desperation_shot_index < desperation_projectile_count:
		fire_desperation_shot()
		desperation_shot_index += 1
		desperation_shot_timer = desperation_shot_interval

	if desperation_charge_timer > 0.0:
		desperation_charge_timer -= delta
		velocity.x = desperation_charge_direction.x * desperation_charge_speed
		velocity.z = desperation_charge_direction.z * desperation_charge_speed
		if is_instance_valid(player) and player.has_method("break_panes_in_enemy_attack"):
			player.break_panes_in_enemy_attack(global_position, 5.5)
		if not desperation_charge_hit and is_instance_valid(player):
			var horizontal_distance := Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length()
			var player_is_low := player.global_position.y <= global_position.y + desperation_jump_clearance
			if horizontal_distance <= 5.5 and player_is_low:
				desperation_charge_hit = true
				player.take_damage(combo_final_damage)
				if player.has_method("apply_enemy_knockback"):
					player.apply_enemy_knockback(desperation_charge_direction, 58.0, 0.4)
		if desperation_charge_timer <= 0.0:
			desperation_charge_cooldown = desperation_charge_interval
			telegraph.hide()
		return

	if desperation_windup_timer > 0.0:
		desperation_windup_timer -= delta
		brake(delta)
		telegraph.text = "JUMP!  %.1f" % desperation_windup_timer
		update_charge_indicator()
		if desperation_windup_timer <= 0.0:
			desperation_charge_direction = player.global_position - global_position
			desperation_charge_direction.y = 0.0
			desperation_charge_direction = desperation_charge_direction.normalized()
			desperation_charge_timer = desperation_charge_duration
			desperation_charge_hit = false
			telegraph.text = "CHARGE"
			clear_charge_indicator()
			impact_sfx.play()
		return

	desperation_charge_cooldown -= delta
	if desperation_charge_cooldown <= 0.0:
		desperation_windup_timer = desperation_charge_windup
		telegraph.text = "JUMP!"
		telegraph.modulate = Color(1.0, 0.95, 0.12, 1.0)
		telegraph.show()
		create_charge_indicator()
		warning_sfx.play()
		return

	# Hunt between charges: fast lateral pressure keeps the player moving.
	var offset := global_position - player.global_position
	offset.y = 0.0
	var radial := offset.normalized() if offset.length_squared() > 0.01 else Vector3.RIGHT
	var tangent := Vector3(-radial.z, 0.0, radial.x) * orbit_direction_sign
	var hunt_direction := (tangent - radial * (offset.length() - 12.0) * 0.25).normalized()
	velocity.x = hunt_direction.x * 72.0
	velocity.z = hunt_direction.z * 72.0


func fire_desperation_shot() -> void:
	if orbit_projectile_scene == null or not is_instance_valid(player):
		return
	var projectile := orbit_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	var side := -1.0 if desperation_shot_index % 2 == 0 else 1.0
	projectile.global_position = global_position + Vector3.UP * 5.5 + global_transform.basis.x * side * 1.6
	# Each shot flashes and fires independently rather than waiting in groups.
	# A short harmless hover precedes the flash/launch, making every shot readable.
	projectile.arm(player, 0.92, orbit_projectile_damage, 0.0, 0.0, 0.0, false)
	projectile.set_trailing_target(5.0)


func begin_dm_focus() -> void:
	dm_world_environment = get_tree().current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if dm_world_environment and dm_world_environment.environment:
		dm_original_environment = dm_world_environment.environment
		var dramatic_environment := dm_original_environment.duplicate() as Environment
		dramatic_environment.adjustment_enabled = true
		dramatic_environment.adjustment_brightness = 0.62
		dramatic_environment.adjustment_saturation = 0.68
		dm_world_environment.environment = dramatic_environment

	dm_focus_light = OmniLight3D.new()
	dm_focus_light.light_color = Color(1.0, 0.12, 0.025)
	dm_focus_light.light_energy = 9.0
	dm_focus_light.omni_range = 32.0
	dm_focus_light.shadow_enabled = true
	add_child(dm_focus_light)
	dm_focus_light.position = Vector3(0.0, 5.0, 0.0)

	dm_vignette_layer = CanvasLayer.new()
	dm_vignette_layer.layer = 55
	get_tree().current_scene.add_child(dm_vignette_layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){ float d=distance(UV,vec2(0.5)); float a=smoothstep(0.28,0.72,d)*0.72; COLOR=vec4(0.025,0.0,0.045,a); }"
	vignette_material.shader = shader
	vignette.material = vignette_material
	dm_vignette_layer.add_child(vignette)


func end_dm_focus() -> void:
	if is_instance_valid(dm_world_environment) and dm_original_environment:
		dm_world_environment.environment = dm_original_environment
	if is_instance_valid(dm_focus_light):
		dm_focus_light.queue_free()
	if is_instance_valid(dm_vignette_layer):
		dm_vignette_layer.queue_free()
	dm_focus_light = null
	dm_vignette_layer = null
	dm_original_environment = null


func create_charge_indicator() -> void:
	clear_charge_indicator()
	charge_indicator = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10.0, 0.08, 90.0)
	charge_indicator.mesh = mesh
	charge_indicator_material = StandardMaterial3D.new()
	charge_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	charge_indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	charge_indicator_material.albedo_color = Color(1.0, 0.04, 0.01, 0.3)
	charge_indicator_material.emission_enabled = true
	charge_indicator_material.emission = Color(1.0, 0.02, 0.0)
	charge_indicator.material_override = charge_indicator_material
	get_tree().current_scene.add_child(charge_indicator)
	update_charge_indicator()


func update_charge_indicator() -> void:
	if not is_instance_valid(charge_indicator) or not is_instance_valid(player):
		return
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return
	direction = direction.normalized()
	charge_indicator.global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP), global_position + direction * 45.0 + Vector3.UP * 0.08)
	var progress := clampf(1.0 - desperation_windup_timer / desperation_charge_windup, 0.0, 1.0)
	var flash := sin(progress * progress * 42.0) * 0.5 + 0.5
	charge_indicator_material.albedo_color = Color(1.0, 0.04, 0.01, lerpf(0.25, 0.9, flash * progress))
	charge_indicator_material.emission_energy_multiplier = lerpf(2.0, 16.0, progress)


func clear_charge_indicator() -> void:
	if is_instance_valid(charge_indicator):
		charge_indicator.queue_free()
	charge_indicator = null


func update_break_system(delta: float) -> void:
	if break_resistance_timer > 0.0:
		break_resistance_timer = maxf(0.0, break_resistance_timer - delta)
	if broken or break_locked or break_value <= 0.0:
		return
	break_decay_timer -= delta
	if break_decay_timer <= 0.0:
		break_value = maxf(0.0, break_value - break_decay_per_second * delta)
		update_break_hud()


func apply_break_damage(amount: float, counter_hit: bool = false) -> void:
	if dead or broken or break_resistance_timer > 0.0:
		return
	if break_locked and not counter_hit:
		return
	var applied := amount
	if counter_hit:
		applied *= 1.8
		desperation_counters += 1
		desperation_state.emit(true, desperation_counters)
	break_value = minf(max_break, break_value + applied)
	break_decay_timer = break_decay_delay
	update_break_hud()
	break_changed.emit(break_value, max_break, break_locked)
	if break_value >= max_break:
		start_broken_state()


func start_broken_state() -> void:
	if broken or dead:
		return
	broken = true
	break_locked = false
	invulnerable = false
	desperation_active = false
	orbiting = false
	attacking = false
	can_attack = false
	velocity = Vector3.ZERO
	clear_charge_indicator()
	end_dm_focus()
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	telegraph.text = "BROKEN"
	telegraph.modulate = Color(1.0, 0.75, 0.1, 1.0)
	telegraph.show()
	if elite_state_label:
		elite_state_label.text = "BROKEN  OPEN ARSENAL"
	broken_started.emit(broken_duration)
	if is_instance_valid(player) and player.has_method("begin_open_arsenal"):
		player.begin_open_arsenal(4.0)
	await get_tree().create_timer(broken_duration).timeout
	if dead:
		return
	broken = false
	break_value = 0.0
	max_break *= 1.2
	break_resistance_timer = break_resistance_duration
	telegraph.text = "RECOVERY BURST"
	if elite_state_label:
		elite_state_label.text = "BREAK RESIST"
	update_break_hud()
	await get_tree().create_timer(0.45).timeout
	telegraph.hide()
	if elite_state_label:
		elite_state_label.text = ""
	can_attack = true


func setup_elite_hud() -> void:
	elite_hud_layer = CanvasLayer.new()
	elite_hud_layer.layer = 45
	get_tree().current_scene.add_child.call_deferred(elite_hud_layer)
	var root := Control.new()
	root.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 460.0, 24.0)
	root.size = Vector2(920.0, 108.0)
	root.pivot_offset = Vector2(460.0, 0.0)
	root.scale = Vector2.ONE * 0.62
	elite_hud_layer.add_child(root)
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([Vector2(0, 44), Vector2(64, 0), Vector2(856, 0), Vector2(920, 44), Vector2(856, 88), Vector2(64, 88)])
	outer.color = Color(0.82, 0.65, 0.25, 1.0)
	root.add_child(outer)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(8, 44), Vector2(68, 5), Vector2(852, 5), Vector2(912, 44), Vector2(852, 83), Vector2(68, 83)])
	inner.color = Color(0.055, 0.04, 0.075, 0.96)
	root.add_child(inner)
	elite_name_label = Label.new()
	elite_name_label.text = "THE ASHEN HOUND"
	elite_name_label.position = Vector2(110, 7)
	elite_name_label.size = Vector2(700, 32)
	elite_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_name_label.add_theme_font_size_override("font_size", 25)
	elite_name_label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.95))
	root.add_child(elite_name_label)
	elite_health_bar = ProgressBar.new()
	elite_health_bar.position = Vector2(82, 47)
	elite_health_bar.size = Vector2(756, 20)
	elite_health_bar.max_value = max_health
	elite_health_bar.value = health
	elite_health_bar.show_percentage = false
	var health_back := StyleBoxFlat.new()
	health_back.bg_color = Color(0.08, 0.055, 0.09)
	health_back.border_color = Color(0.48, 0.38, 0.52)
	health_back.set_border_width_all(2)
	health_back.set_corner_radius_all(9)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.64, 0.035, 0.16)
	health_fill.set_corner_radius_all(8)
	elite_health_bar.add_theme_stylebox_override("background", health_back)
	elite_health_bar.add_theme_stylebox_override("fill", health_fill)
	root.add_child(elite_health_bar)
	elite_break_bar = ProgressBar.new()
	elite_break_bar.position = Vector2(122, 74)
	elite_break_bar.size = Vector2(660, 10)
	elite_break_bar.max_value = max_break
	elite_break_bar.value = break_value
	elite_break_bar.show_percentage = false
	root.add_child(elite_break_bar)
	for i in range(1, 8):
		var divider := ColorRect.new()
		divider.position = Vector2(122 + i * 82.5, 73)
		divider.size = Vector2(3, 12)
		divider.color = Color(0.82, 0.65, 0.25)
		root.add_child(divider)
	var break_text := Label.new()
	break_text.text = "BREAK"
	break_text.position = Vector2(790, 67)
	break_text.add_theme_font_size_override("font_size", 12)
	break_text.add_theme_color_override("font_color", Color(0.88, 0.7, 0.3))
	root.add_child(break_text)
	elite_state_label = Label.new()
	elite_state_label.position = Vector2(250, 89)
	elite_state_label.size = Vector2(420, 22)
	elite_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_state_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	root.add_child(elite_state_label)


func setup_elite_hud_legacy() -> void:
	elite_hud_layer = CanvasLayer.new()
	elite_hud_layer.layer = 45
	get_tree().current_scene.add_child.call_deferred(elite_hud_layer)
	var plate := VBoxContainer.new()
	plate.set_anchors_preset(Control.PRESET_CENTER_TOP)
	plate.offset_left = -340.0
	plate.offset_right = 340.0
	plate.offset_top = 22.0
	plate.offset_bottom = 118.0
	elite_hud_layer.add_child(plate)
	elite_name_label = Label.new()
	elite_name_label.text = "ASHBOUND RAVAGER"
	elite_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_name_label.add_theme_font_size_override("font_size", 25)
	elite_name_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.86))
	plate.add_child(elite_name_label)
	elite_health_bar = ProgressBar.new()
	elite_health_bar.max_value = max_health
	elite_health_bar.value = health
	elite_health_bar.show_percentage = false
	elite_health_bar.custom_minimum_size = Vector2(680, 18)
	plate.add_child(elite_health_bar)
	elite_break_bar = ProgressBar.new()
	elite_break_bar.max_value = max_break
	elite_break_bar.value = break_value
	elite_break_bar.show_percentage = false
	elite_break_bar.custom_minimum_size = Vector2(680, 10)
	elite_break_bar.modulate = Color(0.72, 0.28, 1.0)
	plate.add_child(elite_break_bar)
	elite_state_label = Label.new()
	elite_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_state_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	plate.add_child(elite_state_label)


func update_break_hud() -> void:
	if elite_break_bar:
		elite_break_bar.max_value = max_break
		elite_break_bar.value = break_value
		elite_break_bar.modulate = Color(0.3, 0.3, 0.35) if break_locked else Color(0.72, 0.28, 1.0)


# Elite poise: all player hit-reaction entry points intentionally reject
# stun, knockback, launch, juggling, and finisher restraint.
func apply_hit_effect(_hit_direction: Vector3, knockback_strength: float, launch_force: float, stun_time: float, is_juggle_hit: bool = false) -> void:
	var counter_hit := desperation_active and desperation_charge_timer > 0.0 and is_instance_valid(player) and not player.is_on_floor()
	if counter_hit:
		# A clean aerial counter still deals a major fixed posture hit, but the
		# reinforced elite now requires roughly nine counters from an empty gauge.
		apply_break_damage(240.0 / 5.4, true)
		return
	var pressure := 1.5 + knockback_strength * 0.07 + launch_force * 0.05 + stun_time * 2.0
	if is_juggle_hit:
		pressure += 2.0
	apply_break_damage(pressure, counter_hit)


func begin_finisher_setup(_incoming_finisher_id: int, _setup_launch_force: float, _setup_hold_time: float, _setup_stun_time: float) -> void:
	apply_break_damage(8.0)


func receive_finisher_hit(_incoming_finisher_id: int, _total_hits: int, _hit_direction: Vector3, _juggle_knockback: float, _juggle_launch: float, _juggle_stun: float, _final_knockback: float, _final_launch: float, _final_stun: float) -> void:
	apply_break_damage(5.0)


func flash_hit() -> void:
	var body_material := $Body.material_override as StandardMaterial3D
	if body_material:
		var old_color := body_material.albedo_color
		body_material.albedo_color = Color.WHITE
		await get_tree().create_timer(0.07).timeout
		if is_instance_valid(self) and not dead:
			body_material.albedo_color = old_color


func die() -> void:
	dead = true
	for player_node in get_tree().get_nodes_in_group("players"):
		if player_node.has_method("on_enemy_killed"):
			player_node.on_enemy_killed()
	orbiting = false
	telegraph.hide()
	clear_charge_indicator()
	end_dm_focus()
	if is_instance_valid(elite_hud_layer):
		elite_hud_layer.queue_free()
	queue_free()
