extends CharacterBody3D

# ===== NODE REFERENCES =====
@onready var camera_pivot = find_child("CameraPivot", true, false)
@onready var spring_arm = find_child("SpringArm3D", true, false)
@onready var camera = find_child("Camera3D", true, false)
@onready var health_bar = find_child("HealthBar", true, false)
@onready var anim = find_child("AnimationPlayer", true, false)

# ===== MOVEMENT =====
@export_category("Movement")
@export var speed = 40.0
@export var jump_force = 25.0
@export var gravity = 50.0

# ===== DASH =====
@export_category("Dash")
@export_group("Movement")
@export var dodge_speed = 300.0
@export var dodge_duration = 0.26
@export var dodge_cooldown = 0.5
@export_group("Dash Hit")
@export var dodge_hit_radius = 6.0
@export var dodge_damage = 8.0
@export var dodge_knockback = 18.0
@export var dodge_launch_force = 24.0
@export var dodge_hit_stun = 0.30
@export_group("End AOE")
@export var dodge_end_aoe_radius = 9.0
@export var dodge_end_damage = 12.0
@export var dodge_end_knockback = 22.0
@export var dodge_end_launch_force = 28.0
@export var dodge_end_stun = 0.35
var is_dodging = false
var can_dodge = true
var dodge_timer = 0.0
var dodge_cooldown_timer = 0.0
var dodge_direction = Vector3.ZERO
var dodge_hit_ids: Dictionary = {}
var dodge_invincible = false
var hit_invincible = false

# ===== CAMERA =====
@export_category("Camera")
@export_group("Mouse")
@export var mouse_sensitivity = 0.003
@export var vertical_mouse_sensitivity = 0.002
@export_group("Pitch")
@export var camera_pitch_min = -45.0
@export var camera_pitch_max = 35.0
@export var camera_pitch_smooth_speed = 20.0
@export_group("Normal Camera")
@export var camera_distance = 6.0
@export var air_camera_distance = 8.0
@export var air_camera_fov_add = 5.0
@export var air_camera_response = 7.0
@export var air_target_pitch_strength = 3.0
@export var camera_yaw_return_speed = 9.0
@export_group("Collision")
@export_flags_3d_physics var camera_collision_mask: int = 1
@export var camera_collision_radius = 0.35
@export var camera_collision_margin = 0.30
@export var camera_near = 0.05
var camera_pitch = 0.0
var camera_pitch_target = 0.0
var camera_base_fov = 75.0

# ===== SLAM CAMERA =====
@export_category("Slam Camera")
@export_group("Normal Slam")
@export var slam_camera_wide_distance = 13.0
@export var slam_camera_focus_distance = 6.0
@export var slam_camera_wide_fov_add = 26.0
@export var slam_camera_focus_fov_add = -10.0
@export var slam_camera_swing_angle = 45.0
@export var slam_camera_yaw_speed = 18.0
@export var slam_camera_pitch_speed = 18.0
@export var slam_camera_zoom_speed = 16.0
@export var slam_camera_focus_speed = 9.0
@export var slam_camera_pitch_lead = 12.0
@export var slam_camera_focus_fall_distance = 14.0
@export_group("Empowered Slam")
@export var empowered_camera_follow_speed = 20.0
@export var empowered_camera_orbit_angle = 70.0
@export var empowered_camera_orbit_speed = 6.0
@export var empowered_camera_pitch = 12.0
@export var empowered_camera_height = 1.1
@export_group("Impact")
@export var slam_camera_impact_hold_time = 0.22
@export var slam_impact_fov_punch = 12.0
@export var empowered_impact_fov_punch = 24.0
var slam_camera_active = false
var slam_camera_detached = false
var slam_camera_focus = 0.0
var slam_camera_side = 1.0
var slam_camera_flip = 1.0
var slam_start_enemy_y = 0.0
var slam_camera_hold_timer = 0.0
var slam_camera_hold_point = Vector3.ZERO
var detached_camera_base_yaw = 0.0
var camera_original_parent = null
var slam_saved_camera_transform = Transform3D.IDENTITY
var slam_saved_spring_length = 6.0
var slam_saved_fov = 75.0

# ===== HEALTH =====
@export_category("Health")
@export var max_health = 10000
@export var hit_invincibility_time = 0.3
var health = 0.0

# ===== LOCK ON =====
@export_category("Lock On")
@export var lock_range = 65.0
@export var lock_turn_speed = 5.0
var locked_enemy = null
var lock_targets = []
var lock_index = 0
var lock_reticle = null

# ===== WALK OF EMO BAND — RMB TELEPORT =====
@export_category("Walk of EMO BAND")
@export_group("Teleport")
@export var teleport_range = 100.0
@export var teleport_cooldown = 0.35
@export var teleport_side_offset = 2.0
@export var teleport_height_offset = 0.5
@export_group("Targeting")
@export var teleport_target_screen_radius = 0.30
@export var teleport_center_priority = 3.5
@export var teleport_distance_priority = 0.15
@export_group("Safe Position")
@export var teleport_position_checks = 8
@export var teleport_use_fallback = true
@export_group("Camera")
@export var teleport_camera_duration = 0.45
@export var teleport_camera_vertical_strength = 12.0
@export_group("Air Control")
@export var teleport_low_gravity_duration = 0.65
@export var teleport_gravity_multiplier = 0.20
@export_group("Follow-Up")
@export var teleport_followup_window = 1.60
var teleport_cooldown_timer = 0.0
var teleport_camera_timer = 0.0
var teleport_followup_timer = 0.0
var low_gravity_timer = 0.0
var teleport_focus_target = null
var teleport_camera_target = null
var teleport_hold_active = false
var teleport_held_enemy = null
var teleport_hold_player_position = Vector3.ZERO
var teleport_hold_enemy_position = Vector3.ZERO
var teleport_enemy_was_physics_active = true

# ===== PANES OF PAIN =====
@export_category("Panes of Pain")
@export_group("Physics")
@export_flags_3d_physics var glass_collision_layer: int = 2
@export var glass_pane_max_count = 96
@export_group("Air Movement")
@export var glass_walk_gravity_multiplier = 0.12
@export var glass_walk_max_fall_speed = -3.0
@export_group("Movement Panes")
@export var walk_pane_size = Vector3(7.0, 0.18, 7.0)
@export var walk_pane_spawn_interval = 0.10
@export var walk_pane_lifetime = 12.0
@export var walk_pane_forward_offset = 1.3
@export var walk_pane_vertical_offset = 1.20
@export_group("Glass Arena")
@export var arena_pane_size = Vector3(26.0, 0.24, 26.0)
@export var arena_pane_lifetime = 20.0
@export var arena_pane_vertical_offset = 1.35
@export var arena_player_lift = 2.0
@export var arena_enemy_lift = 1.5
@export_group("Shatter")
@export var pane_shatter_shard_count = 14
@export var pane_shatter_distance = 6.0
@export var pane_shatter_duration = 0.40
@export_group("Ult Charge")
@export var small_pane_ult_charge = 10.0
@export var big_pane_ult_charge = 30.0
@export_group("Enemy One-Way")
@export var enemy_pane_stand_offset = 1.0
@export var enemy_pane_edge_margin = 0.25
@export var enemy_pane_snap_margin = 0.35
@export var pane_enemy_sync_interval = 0.25
var glass_walk_active = false
var glass_walk_needs_pane = false
var glass_pane_spawn_timer = 0.0
var pane_enemy_sync_timer = 0.0
var active_glass_panes = []
var enemy_previous_y: Dictionary = {}
var small_glass_material
var big_glass_material
var shard_materials = []
var ult_wave_materials = []

# ===== GLASS BLOCK — F =====
@export_category("Glass Block — F")
@export_group("Wall Layout")
@export var glass_block_distance = 8.0
@export var glass_block_columns = 10
@export var glass_block_spacing_x = 4.2
@export var glass_block_spacing_y = 3.0
@export var glass_block_base_height = 1.4
@export_group("Movement")
@export var glass_block_pull_speed = 20.0
@export var glass_block_return_speed = 10.0
@export var glass_block_return_snap_distance = 0.08
@export_group("Overload")
@export var glass_block_max_hold_time = 2.0
@export var glass_block_break_shards = 8
var glass_block_active = false
var glass_block_returning = false
var glass_block_broken_until_release = false
var glass_block_time_left = 0.0
var glass_block_original_transforms: Dictionary = {}
var glass_block_enemy_masks: Dictionary = {}

# ===== PANE VOLLEY — E =====
@export_category("Pane Volley — E")
@export var pane_volley_damage = 3.0
@export var pane_volley_size = 0.45
@export var pane_volley_speed = 95.0
@export var pane_volley_homing = 10.0
@export var pane_volley_target_range = 100.0
@export var pane_volley_launch_force = 2.0
@export var pane_volley_knockback = 0.0
@export var pane_volley_stun = 0.25
@export var pane_volley_visual_shards = 3

# ===== SLAM =====
@export_category("Slam")
@export_group("Normal Slam")
@export var slam_windup_time = 0.14
@export var slam_recovery_time = 0.16
@export var slam_down_force = 95.0
@export var slam_stun_time = 0.35
@export var slam_break_radius = 1.2
@export var slam_impact_arm_delay = 0.08
@export_group("Normal Impact")
@export var slam_aoe_radius = 8.0
@export var slam_aoe_damage = 30.0
@export var slam_aoe_knockback = 28.0
@export var slam_aoe_launch_force = 8.0
@export var slam_aoe_stun_time = 0.35
@export_group("Empowered Slam")
@export var empowered_required_walk_panes = 50
@export var pane_chain_entry_height = 4.0
@export var pane_chain_entry_time = 0.10
@export var pane_chain_step_time = 0.035
@export var pane_chain_shards_per_pane = 5
@export var pane_chain_down_multiplier = 1.80
@export_group("Empowered Impact")
@export var pane_chain_aoe_radius = 30.0
@export var pane_chain_aoe_damage = 150.0
@export var pane_chain_aoe_knockback = 80.0
@export var pane_chain_aoe_launch_force = 30.0
@export var pane_chain_aoe_stun_time = 1.0
@export var pane_chain_fx_radius = 38.0
@export_group("Popup")
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
var slam_last_position = Vector3.ZERO
var slam_enemy_was_physics_active = true
var slam_chain_empowered = false
var slam_chain_running = false
var slam_chain_progress = 0.0

# ===== ULT — Q =====
@export_category("NO ONE UNDERSTANDS MY ART — Q")
@export_group("Charge")
@export var ult_max_charge = 100.0
@export_group("Range")
@export var ult_radius = 55.0
@export var ult_visual_radius = 65.0
@export_group("Weak Enemies")
@export var ult_weak_enemy_health = 100.0
@export var ult_lift_speed = 11.0
@export var ult_lift_time = 0.24
@export_group("Strong Enemies")
@export var ult_strong_enemy_damage = 80.0
@export var ult_knockback = 26.0
@export var ult_launch_force = 12.0
@export var ult_stun_time = 0.85
@export_group("Visuals")
@export var ult_enemy_shard_count = 28
@export var ult_enemy_piece_distance = 12.0
@export var ult_center_shard_count = 64
@export var ult_screen_flash_time = 0.22
var ult_charge = 0.0
var ult_ready = false
var ult_ui
var ult_label
var ult_bar

# ===== VORTEX OF POETRY — LMB =====
@export_category("Vortex of POETRY — LMB")
@export_group("Scenes")
@export var projectile_scene: PackedScene
@export var homing_projectile_scene: PackedScene
@export_group("Spawn")
@export var projectile_spawn_height = 1.5
@export var projectile_spawn_forward = 1.5
@export var projectile_spawn_side = 0.0
@export_group("Normal Projectile")
@export var normal_projectile_target_range = 65.0
@export_group("Combo")
@export var combo_reset_time = 1.0
@export var combo_hold_delay = 0.10
@export_group("Finisher")
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

# ===== UI STATE =====
var followup_ui
var followup_label
var followup_bar
var pane_counter_label

# ===== INITIALIZATION =====
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health = max_health
	collision_mask |= glass_collision_layer
	setup_camera()
	setup_materials()
	setup_ui()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	lock_reticle = get_tree().get_first_node_in_group("lock_reticle")
	if lock_reticle:
		lock_reticle.hide()
	play_animation("rig_idle")
func setup_camera():
	if camera_pivot:
		camera_original_parent = camera_pivot.get_parent()
		camera_pitch = camera_pivot.rotation.x
		camera_pitch_target = camera_pitch
	if camera:
		camera_base_fov = camera.fov
		camera.near = camera_near
	if not spring_arm:
		return
	var shape = SphereShape3D.new()
	shape.radius = camera_collision_radius
	spring_arm.spring_length = camera_distance
	spring_arm.margin = camera_collision_margin
	spring_arm.collision_mask = camera_collision_mask
	spring_arm.shape = shape
	spring_arm.add_excluded_object(get_rid())
func setup_materials():
	small_glass_material = make_material(Color(0.55, 0.72, 1.0, 0.32), 1.5)
	big_glass_material = make_material(Color(0.45, 0.85, 1.0, 0.45), 3.0)
	shard_materials = [make_material(Color(0.35, 0.85, 1.0), 6.0), make_material(Color.WHITE, 8.0), make_material(Color(1.0, 0.2, 0.75), 7.0)]
	ult_wave_materials = [make_material(Color(0.35, 0.85, 1.0, 0.16), 8.0), make_material(Color.WHITE, 10.0), make_material(Color(1.0, 0.2, 0.75, 0.14), 9.0)]

# ===== INPUT =====
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if slam_camera_active:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch_target = clamp(camera_pitch_target + event.relative.y * vertical_mouse_sensitivity, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))
	if event is InputEventMouseButton and event.pressed:
		if slam_camera_active:
			return
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				try_airborne_teleport()
			MOUSE_BUTTON_MIDDLE:
				toggle_lock()
			MOUSE_BUTTON_WHEEL_UP:
				switch_target(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				switch_target(-1)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				try_activate_ult()
			KEY_E:
				cast_pane_volley()

# ===== MAIN PHYSICS LOOP =====
func _physics_process(delta):
	update_timers(delta)
	update_slam_windup(delta)
	var direction = get_movement_direction()
	update_glass_walk_state()
	var used_jump = update_followup_input()
	update_attack_input()
	update_gravity(delta)
	update_jump(used_jump)
	update_dodge(direction, delta)
	update_glass_walk(direction)
	update_animation(direction)
	var move_start = global_position
	move_and_slide()
	if is_dodging:
		hit_enemies_with_dash(move_start, global_position)
	maintain_teleport_hold()
	maintain_slam_player_lock()
	update_glass_block(delta)
	update_enemy_one_way_panes(delta)
	update_slam_impact(delta)
	update_lock_camera(delta)
	update_teleport_camera(delta)
	update_air_camera_focus(delta)
	update_slam_camera(delta)
	update_camera(delta)
	update_lock_reticle()
	update_followup_ui()

# ===== GENERAL TIMERS / HELPERS =====
func update_timers(delta):
	teleport_cooldown_timer = tick(teleport_cooldown_timer, delta)
	low_gravity_timer = tick(low_gravity_timer, delta)
	glass_pane_spawn_timer = tick(glass_pane_spawn_timer, delta)
	combo_hold_timer = tick(combo_hold_timer, delta)
	slam_recovery_timer = tick(slam_recovery_timer, delta)
	pane_enemy_sync_timer -= delta
	if pane_enemy_sync_timer <= 0.0:
		sync_all_pane_enemy_exceptions()
		pane_enemy_sync_timer = pane_enemy_sync_interval
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
	if slam_camera_hold_timer > 0.0:
		slam_camera_hold_timer -= delta
		if slam_camera_hold_timer <= 0.0 and not valid(slam_impact_target) and not slam_chain_running:
			end_slam_camera()
func tick(value, delta):
	return max(value - delta, 0.0)
func weight(speed_value, delta):
	return clamp(speed_value * delta, 0.0, 1.0)
func valid(node):
	return is_instance_valid(node)

# ===== PLAYER MOVEMENT =====
func get_movement_direction():
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward = -transform.basis.z
	var right = -transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	return (forward.normalized() * input.y + right.normalized() * input.x).normalized()
func update_gravity(delta):
	if teleport_hold_active or slam_camera_active:
		velocity.y = 0.0
		return
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
		return
	var gravity_scale = 1.0
	if low_gravity_timer > 0.0:
		gravity_scale = min(gravity_scale, teleport_gravity_multiplier)
	if glass_walk_active:
		gravity_scale = min(gravity_scale, glass_walk_gravity_multiplier)
	velocity.y -= gravity * gravity_scale * delta
	if glass_walk_active:
		velocity.y = max(velocity.y, glass_walk_max_fall_speed)
func update_jump(used_followup):
	if teleport_hold_active or slam_camera_active:
		return
	if not used_followup and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

# ===== DASH =====
func update_dodge(direction, delta):
	if teleport_hold_active or slam_camera_active:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if Input.is_action_just_pressed("dodge") and can_dodge:
		start_dodge(direction)
	if is_dodging:
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			end_dodge()
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
func start_dodge(direction):
	is_dodging = true
	can_dodge = false
	dodge_invincible = true
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	dodge_hit_ids.clear()
	dodge_direction = direction if direction != Vector3.ZERO else -transform.basis.z
	dodge_direction.y = 0.0
	dodge_direction = dodge_direction.normalized()
	flash_blue()
func end_dodge():
	if not is_dodging:
		return
	dash_end_aoe()
	is_dodging = false
	dodge_invincible = false
	remove_flash()
func hit_enemies_with_dash(from_position, to_position):
	var segment = to_position - from_position
	var length_squared = max(segment.length_squared(), 0.0001)
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is Node3D:
			continue
		var id = enemy.get_instance_id()
		if dodge_hit_ids.has(id):
			continue
		var t = clamp((enemy.global_position - from_position).dot(segment) / length_squared, 0.0, 1.0)
		var closest = from_position + segment * t
		if enemy.global_position.distance_to(closest) > dodge_hit_radius:
			continue
		dodge_hit_ids[id] = true
		hit_enemy(enemy, dodge_damage, dodge_knockback, dodge_launch_force, dodge_hit_stun, dodge_direction)
func dash_end_aoe():
	for enemy in get_enemies_near(global_position, dodge_end_aoe_radius):
		if not valid(enemy):
			continue
		var id = enemy.get_instance_id()
		if dodge_hit_ids.has(id):
			continue
		dodge_hit_ids[id] = true
		var direction = enemy.global_position - global_position
		direction.y = 0.0
		if direction.length() < 0.01:
			direction = dodge_direction
		hit_enemy(enemy, dodge_end_damage, dodge_end_knockback, dodge_end_launch_force, dodge_end_stun, direction.normalized())
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(global_position + Vector3.UP * 0.5, dodge_end_aoe_radius, ult_wave_materials[0], 0.14)
func hit_enemy(enemy, damage, knockback, launch, stun, direction):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	if enemy.has_method("apply_hit_effect"):
		enemy.apply_hit_effect(direction, knockback, launch, stun)
	elif enemy is CharacterBody3D:
		enemy.velocity.x = direction.x * knockback
		enemy.velocity.z = direction.z * knockback
		enemy.velocity.y = max(enemy.velocity.y, launch)

# ===== NORMAL CAMERA =====
func update_camera(delta):
	if not camera_pivot or slam_camera_detached:
		return
	var airborne = not is_on_floor()
	var target_distance = air_camera_distance if airborne else camera_distance
	var target_fov = camera_base_fov + (air_camera_fov_add if airborne else 0.0)
	var response = air_camera_response
	if slam_camera_active:
		target_distance = lerp(slam_camera_wide_distance, slam_camera_focus_distance, slam_camera_focus)
		target_fov = camera_base_fov + lerp(slam_camera_wide_fov_add, slam_camera_focus_fov_add, slam_camera_focus)
		if slam_camera_hold_timer > 0.0:
			target_fov = camera_base_fov + slam_impact_fov_punch
		response = slam_camera_zoom_speed
	else:
		camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, 0.0, weight(camera_yaw_return_speed, delta))
	var w = weight(response, delta)
	if spring_arm:
		spring_arm.spring_length = lerp(spring_arm.spring_length, target_distance, w)
	if camera:
		camera.fov = lerp(camera.fov, target_fov, w)
	camera_pitch = lerp_angle(camera_pitch, camera_pitch_target, weight(camera_pitch_smooth_speed, delta))
	camera_pivot.rotation.x = camera_pitch
func update_air_camera_focus(delta):
	if is_on_floor() or slam_camera_active or teleport_hold_active or teleport_camera_timer > 0.0:
		return
	var target = locked_enemy if valid(locked_enemy) else teleport_focus_target
	if valid(target):
		aim_camera_pitch_at(target.global_position + Vector3.UP * 1.2, air_target_pitch_strength, delta)
func aim_camera_pitch_at(point, strength, delta):
	var direction = point - global_position
	var horizontal = max(Vector2(direction.x, direction.z).length(), 0.01)
	var pitch = clamp(-atan2(direction.y, horizontal), deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))
	camera_pitch_target = lerp_angle(camera_pitch_target, pitch, weight(strength, delta))

# ===== SLAM CAMERA =====
func start_slam_camera(enemy):
	if not valid(enemy) or not camera_pivot:
		return
	slam_camera_active = true
	slam_camera_focus = 0.0
	slam_camera_hold_timer = 0.0
	slam_start_enemy_y = enemy.global_position.y
	slam_camera_side = choose_slam_camera_side(enemy)
	slam_saved_camera_transform = camera_pivot.transform
	if spring_arm:
		slam_saved_spring_length = spring_arm.spring_length
	if camera:
		slam_saved_fov = camera.fov
	if slam_chain_empowered:
		detach_empowered_camera()
	else:
		if spring_arm:
			spring_arm.spring_length = slam_camera_wide_distance
		if camera:
			camera.fov = camera_base_fov + slam_camera_wide_fov_add
func choose_slam_camera_side(enemy):
	if camera:
		var side = camera.global_transform.basis.x.dot(enemy.global_position - camera.global_position)
		if abs(side) > 0.20:
			return -sign(side)
	slam_camera_flip *= -1.0
	return slam_camera_flip
func detach_empowered_camera():
	if slam_camera_detached or not camera_pivot:
		return
	var parent = get_tree().current_scene
	if parent == null:
		return
	camera_pivot.reparent(parent, true)
	slam_camera_detached = true
	detached_camera_base_yaw = camera_pivot.global_rotation.y
	if spring_arm:
		spring_arm.spring_length = slam_camera_wide_distance
	if camera:
		camera.fov = camera_base_fov + slam_camera_wide_fov_add
func update_slam_camera(delta):
	if not slam_camera_active or not camera_pivot:
		return
	var enemy = slam_impact_target if valid(slam_impact_target) else pending_slam_target
	if slam_camera_detached:
		update_detached_slam_camera(enemy, delta)
	else:
		update_attached_slam_camera(enemy, delta)
func update_detached_slam_camera(enemy, delta):
	var point = slam_camera_hold_point
	if valid(enemy):
		point = enemy.global_position + Vector3.UP * empowered_camera_height
	elif slam_camera_hold_timer <= 0.0:
		end_slam_camera()
		return
	var follow_weight = weight(empowered_camera_follow_speed, delta)
	camera_pivot.global_position = camera_pivot.global_position.lerp(point, follow_weight)
	var desired_focus = 1.0 if slam_camera_hold_timer > 0.0 else slam_chain_progress
	slam_camera_focus = lerp(slam_camera_focus, desired_focus, weight(slam_camera_focus_speed, delta))
	var orbit = deg_to_rad(empowered_camera_orbit_angle * slam_camera_side * (1.0 - slam_camera_focus))
	var current = camera_pivot.global_rotation
	current.y = lerp_angle(current.y, detached_camera_base_yaw + orbit, weight(empowered_camera_orbit_speed, delta))
	current.x = lerp_angle(current.x, deg_to_rad(empowered_camera_pitch), follow_weight)
	current.z = lerp_angle(current.z, 0.0, follow_weight)
	camera_pivot.global_rotation = current
	if spring_arm:
		var distance = lerp(slam_camera_wide_distance, slam_camera_focus_distance, slam_camera_focus)
		spring_arm.spring_length = lerp(spring_arm.spring_length, distance, follow_weight)
	if camera:
		var target_fov = camera_base_fov + lerp(slam_camera_wide_fov_add, slam_camera_focus_fov_add, slam_camera_focus)
		if slam_camera_hold_timer > 0.0:
			target_fov = camera_base_fov + empowered_impact_fov_punch
		camera.fov = lerp(camera.fov, target_fov, follow_weight)
func update_attached_slam_camera(enemy, delta):
	var point = slam_camera_hold_point
	if valid(enemy):
		point = enemy.global_position + Vector3.UP * 0.5
	elif slam_camera_hold_timer <= 0.0:
		end_slam_camera()
		return
	var flat = point - camera_pivot.global_position
	flat.y = 0.0
	if flat.length() > 0.01:
		var world_yaw = atan2(-flat.x, -flat.z)
		var local_yaw = wrapf(world_yaw - rotation.y, -PI, PI)
		var swing = deg_to_rad(slam_camera_swing_angle) * slam_camera_side * (1.0 - slam_camera_focus)
		camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, local_yaw + swing, weight(slam_camera_yaw_speed, delta))
	var direction = point - camera_pivot.global_position
	var horizontal = max(Vector2(direction.x, direction.z).length(), 0.01)
	var pitch = clamp(-atan2(direction.y, horizontal) + deg_to_rad(slam_camera_pitch_lead), deg_to_rad(-55.0), deg_to_rad(70.0))
	camera_pitch_target = lerp_angle(camera_pitch_target, pitch, weight(slam_camera_pitch_speed, delta))
	var focus = 1.0
	if valid(enemy) and slam_camera_hold_timer <= 0.0:
		focus = clamp((slam_start_enemy_y - enemy.global_position.y) / slam_camera_focus_fall_distance, 0.0, 1.0)
	slam_camera_focus = lerp(slam_camera_focus, focus, weight(slam_camera_focus_speed, delta))
func maintain_slam_player_lock():
	if slam_camera_active:
		velocity = Vector3.ZERO
func hold_slam_camera_on_impact(point):
	slam_camera_hold_point = point + Vector3.UP * 0.8
	slam_camera_hold_timer = slam_camera_impact_hold_time
	slam_camera_focus = 1.0
func end_slam_camera():
	if not slam_camera_active:
		return
	slam_camera_active = false
	slam_camera_focus = 0.0
	slam_camera_hold_timer = 0.0
	if slam_camera_detached and valid(camera_pivot) and valid(camera_original_parent):
		camera_pivot.reparent(camera_original_parent, true)
		camera_pivot.transform = slam_saved_camera_transform
		camera_pitch = camera_pivot.rotation.x
		camera_pitch_target = camera_pitch
		slam_camera_detached = false
	if spring_arm:
		spring_arm.spring_length = slam_saved_spring_length
	if camera:
		camera.fov = slam_saved_fov

# ===== RMB TELEPORT TARGETING =====
func try_airborne_teleport():
	if teleport_cooldown_timer > 0.0 or slam_camera_active:
		return
	var target = get_airborne_teleport_target()
	if not target:
		return
	teleport_to_enemy(target)
	teleport_cooldown_timer = teleport_cooldown
func get_airborne_teleport_target():
	if is_usable_enemy(locked_enemy, teleport_range, true):
		return locked_enemy
	var target = get_screen_center_airborne_enemy()
	return target if target else get_nearest_enemy(teleport_range, true)
func get_screen_center_airborne_enemy():
	if not camera:
		return null
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size * 0.5
	var radius = min(viewport_size.x, viewport_size.y) * teleport_target_screen_radius
	var best = null
	var best_score = INF
	for enemy in get_enemies():
		if not is_usable_enemy(enemy, teleport_range, true):
			continue
		var point = enemy.global_position + Vector3.UP * 1.2
		if camera.is_position_behind(point):
			continue
		var screen_distance = camera.unproject_position(point).distance_to(center)
		if screen_distance > radius:
			continue
		var score = screen_distance / max(radius, 1.0) * teleport_center_priority + global_position.distance_to(enemy.global_position) / teleport_range * teleport_distance_priority
		if score < best_score:
			best_score = score
			best = enemy
	return best

# ===== RMB TELEPORT EXECUTION =====
func teleport_to_enemy(enemy):
	if not valid(enemy):
		return
	force_end_glass_block(true)
	teleport_focus_target = enemy
	teleport_camera_target = enemy
	slam_target = enemy
	var direction = global_position - enemy.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		direction = global_transform.basis.x
	global_position = get_safe_teleport_position(enemy, direction.normalized())
	velocity = Vector3.ZERO
	low_gravity_timer = teleport_low_gravity_duration
	teleport_followup_timer = teleport_followup_window
	teleport_camera_timer = teleport_camera_duration
	face_enemy(enemy)
	begin_teleport_hold(enemy)
func get_safe_teleport_position(enemy, direction):
	var checks = max(teleport_position_checks, 1)
	for i in range(checks):
		var test_direction = direction.rotated(Vector3.UP, TAU * float(i) / float(checks))
		var position = enemy.global_position + test_direction * teleport_side_offset + Vector3.UP * teleport_height_offset
		if is_teleport_path_clear(enemy, position):
			return position
	if teleport_use_fallback:
		return enemy.global_position + direction * teleport_side_offset + Vector3.UP * teleport_height_offset
	return global_position
func is_teleport_path_clear(enemy, destination):
	var world = get_world_3d()
	if world == null:
		return true
	var query = PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3.UP * teleport_height_offset, destination)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	if enemy is CollisionObject3D:
		query.exclude.append(enemy.get_rid())
	return world.direct_space_state.intersect_ray(query).is_empty()
func face_enemy(enemy):
	if not valid(enemy):
		return
	var target = Vector3(enemy.global_position.x, global_position.y, enemy.global_position.z)
	if global_position.distance_to(target) > 0.01:
		look_at(target, Vector3.UP, true)

# ===== RMB TELEPORT HOLD =====
func begin_teleport_hold(enemy):
	release_teleport_hold()
	teleport_hold_active = true
	teleport_held_enemy = enemy
	teleport_hold_player_position = global_position
	teleport_hold_enemy_position = enemy.global_position
	teleport_enemy_was_physics_active = enemy.is_physics_processing()
	enemy.set_physics_process(false)
	if enemy is CharacterBody3D:
		enemy.velocity = Vector3.ZERO
func maintain_teleport_hold():
	if not teleport_hold_active:
		return
	if not valid(teleport_held_enemy):
		teleport_hold_active = false
		teleport_followup_timer = 0.0
		slam_target = null
		return
	global_position = teleport_hold_player_position
	velocity = Vector3.ZERO
	teleport_held_enemy.global_position = teleport_hold_enemy_position
	if teleport_held_enemy is CharacterBody3D:
		teleport_held_enemy.velocity = Vector3.ZERO
func release_teleport_hold():
	if teleport_hold_active and valid(teleport_held_enemy):
		teleport_held_enemy.set_physics_process(teleport_enemy_was_physics_active)
	teleport_hold_active = false
	teleport_held_enemy = null
func clear_teleport_followup():
	release_teleport_hold()
	teleport_followup_timer = 0.0
	slam_target = null

# ===== RMB TELEPORT CAMERA / FOLLOW-UP =====
func update_teleport_camera(delta):
	if slam_camera_active:
		return
	var following = teleport_followup_timer > 0.0 and valid(teleport_focus_target)
	if teleport_camera_timer <= 0.0 and not following:
		teleport_camera_target = null
		teleport_focus_target = null
		return
	if following:
		teleport_camera_target = teleport_focus_target
	if not valid(teleport_camera_target):
		return
	teleport_camera_timer = tick(teleport_camera_timer, delta)
	var strength = teleport_camera_timer / teleport_camera_duration if teleport_camera_timer > 0.0 else 0.30
	aim_camera_pitch_at(teleport_camera_target.global_position + Vector3.UP * 1.3, teleport_camera_vertical_strength * strength, delta)
func update_followup_input():
	if teleport_followup_timer <= 0.0 or not valid(teleport_focus_target):
		return false
	if Input.is_action_just_pressed("jump"):
		create_glass_arena()
		return true
	return false
func update_attack_input():
	if slam_windup_timer > 0.0 or slam_recovery_timer > 0.0 or slam_chain_running:
		return
	if teleport_followup_timer > 0.0 and valid(slam_target) and Input.is_action_just_pressed("attack"):
		start_air_slam()
		return
	if Input.is_action_pressed("attack") and combo_hold_timer <= 0.0 and not attacking:
		attack()
		combo_hold_timer = combo_hold_delay
	if Input.is_key_pressed(KEY_H):
		take_damage(10)

# ===== PANES OF PAIN — MOVEMENT PANES =====
func update_glass_walk_state():
	var was_active = glass_walk_active
	glass_walk_active = Input.is_action_pressed("dodge") and (not is_on_floor() or is_on_glass())
	if glass_walk_active and not was_active:
		glass_walk_needs_pane = true
	if not glass_walk_active:
		glass_walk_needs_pane = false
func is_on_glass():
	if not is_on_floor():
		return false
	for i in range(get_slide_collision_count()):
		var collider = get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("lucian_glass_panes"):
			return true
	return false
func update_glass_walk(direction):
	if not glass_walk_active:
		return
	if teleport_hold_active or slam_camera_active or glass_block_active or Input.is_key_pressed(KEY_F):
		return
	if glass_walk_needs_pane:
		spawn_walk_pane(direction)
		glass_walk_needs_pane = false
		return
	if glass_pane_spawn_timer <= 0.0:
		spawn_walk_pane(direction)
func spawn_walk_pane(direction):
	var move_direction = direction
	if move_direction.length() < 0.05:
		move_direction = -transform.basis.z
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	var pane_position = global_position + move_direction * walk_pane_forward_offset + Vector3.DOWN * walk_pane_vertical_offset
	create_glass_pane(pane_position, walk_pane_size, walk_pane_lifetime, small_glass_material, small_pane_ult_charge, true)
	glass_pane_spawn_timer = walk_pane_spawn_interval

# ===== GLASS BLOCK — F =====
func update_glass_block(delta):
	if teleport_hold_active or slam_camera_active:
		if glass_block_active or glass_block_returning:
			force_end_glass_block(true)
		return
	var wants_block = Input.is_key_pressed(KEY_F)
	if not wants_block:
		glass_block_broken_until_release = false
		if glass_block_active:
			start_glass_block_return()
		if glass_block_returning:
			update_glass_block_return(delta)
		return
	if glass_block_broken_until_release:
		return
	if not glass_block_active:
		begin_glass_block()
	if glass_block_active:
		glass_block_time_left -= delta
		position_glass_block(delta)
		update_glass_block_enemy_collision()
		if glass_block_time_left <= 0.0:
			break_glass_block()
func begin_glass_block():
	var panes = get_valid_panes()
	if panes.is_empty():
		return
	glass_block_returning = false
	glass_block_active = true
	glass_block_time_left = glass_block_max_hold_time
	for pane in panes:
		if not valid(pane):
			continue
		var id = pane.get_instance_id()
		if not glass_block_original_transforms.has(id):
			glass_block_original_transforms[id] = pane.global_transform
		pane.set_meta("blocking", true)
		remove_pane_enemy_exceptions(pane)
		set_pane_block_detector(pane, true)
	update_glass_block_enemy_collision()
func position_glass_block(delta):
	var panes = get_valid_panes()
	if panes.is_empty():
		glass_block_active = false
		restore_glass_block_enemy_masks()
		glass_block_original_transforms.clear()
		return
	var forward = global_transform.basis.z
	var right = global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var columns = max(glass_block_columns, 1)
	var movement_weight = weight(glass_block_pull_speed, delta)
	for i in range(panes.size()):
		var pane = panes[i]
		if not valid(pane):
			continue
		var row = int(i / columns)
		var column = i % columns
		var remaining = panes.size() - row * columns
		var row_count = min(columns, remaining)
		var horizontal = (float(column) - float(row_count - 1) * 0.5) * glass_block_spacing_x
		var vertical = glass_block_base_height + float(row) * glass_block_spacing_y
		var target_position = global_position + forward * glass_block_distance + right * horizontal + Vector3.UP * vertical
		pane.global_position = pane.global_position.lerp(target_position, movement_weight)
		var current_rotation = pane.global_rotation
		current_rotation.x = lerp_angle(current_rotation.x, deg_to_rad(90.0), movement_weight)
		current_rotation.y = lerp_angle(current_rotation.y, rotation.y, movement_weight)
		current_rotation.z = lerp_angle(current_rotation.z, 0.0, movement_weight)
		pane.global_rotation = current_rotation

# ===== GLASS BLOCK — RELEASE / RETURN =====
func start_glass_block_return():
	if not glass_block_active:
		return
	glass_block_active = false
	glass_block_returning = true
	glass_block_time_left = 0.0
	restore_glass_block_enemy_masks()
	for pane in get_valid_panes():
		if not valid(pane):
			continue
		pane.set_meta("blocking", false)
		set_pane_block_detector(pane, false)
		pane.set_meta("enemy_exception_ids", {})
		sync_pane_enemy_exceptions(pane)
	if glass_block_original_transforms.is_empty():
		glass_block_returning = false
func update_glass_block_return(delta):
	if glass_block_original_transforms.is_empty():
		glass_block_returning = false
		return
	var return_weight = weight(glass_block_return_speed, delta)
	var still_returning = false
	for pane in get_valid_panes():
		if not valid(pane):
			continue
		var id = pane.get_instance_id()
		if not glass_block_original_transforms.has(id):
			continue
		var target: Transform3D = glass_block_original_transforms[id]
		var distance = pane.global_position.distance_to(target.origin)
		if distance <= glass_block_return_snap_distance:
			pane.global_transform = target
			glass_block_original_transforms.erase(id)
			continue
		still_returning = true
		pane.global_transform = pane.global_transform.interpolate_with(target, return_weight)
	if not still_returning or glass_block_original_transforms.is_empty():
		for pane in get_valid_panes():
			if not valid(pane):
				continue
			var id = pane.get_instance_id()
			if glass_block_original_transforms.has(id):
				pane.global_transform = glass_block_original_transforms[id]
		glass_block_original_transforms.clear()
		glass_block_returning = false

# ===== GLASS BLOCK — 2 SECOND OVERLOAD =====
func break_glass_block():
	if not glass_block_active:
		return
	glass_block_active = false
	glass_block_returning = false
	glass_block_time_left = 0.0
	glass_block_broken_until_release = true
	restore_glass_block_enemy_masks()
	var panes = get_valid_panes().duplicate()
	glass_block_original_transforms.clear()
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(global_position + global_transform.basis.z * glass_block_distance + Vector3.UP * 2.0, 10.0, ult_wave_materials[2], 0.18)
	for pane in panes:
		if not valid(pane):
			continue
		set_pane_block_detector(pane, false)
		pane.set_meta("blocking", false)
		shatter_glass_pane(pane, false, glass_block_break_shards)

# ===== GLASS BLOCK — ENEMY COLLISION =====
func update_glass_block_enemy_collision():
	if not glass_block_active:
		return
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is CollisionObject3D:
			continue
		if not glass_block_enemy_masks.has(enemy):
			glass_block_enemy_masks[enemy] = enemy.collision_mask
			for pane in get_valid_panes():
				if not valid(pane) or not pane is PhysicsBody3D:
					continue
				pane.remove_collision_exception_with(enemy)
				if enemy is PhysicsBody3D:
					enemy.remove_collision_exception_with(pane)
		enemy.collision_mask |= glass_collision_layer
func restore_glass_block_enemy_masks():
	for enemy in glass_block_enemy_masks.keys():
		if not valid(enemy):
			continue
		enemy.collision_mask = glass_block_enemy_masks[enemy]
	glass_block_enemy_masks.clear()
func remove_pane_enemy_exceptions(pane):
	if not valid(pane) or not pane is PhysicsBody3D:
		return
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is PhysicsBody3D:
			continue
		pane.remove_collision_exception_with(enemy)
		enemy.remove_collision_exception_with(pane)
	pane.set_meta("enemy_exception_ids", {})

# ===== GLASS BLOCK — PROJECTILE BLOCKING =====
func set_pane_block_detector(pane, enabled):
	if not valid(pane):
		return
	var detector = pane.get_meta("block_detector", null)
	if not valid(detector):
		return
	detector.monitoring = enabled
func _on_glass_block_detector_area_entered(area):
	if not glass_block_active:
		return
	block_projectile_node(area)
func _on_glass_block_detector_body_entered(body):
	if not glass_block_active:
		return
	block_projectile_node(body)
func block_projectile_node(node):
	var projectile = find_projectile_root(node)
	if not valid(projectile):
		return
	if projectile == self:
		return
	if projectile.is_in_group("enemies"):
		return
	if projectile.is_in_group("lucian_glass_panes"):
		return
	projectile.queue_free()
func find_projectile_root(node):
	var current = node
	for _i in range(6):
		if not valid(current):
			break
		if looks_like_projectile(current):
			return current
		current = current.get_parent()
	return null
func looks_like_projectile(node):
	if not valid(node):
		return false
	if node.is_in_group("projectiles") or node.is_in_group("enemy_projectiles") or node.is_in_group("player_projectiles"):
		return true
	var lower_name = String(node.name).to_lower()
	if "projectile" in lower_name or "bullet" in lower_name or "missile" in lower_name:
		return node is Area3D or node is PhysicsBody3D
	if not (node is Area3D or node is PhysicsBody3D):
		return false
	var has_damage = false
	var has_motion = false
	for info in node.get_property_list():
		var property_name = String(info["name"])
		if property_name == "damage":
			has_damage = true
		elif property_name == "direction" or property_name == "speed" or property_name == "velocity":
			has_motion = true
	return has_damage and has_motion
func force_end_glass_block(restore_positions = true):
	if not glass_block_active and not glass_block_returning and glass_block_original_transforms.is_empty():
		restore_glass_block_enemy_masks()
		return
	restore_glass_block_enemy_masks()
	for pane in get_valid_panes():
		if not valid(pane):
			continue
		var id = pane.get_instance_id()
		if restore_positions and glass_block_original_transforms.has(id):
			pane.global_transform = glass_block_original_transforms[id]
		pane.set_meta("blocking", false)
		set_pane_block_detector(pane, false)
		pane.set_meta("enemy_exception_ids", {})
		sync_pane_enemy_exceptions(pane)
	glass_block_original_transforms.clear()
	glass_block_active = false
	glass_block_returning = false
	glass_block_time_left = 0.0

# ===== GLASS ARENA — RMB → SPACE =====
func create_glass_arena():
	if not valid(teleport_focus_target):
		return
	force_end_glass_block(true)
	var enemy = teleport_focus_target
	clear_teleport_followup()
	var position = (global_position + enemy.global_position) * 0.5
	position.y = min(global_position.y, enemy.global_position.y) - arena_pane_vertical_offset
	create_glass_pane(position, arena_pane_size, arena_pane_lifetime, big_glass_material, big_pane_ult_charge, false)
	velocity.y = max(velocity.y, arena_player_lift)
	low_gravity_timer = max(low_gravity_timer, teleport_low_gravity_duration)
	if enemy is CharacterBody3D:
		enemy.velocity.y = max(enemy.velocity.y, arena_enemy_lift)
	teleport_camera_target = enemy
	teleport_camera_timer = 0.30

# ===== PANE VOLLEY — E =====
func cast_pane_volley():
	if slam_camera_active or teleport_hold_active or not homing_projectile_scene:
		return
	force_end_glass_block(true)
	var panes = get_valid_panes()
	if panes.is_empty() or get_enemies().is_empty():
		return
	var resume_glass_walk = Input.is_action_pressed("dodge") and (not is_on_floor() or is_on_glass() or glass_walk_active)
	for pane in panes:
		if not valid(pane):
			continue
		var origin = pane.global_position + Vector3.UP * 0.15
		var target = get_nearest_enemy_to(origin, pane_volley_target_range)
		if valid(target):
			spawn_pane_projectile(origin, target)
		shatter_glass_pane(pane, false, pane_volley_visual_shards)
	if resume_glass_walk:
		glass_walk_active = true
		glass_walk_needs_pane = false
		glass_pane_spawn_timer = 0.0
		spawn_walk_pane(get_movement_direction())
func spawn_pane_projectile(origin, target):
	var projectile = homing_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	projectile.target = target
	projectile.damage = pane_volley_damage
	projectile.projectile_size = pane_volley_size
	projectile.is_finisher_projectile = false
	projectile.direction = (target.global_position + Vector3.UP - origin).normalized()
	set_if_has(projectile, "speed", pane_volley_speed)
	set_if_has(projectile, "homing_strength", pane_volley_homing)
	set_if_has(projectile, "launch_force", pane_volley_launch_force)
	set_if_has(projectile, "knockback_strength", pane_volley_knockback)
	set_if_has(projectile, "stun_time", pane_volley_stun)
func get_nearest_enemy_to(point, max_range):
	var best = null
	var best_distance = max_range
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is Node3D:
			continue
		var distance = point.distance_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best
func set_if_has(object, property_name, value):
	for info in object.get_property_list():
		if String(info["name"]) == property_name:
			object.set(property_name, value)
			return

# ===== GLASS PANE CREATION =====
func make_material(color, emission):
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = emission
	return material
func create_glass_pane(position, size, lifetime, material, charge, is_walk_pane):
	clean_glass_panes()
	if active_glass_panes.size() >= glass_pane_max_count:
		remove_glass_pane(active_glass_panes.pop_front())
	var pane = StaticBody3D.new()
	var shape = BoxShape3D.new()
	var collision = CollisionShape3D.new()
	var mesh = BoxMesh.new()
	var visual = MeshInstance3D.new()
	pane.collision_layer = glass_collision_layer
	pane.add_to_group("lucian_glass_panes")
	pane.set_meta("shattered", false)
	pane.set_meta("blocking", false)
	pane.set_meta("ult_charge", charge)
	pane.set_meta("pane_size", size)
	pane.set_meta("is_walk_pane", is_walk_pane)
	pane.set_meta("enemy_exception_ids", {})
	shape.size = size
	collision.shape = shape
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	var block_detector = Area3D.new()
	block_detector.name = "BlockDetector"
	block_detector.collision_layer = 0
	block_detector.collision_mask = 0xFFFFFFFF
	block_detector.monitoring = false
	block_detector.monitorable = false
	var detector_collision = CollisionShape3D.new()
	var detector_shape = BoxShape3D.new()
	detector_shape.size = size
	detector_collision.shape = detector_shape
	block_detector.add_child(detector_collision)
	block_detector.area_entered.connect(_on_glass_block_detector_area_entered)
	block_detector.body_entered.connect(_on_glass_block_detector_body_entered)
	pane.set_meta("block_detector", block_detector)
	get_tree().current_scene.add_child(pane)
	pane.global_position = position
	pane.rotation.y = rotation.y
	pane.add_child(collision)
	pane.add_child(visual)
	pane.add_child(block_detector)
	active_glass_panes.append(pane)
	sync_pane_enemy_exceptions(pane)
	update_pane_counter_ui()
	expire_glass_pane(pane, lifetime)

# ===== GLASS PANE HELPERS =====
func get_valid_panes():
	clean_glass_panes()
	var panes = []
	for pane in active_glass_panes:
		if valid(pane) and not pane.get_meta("shattered", false):
			panes.append(pane)
	return panes
func get_walk_panes():
	var panes = []
	for pane in get_valid_panes():
		if pane.get_meta("is_walk_pane", false):
			panes.append(pane)
	return panes
func get_walk_pane_count():
	return get_walk_panes().size()
func get_chain_panes():
	var panes = get_walk_panes()
	for i in range(panes.size()):
		var highest = i
		for j in range(i + 1, panes.size()):
			if panes[j].global_position.y > panes[highest].global_position.y:
				highest = j
		if highest != i:
			var temp = panes[i]
			panes[i] = panes[highest]
			panes[highest] = temp
	return panes
func get_pane_hit_point(pane, enemy_position):
	var size = pane.get_meta("pane_size", Vector3.ONE)
	var local_position = pane.to_local(enemy_position)
	local_position.x = clamp(local_position.x, -size.x * 0.45, size.x * 0.45)
	local_position.z = clamp(local_position.z, -size.z * 0.45, size.z * 0.45)
	local_position.y = 0.0
	return pane.to_global(local_position)
func clean_glass_panes():
	for pane in active_glass_panes.duplicate():
		if not valid(pane):
			active_glass_panes.erase(pane)
func remove_glass_pane(pane):
	if not valid(pane):
		return
	active_glass_panes.erase(pane)
	glass_block_original_transforms.erase(pane.get_instance_id())
	pane.queue_free()
	update_pane_counter_ui()
func expire_glass_pane(pane, lifetime):
	await get_tree().create_timer(lifetime).timeout
	remove_glass_pane(pane)

# ===== ENEMY / GLASS ONE-WAY COLLISION =====
func sync_pane_enemy_exceptions(pane):
	if not valid(pane) or not pane is PhysicsBody3D or pane.get_meta("blocking", false):
		return
	var ids: Dictionary = pane.get_meta("enemy_exception_ids", {})
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is PhysicsBody3D:
			continue
		var id = enemy.get_instance_id()
		if ids.has(id):
			continue
		pane.add_collision_exception_with(enemy)
		enemy.add_collision_exception_with(pane)
		ids[id] = true
	pane.set_meta("enemy_exception_ids", ids)
func sync_all_pane_enemy_exceptions():
	for pane in get_valid_panes():
		sync_pane_enemy_exceptions(pane)
func update_enemy_one_way_panes(delta):
	var panes = get_valid_panes()
	for enemy in get_enemies():
		if not valid(enemy) or not enemy is CharacterBody3D:
			continue
		var id = enemy.get_instance_id()
		var current_y = enemy.global_position.y
		var previous_y = float(enemy_previous_y.get(id, current_y - enemy.velocity.y * delta))
		if panes.is_empty() or is_slam_controlled_enemy(enemy) or enemy == teleport_held_enemy or enemy.velocity.y > 0.0:
			enemy_previous_y[id] = current_y
			continue
		var best_top = -INF
		for pane in panes:
			if pane.get_meta("blocking", false):
				continue
			var size = pane.get_meta("pane_size", Vector3.ONE)
			var local_position = pane.to_local(enemy.global_position)
			if abs(local_position.x) > size.x * 0.5 - enemy_pane_edge_margin:
				continue
			if abs(local_position.z) > size.z * 0.5 - enemy_pane_edge_margin:
				continue
			var top = pane.global_position.y + size.y * 0.5 + enemy_pane_stand_offset
			var crossed = previous_y >= top and current_y <= top
			var resting = abs(current_y - top) <= enemy_pane_snap_margin
			if (crossed or resting) and top > best_top:
				best_top = top
		if best_top > -INF:
			enemy.global_position.y = best_top
			enemy.velocity.y = max(enemy.velocity.y, 0.0)
			current_y = best_top
		enemy_previous_y[id] = current_y
func is_slam_controlled_enemy(enemy):
	return enemy == pending_slam_target or enemy == slam_impact_target

# ===== GLASS SHATTER =====
func shatter_glass_pane(pane, give_charge = true, shard_override = -1):
	if not valid(pane) or pane.get_meta("shattered", false):
		return
	pane.set_meta("shattered", true)
	var size = pane.get_meta("pane_size", Vector3.ONE)
	var scale_value = clamp(max(size.x, size.z) / 8.0, 0.65, 2.5)
	var shards = shard_override if shard_override > 0 else pane_shatter_shard_count
	spawn_shard_burst(pane.global_position, shards, pane_shatter_distance * scale_value, scale_value, pane_shatter_duration)
	if give_charge:
		add_ult_charge(float(pane.get_meta("ult_charge", 0.0)))
	remove_glass_pane(pane)
func shatter_panes_crossed_by_slam(from_position, to_position):
	for pane in get_valid_panes():
		var size = pane.get_meta("pane_size", Vector3.ONE)
		var start = pane.to_local(from_position)
		var finish = pane.to_local(to_position)
		var half = Vector3(size.x * 0.5 + slam_break_radius, size.y * 0.5 + slam_break_radius, size.z * 0.5 + slam_break_radius)
		if min(start.y, finish.y) > half.y or max(start.y, finish.y) < -half.y:
			continue
		var dy = finish.y - start.y
		var t = clamp(-start.y / dy, 0.0, 1.0) if abs(dy) > 0.0001 else 0.0
		var hit = start.lerp(finish, t)
		if abs(hit.x) <= half.x and abs(hit.z) <= half.z:
			shatter_glass_pane(pane)
func shatter_panes_at_slam_impact(position, radius):
	for pane in get_valid_panes():
		var size = pane.get_meta("pane_size", Vector3.ONE)
		var hit = pane.to_local(position)
		if abs(hit.x) <= size.x * 0.5 + radius and abs(hit.z) <= size.z * 0.5 + radius and abs(hit.y) <= 3.0:
			shatter_glass_pane(pane)

# ===== SLAM — START =====
func start_air_slam():
	if not valid(slam_target):
		return
	force_end_glass_block(true)
	pending_slam_target = slam_target
	slam_chain_empowered = get_walk_pane_count() >= empowered_required_walk_panes
	clear_teleport_followup()
	slam_enemy_was_physics_active = pending_slam_target.is_physics_processing()
	pending_slam_target.set_physics_process(false)
	if pending_slam_target is CharacterBody3D:
		pending_slam_target.velocity = Vector3.ZERO
	slam_windup_timer = slam_windup_time
	combo_hold_timer = max(combo_hold_timer, slam_windup_time + slam_recovery_time)
	velocity = Vector3.ZERO
	start_slam_camera(pending_slam_target)
func update_slam_windup(delta):
	if slam_windup_timer <= 0.0:
		return
	slam_windup_timer -= delta
	if slam_windup_timer <= 0.0:
		execute_air_slam()
func execute_air_slam():
	if not valid(pending_slam_target):
		pending_slam_target = null
		end_slam_camera()
		return
	var enemy = pending_slam_target
	pending_slam_target = null
	if slam_chain_empowered:
		perform_pane_chain_slam(enemy)
	else:
		execute_normal_slam(enemy)
func execute_normal_slam(enemy):
	if not valid(enemy):
		return
	enemy.set_physics_process(slam_enemy_was_physics_active)
	if enemy.has_method("apply_hit_effect"):
		enemy.apply_hit_effect(Vector3.ZERO, 0.0, 0.0, slam_stun_time)
	if enemy is CharacterBody3D:
		enemy.velocity.x *= 0.20
		enemy.velocity.z *= 0.20
		enemy.velocity.y = -slam_down_force
	slam_impact_target = enemy
	slam_last_position = enemy.global_position
	slam_impact_arm_timer = slam_impact_arm_delay
	slam_recovery_timer = slam_recovery_time

# ===== EMPOWERED SLAM — 50 PANE CHAIN =====
func perform_pane_chain_slam(enemy):
	if not valid(enemy):
		return
	var panes = get_chain_panes()
	if panes.size() < empowered_required_walk_panes:
		slam_chain_empowered = false
		execute_normal_slam(enemy)
		return
	slam_chain_running = true
	slam_impact_target = enemy
	enemy.set_physics_process(false)
	if enemy is CharacterBody3D:
		enemy.velocity = Vector3.ZERO
	var entry = get_pane_hit_point(panes[0], enemy.global_position) + Vector3.UP * pane_chain_entry_height
	var tween = create_tween()
	tween.tween_property(enemy, "global_position", entry, pane_chain_entry_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	for i in range(panes.size()):
		if not valid(enemy):
			break
		var pane = panes[i]
		if not valid(pane):
			continue
		slam_chain_progress = float(i + 1) / float(panes.size() + 1)
		var destination = get_pane_hit_point(pane, enemy.global_position)
		destination.y -= 0.35
		tween = create_tween()
		tween.tween_property(enemy, "global_position", destination, pane_chain_step_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished
		if not valid(enemy):
			break
		if valid(pane):
			spawn_flash_sphere(pane.global_position, 3.0, ult_wave_materials[i % ult_wave_materials.size()], 0.08)
			shatter_glass_pane(pane, true, pane_chain_shards_per_pane)
	if not valid(enemy):
		slam_chain_running = false
		slam_impact_target = null
		end_slam_camera()
		return
	enemy.set_physics_process(slam_enemy_was_physics_active)
	slam_chain_running = false
	slam_chain_progress = 1.0
	if enemy is CharacterBody3D:
		enemy.velocity = Vector3(0.0, -slam_down_force * pane_chain_down_multiplier, 0.0)
	slam_last_position = enemy.global_position
	slam_impact_arm_timer = slam_impact_arm_delay
	slam_recovery_timer = slam_recovery_time

# ===== SLAM — FALL / IMPACT DETECTION =====
func update_slam_impact(delta):
	if slam_chain_running:
		return
	if not valid(slam_impact_target):
		slam_impact_target = null
		if slam_camera_active and slam_camera_hold_timer <= 0.0 and not valid(pending_slam_target):
			end_slam_camera()
		return
	var enemy = slam_impact_target
	if not enemy is CharacterBody3D:
		slam_impact_target = null
		end_slam_camera()
		return
	if not slam_chain_empowered:
		shatter_panes_crossed_by_slam(slam_last_position, enemy.global_position)
		slam_last_position = enemy.global_position
	var down_force = slam_down_force * pane_chain_down_multiplier if slam_chain_empowered else slam_down_force
	enemy.velocity.y = min(enemy.velocity.y, -down_force)
	if slam_impact_arm_timer > 0.0:
		slam_impact_arm_timer -= delta
		return
	if enemy.is_on_floor():
		var impact = enemy.global_position
		trigger_slam_impact(impact)
		slam_impact_target = null
		hold_slam_camera_on_impact(impact)

# ===== SLAM — IMPACT =====
func trigger_slam_impact(position):
	var empowered = slam_chain_empowered
	var radius = pane_chain_aoe_radius if empowered else slam_aoe_radius
	var damage = pane_chain_aoe_damage if empowered else slam_aoe_damage
	var knockback = pane_chain_aoe_knockback if empowered else slam_aoe_knockback
	var launch = pane_chain_aoe_launch_force if empowered else slam_aoe_launch_force
	var stun = pane_chain_aoe_stun_time if empowered else slam_aoe_stun_time
	shatter_panes_at_slam_impact(position, radius)
	var nearby = get_enemies_near(position, radius)
	for enemy in nearby:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if enemy.has_method("apply_hit_effect"):
			var direction = enemy.global_position - position
			direction.y = 0.0
			direction = direction.normalized() if direction.length() > 0.01 else Vector3.UP
			enemy.apply_hit_effect(direction, knockback, launch, stun)
	slam_popup_burst(position, get_nearest_targets(position, nearby, slam_popup_projectile_count))
	if empowered:
		create_empowered_slam_impact(position)
	else:
		spawn_flash_sphere(position + Vector3.UP * 0.2, slam_aoe_radius, ult_wave_materials[2], 0.18)
	slam_chain_empowered = false
	slam_chain_progress = 0.0
func create_empowered_slam_impact(position):
	spawn_flash_sphere(position + Vector3.UP, pane_chain_fx_radius, ult_wave_materials[0], 0.30)
	spawn_flash_sphere(position + Vector3.UP * 0.5, pane_chain_fx_radius * 0.75, ult_wave_materials[2], 0.24)
	spawn_shard_burst(position + Vector3.UP, 96, pane_chain_fx_radius * 0.80, 1.5, 0.55)
	spawn_light_flash(position + Vector3.UP * 2.0, pane_chain_fx_radius, 16.0, Color(0.65, 0.85, 1.0), 0.40)

# ===== SLAM — POPUP PROJECTILES =====
func slam_popup_burst(position, targets):
	if targets.is_empty():
		return
	spawn_slam_projectiles(position, targets)
	await get_tree().create_timer(slam_popup_delay).timeout
	for enemy in targets:
		if valid(enemy):
			pop_enemy_to_lucian(enemy)
func spawn_slam_projectiles(position, targets):
	if not homing_projectile_scene:
		return
	var count = targets.size()
	for i in range(count):
		var enemy = targets[i]
		if not valid(enemy):
			continue
		var projectile = homing_projectile_scene.instantiate()
		var angle = TAU * float(i) / float(max(count, 1))
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = position + Vector3(cos(angle), 0.0, sin(angle)) * slam_popup_projectile_radius + Vector3.UP * slam_popup_projectile_height
		projectile.projectile_size = slam_popup_projectile_size
		projectile.damage = slam_popup_projectile_damage
		projectile.is_finisher_projectile = false
		projectile.target = enemy
		projectile.direction = (enemy.global_position - projectile.global_position).normalized()
func pop_enemy_to_lucian(enemy):
	if not enemy is CharacterBody3D:
		return
	var height = max(global_position.y - enemy.global_position.y, slam_popup_min_height)
	var speed_needed = sqrt(2.0 * slam_popup_gravity_reference * height)
	enemy.velocity.y = max(enemy.velocity.y, min(speed_needed, slam_popup_max_up_speed))

# ===== ULT — Q =====
func add_ult_charge(amount):
	if ult_ready:
		return
	ult_charge = clamp(ult_charge + amount, 0.0, ult_max_charge)
	ult_ready = ult_charge >= ult_max_charge
	update_ult_ui()
func try_activate_ult():
	if not ult_ready or slam_camera_active:
		return
	ult_charge = 0.0
	ult_ready = false
	update_ult_ui()
	clear_teleport_followup()
	create_ult_explosion()
	for enemy in get_enemies_near(global_position, ult_radius):
		if can_ult_shatter_enemy(enemy):
			ult_lift_and_shatter(enemy)
		else:
			ult_hit_strong_enemy(enemy)
func create_ult_explosion():
	screen_flash()
	camera_fov_pulse()
	for i in range(ult_wave_materials.size()):
		spawn_delayed_wave(i * 0.045, ult_visual_radius * (0.75 + i * 0.18), ult_wave_materials[i])
	spawn_shard_burst(global_position + Vector3.UP * 1.2, ult_center_shard_count, ult_visual_radius * 0.65, 1.4, 0.55)
	spawn_light_flash(global_position + Vector3.UP * 2.0, ult_visual_radius, 14.0, Color(0.55, 0.85, 1.0), 0.35)
func spawn_delayed_wave(delay, radius, material):
	await get_tree().create_timer(delay).timeout
	spawn_flash_sphere(global_position + Vector3.UP * 1.2, radius, material, 0.34)
func can_ult_shatter_enemy(enemy):
	if not valid(enemy) or enemy.is_in_group("bosses") or enemy.is_in_group("elites"):
		return false
	var hp = get_property_if_exists(enemy, "max_health")
	if hp == null:
		hp = get_property_if_exists(enemy, "health")
	return hp != null and float(hp) <= ult_weak_enemy_health
func ult_lift_and_shatter(enemy):
	if not valid(enemy):
		return
	if enemy is CharacterBody3D:
		enemy.velocity.x *= 0.25
		enemy.velocity.z *= 0.25
		enemy.velocity.y = max(enemy.velocity.y, ult_lift_speed)
	if enemy.has_method("apply_hit_effect"):
		enemy.apply_hit_effect(Vector3.ZERO, 0.0, 0.0, ult_lift_time + 0.12)
	await get_tree().create_timer(ult_lift_time).timeout
	if not valid(enemy):
		return
	var position = enemy.global_position + Vector3.UP
	spawn_flash_sphere(position, 7.0, ult_wave_materials[0], 0.18)
	spawn_flash_sphere(position, 5.0, ult_wave_materials[2], 0.14)
	spawn_shard_burst(position, ult_enemy_shard_count, ult_enemy_piece_distance, 0.95, 0.50)
	if enemy.has_method("take_damage"):
		enemy.take_damage(999999.0)
	else:
		enemy.queue_free()
func ult_hit_strong_enemy(enemy):
	if not valid(enemy):
		return
	if enemy is CharacterBody3D:
		enemy.velocity.y = max(enemy.velocity.y, ult_lift_speed * 0.65)
	if enemy.has_method("take_damage"):
		enemy.take_damage(ult_strong_enemy_damage)
	if enemy.has_method("apply_hit_effect"):
		var direction = enemy.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized() if direction.length() > 0.01 else Vector3.UP
		enemy.apply_hit_effect(direction, ult_knockback, ult_launch_force, ult_stun_time)
	spawn_shard_burst(enemy.global_position + Vector3.UP, 10, 6.0, 0.55, 0.35)
func get_property_if_exists(object, property_name):
	for info in object.get_property_list():
		if String(info["name"]) == property_name:
			return object.get(property_name)
	return null

# ===== ENEMY TARGETING HELPERS =====
func get_enemies():
	return get_tree().get_nodes_in_group("enemies")
func is_usable_enemy(enemy, max_range, airborne_only = false):
	return valid(enemy) and enemy is Node3D and global_position.distance_to(enemy.global_position) <= max_range and (not airborne_only or (enemy is CharacterBody3D and not enemy.is_on_floor()))
func get_nearest_enemy(max_range, airborne_only = false):
	var nearest = null
	var nearest_distance = max_range
	for enemy in get_enemies():
		if not is_usable_enemy(enemy, max_range, airborne_only):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest
func get_enemies_near(point, radius):
	var result = []
	for enemy in get_enemies():
		if valid(enemy) and enemy is Node3D and point.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result
func get_nearest_targets(point, candidates, count):
	var remaining = candidates.duplicate()
	var result = []
	while not remaining.is_empty() and result.size() < count:
		var nearest = null
		var nearest_distance = INF
		for enemy in remaining:
			if not valid(enemy):
				continue
			var distance = point.distance_squared_to(enemy.global_position)
			if distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
		if nearest == null:
			break
		result.append(nearest)
		remaining.erase(nearest)
	return result

# ===== LOCK ON =====
func toggle_lock():
	if valid(locked_enemy):
		clear_lock()
		return
	lock_targets.clear()
	for enemy in get_enemies():
		if is_usable_enemy(enemy, lock_range):
			lock_targets.append(enemy)
	if lock_targets.is_empty():
		return
	lock_index = 0
	locked_enemy = lock_targets[0]
	if lock_reticle:
		lock_reticle.show()
func clear_lock():
	locked_enemy = null
	if lock_reticle:
		lock_reticle.hide()
func switch_target(direction):
	var valid_targets = []
	for enemy in lock_targets:
		if valid(enemy):
			valid_targets.append(enemy)
	lock_targets = valid_targets
	if lock_targets.is_empty():
		clear_lock()
		return
	lock_index = wrapi(lock_index + direction, 0, lock_targets.size())
	locked_enemy = lock_targets[lock_index]
func update_lock_camera(delta):
	if slam_camera_active or teleport_hold_active or not valid(locked_enemy):
		return
	var direction = locked_enemy.global_position + Vector3.UP * 1.5 - global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), weight(lock_turn_speed, delta))
func update_lock_reticle():
	if not lock_reticle:
		return
	if not valid(locked_enemy) or not camera:
		lock_reticle.hide()
		if not valid(locked_enemy):
			locked_enemy = null
		return
	lock_reticle.show()
	lock_reticle.position = camera.unproject_position(locked_enemy.global_position + Vector3.UP * 2.5)

# ===== VORTEX OF POETRY — LMB =====
func attack():
	combo_step = 1 if combo_step >= 3 else combo_step + 1
	attacking = true
	combo_timer = combo_reset_time
	match combo_step:
		1:
			shoot_projectile(1)
		2:
			shoot_projectile(2)
		3:
			perform_vortex_finisher()
	await get_tree().create_timer(0.08).timeout
	attacking = false
func perform_vortex_finisher():
	var target = locked_enemy if is_usable_enemy(locked_enemy, finisher_target_range) else get_nearest_enemy(finisher_target_range)
	if not valid(target):
		return
	finisher_id_counter += 1
	if target.has_method("begin_finisher_setup"):
		target.begin_finisher_setup(finisher_id_counter, finisher_setup_launch_force, finisher_setup_hold_time, finisher_setup_stun_time)
	shoot_projectile(finisher_projectile_count, finisher_id_counter, target)
func shoot_projectile(amount, finisher_id = -1, finisher_target = null):
	for i in range(amount):
		var projectile = create_projectile()
		if not projectile:
			return
		match combo_step:
			1:
				projectile.projectile_size = 0.5
				projectile.damage = 10
			2:
				projectile.projectile_size = 0.5
			3:
				projectile.projectile_size = 1.0
				projectile.damage = finisher_projectile_damage
				projectile.is_finisher_projectile = true
				projectile.finisher_id = finisher_id
				projectile.finisher_hit_count = amount
				projectile.target = finisher_target
				projectile.orbit_index = i
				projectile.orbit_count = amount
		spawn_projectile(projectile)
func create_projectile():
	var scene = homing_projectile_scene if combo_step == 3 else projectile_scene
	if not scene:
		return null
	var projectile = scene.instantiate()
	if combo_step != 3:
		projectile.target = get_normal_projectile_target()
	return projectile
func get_normal_projectile_target():
	if is_usable_enemy(locked_enemy, normal_projectile_target_range):
		return locked_enemy
	return get_nearest_enemy(normal_projectile_target_range)
func spawn_projectile(projectile):
	get_tree().current_scene.add_child(projectile)
	var forward = (-global_transform.basis.z).normalized()
	var right = global_transform.basis.x.normalized()
	projectile.global_position = global_position + Vector3.UP * projectile_spawn_height + forward * projectile_spawn_forward + right * projectile_spawn_side
	projectile.direction = (-camera.global_transform.basis.z).normalized() if camera else forward

# ===== VISUAL EFFECTS =====
func spawn_shard_burst(position, count, distance, size_scale = 1.0, duration = 0.45):
	if shard_materials.is_empty():
		return
	for i in range(max(count, 1)):
		var shard = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(randf_range(0.12, 0.42), randf_range(0.05, 0.16), randf_range(0.35, 0.95)) * size_scale
		shard.mesh = mesh
		shard.material_override = shard_materials[i % shard_materials.size()]
		get_tree().current_scene.add_child(shard)
		var angle = TAU * float(i) / float(max(count, 1)) + randf_range(-0.18, 0.18)
		var direction = Vector3(cos(angle), randf_range(0.15, 0.95), sin(angle)).normalized()
		shard.global_position = position + direction * randf_range(0.1, 1.2) * size_scale
		shard.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
		var tween = shard.create_tween().set_parallel(true)
		tween.tween_property(shard, "global_position", shard.global_position + direction * distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", shard.rotation + Vector3(randf_range(2.0, 6.0), randf_range(2.0, 6.0), randf_range(2.0, 6.0)), duration)
		tween.tween_property(shard, "scale", Vector3.ZERO, duration)
		tween.finished.connect(shard.queue_free)
func spawn_flash_sphere(position, radius, material, duration = 0.28):
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	sphere.mesh = mesh
	sphere.material_override = material
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = position
	sphere.scale = Vector3.ONE * 0.2
	var tween = sphere.create_tween()
	tween.tween_property(sphere, "scale", Vector3.ONE * radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(sphere.queue_free)
func spawn_light_flash(position, radius, energy, color, duration):
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	get_tree().current_scene.add_child(light)
	light.global_position = position
	var tween = light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.finished.connect(light.queue_free)
func screen_flash():
	var layer = CanvasLayer.new()
	var flash = ColorRect.new()
	layer.layer = 100
	add_child(layer)
	flash.color = Color.WHITE
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.78
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, ult_screen_flash_time)
	tween.finished.connect(layer.queue_free)
func camera_fov_pulse():
	if camera:
		camera.fov += 8.0

# ===== UI SETUP =====
func setup_ui():
	var follow = create_meter_ui(20, Control.PRESET_CENTER_BOTTOM, Vector4(-240, -115, 240, -45), "", teleport_followup_window, Vector2(460, 8))
	followup_ui = follow[0]
	followup_label = follow[1]
	followup_bar = follow[2]
	followup_ui.hide()
	var pane_layer = CanvasLayer.new()
	pane_layer.layer = 18
	add_child(pane_layer)
	pane_counter_label = Label.new()
	pane_layer.add_child(pane_counter_label)
	pane_counter_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pane_counter_label.offset_left = -210.0
	pane_counter_label.offset_right = 210.0
	pane_counter_label.offset_top = 28.0
	pane_counter_label.offset_bottom = 65.0
	pane_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pane_counter_label.add_theme_font_size_override("font_size", 22)
	var ult = create_meter_ui(19, Control.PRESET_BOTTOM_LEFT, Vector4(30, -105, 350, -35), "", ult_max_charge, Vector2(320, 12))
	ult_ui = ult[0]
	ult_label = ult[1]
	ult_bar = ult[2]
	update_pane_counter_ui()
	update_ult_ui()
func create_meter_ui(layer_number, preset, offsets, text, max_value, bar_size):
	var layer = CanvasLayer.new()
	var root = VBoxContainer.new()
	var label = Label.new()
	var bar = ProgressBar.new()
	layer.layer = layer_number
	add_child(layer)
	layer.add_child(root)
	root.set_anchors_preset(preset)
	root.offset_left = offsets.x
	root.offset_top = offsets.y
	root.offset_right = offsets.z
	root.offset_bottom = offsets.w
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	bar.max_value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = bar_size
	root.add_child(label)
	root.add_child(bar)
	return [root, label, bar]

# ===== UI UPDATES =====
func update_followup_ui():
	if not followup_ui:
		return
	var available = teleport_followup_timer > 0.0 and valid(teleport_focus_target) and slam_windup_timer <= 0.0
	followup_ui.visible = available
	if not available:
		return
	followup_bar.max_value = teleport_followup_window
	followup_bar.value = teleport_followup_timer
	var empowered = get_walk_pane_count() >= empowered_required_walk_panes
	followup_label.text = "[ LMB ] EMPOWERED SLAM      [ SPACE ] GLASS ARENA" if empowered else "[ LMB ] SLAM      [ SPACE ] GLASS ARENA"
func update_pane_counter_ui():
	if not pane_counter_label:
		return
	var count = get_walk_pane_count()
	if count >= empowered_required_walk_panes:
		pane_counter_label.text = "EMPOWERED SLAM READY   %d / %d" % [count, empowered_required_walk_panes]
	else:
		pane_counter_label.text = "MOVEMENT PANES   %d / %d" % [count, empowered_required_walk_panes]
func update_ult_ui():
	if not ult_bar:
		return
	ult_bar.max_value = ult_max_charge
	ult_bar.value = ult_charge
	ult_label.text = "[ Q ] NO ONE UNDERSTANDS MY ART" if ult_ready else "NO ONE UNDERSTANDS MY ART"

# ===== HEALTH =====
func _on_hurtbox_body_entered(_body):
	pass
func take_damage(amount):
	if dodge_invincible or hit_invincible:
		return
	hit_invincible = true
	health -= amount
	if health_bar:
		health_bar.value = health
	if health <= 0:
		die()
		return
	flash_red()
	await get_tree().create_timer(hit_invincibility_time).timeout
	hit_invincible = false
	if not dodge_invincible:
		remove_flash()
func die():
	release_teleport_hold()
	force_end_glass_block(false)
	if slam_camera_active:
		end_slam_camera()
	queue_free()

# ===== ANIMATION =====
func update_animation(direction):
	if not anim:
		return
	if teleport_hold_active or slam_camera_active:
		play_animation("rig_idle")
	elif is_dodging:
		play_animation("rig_dodge")
	elif direction.length() > 0.1:
		play_animation("rig_run")
	else:
		play_animation("rig_idle")
func play_animation(name):
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name)

# ===== PLAYER COLOR FLASH =====
func flash_red():
	set_player_color(Color.RED)
	await get_tree().create_timer(0.1).timeout
	if not dodge_invincible:
		remove_flash()
func flash_blue():
	set_player_color(Color.CYAN)
func remove_flash():
	set_player_color(Color.WHITE)
func set_player_color(color):
	for mesh in get_all_meshes(self):
		if not mesh.mesh:
			continue
		for i in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_surface_override_material(i)
			if material == null:
				var original = mesh.mesh.surface_get_material(i)
				material = original.duplicate() if original else StandardMaterial3D.new()
				mesh.set_surface_override_material(i, material)
			if material is StandardMaterial3D:
				material.albedo_color = color
func get_all_meshes(node):
	var meshes = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		meshes.append_array(get_all_meshes(child))
	return meshes
