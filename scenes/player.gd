extends CharacterBody3D

# ── MOVEMENT / DASH ──
@export var speed = 40.0
@export var jump_force = 25.0
@export var gravity = 50.0
@export var dodge_speed = 108.0
@export var dodge_duration = 0.22
@export var dodge_cooldown = 0.34
@export var dodge_chain_reset_time = 1.5
@export var dodge_exhaustion_recovery = 0.85
@export var dodge_hit_radius = 6.0
@export var dodge_damage = 8.0
@export var dodge_knockback = 18.0
@export var dodge_launch_force = 24.0
@export var dodge_hit_stun = 0.30
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
var consecutive_dodges := 0
var dodge_chain_reset_timer := 0.0
var dodge_invincible = false
var hit_invincible = false
var enemy_knockback_timer := 0.0
var enemy_knockback_velocity := Vector3.ZERO
var dodge_visual_base_rotation := Vector3.ZERO
var dodge_visual_base_position := Vector3.ZERO

# ── VIRTUAL BOOM ACTION CAMERA ──
@export var mouse_sensitivity = 0.003
@export var vertical_mouse_sensitivity = 0.002
@export var camera_pitch_min = -42.0
@export var camera_pitch_max = 35.0
@export var camera_pitch_smooth_speed = 22.0

# Base third-person framing.
@export var camera_distance = 8.5
@export var camera_pivot_height = 2.6
@export var camera_shoulder_offset = 0.0

# Dynamic framing for fast combat.
@export var camera_speed_reference = 40.0
@export var camera_speed_distance_add = 1.0
@export var camera_speed_fov_add = 3.0
@export var camera_air_distance_add = 0.8
@export var camera_air_fov_add = 2.0
@export var camera_dash_distance_add = 1.8
@export var camera_dash_fov_add = 7.0
@export var camera_attack_distance_add = 0.6
@export var camera_attack_fov_add = 2.0

# Virtual boom collision.
# No SpringArm collision is used.
@export_flags_3d_physics var camera_collision_mask: int = 1
@export var camera_collision_radius = 0.38
@export var camera_collision_padding = 0.18
@export var camera_collision_in_speed = 40.0
@export var camera_collision_out_speed = 9.0
@export var camera_min_safe_distance = 1.1

# Keep Lucian centered even when collision pushes the camera close.
@export var camera_close_shoulder_boost = 0.0
@export var camera_close_threshold = 2.75

@export var camera_fov_response = 10.0
@export var camera_collision_fov_add = 7.0
@export var camera_yaw_return_speed = 10.0
@export var camera_near = 0.04

# Air targeting.
@export var air_target_pitch_strength = 3.0

# Slam camera.
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

# Final-finisher detached camera.
@export var empowered_camera_follow_speed = 20.0
@export var empowered_camera_orbit_angle = 70.0
@export var empowered_camera_orbit_speed = 6.0
@export var empowered_camera_pitch = 12.0
@export var empowered_camera_height = 1.1

# Empowered Slam stationary observer camera.
@export var empowered_slam_camera_height = 16.0
@export var empowered_slam_camera_back_offset = 10.0
@export var empowered_slam_camera_side_offset = 4.0
@export var empowered_slam_camera_start_fov = 72.0
@export var empowered_slam_camera_focus_fov = 24.0
@export var empowered_slam_camera_zoom_speed = 6.5
@export var empowered_slam_camera_track_speed = 18.0
@export var empowered_slam_camera_impact_fov = 86.0

# Existing empowered-slam ending.
@export var empowered_slam_return_delay = 0.02
@export var empowered_slam_player_drop_velocity = 10000.0
@export var empowered_slam_player_drop_lock_time = 0.05

@export var slam_camera_impact_hold_time = 0.22
@export var slam_impact_fov_punch = 12.0
@export var empowered_impact_fov_punch = 24.0

@onready var camera_pivot = find_child("CameraPivot", true, false)
@onready var spring_arm = find_child("SpringArm3D", true, false)
@onready var camera = find_child("Camera3D", true, false)

var camera_pitch = 0.0
var camera_pitch_target = 0.0
var camera_base_fov = 75.0

var camera_boom_distance = 8.5
var camera_collision_shape: SphereShape3D

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
var slam_saved_spring_length = 8.5
var slam_saved_fov = 75.0

var empowered_slam_camera_active = false
var empowered_slam_camera_fixed_position = Vector3.ZERO
var empowered_slam_camera_look_target = null
var empowered_slam_player_hold_position = Vector3.ZERO
var empowered_slam_return_pending = false
var empowered_slam_return_timer = 0.0
var empowered_slam_return_impact_point = Vector3.ZERO
var empowered_slam_player_drop_lock_timer = 0.0
var empowered_slam_ground_y_for_camera = 0.0
var empowered_slam_apex_y_for_camera = 0.0

var slam_camera_roll_kick = 0.0
@export var slam_camera_roll_return_speed = 22.0

# ── HEALTH / LOCK ──
@export var max_health = 10000
@export var hit_invincibility_time = 0.3
@export var lock_range = 65.0
@export var lock_turn_speed = 5.0
@onready var health_bar = find_child("HealthBar", true, false)
@onready var anim = find_child("AnimationPlayer", true, false)
@onready var dodge_visual: Node3D = $edgelord
@onready var character_skeleton: Skeleton3D = $edgelord/rig/Skeleton3D
var health = 0.0
var locked_enemy = null
var lock_targets = []
var lock_index = 0
var lock_reticle = null

# ── WALK OF EMO BAND ──
@export var teleport_range = 100.0
@export var teleport_cooldown = 0.12
@export var teleport_kill_refund: float = 0.08
@export var teleport_recovery = 0.10
@export var teleport_input_buffer_time: float = 0.18
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
@export var teleport_followup_window = 1.60
@export var pane_pull_time: float = 0.12
@export var pane_pull_forward_offset: float = 4.0
@export var pane_pull_height_offset: float = 1.5
@export var pane_pull_cooldown: float = 14.0
var teleport_cooldown_timer = 0.0
var pane_pull_cooldown_timer = 0.0
var teleport_input_buffer_timer: float = 0.0
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

# ── PANES OF PAIN ──
@export_flags_3d_physics var glass_collision_layer: int = 2
@export_group("Breakable Panes")
@export var pane_tumble_break_speed: float = 12.0
@export var pane_attack_break_shards: int = 32
@export var glass_pane_max_count = 96
@export var glass_walk_gravity_multiplier = 0.12
@export var glass_walk_max_fall_speed = -3.0
@export var walk_pane_size = Vector3(7.0, 0.18, 7.0)
@export var walk_pane_spawn_interval = 0.10
@export var walk_pane_lifetime = 12.0
@export var walk_pane_forward_offset = 1.3
@export var walk_pane_vertical_offset = 1.20
@export var arena_pane_size = Vector3(42.0, 0.30, 42.0)
@export var arena_pane_lifetime = 20.0
@export var arena_pane_vertical_offset = 1.35
@export var arena_player_lift = 2.0
@export var arena_enemy_lift = 1.5
@export var pane_shatter_shard_count = 14
@export var pane_shatter_distance = 6.0
@export var pane_shatter_duration = 0.40
@export var small_pane_ult_charge = 2.0
@export var big_pane_ult_charge = 6.0
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

# ── F — GLASS BLOCK / PERFECT BLOCK ──
@export var glass_block_distance = 8.0
@export var glass_block_columns = 10
@export var glass_block_spacing_x = 4.2
@export var glass_block_spacing_y = 3.0
@export var glass_block_base_height = 1.4
@export var glass_block_pull_speed = 20.0
@export var glass_block_return_speed = 10.0
@export var glass_block_return_snap_distance = 0.08
@export var glass_block_max_hold_time = 2.0
@export var glass_block_break_shards = 8

@export var perfect_block_window = 0.25
@export var perfect_block_ult_charge = 1.0
@export var perfect_block_counter_shards = 3
@export var perfect_block_counter_damage = 8.0
@export var perfect_block_counter_size = 0.45
@export var perfect_block_counter_speed = 110.0
@export var perfect_block_counter_homing = 12.0
@export var perfect_block_counter_launch = 3.0
@export var perfect_block_counter_stun = 0.40
@export var perfect_block_flash_radius = 8.0

var glass_block_active = false
var glass_block_returning = false
var glass_block_broken_until_release = false
var glass_block_time_left = 0.0
var glass_block_perfect_timer = 0.0
var glass_block_original_transforms: Dictionary = {}
var glass_block_enemy_masks: Dictionary = {}

# ── E — PANE VOLLEY ──
@export var pane_volley_damage = 3.0
@export var pane_volley_size = 0.45
@export var pane_volley_speed = 95.0
@export var pane_volley_homing = 10.0
@export var pane_volley_target_range = 100.0
@export var pane_volley_launch_force = 2.0
@export var pane_volley_knockback = 0.0
@export var pane_volley_stun = 0.25
@export var pane_volley_visual_shards = 3

# ── SLAM ──
@export var slam_windup_time = 0.12
@export var slam_recovery_time = 0.18
@export var slam_down_force = 95.0
@export var slam_stun_time = 0.35
@export var slam_break_radius = 1.2
@export var slam_impact_arm_delay = 0.08

@export var slam_aoe_radius = 8.0
@export var slam_aoe_damage = 30.0
@export var slam_aoe_knockback = 28.0
@export var slam_aoe_launch_force = 8.0
@export var slam_aoe_stun_time = 0.35

# NEW EMPOWERED SLAM — 50 movement panes
@export var empowered_required_walk_panes = 50
@export var empowered_slam_apex_height = 70.0
@export var empowered_slam_launch_time = 0.30
@export var empowered_slam_pane_move_time = 0.48

# Huge separation: 50 panes can make a ~300-unit tower.
@export var empowered_slam_pane_spacing = 6.0
@export var empowered_slam_pane_bottom_height = 2.0
@export var empowered_slam_pane_top_gap = 8.0

# Lucian stays above the target, visually driving them down.
@export var empowered_slam_player_above_height = 4.5
@export var empowered_slam_player_follow_speed = 40.0

@export var empowered_slam_down_force = 240.0

# Each pane swells before the enemy crashes through it.
@export var empowered_pane_expand_distance = 28.0
@export var empowered_pane_expand_scale = 8.0
@export var empowered_pane_expand_speed = 42.0
@export var empowered_pane_break_distance = 2.5
@export var empowered_pane_shatter_radius = 16.0
@export var empowered_pane_shatter_shards = 22
@export var empowered_pane_shatter_distance = 20.0
@export var empowered_pane_flash_energy = 16.0
@export var empowered_pane_fov_punch = 2.6

# Massive final impact.
@export var empowered_slam_aoe_radius = 70.0
@export var empowered_slam_aoe_damage = 280.0
@export var empowered_slam_aoe_knockback = 140.0
@export var empowered_slam_aoe_launch_force = 60.0
@export var empowered_slam_aoe_stun_time = 1.75
@export var empowered_slam_fx_radius = 85.0

# Old pane-chain move is now a fight-ending finisher.
@export var final_finisher_damage = 150.0
@export var final_finisher_entry_height = 4.0
@export var final_finisher_entry_time = 0.10
@export var final_finisher_step_time = 0.035
@export var final_finisher_shards_per_pane = 5
@export var final_finisher_down_multiplier = 1.80

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
var slam_final_finisher_active = false
var slam_chain_running = false
var slam_chain_progress = 0.0

var empowered_slam_active = false
var empowered_slam_victim = null
var empowered_slam_player_offset = Vector3.ZERO
var empowered_slam_panes = []
var empowered_slam_next_pane = 0

# ── ULT ──
@export var ult_max_charge = 100.0
@export var ult_radius = 55.0
@export var ult_visual_radius = 65.0
@export var ult_weak_enemy_health = 100.0
@export var ult_lift_speed = 11.0
@export var ult_lift_time = 0.24
@export var ult_strong_enemy_damage = 80.0
@export var ult_knockback = 26.0
@export var ult_launch_force = 12.0
@export var ult_stun_time = 0.85
@export var ult_enemy_shard_count = 28
@export var ult_enemy_piece_distance = 12.0
@export var ult_center_shard_count = 96
@export var ult_screen_flash_time = 0.30

# Gothic glass styling.
@export var ult_rose_spokes = 24
@export var ult_rose_radius = 16.0
@export var ult_rose_height = 0.32
@export var ult_crown_shards = 28
@export var ult_crown_radius = 7.5
@export var ult_crown_height = 9.0
@export var ult_crown_expand_radius = 24.0
@export var ult_style_duration = 0.58
var ult_charge = 0.0
var ult_ready = false
var ult_ui
var ult_label
var ult_bar

# ── VORTEX OF POETRY ──
@export var projectile_scene: PackedScene
@export var homing_projectile_scene: PackedScene
@export var projectile_spawn_height = 1.5
@export var projectile_spawn_forward = 1.5
@export var projectile_spawn_side = 0.0
@export var normal_projectile_target_range = 65.0
@export var combo_reset_time = 1.0
@export var combo_hold_delay = 0.10
@export var combo_hit_one_recovery = 0.28
@export var combo_hit_two_recovery = 0.34
@export var combo_finisher_recovery = 0.56
@export var ability_recovery = 0.42
@export var ultimate_recovery = 0.85
@export var finisher_projectile_count = 8
@export var finisher_projectile_damage = 0.3
@export var finisher_setup_launch_force = 7.0
@export var finisher_setup_hold_time = 1.5
@export var finisher_setup_stun_time = 1.5
@export var finisher_target_range = 90.0
@export_category("Vortex of Poetry Melee")
@export var melee_reach: float = 11.5
@export var melee_step_distances: Vector3 = Vector3(1.1, 1.5, 0.9)
@export_group("Sword Body Movement")
@export var sword_motion_speeds: Vector3 = Vector3(52.0, 66.0, 82.0)
@export var sword_motion_durations: Vector3 = Vector3(0.16, 0.19, 0.25)
@export var second_swing_cross_amount: float = 0.32
@export var left_finisher_motion_angle: float = -42.0
@export var right_finisher_motion_angle: float = 52.0
@export var sword_motion_input_influence: float = 0.14
@export var sword_motion_targeting_strength: float = 0.88
@export var sword_motion_side_targeting_strength: float = 0.42
@export var sword_motion_arrival_distance: float = 2.4
@export var melee_focus_range: float = 46.0
@export_group("Melee Hit Tuning")
@export var melee_damage_tiers: Vector3 = Vector3(14.0, 21.0, 38.0)
@export var melee_break_tiers: Vector3 = Vector3(16.0, 28.0, 75.0)
@export var melee_stagger_tiers: Vector3 = Vector3(0.14, 0.28, 0.55)
@export var melee_knockback_tiers: Vector3 = Vector3(18.0, 32.0, 58.0)
@export var melee_launch_tiers: Vector3 = Vector3(2.0, 5.0, 10.0)
@export var melee_wave_start_distance: float = 11.8
@export var melee_cooldown_refund: float = 0.28
@export var melee_contact_delays: Vector3 = Vector3(0.10, 0.115, 0.18)
@export var melee_contact_brake: float = 0.32
@export var melee_impact_light_energy: Vector3 = Vector3(5.0, 8.0, 15.0)
@export var melee_impact_flash_radius: Vector3 = Vector3(3.5, 5.0, 8.0)
@export var running_attack_speed_threshold: float = 11.0
@export var dodge_attack_window: float = 0.42
@export var mobility_attack_damage_multiplier: float = 1.35
@export var teleport_backslash_break: float = 95.0
@export var blade_flash_energy: float = 14.0
@export var blade_shard_count: int = 18
@export var perfect_click_window: float = 0.16
@export var blade_hand_offset: Vector3 = Vector3(0.85, 1.45, 0.9)
@export var blade_horizontal_arc_degrees: float = 72.0
@export var blade_hand_anchor_stability: float = 0.55
@export var blade_assembly_time: float = 0.045
@export var blade_cut_time: float = 0.105
@export var blade_follow_through_time: float = 0.09
@export_group("Combat Responsiveness")
@export var attack_input_buffer_time: float = 0.16
@export var combo_dodge_preserve_time: float = 0.78
@export var dodge_exit_momentum: float = 0.24
@export var finisher_dodge_commitment: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var jump_coyote_time: float = 0.10
@export_group("Sword Combo Branches")
@export var lateral_sweep_radius_multiplier: float = 1.35
@export var driving_finisher_knockback_multiplier: float = 1.45
@export var driving_finisher_launch: float = 3.0
@export_group("Directional Finishers")
@export var left_finisher_gather_radius_multiplier: float = 1.42
@export var left_finisher_inward_force: float = 32.0
@export var left_finisher_launch: float = 17.0
@export var right_finisher_cleave_radius_multiplier: float = 1.28
@export var right_finisher_sweep_force: float = 72.0
@export var right_finisher_launch: float = 8.0
@export var directional_branch_threshold: float = 0.45
@export_group("Double Click Sword Cyclone")
@export var sword_cyclone_duration: float = 3.0
@export var sword_cyclone_cooldown: float = 14.0
@export var sword_cyclone_radius: float = 23.0
@export var sword_cyclone_hit_interval: float = 0.08
@export var sword_cyclone_sweep_arc_degrees: float = 115.0
@export var sword_cyclone_move_speed_multiplier: float = 0.85
@export var sword_cyclone_damage: float = 8.0
@export var sword_cyclone_knockback: float = 10.0
@export var sword_cyclone_launch: float = 2.5
@export var sword_cyclone_final_damage: float = 30.0
@export var sword_cyclone_final_knockback: float = 76.0
@export var sword_cyclone_final_launch: float = 16.0
@export var sword_cyclone_turns_per_second: float = 4.5
@export var sword_cyclone_direction_spread_degrees: float = 78.0
@export var sword_cyclone_final_direction_spread_degrees: float = 145.0
@export var sword_cyclone_launch_variation: float = 8.0
@export var air_arena_cooldown: float = 1.25
@export_group("Final Word Air Carry")
@export var vortex_carry_duration: float = 0.72
@export var vortex_carry_height_offset: float = 0.4
@export var vortex_carry_side_distance: float = 2.8
@export var vortex_carry_follow_speed: float = 52.0
@export var vortex_carry_vertical_speed: float = 12.0
@export var aerial_suspension_speed: float = 4.5
@export var finisher_auto_air_carry: bool = false
var run_projectile_damage_multiplier = 1.0
# ── RETICLE AIMING ──
@export var aim_distance = 2000.0
@export var aim_assist_screen_radius = 70.0
@export var aim_assist_range = 90.0
@export_flags_3d_physics var aim_collision_mask: int = 0xFFFFFFFF
var aim_reticle = null
var aim_reticle_target = null

var attacking = false
var combo_step = 0
var combo_timer = 0.0
var combo_hold_timer = 0.0
var combat_recovery_timer = 0.0
var finisher_id_counter = 0
var combo_melee_hit_ids: Dictionary = {}
var last_combo_click_msec: int = 0
var vortex_carry_target: Node3D
var vortex_carry_timer := 0.0
var attack_buffer_timer := 0.0
var attack_held := false
var attack_buffer_is_hold := false
var dodge_preserved_combo := false
var attack_cancel_lock_timer := 0.0
var sword_motion_timer: float = 0.0
var sword_motion_velocity: Vector3 = Vector3.ZERO
var sword_motion_target = null
var sword_motion_tracking_strength: float = 0.0
var melee_focus_target = null
var sword_cyclone_active: bool = false
var sword_cyclone_timer: float = 0.0
var sword_cyclone_cooldown_timer: float = 0.0
var sword_cyclone_hit_timer: float = 0.0
var sword_cyclone_visual_start_y: float = 0.0
var sword_cyclone_angle: float = 0.0
var sword_cyclone_hit_serial: int = 0
var jump_buffer_timer := 0.0
var coyote_timer := 0.0
var air_arena_cooldown_timer := 0.0

# Fast active abilities. Neither one requires movement panes.
@export var rift_cleave_cooldown = 2.4
@export var rift_cleave_radius = 13.0
@export var rift_cleave_damage = 12.0
@export var rift_cleave_knockback = 24.0
@export var ruin_volley_cooldown = 4.0
@export var ruin_volley_projectiles = 7
@export var ruin_volley_damage = 4.0
@export_group("F - Falling Pane Crown")
@export var falling_pane_spawn_height: float = 20.0
@export var falling_pane_forward_offset: float = 8.0
@export var falling_pane_form_time: float = 0.72
@export var falling_pane_camera_pitch_degrees: float = -38.0
@export var falling_pane_crash_time: float = 0.42
@export var falling_pane_size: Vector3 = Vector3(90.0, 0.8, 55.0)
@export var falling_pane_impact_radius: float = 48.0
@export var falling_pane_explosion_damage: float = 24.0
@export var falling_pane_knockback: float = 58.0
@export var falling_pane_launch: float = 16.0
@export var falling_pane_explosion_light_energy: float = 18.0
@export_group("E - Cathedral Suspension Pulse")
@export var fracture_well_radius: float = 38.0
@export var fracture_well_pull: float = 7.0
@export var fracture_well_damage: float = 12.0
@export var suspension_pulse_launch: float = 15.0
@export var suspension_pulse_hold_time: float = 1.15
@export var suspension_pulse_stun: float = 0.75
@export_group("Combo Center Retention")
@export var combo_center_lane_half_width: float = 3.4
@export var combo_center_knockback: float = 2.5
@export var combo_center_launch: float = 0.5
@export var combo_side_launch: Vector2 = Vector2(22.0, 26.0)
@export var swing_one_center_launch: float = 18.0
var rift_cleave_timer := 0.0
var ruin_volley_timer := 0.0
var falling_pane_cast_active: bool = false
var falling_pane_saved_camera_pitch: float = 0.0

# ── UI ──
var followup_ui
var followup_label
var followup_bar
var pane_counter_label
var reliquary_health_bar: ProgressBar
var reliquary_loss_bar: ProgressBar
var reliquary_frame: PanelContainer
var reliquary_portrait: Label
var reliquary_critical_notch: Label
var reliquary_ability_diamonds: Array[PanelContainer] = []
var reliquary_status_label: Label
var open_arsenal_label: Label
var open_arsenal_active := false
var open_arsenal_timer := 0.0
var open_arsenal_saved_teleport := 0.0

# ── READY ──

func _ready():
	add_to_group("players")
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
	if dodge_visual:
		dodge_visual_base_rotation = dodge_visual.rotation
		dodge_visual_base_position = dodge_visual.position

func setup_camera():
	if not camera_pivot or not camera:
		push_warning(
			"Camera setup needs CameraPivot and Camera3D."
		)
		return

	camera_original_parent = camera_pivot.get_parent()

	camera_pivot.position = Vector3(
		0.0,
		camera_pivot_height,
		0.0
	)

	camera_pivot.rotation.y = 0.0
	camera_pivot.rotation.z = 0.0

	camera_pitch = camera_pivot.rotation.x
	camera_pitch_target = camera_pitch

	# This system intentionally bypasses SpringArm3D.
	# Camera3D lives directly on the pivot and we control its local
	# X/Z position ourselves.
	if camera.get_parent() != camera_pivot:
		camera.reparent(
			camera_pivot,
			false
		)

	camera.position = Vector3(
		camera_shoulder_offset,
		0.0,
		-camera_distance
	)

	camera.rotation = Vector3(0.0, PI, 0.0)
	camera.top_level = false
	camera.current = true
	camera.near = camera_near
	camera_base_fov = camera.fov

	camera_boom_distance = camera_distance

	camera_collision_shape = SphereShape3D.new()
	camera_collision_shape.radius = camera_collision_radius

	# Leave the old node harmlessly in the scene.
	if spring_arm:
		spring_arm.spring_length = 0.0
		spring_arm.collision_mask = 0
		spring_arm.shape = null


func setup_materials():
	small_glass_material = make_material(Color(0.55, 0.72, 1.0, 0.32), 1.5)
	big_glass_material = make_material(Color(0.45, 0.85, 1.0, 0.45), 3.0)
	shard_materials = [
		make_material(Color(0.35, 0.85, 1.0), 6.0),
		make_material(Color.WHITE, 8.0),
		make_material(Color(1.0, 0.2, 0.75), 7.0)
	]
	ult_wave_materials = [
		make_material(Color(0.35, 0.85, 1.0, 0.16), 8.0),
		make_material(Color.WHITE, 10.0),
		make_material(Color(1.0, 0.2, 0.75, 0.14), 9.0)
	]

# ── INPUT ──

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
		try_start_sword_cyclone()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("attack"):
		attack_held = true
		attack_buffer_timer = attack_input_buffer_time
		attack_buffer_is_hold = false
	elif event.is_action_released("attack"):
		attack_held = false
		if attack_buffer_is_hold:
			attack_buffer_timer = 0.0
	if event.is_action_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	if event.is_action_pressed("dodge"):
		# Survival input owns the one-slot buffer. Never make the player fight
		# an old queued slash after asking to evade.
		attack_buffer_timer = 0.0
		attack_buffer_is_hold = false
	if event is InputEventMouseMotion:
		if slam_camera_active or falling_pane_cast_active:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch_target = clamp(
			camera_pitch_target
			+ event.relative.y * vertical_mouse_sensitivity,
			deg_to_rad(camera_pitch_min),
			deg_to_rad(camera_pitch_max)
		)
	if event is InputEventMouseButton and event.pressed:
		if slam_camera_active:
			return
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				# Buffer the click briefly instead of dropping it during the last
				# frames of an attack or teleport recovery.
				teleport_input_buffer_timer = teleport_input_buffer_time
			MOUSE_BUTTON_MIDDLE:
				if combat_recovery_timer <= 0.0:
					toggle_lock()
			MOUSE_BUTTON_WHEEL_UP:
				if combat_recovery_timer <= 0.0:
					switch_target(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if combat_recovery_timer <= 0.0:
					switch_target(-1)
	if event is InputEventKey and event.pressed and not event.echo:
		if combat_recovery_timer > 0.0:
			return
		match event.keycode:
			KEY_Q:
				try_activate_ult()
			KEY_F:
				cast_rift_cleave()
			KEY_E:
				cast_ruin_volley()

func elite_mini_boss_active() -> bool:
	for elite in get_tree().get_nodes_in_group("elite_enemies"):
		if is_instance_valid(elite) and elite.get("broken") != true:
			return true
	return false

# ── MAIN LOOP ──

func _physics_process(delta):
	update_timers(delta)
	update_sword_cyclone(delta)
	update_teleport_input()
	update_empowered_slam_return(delta)

	if empowered_slam_player_drop_lock_timer > 0.0:
		empowered_slam_player_drop_lock_timer = max(
			empowered_slam_player_drop_lock_timer - delta,
			0.0
		)

	update_slam_windup(delta)
	var direction = get_movement_direction()
	update_glass_walk_state()
	var used_jump = update_followup_input()
	update_attack_input()
	update_gravity(delta)
	update_jump(used_jump)
	update_dodge(direction, delta)
	update_sword_motion(direction, delta)
	update_vortex_air_carry(delta)
	update_dodge_visual()
	if enemy_knockback_timer > 0.0 and not is_dodging:
		enemy_knockback_timer = maxf(0.0, enemy_knockback_timer - delta)
		velocity.x = enemy_knockback_velocity.x
		velocity.z = enemy_knockback_velocity.z
		enemy_knockback_velocity = enemy_knockback_velocity.move_toward(Vector3.ZERO, 55.0 * delta)
	update_glass_walk(direction)
	update_animation(direction)
	var move_start = global_position
	move_and_slide()
	if is_dodging:
		hit_enemies_with_dash(move_start, global_position)
	maintain_teleport_hold()
	maintain_slam_player_lock()
	update_enemy_one_way_panes(delta)
	update_slam_impact(delta)
	update_lock_camera(delta)
	update_teleport_camera(delta)
	update_air_camera_focus(delta)
	update_slam_camera(delta)
	update_camera(delta)
	update_falling_pane_camera(delta)
	update_lock_reticle()
	update_aim_reticle()
	update_followup_ui()
	update_reliquary_ui()

func update_timers(delta):
	if open_arsenal_active:
		open_arsenal_timer = maxf(0.0, open_arsenal_timer - delta)
		if open_arsenal_label:
			open_arsenal_label.text = "OPEN ARSENAL  %.1f" % open_arsenal_timer
		if open_arsenal_timer <= 0.0:
			end_open_arsenal()
	if dodge_chain_reset_timer > 0.0:
		dodge_chain_reset_timer = maxf(0.0, dodge_chain_reset_timer - delta)
		if dodge_chain_reset_timer <= 0.0:
			consecutive_dodges = 0
	teleport_cooldown_timer = tick(teleport_cooldown_timer, delta)
	pane_pull_cooldown_timer = tick(pane_pull_cooldown_timer, delta)
	teleport_input_buffer_timer = tick(teleport_input_buffer_timer, delta)
	rift_cleave_timer = tick(rift_cleave_timer, delta)
	ruin_volley_timer = tick(ruin_volley_timer, delta)
	low_gravity_timer = tick(low_gravity_timer, delta)
	glass_pane_spawn_timer = tick(glass_pane_spawn_timer, delta)
	combo_hold_timer = tick(combo_hold_timer, delta)
	attack_buffer_timer = tick(attack_buffer_timer, delta)
	attack_cancel_lock_timer = tick(attack_cancel_lock_timer, delta)
	sword_motion_timer = tick(sword_motion_timer, delta)
	sword_cyclone_cooldown_timer = tick(sword_cyclone_cooldown_timer, delta)
	jump_buffer_timer = tick(jump_buffer_timer, delta)
	air_arena_cooldown_timer = tick(air_arena_cooldown_timer, delta)
	combat_recovery_timer = tick(combat_recovery_timer, delta)
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
		melee_focus_target = null
		dodge_preserved_combo = false
	if not can_dodge:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0.0:
			can_dodge = true
	if slam_camera_hold_timer > 0.0:
		slam_camera_hold_timer -= delta
		if (slam_camera_hold_timer <= 0.0 and not valid(slam_impact_target) and not slam_chain_running):
			end_slam_camera()

func tick(value, delta):
	return max(value - delta, 0.0)

func weight(speed_value, delta):
	return clamp(speed_value * delta, 0.0, 1.0)

func valid(node):
	return is_instance_valid(node)

func try_start_sword_cyclone() -> void:
	if sword_cyclone_active or sword_cyclone_cooldown_timer > 0.0 or slam_camera_active or falling_pane_cast_active:
		return
	sword_cyclone_active = true
	sword_cyclone_timer = sword_cyclone_duration
	sword_cyclone_cooldown_timer = sword_cyclone_cooldown
	sword_cyclone_hit_timer = 0.0
	sword_cyclone_angle = 0.0
	sword_cyclone_hit_serial = 0
	sword_cyclone_visual_start_y = dodge_visual.rotation.y if dodge_visual else 0.0
	attack_buffer_timer = 0.0
	attack_buffer_is_hold = false
	sword_motion_timer = 0.0
	combo_step = 0
	combo_timer = 0.0
	melee_focus_target = null
	attacking = true
	combat_recovery_timer = sword_cyclone_duration
	velocity = Vector3.ZERO

func update_sword_cyclone(delta: float) -> void:
	if not sword_cyclone_active:
		return
	sword_cyclone_timer = maxf(0.0, sword_cyclone_timer - delta)
	sword_cyclone_hit_timer -= delta
	combat_recovery_timer = maxf(combat_recovery_timer, sword_cyclone_timer)
	sword_cyclone_angle = fmod(sword_cyclone_angle + TAU * sword_cyclone_turns_per_second * delta, TAU)
	if dodge_visual:
		dodge_visual.rotation.y += TAU * sword_cyclone_turns_per_second * delta
	if sword_cyclone_hit_timer <= 0.0 and sword_cyclone_timer > 0.0:
		sword_cyclone_hit_timer = sword_cyclone_hit_interval
		perform_sword_cyclone_hit(false)
	if sword_cyclone_timer <= 0.0:
		perform_sword_cyclone_hit(true)
		sword_cyclone_active = false
		attacking = false
		combat_recovery_timer = 0.12
		if dodge_visual:
			dodge_visual.rotation.y = sword_cyclone_visual_start_y

func perform_sword_cyclone_hit(final_hit: bool) -> void:
	sword_cyclone_hit_serial += 1
	var radius := sword_cyclone_radius * (1.25 if final_hit else 1.0)
	var center := global_position + Vector3.UP
	break_panes_in_enemy_attack(center, radius)
	var sweep_direction := Vector3(sin(sword_cyclone_angle), 0.0, cos(sword_cyclone_angle)).normalized()
	var sweep_threshold := cos(deg_to_rad(sword_cyclone_sweep_arc_degrees * 0.5))
	for enemy in get_enemies_near(center, radius):
		var outward: Vector3 = enemy.global_position - global_position
		outward.y = 0.0
		if outward.length_squared() < 0.01:
			outward = global_transform.basis.z
		if not final_hit and sweep_direction.dot(outward.normalized()) < sweep_threshold:
			continue
		# Scatter each victim along a different spoke of the cyclone. The serial
		# changes every sweep, so repeated contacts do not form one tidy line.
		var scatter_seed := float((enemy.get_instance_id() * 37 + sword_cyclone_hit_serial * 83) % 1000) / 999.0
		var spread := sword_cyclone_final_direction_spread_degrees if final_hit else sword_cyclone_direction_spread_degrees
		var scatter_angle := deg_to_rad(lerpf(-spread, spread, scatter_seed))
		var scatter_direction := outward.normalized().rotated(Vector3.UP, scatter_angle)
		var launch_variation := lerpf(-sword_cyclone_launch_variation * 0.35, sword_cyclone_launch_variation, fmod(scatter_seed * 7.13, 1.0))
		hit_enemy(
			enemy,
			sword_cyclone_final_damage if final_hit else sword_cyclone_damage,
			sword_cyclone_final_knockback if final_hit else sword_cyclone_knockback,
			maxf(0.0, (sword_cyclone_final_launch if final_hit else sword_cyclone_launch) + launch_variation),
			0.55 if final_hit else 0.10,
			scatter_direction
		)
	spawn_cyclone_sweep_visual(sword_cyclone_angle, final_hit)
	if final_hit and not ult_wave_materials.is_empty():
		spawn_flash_sphere(center, radius, ult_wave_materials[2], 0.22)
	if final_hit:
		spawn_shard_burst(center, 84, radius, 1.1, 0.4)
		camera_fov_pulse()

func spawn_cyclone_sweep_visual(angle: float, final_hit: bool) -> void:
	var pivot := Node3D.new()
	add_child(pivot)
	pivot.position = Vector3.UP * 1.15
	pivot.rotation.y = angle - deg_to_rad(sword_cyclone_sweep_arc_degrees * 0.5)
	var blade := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	var visual_radius := sword_cyclone_radius * (1.25 if final_hit else 1.0)
	mesh.size = Vector3(0.55 if not final_hit else 1.1, 0.24, visual_radius * 1.15)
	blade.mesh = mesh
	blade.position.z = visual_radius * 0.52
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.32, 0.82, 1.0, 0.78) if not final_hit else Color(1.0, 0.22, 0.65, 0.94)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 12.0 if not final_hit else 22.0
	blade.material_override = material
	pivot.add_child(blade)
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", pivot.rotation.y + deg_to_rad(sword_cyclone_sweep_arc_degrees), sword_cyclone_hit_interval * 1.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(blade, "scale", Vector3(1.25, 0.4, 1.05), sword_cyclone_hit_interval * 1.35)
	tween.parallel().tween_property(blade, "transparency", 1.0, sword_cyclone_hit_interval * 1.35)
	tween.tween_callback(pivot.queue_free)

func start_sword_motion(step: int, forward: Vector3, finisher_side: int = 0, target = null) -> void:
	var motion_direction := forward.normalized()
	if step == 2:
		# The reverse cut carries Lucian across the target line instead of
		# leaving his feet planted beneath a large sword effect.
		motion_direction = (forward + global_transform.basis.x * second_swing_cross_amount).normalized()
	elif step == 3 and finisher_side != 0:
		var angle := left_finisher_motion_angle if finisher_side < 0 else right_finisher_motion_angle
		motion_direction = forward.rotated(Vector3.UP, deg_to_rad(angle)).normalized()
	var speed: float = [sword_motion_speeds.x, sword_motion_speeds.y, sword_motion_speeds.z][step - 1]
	var duration: float = [sword_motion_durations.x, sword_motion_durations.y, sword_motion_durations.z][step - 1]
	sword_motion_velocity = motion_direction * speed
	sword_motion_timer = duration
	sword_motion_target = target if valid(target) else null
	sword_motion_tracking_strength = sword_motion_side_targeting_strength if finisher_side != 0 else sword_motion_targeting_strength

func update_sword_motion(input_direction: Vector3, delta: float) -> void:
	if sword_motion_timer <= 0.0 or is_dodging or enemy_knockback_timer > 0.0:
		return
	var steered_velocity := sword_motion_velocity
	if valid(sword_motion_target):
		var to_target: Vector3 = sword_motion_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.01:
			var target_velocity := to_target.normalized() * sword_motion_velocity.length()
			steered_velocity = steered_velocity.lerp(target_velocity, sword_motion_tracking_strength)
			# Keep the large Kingdom-Hearts-style travel without tunneling straight
			# through the enemy when Lucian reaches striking distance.
			var remaining_distance := maxf(0.0, to_target.length() - sword_motion_arrival_distance)
			var arrival_speed := remaining_distance / maxf(delta, 0.001)
			if arrival_speed < steered_velocity.length():
				steered_velocity = steered_velocity.normalized() * arrival_speed
	if input_direction.length_squared() > 0.01:
		steered_velocity = steered_velocity.lerp(
			input_direction.normalized() * sword_motion_velocity.length(),
			sword_motion_input_influence
		)
	velocity.x = steered_velocity.x
	velocity.z = steered_velocity.z

# ── MOVEMENT ──

func get_movement_direction():
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward = -transform.basis.z
	var right = -transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	return (forward.normalized() * input.y + right.normalized() * input.x).normalized()

func update_gravity(delta):
	# During the empowered post-impact drop, preserve the huge downward
	# velocity instead of the cinematic camera zeroing it.
	if empowered_slam_player_drop_lock_timer > 0.0:
		velocity.y -= gravity * delta
		return

	if teleport_hold_active or slam_camera_active:
		velocity.y = 0.0
		return
	if is_on_floor():
		coyote_timer = jump_coyote_time
		if velocity.y < 0.0:
			velocity.y = 0.0
		return
	coyote_timer = tick(coyote_timer, delta)
	var gravity_scale = 1.0
	if low_gravity_timer > 0.0:
		gravity_scale = min(gravity_scale, teleport_gravity_multiplier)
	if glass_walk_active:
		gravity_scale = min(gravity_scale, glass_walk_gravity_multiplier)
	velocity.y -= (gravity * gravity_scale * delta)
	if glass_walk_active:
		velocity.y = max(velocity.y, glass_walk_max_fall_speed)

func update_jump(used_followup):
	if teleport_hold_active or slam_camera_active or falling_pane_cast_active or sword_cyclone_active:
		return
	if not used_followup and jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0):
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

# ── DASH ──

func update_dodge(direction, delta):
	if empowered_slam_player_drop_lock_timer > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if sword_cyclone_active:
		# Lucian may drive the cyclone through the horde, but the input remains
		# movement-only until the committed attack finishes.
		velocity.x = direction.x * speed * sword_cyclone_move_speed_multiplier
		velocity.z = direction.z * speed * sword_cyclone_move_speed_multiplier
		return
	if falling_pane_cast_active:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if teleport_hold_active or slam_camera_active:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if (Input.is_action_just_pressed("dodge") and can_dodge and attack_cancel_lock_timer <= 0.0):
		# Recovery is deliberately dodge-cancellable. Preserve the next combo
		# step through one dodge, but never through an indefinite dodge chain.
		if combo_step > 0 and combo_timer > 0.0 and not dodge_preserved_combo:
			combo_timer = maxf(combo_timer, dodge_duration + combo_dodge_preserve_time)
			dodge_preserved_combo = true
		combat_recovery_timer = 0.0
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
	if dodge_chain_reset_timer <= 0.0:
		consecutive_dodges = 0
	consecutive_dodges += 1
	dodge_chain_reset_timer = dodge_chain_reset_time
	is_dodging = true
	can_dodge = false
	dodge_invincible = true
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_exhaustion_recovery if consecutive_dodges >= 4 else dodge_cooldown
	if consecutive_dodges >= 4:
		consecutive_dodges = 0
		dodge_chain_reset_timer = 0.0
	dodge_hit_ids.clear()
	dodge_direction = (direction if direction != Vector3.ZERO else transform.basis.z)
	dodge_direction.y = 0.0
	dodge_direction = dodge_direction.normalized()
	if anim:
		anim.stop()
	flash_blue()

func update_dodge_visual():
	if not dodge_visual:
		return
	if not is_dodging:
		dodge_visual.rotation = dodge_visual_base_rotation
		dodge_visual.position = dodge_visual_base_position
		return
	var progress := clampf(1.0 - dodge_timer / maxf(dodge_duration, 0.001), 0.0, 1.0)
	# Fast forward somersault with a compact dip through the middle.
	var eased_progress := progress * progress * (3.0 - 2.0 * progress)
	dodge_visual.rotation = dodge_visual_base_rotation + Vector3(-TAU * eased_progress, 0.0, 0.0)
	dodge_visual.position = dodge_visual_base_position + Vector3.DOWN * sin(progress * PI) * 0.42

func end_dodge():
	if not is_dodging:
		return
	dash_end_aoe()
	is_dodging = false
	dodge_invincible = false
	velocity.x *= dodge_exit_momentum
	velocity.z *= dodge_exit_momentum
	enemy_knockback_velocity = Vector3.ZERO
	enemy_knockback_timer = 0.0
	if dodge_visual:
		dodge_visual.rotation = dodge_visual_base_rotation
		dodge_visual.position = dodge_visual_base_position
	remove_flash()

func hit_enemies_with_dash(from_position, to_position):
	var segment = to_position - from_position
	var length_squared = max(segment.length_squared(), 0.0001)
	for enemy in get_enemies():
		if (not valid(enemy) or not enemy is Node3D):
			continue
		var id = enemy.get_instance_id()
		if dodge_hit_ids.has(id):
			continue
		var t = clamp((enemy.global_position - from_position).dot(segment) / length_squared, 0.0, 1.0)
		var closest = (from_position + segment * t)
		if (enemy.global_position.distance_to(closest) > dodge_hit_radius):
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
		var direction = (enemy.global_position - global_position)
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
		enemy.velocity.x = (direction.x * knockback)
		enemy.velocity.z = (direction.z * knockback)
		enemy.velocity.y = max(enemy.velocity.y, launch)

# ── VIRTUAL BOOM ACTION CAMERA ──

func camera_lerp_weight(speed_value, delta):
	return 1.0 - exp(-speed_value * delta)


func update_camera(delta):
	if not camera_pivot or not camera:
		return

	# Detached finishers / empowered observer camera control the pivot.
	if slam_camera_detached:
		return

	var desired_distance = camera_distance
	var desired_fov = camera_base_fov

	if not slam_camera_active:
		camera_pivot.rotation.y = lerp_angle(
			camera_pivot.rotation.y,
			0.0,
			camera_lerp_weight(
				camera_yaw_return_speed,
				delta
			)
		)

		var horizontal_speed = Vector2(
			velocity.x,
			velocity.z
		).length()

		var speed_ratio = clamp(
			horizontal_speed
			/ max(camera_speed_reference, 0.01),
			0.0,
			1.0
		)

		desired_distance += (
			camera_speed_distance_add
			* speed_ratio
		)

		desired_fov += (
			camera_speed_fov_add
			* speed_ratio
		)

		if not is_on_floor():
			desired_distance += camera_air_distance_add
			desired_fov += camera_air_fov_add

		if is_dodging:
			desired_distance += camera_dash_distance_add
			desired_fov += camera_dash_fov_add

		if attacking:
			desired_distance += camera_attack_distance_add
			desired_fov += camera_attack_fov_add

	else:
		desired_distance = lerp(
			slam_camera_wide_distance,
			slam_camera_focus_distance,
			slam_camera_focus
		)

		desired_fov = (
			camera_base_fov
			+ lerp(
				slam_camera_wide_fov_add,
				slam_camera_focus_fov_add,
				slam_camera_focus
			)
		)

		if slam_camera_hold_timer > 0.0:
			desired_fov = (
				camera_base_fov
				+ slam_impact_fov_punch
			)

	var safe_distance = get_virtual_boom_safe_distance(
		desired_distance
	)

	# Collision snaps inward quickly.
	# Returning to normal distance is slower and smooth.
	var boom_speed = (
		camera_collision_in_speed
		if safe_distance < camera_boom_distance
		else camera_collision_out_speed
	)

	camera_boom_distance = lerp(
		camera_boom_distance,
		safe_distance,
		camera_lerp_weight(
			boom_speed,
			delta
		)
	)

	var close_amount = clamp(
		(
			camera_close_threshold
			- camera_boom_distance
		)
		/ max(
			camera_close_threshold
			- camera_min_safe_distance,
			0.01
		),
		0.0,
		1.0
	)

	# If forced close, slide toward a shoulder view instead of placing
	# the camera directly inside Lucian's back.
	var desired_side = (
		camera_shoulder_offset
		+ camera_close_shoulder_boost
		* close_amount
	)

	camera.position.x = lerp(
		camera.position.x,
		desired_side,
		camera_lerp_weight(
			14.0,
			delta
		)
	)

	camera.position.y = 0.0
	camera.position.z = -camera_boom_distance

	# Slight FOV rescue when collision compresses the camera.
	var collision_amount = clamp(
		1.0
		- safe_distance / max(desired_distance, 0.01),
		0.0,
		1.0
	)

	desired_fov += (
		camera_collision_fov_add
		* collision_amount
	)

	camera.fov = lerp(
		camera.fov,
		desired_fov,
		camera_lerp_weight(
			camera_fov_response,
			delta
		)
	)

	camera_pitch = lerp_angle(
		camera_pitch,
		camera_pitch_target,
		camera_lerp_weight(
			camera_pitch_smooth_speed,
			delta
		)
	)

	camera_pivot.rotation.x = camera_pitch

	slam_camera_roll_kick = lerp(
		slam_camera_roll_kick,
		0.0,
		camera_lerp_weight(
			slam_camera_roll_return_speed,
			delta
		)
	)

	camera_pivot.rotation.z = slam_camera_roll_kick


func get_virtual_boom_safe_distance(desired_distance):
	var world = get_world_3d()

	if world == null or camera_collision_shape == null:
		return desired_distance

	var origin = camera_pivot.global_position

	# This project's camera sits on CameraPivot local -Z.
	# Cast in the same direction that Camera3D actually occupies.
	var boom_direction = (
		-camera_pivot.global_transform.basis.z
	).normalized()

	var motion = (
		boom_direction
		* max(
			desired_distance,
			camera_min_safe_distance
		)
	)

	var query = PhysicsShapeQueryParameters3D.new()

	query.shape = camera_collision_shape
	query.transform = Transform3D(
		Basis.IDENTITY,
		origin
	)

	query.motion = motion
	query.collision_mask = camera_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var cast = (
		world.direct_space_state
		.cast_motion(query)
	)

	if cast.size() < 1:
		return desired_distance

	var safe_fraction = clamp(
		float(cast[0]),
		0.0,
		1.0
	)

	var safe_distance = (
		motion.length()
		* safe_fraction
		- camera_collision_padding
	)

	return clamp(
		safe_distance,
		camera_min_safe_distance,
		desired_distance
	)


func update_air_camera_focus(delta):
	if (
		is_on_floor()
		or slam_camera_active
		or teleport_hold_active
		or teleport_camera_timer > 0.0
	):
		return

	var target = (
		locked_enemy
		if valid(locked_enemy)
		else teleport_focus_target
	)

	if valid(target):
		aim_camera_pitch_at(
			target.global_position + Vector3.UP * 1.2,
			air_target_pitch_strength,
			delta
		)


func aim_camera_pitch_at(point, strength, delta):
	var direction = point - global_position

	var horizontal = max(
		Vector2(
			direction.x,
			direction.z
		).length(),
		0.01
	)

	var pitch = clamp(
		-atan2(
			direction.y,
			horizontal
		),
		deg_to_rad(camera_pitch_min),
		deg_to_rad(camera_pitch_max)
	)

	camera_pitch_target = lerp_angle(
		camera_pitch_target,
		pitch,
		camera_lerp_weight(
			strength,
			delta
		)
	)


# ── SLAM CAMERA ──

func start_slam_camera(enemy):
	if not valid(enemy) or not camera_pivot:
		return

	slam_camera_active = true
	slam_camera_roll_kick = 0.0
	camera_pivot.rotation.z = 0.0

	slam_camera_focus = 0.0
	slam_camera_hold_timer = 0.0
	slam_start_enemy_y = enemy.global_position.y
	slam_camera_side = choose_slam_camera_side(enemy)
	slam_saved_camera_transform = camera_pivot.transform

	slam_saved_spring_length = camera_boom_distance

	if camera:
		slam_saved_fov = camera.fov

	# Final enemy finisher keeps its detached cinematic camera.
	if slam_final_finisher_active:
		detach_empowered_camera()
		return

	# Empowered Slam gets a fixed observer camera above the action.
	if slam_chain_empowered:
		start_empowered_slam_observer_camera(enemy)
		return

	# Normal Slam stays on the attached virtual-boom camera.
	camera_boom_distance = slam_camera_wide_distance

	if camera:
		camera.position.z = -camera_boom_distance
		camera.fov = camera_base_fov + slam_camera_wide_fov_add


func start_empowered_slam_observer_camera(enemy):
	if not camera_pivot or not valid(enemy):
		return

	var parent = get_tree().current_scene

	if parent == null:
		return

	camera_pivot.reparent(parent, true)
	slam_camera_detached = true
	empowered_slam_camera_active = true
	empowered_slam_camera_look_target = enemy

	var player_forward = -global_transform.basis.z
	var player_right = global_transform.basis.x

	player_forward.y = 0.0
	player_right.y = 0.0

	player_forward = (
		player_forward.normalized()
		if player_forward.length() > 0.01
		else Vector3.FORWARD
	)

	player_right = (
		player_right.normalized()
		if player_right.length() > 0.01
		else Vector3.RIGHT
	)

	# Position is captured ONCE. The pivot only rotates after this.
	empowered_slam_camera_fixed_position = (
		enemy.global_position
		+ Vector3.UP * empowered_slam_camera_height
		- player_forward * empowered_slam_camera_back_offset
		+ player_right * empowered_slam_camera_side_offset
	)

	camera_pivot.global_position = empowered_slam_camera_fixed_position

	camera_boom_distance = slam_camera_focus_distance

	if camera:
		camera.position.z = -camera_boom_distance
		camera.fov = empowered_slam_camera_start_fov


func choose_slam_camera_side(enemy):
	if camera:
		var side = (camera.global_transform.basis.x.dot(enemy.global_position - camera.global_position))
		if abs(side) > 0.20:
			return -sign(side)
	slam_camera_flip *= -1.0
	return slam_camera_flip

func detach_empowered_camera():
	if (slam_camera_detached or not camera_pivot):
		return
	var parent = get_tree().current_scene
	if parent == null:
		return
	camera_pivot.reparent(parent, true)
	slam_camera_detached = true
	detached_camera_base_yaw = (camera_pivot.global_rotation.y)
	camera_boom_distance = slam_camera_wide_distance
	if camera:
		camera.position.z = -camera_boom_distance
		camera.fov = (camera_base_fov + slam_camera_wide_fov_add)

func update_slam_camera(delta):
	if not slam_camera_active or not camera_pivot:
		return

	var enemy = (
		slam_impact_target
		if valid(slam_impact_target)
		else pending_slam_target
	)

	if empowered_slam_camera_active:
		update_empowered_slam_observer_camera(delta)
		return

	if slam_camera_detached:
		update_detached_slam_camera(enemy, delta)
	else:
		update_attached_slam_camera(enemy, delta)


func update_empowered_slam_observer_camera(delta):
	if not empowered_slam_camera_active or not camera_pivot:
		return

	# Stationary means stationary: never move the pivot during the fall.
	camera_pivot.global_position = empowered_slam_camera_fixed_position

	var target = empowered_slam_camera_look_target

	if not valid(target):
		target = slam_impact_target

	var look_point = (
		empowered_slam_return_impact_point
		if empowered_slam_return_pending
		else slam_camera_hold_point
	)
	var has_target = valid(target)

	if has_target:
		look_point = target.global_position + Vector3.UP * 0.7

	var direction = look_point - camera_pivot.global_position

	if direction.length() > 0.01:
		var target_basis = Basis.looking_at(
			direction.normalized(),
			Vector3.UP,
			true
		)

		var current_quat = (
			camera_pivot.global_transform.basis
			.get_rotation_quaternion()
		)

		var target_quat = (
			target_basis.get_rotation_quaternion()
		)

		var blend = (
			1.0
			if delta <= 0.0
			else weight(
				empowered_slam_camera_track_speed,
				delta
			)
		)

		var new_quat = current_quat.slerp(
			target_quat,
			blend
		)

		var camera_transform = camera_pivot.global_transform
		camera_transform.basis = Basis(new_quat)
		camera_pivot.global_transform = camera_transform

	if camera:
		var zoom_progress = 0.0

		if has_target:
			var total_fall = max(
				empowered_slam_apex_y_for_camera
				- empowered_slam_ground_y_for_camera,
				1.0
			)

			var fallen = (
				empowered_slam_apex_y_for_camera
				- target.global_position.y
			)

			zoom_progress = clamp(
				fallen / total_fall,
				0.0,
				1.0
			)

			# Ease the focal length inward early, then tighten hard
			# near the ground. Lower FOV = stronger zoom into the victim.
			zoom_progress = pow(
				zoom_progress,
				0.62
			)

		var desired_fov = lerp(
			empowered_slam_camera_start_fov,
			empowered_slam_camera_focus_fov,
			zoom_progress
		)

		# Explosion blows the focal zoom back open.
		if slam_camera_hold_timer > 0.0:
			desired_fov = empowered_slam_camera_impact_fov

		camera.fov = lerp(
			camera.fov,
			desired_fov,
			weight(
				empowered_slam_camera_zoom_speed,
				max(delta, 0.016)
			)
		)


func update_detached_slam_camera(enemy, delta):
	var point = slam_camera_hold_point
	if valid(enemy):
		point = (enemy.global_position + Vector3.UP * empowered_camera_height)
	elif slam_camera_hold_timer <= 0.0:
		end_slam_camera()
		return
	var w = weight(empowered_camera_follow_speed, delta)
	camera_pivot.global_position = (camera_pivot.global_position.lerp(point, w))
	var desired_focus = (1.0 if slam_camera_hold_timer > 0.0 else slam_chain_progress)
	slam_camera_focus = lerp(slam_camera_focus, desired_focus, weight(slam_camera_focus_speed, delta))
	var orbit = deg_to_rad(empowered_camera_orbit_angle * slam_camera_side * (1.0 - slam_camera_focus))
	var current = (camera_pivot.global_rotation)
	current.y = lerp_angle(current.y, detached_camera_base_yaw + orbit, weight(empowered_camera_orbit_speed, delta))
	current.x = lerp_angle(current.x, deg_to_rad(empowered_camera_pitch), w)
	current.z = lerp_angle(current.z, 0.0, w)
	camera_pivot.global_rotation = current
	var distance = lerp(
		slam_camera_wide_distance,
		slam_camera_focus_distance,
		slam_camera_focus
	)
	camera_boom_distance = lerp(
		camera_boom_distance,
		distance,
		w
	)
	if camera:
		camera.position.z = -camera_boom_distance
		var target_fov = (camera_base_fov + lerp(slam_camera_wide_fov_add, slam_camera_focus_fov_add, slam_camera_focus))
		if slam_camera_hold_timer > 0.0:
			target_fov = (camera_base_fov + empowered_impact_fov_punch)
		camera.fov = lerp(camera.fov, target_fov, w)

func update_attached_slam_camera(enemy, delta):
	var point = slam_camera_hold_point
	if valid(enemy):
		point = (enemy.global_position + Vector3.UP * 0.5)
	elif slam_camera_hold_timer <= 0.0:
		end_slam_camera()
		return
	var flat = (point - camera_pivot.global_position)
	flat.y = 0.0
	if flat.length() > 0.01:
		var world_yaw = atan2(-flat.x, -flat.z)
		var local_yaw = wrapf(world_yaw - rotation.y, -PI, PI)
		var swing = (deg_to_rad(slam_camera_swing_angle) * slam_camera_side * (1.0 - slam_camera_focus))
		camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, local_yaw + swing, weight(slam_camera_yaw_speed, delta))
	var direction = (point - camera_pivot.global_position)
	var horizontal = max(Vector2(direction.x, direction.z).length(), 0.01)
	var pitch = clamp(-atan2(direction.y, horizontal) + deg_to_rad(slam_camera_pitch_lead), deg_to_rad(-55.0), deg_to_rad(70.0))
	camera_pitch_target = lerp_angle(camera_pitch_target, pitch, weight(slam_camera_pitch_speed, delta))
	var focus = 1.0
	if (valid(enemy) and slam_camera_hold_timer <= 0.0):
		focus = clamp((slam_start_enemy_y - enemy.global_position.y) / slam_camera_focus_fall_distance, 0.0, 1.0)
	slam_camera_focus = lerp(slam_camera_focus, focus, weight(slam_camera_focus_speed, delta))

func maintain_slam_player_lock():
	if (
		empowered_slam_active
		and valid(empowered_slam_victim)
		and not empowered_slam_return_pending
	):
		# CAMERA stays stationary during the empowered cinematic.
		# LUCIAN stays locked directly above the victim and rides the
		# victim down through the entire pane tower.
		global_position = (
			empowered_slam_victim.global_position
			+ empowered_slam_player_offset
		)

		velocity = Vector3.ZERO
		face_enemy(empowered_slam_victim)
		return

	if slam_camera_active:
		velocity = Vector3.ZERO


func hold_slam_camera_on_impact(point):
	slam_camera_hold_point = (point + Vector3.UP * 0.8)
	slam_camera_hold_timer = (slam_camera_impact_hold_time)
	slam_camera_focus = 1.0

	if empowered_slam_camera_active and camera:
		# Snap wide exactly when the AOE detonates.
		camera.fov = empowered_slam_camera_impact_fov

func end_slam_camera():
	if not slam_camera_active:
		# Still force-clear roll as a safety net.
		slam_camera_roll_kick = 0.0

		if camera_pivot and not slam_camera_detached:
			camera_pivot.rotation.z = 0.0

		return

	slam_camera_active = false
	slam_camera_focus = 0.0
	slam_camera_hold_timer = 0.0
	empowered_slam_camera_active = false
	empowered_slam_camera_look_target = null

	# Critical fix:
	# Pane impacts used to add directly to rotation.z, but attached slam
	# cameras never restored that axis. That is what caused the sideways camera.
	slam_camera_roll_kick = 0.0

	if (
		slam_camera_detached
		and valid(camera_pivot)
		and valid(camera_original_parent)
	):
		camera_pivot.reparent(
			camera_original_parent,
			true
		)

		camera_pivot.transform = (
			slam_saved_camera_transform
		)

		camera_pitch = (
			camera_pivot.rotation.x
		)

		camera_pitch_target = camera_pitch
		slam_camera_detached = false

	elif camera_pivot:
		# Keep current pitch/yaw, but guarantee zero roll and restore the
		# normal pivot height target after the cinematic.
		camera_pivot.rotation.z = 0.0
		camera_pivot.position.y = camera_pivot_height

	camera_boom_distance = slam_saved_spring_length

	if camera:
		camera.position.z = -camera_boom_distance
		camera.fov = slam_saved_fov


# ── TELEPORT TARGETING ──

func update_teleport_input() -> void:
	if teleport_input_buffer_timer <= 0.0:
		return
	if try_airborne_teleport():
		teleport_input_buffer_timer = 0.0

func try_airborne_teleport() -> bool:
	if (teleport_cooldown_timer > 0.0 or slam_camera_active or combat_recovery_timer > 0.0):
		return false
	var target = (get_airborne_teleport_target())
	if not target:
		return false
	if get_walk_pane_count() > 0:
		if pane_pull_cooldown_timer > 0.0:
			# Pane pull remains a deliberate power move. Do not silently turn a
			# blocked pull click into a normal teleport.
			return true
		pull_enemy_into_pane_finisher(target)
		pane_pull_cooldown_timer = pane_pull_cooldown
	else:
		teleport_to_enemy(target)
	teleport_cooldown_timer = (teleport_cooldown)
	combat_recovery_timer = teleport_recovery
	return true

func get_airborne_teleport_target():
	# Right-click accepts the enemy Lucian is deliberately looking at whether
	# it is grounded or airborne. There is no nearest-enemy fallback.
	if is_usable_enemy(locked_enemy, teleport_range, false):
		return locked_enemy
	return get_screen_center_enemy(false)

func get_screen_center_airborne_enemy():
	return get_screen_center_enemy(true)

func get_screen_center_enemy(airborne_only: bool = false):
	if not camera:
		return null
	var size = (get_viewport() .get_visible_rect() .size)
	var center = size * 0.5
	var radius = (min(size.x, size.y) * teleport_target_screen_radius)
	var best = null
	var best_score = INF
	for enemy in get_enemies():
		if not is_usable_enemy(enemy, teleport_range, airborne_only):
			continue
		var point = (enemy.global_position + Vector3.UP * 1.2)
		if camera.is_position_behind(point):
			continue
		var screen_distance = (camera.unproject_position(point) .distance_to(center))
		if screen_distance > radius:
			continue
		var score = (
			screen_distance
			/ max(radius, 1.0)
			* teleport_center_priority
			+
			global_position.distance_to(enemy.global_position)
			/ teleport_range
			* teleport_distance_priority
		)
		if score < best_score:
			best_score = score
			best = enemy
	return best

func pull_enemy_into_pane_finisher(enemy) -> void:
	if not valid(enemy):
		return
	force_end_glass_block(true)
	vortex_carry_target = null
	vortex_carry_timer = 0.0
	var enemy_was_processing: bool = enemy.is_physics_processing()
	slam_enemy_was_physics_active = enemy_was_processing
	enemy.set_physics_process(false)
	if enemy is CharacterBody3D:
		enemy.velocity = Vector3.ZERO
	var destination := global_position + global_transform.basis.z.normalized() * pane_pull_forward_offset + Vector3.UP * pane_pull_height_offset
	face_enemy(enemy)
	var pull_tween := create_tween()
	pull_tween.tween_property(enemy, "global_position", destination, pane_pull_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await pull_tween.finished
	if not valid(enemy):
		return
	# Reuse the retired pane tower directly. This branch deliberately does not
	# call start_slam_camera(), so player camera control is never taken away.
	slam_chain_empowered = true
	perform_empowered_slam(enemy)

# ── TELEPORT ──

func teleport_to_enemy(enemy):
	if not valid(enemy):
		return
	# Teleport can branch out of an aerial carry into a new target.
	vortex_carry_target = null
	vortex_carry_timer = 0.0
	force_end_glass_block(true)
	teleport_focus_target = enemy
	teleport_camera_target = enemy
	slam_target = enemy
	melee_focus_target = enemy
	var direction = (global_position - enemy.global_position)
	direction.y = 0.0
	if direction.length() < 0.01:
		direction = (global_transform.basis.x)
	global_position = (get_safe_teleport_position(enemy, direction.normalized()))
	velocity = Vector3.ZERO
	low_gravity_timer = (teleport_low_gravity_duration)
	teleport_followup_timer = 0.0
	teleport_camera_timer = (teleport_camera_duration)
	face_enemy(enemy)
	# Teleport is a one-hit finisher branch. Holding back/down deliberately
	# trades the slash for Lucian's old targeted slam.
	if Input.is_action_pressed("move_back"):
		call_deferred("start_air_slam")
		return
	# Teleport is now one immediate offensive action instead of a frozen
	# prompt state. The backslash uses the same directional finisher grammar as
	# the third melee hit.
	call_deferred("perform_teleport_backslash")

func get_safe_teleport_position(enemy, direction):
	var checks = max(teleport_position_checks, 1)
	for i in range(checks):
		var test_direction = (direction.rotated(Vector3.UP, TAU * float(i) / float(checks)))
		var position = (enemy.global_position + test_direction * teleport_side_offset + Vector3.UP * teleport_height_offset)
		if is_teleport_path_clear(enemy, position):
			return position
	if teleport_use_fallback:
		return (enemy.global_position + direction * teleport_side_offset + Vector3.UP * teleport_height_offset)
	return global_position

func is_teleport_path_clear(enemy, destination):
	var world = get_world_3d()
	if world == null:
		return true
	var query = (PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3.UP * teleport_height_offset, destination))
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	if enemy is CollisionObject3D:
		query.exclude.append(enemy.get_rid())
	return (world.direct_space_state .intersect_ray(query) .is_empty())

func face_enemy(enemy):
	if not valid(enemy):
		return
	var target = Vector3(enemy.global_position.x, global_position.y, enemy.global_position.z)
	if (global_position.distance_to(target) > 0.01):
		look_at(target, Vector3.UP, true)

# ── TELEPORT HOLD ──

func begin_teleport_hold(enemy):
	release_teleport_hold()
	teleport_hold_active = true
	teleport_held_enemy = enemy
	teleport_hold_player_position = (global_position)
	teleport_hold_enemy_position = (enemy.global_position)
	teleport_enemy_was_physics_active = (enemy.is_physics_processing())
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
	global_position = (teleport_hold_player_position)
	velocity = Vector3.ZERO
	teleport_held_enemy.global_position = (teleport_hold_enemy_position)
	if teleport_held_enemy is CharacterBody3D:
		teleport_held_enemy.velocity = (Vector3.ZERO)

func release_teleport_hold():
	if (teleport_hold_active and valid(teleport_held_enemy)):
		teleport_held_enemy.set_physics_process(teleport_enemy_was_physics_active)
	teleport_hold_active = false
	teleport_held_enemy = null

func clear_teleport_followup():
	release_teleport_hold()
	teleport_followup_timer = 0.0
	slam_target = null

# ── TELEPORT CAMERA / FOLLOW-UP ──

func update_teleport_camera(delta):
	if slam_camera_active:
		return
	var following = (teleport_followup_timer > 0.0 and valid(teleport_focus_target))
	if (teleport_camera_timer <= 0.0 and not following):
		teleport_camera_target = null
		teleport_focus_target = null
		return
	if following:
		teleport_camera_target = (teleport_focus_target)
	if not valid(teleport_camera_target):
		return
	teleport_camera_timer = tick(teleport_camera_timer, delta)
	var strength = (teleport_camera_timer / teleport_camera_duration if teleport_camera_timer > 0.0 else 0.30)
	aim_camera_pitch_at(teleport_camera_target.global_position + Vector3.UP * 1.3, teleport_camera_vertical_strength * strength, delta)

func update_followup_input():
	# Glass Arena now belongs to air movement itself: press jump again while
	# airborne. It no longer depends on a short post-teleport action timer.
	if not is_on_floor() and Input.is_action_just_pressed("jump") and air_arena_cooldown_timer <= 0.0:
		create_glass_arena()
		air_arena_cooldown_timer = air_arena_cooldown
		return true
	return false

func update_attack_input():
	# Holding requests only the next swing. Releasing immediately stops future
	# requests, while a press made during recovery remains buffered.
	if attack_held and combo_hold_timer <= 0.0:
		attack_buffer_timer = maxf(attack_buffer_timer, attack_input_buffer_time)
		attack_buffer_is_hold = true
		combo_hold_timer = combo_hold_delay
	if (slam_windup_timer > 0.0 or slam_recovery_timer > 0.0 or slam_chain_running or combat_recovery_timer > 0.0):
		return
	# Downward air attack rehomes the existing slam outside the old teleport
	# timer: hold back/down while attacking in the air.
	if not is_on_floor() and combo_step == 2 and Input.is_action_pressed("move_back") and attack_buffer_timer > 0.0:
		slam_target = get_aim_target(finisher_target_range)
		if valid(slam_target):
			attack_buffer_timer = 0.0
			attack_buffer_is_hold = false
			start_air_slam()
			return
	if (teleport_followup_timer > 0.0 and valid(slam_target) and attack_buffer_timer > 0.0):
		attack_buffer_timer = 0.0
		attack_buffer_is_hold = false
		perform_teleport_backslash()
		return
	if attack_buffer_timer > 0.0 and not attacking:
		attack_buffer_timer = 0.0
		attack_buffer_is_hold = false
		attack()
	if Input.is_key_pressed(KEY_H):
		take_damage(10)

# ── PANES OF PAIN ──

func update_glass_walk_state():
	if elite_mini_boss_active():
		glass_walk_active = false
		glass_walk_needs_pane = false
		return
	var was_active = glass_walk_active
	glass_walk_active = (Input.is_action_pressed("dodge") and (not is_on_floor() or is_on_glass()))
	if (glass_walk_active and not was_active):
		glass_walk_needs_pane = true
	if not glass_walk_active:
		glass_walk_needs_pane = false

func is_on_glass():
	if not is_on_floor():
		return false
	for i in range(get_slide_collision_count()):
		var collider = (get_slide_collision(i) .get_collider())
		if (collider and collider.is_in_group("lucian_glass_panes")):
			return true
	return false

func update_glass_walk(direction):
	if not glass_walk_active:
		return
	# F owns all panes while held.
	if (teleport_hold_active or slam_camera_active or glass_block_active or Input.is_key_pressed(KEY_F)):
		return
	if glass_walk_needs_pane:
		spawn_walk_pane(direction)
		glass_walk_needs_pane = false
		return
	if glass_pane_spawn_timer <= 0.0:
		spawn_walk_pane(direction)

func spawn_walk_pane(direction):
	if elite_mini_boss_active():
		return
	var move_direction = direction
	if move_direction.length() < 0.05:
		move_direction = transform.basis.z
	move_direction.y = 0.0
	move_direction = (move_direction.normalized())
	var pane_position = (global_position + move_direction * walk_pane_forward_offset + Vector3.DOWN * walk_pane_vertical_offset)
	create_glass_pane(pane_position, walk_pane_size, walk_pane_lifetime, small_glass_material, small_pane_ult_charge, true)
	glass_pane_spawn_timer = (walk_pane_spawn_interval)

# ── F — GLASS BLOCK ──

func update_glass_block(delta):
	if (teleport_hold_active or slam_camera_active):
		if (glass_block_active or glass_block_returning):
			force_end_glass_block(true)
		return
	var wants_block = (Input.is_key_pressed(KEY_F))
	# F released.
	if not wants_block:
		glass_block_broken_until_release = false
		glass_block_perfect_timer = 0.0
		if glass_block_active:
			start_glass_block_return()
		if glass_block_returning:
			update_glass_block_return(delta)
		return
	# Wall already overloaded.
	# Must release F before using again.
	if glass_block_broken_until_release:
		return
	if not glass_block_active:
		begin_glass_block()
	if glass_block_active:
		glass_block_time_left -= delta
		glass_block_perfect_timer = max(glass_block_perfect_timer - delta, 0.0)
		position_glass_block(delta)
		update_glass_block_enemy_collision()
		if glass_block_time_left <= 0.0:
			break_glass_block()

func begin_glass_block():
	var panes = get_walk_panes()
	if panes.is_empty():
		return
	glass_block_returning = false
	glass_block_active = true
	glass_block_time_left = (glass_block_max_hold_time)
	glass_block_perfect_timer = perfect_block_window
	for pane in panes:
		if not valid(pane):
			continue
		var id = (pane.get_instance_id())
		if not glass_block_original_transforms.has(id):
			glass_block_original_transforms[id] = (pane.global_transform)
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
	# IMPORTANT:
	# +Z is the visible front of Lucian.
	var forward = (global_transform.basis.z)
	var right = (global_transform.basis.x)
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var columns = max(glass_block_columns, 1)
	var w = weight(glass_block_pull_speed, delta)
	for i in range(panes.size()):
		var pane = panes[i]
		if not valid(pane):
			continue
		var row = int(i / columns)
		var column = (i % columns)
		var remaining = (panes.size() - row * columns)
		var row_count = min(columns, remaining)
		var horizontal = (float(column) - float(row_count - 1) * 0.5) * glass_block_spacing_x
		var vertical = (glass_block_base_height + float(row) * glass_block_spacing_y)
		var target_position = (global_position + forward * glass_block_distance + right * horizontal + Vector3.UP * vertical)
		pane.global_position = (pane.global_position.lerp(target_position, w))
		var current = (pane.global_rotation)
		current.x = lerp_angle(current.x, deg_to_rad(90.0), w)
		current.y = lerp_angle(current.y, rotation.y, w)
		current.z = lerp_angle(current.z, 0.0, w)
		pane.global_rotation = current

# ── RELEASE F — FLY BACK HOME ──

func start_glass_block_return():
	if not glass_block_active:
		return
	glass_block_active = false
	glass_block_returning = true
	glass_block_time_left = 0.0
	glass_block_perfect_timer = 0.0
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
		var target: Transform3D = (glass_block_original_transforms[id])
		var distance = (pane.global_position.distance_to(target.origin))
		if (distance <= glass_block_return_snap_distance):
			pane.global_transform = target
			glass_block_original_transforms.erase(id)
			continue
		still_returning = true
		pane.global_transform = (pane.global_transform.interpolate_with(target, return_weight))
	if (not still_returning or glass_block_original_transforms.is_empty()):
		for pane in get_valid_panes():
			if not valid(pane):
				continue
			var id = (pane.get_instance_id())
			if glass_block_original_transforms.has(id):
				pane.global_transform = (glass_block_original_transforms[id])
		glass_block_original_transforms.clear()
		glass_block_returning = false

# ── 2 SECOND BLOCK OVERLOAD ──

func break_glass_block():
	if not glass_block_active:
		return
	glass_block_active = false
	glass_block_returning = false
	glass_block_time_left = 0.0
	glass_block_perfect_timer = 0.0
	# F must be released before another block.
	glass_block_broken_until_release = true
	restore_glass_block_enemy_masks()
	var panes = (get_valid_panes().duplicate())
	glass_block_original_transforms.clear()
	# Wall collapse flash.
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(global_position + global_transform.basis.z * glass_block_distance + Vector3.UP * 2.0, 10.0, ult_wave_materials[2], 0.18)
	for pane in panes:
		if not valid(pane):
			continue
		set_pane_block_detector(pane, false)
		pane.set_meta("blocking", false)
		# Overload gives NO ult charge.
		shatter_glass_pane(pane, false, glass_block_break_shards)

# ── ENEMIES COLLIDE WITH F WALL ──

func update_glass_block_enemy_collision():
	if not glass_block_active:
		return
	for enemy in get_enemies():
		if (not valid(enemy) or not enemy is CollisionObject3D):
			continue
		if not glass_block_enemy_masks.has(enemy):
			glass_block_enemy_masks[enemy] = (enemy.collision_mask)
			# Remove normal pass-through exceptions.
			for pane in get_valid_panes():
				if (not valid(pane) or not pane is PhysicsBody3D):
					continue
				pane.remove_collision_exception_with(enemy)
				if enemy is PhysicsBody3D:
					enemy.remove_collision_exception_with(pane)
		# Enemy now detects Lucian glass.
		enemy.collision_mask |= (glass_collision_layer)

func restore_glass_block_enemy_masks():
	for enemy in glass_block_enemy_masks.keys():
		if not valid(enemy):
			continue
		enemy.collision_mask = (glass_block_enemy_masks[enemy])
	glass_block_enemy_masks.clear()

func remove_pane_enemy_exceptions(pane):
	if (not valid(pane) or not pane is PhysicsBody3D):
		return
	for enemy in get_enemies():
		if (not valid(enemy) or not enemy is PhysicsBody3D):
			continue
		pane.remove_collision_exception_with(enemy)
		enemy.remove_collision_exception_with(pane)
	pane.set_meta("enemy_exception_ids", {})

# ── F WALL PROJECTILE BLOCKING ──

func set_pane_block_detector(pane, _enabled):
	if not valid(pane):
		return
	var detector = pane.get_meta("block_detector", null)
	if not valid(detector):
		return
	# Detection remains live outside the old block stance so projectiles,
	# attack volumes, and tumbling enemies can always break the pane.
	detector.monitoring = true

func _on_glass_block_detector_area_entered(area, pane = null):
	var projectile = find_projectile_root(area)
	if valid(pane) and valid(projectile) and (projectile.is_in_group("enemy_projectiles") or projectile.is_in_group("player_projectiles")):
		projectile.set_meta("glass_block_resolved", true)
		projectile.queue_free()
		shatter_glass_pane(pane, false, pane_attack_break_shards)
		return
	if glass_block_active:
		block_projectile_node(area)

func _on_glass_block_detector_body_entered(body, pane = null):
	if valid(pane) and valid(body) and body.is_in_group("enemies"):
		var body_velocity: Vector3 = body.velocity if body is CharacterBody3D else Vector3.ZERO
		var tumbling: bool = get_property_if_exists(body, "aerial_spin_active") == true
		var knocked_back: bool = float(get_property_if_exists(body, "knockback_timer")) > 0.0
		var juggled: bool = float(get_property_if_exists(body, "juggle_gravity_timer")) > 0.0
		var dying_body: bool = get_property_if_exists(body, "dying") == true
		if body_velocity.length() >= pane_tumble_break_speed and (tumbling or knocked_back or juggled or dying_body):
			shatter_glass_pane(pane, false, pane_attack_break_shards)
			return
	if glass_block_active:
		block_projectile_node(body)

func break_panes_in_enemy_attack(attack_center: Vector3, attack_radius: float) -> void:
	for pane in get_valid_panes():
		var pane_size: Vector3 = pane.get_meta("pane_size", Vector3.ONE)
		var local_hit: Vector3 = pane.to_local(attack_center)
		var horizontal_reach := attack_radius + maxf(pane_size.x, pane_size.z) * 0.5
		if Vector2(local_hit.x, local_hit.z).length() <= horizontal_reach and absf(local_hit.y) <= attack_radius + pane_size.y * 0.5:
			shatter_glass_pane(pane, false, pane_attack_break_shards)

func break_panes_along_enemy_attack(from_position: Vector3, to_position: Vector3, attack_radius: float) -> void:
	# Sampling keeps long claw lanes and lunges reliable against rotated panes
	# without requiring each enemy move to own a separate physics hitbox.
	for i in range(9):
		break_panes_in_enemy_attack(from_position.lerp(to_position, float(i) / 8.0), attack_radius)

func block_projectile_node(node):
	var projectile = find_projectile_root(node)

	if not valid(projectile) or projectile == self:
		return
	if projectile.is_in_group("enemies"):
		return
	if projectile.is_in_group("lucian_glass_panes"):
		return
	if projectile.get_meta("ignore_glass_block", false):
		return
	if projectile.get_meta("glass_block_resolved", false):
		return

	projectile.set_meta("glass_block_resolved", true)

	var hit_position = (
		global_position
		+ global_transform.basis.z * glass_block_distance
		+ Vector3.UP * 2.0
	)

	if projectile is Node3D:
		hit_position = projectile.global_position

	var enemy_projectile = projectile.is_in_group("enemy_projectiles")
	var source_enemy = get_projectile_source_enemy(projectile, hit_position)
	var perfect = enemy_projectile and glass_block_perfect_timer > 0.0

	projectile.queue_free()

	if perfect:
		perform_perfect_glass_block(hit_position, source_enemy)


func get_projectile_source_enemy(projectile, hit_position):
	for property_name in ["source_enemy", "shooter", "owner_enemy"]:
		var source = get_property_if_exists(projectile, property_name)

		if (
			valid(source)
			and source is Node3D
			and source.is_in_group("enemies")
		):
			return source

	return get_nearest_enemy_to(hit_position, pane_volley_target_range)


func perform_perfect_glass_block(hit_position, source_enemy):
	glass_block_perfect_timer = 0.0
	add_ult_charge(perfect_block_ult_charge)

	if ult_wave_materials.size() > 1:
		spawn_flash_sphere(
			hit_position,
			perfect_block_flash_radius,
			ult_wave_materials[1],
			0.12
		)

	spawn_shard_burst(hit_position, 18, 7.0, 0.75, 0.28)

	spawn_light_flash(
		hit_position + Vector3.UP * 0.5,
		perfect_block_flash_radius,
		10.0,
		Color(0.7, 0.95, 1.0),
		0.18
	)

	if valid(source_enemy) and source_enemy.has_method("apply_hit_effect"):
		var stagger_direction = source_enemy.global_position - global_position
		stagger_direction.y = 0.0

		if stagger_direction.length() > 0.01:
			stagger_direction = stagger_direction.normalized()

		source_enemy.apply_hit_effect(
			stagger_direction,
			0.0,
			0.0,
			perfect_block_counter_stun
		)

	spawn_perfect_block_counter_shards(hit_position, source_enemy)


func spawn_perfect_block_counter_shards(origin, preferred_target):
	if not homing_projectile_scene:
		return

	var target = (
		preferred_target
		if valid(preferred_target)
		else get_nearest_enemy_to(origin, pane_volley_target_range)
	)

	if not valid(target):
		return

	for i in range(perfect_block_counter_shards):
		var projectile = homing_projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)

		var angle = (
			TAU * float(i)
			/ float(max(perfect_block_counter_shards, 1))
		)

		projectile.global_position = (
			origin
			+ Vector3(cos(angle), 0.35, sin(angle)) * 0.8
		)

		projectile.set_meta("ignore_glass_block", true)
		projectile.target = target
		projectile.damage = perfect_block_counter_damage
		projectile.projectile_size = perfect_block_counter_size
		projectile.is_finisher_projectile = false
		projectile.direction = (
			target.global_position
			+ Vector3.UP
			- projectile.global_position
		).normalized()

		set_if_has(projectile, "speed", perfect_block_counter_speed)
		set_if_has(projectile, "homing_strength", perfect_block_counter_homing)
		set_if_has(projectile, "launch_force", perfect_block_counter_launch)
		set_if_has(projectile, "knockback_strength", 0.0)
		set_if_has(projectile, "stun_time", perfect_block_counter_stun)


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
	if (node.is_in_group("projectiles") or node.is_in_group("enemy_projectiles") or node.is_in_group("player_projectiles")):
		return true
	var lower_name = (String(node.name).to_lower())
	if ("projectile" in lower_name or "bullet" in lower_name or "missile" in lower_name):
		return (node is Area3D or node is PhysicsBody3D)
	if not (node is Area3D or node is PhysicsBody3D):
		return false
	var has_damage = false
	var has_motion = false
	for info in node.get_property_list():
		var property_name = String(info["name"])
		if property_name == "damage":
			has_damage = true
		elif (property_name == "direction" or property_name == "speed" or property_name == "velocity"):
			has_motion = true
	return (has_damage and has_motion)

# ── FORCE CANCEL F WALL ──

func force_end_glass_block(restore_positions = true):
	if (not glass_block_active and not glass_block_returning and glass_block_original_transforms.is_empty()):
		restore_glass_block_enemy_masks()
		return
	restore_glass_block_enemy_masks()
	for pane in get_valid_panes():
		if not valid(pane):
			continue
		var id = (pane.get_instance_id())
		if (restore_positions and glass_block_original_transforms.has(id)):
			pane.global_transform = (glass_block_original_transforms[id])
		pane.set_meta("blocking", false)
		set_pane_block_detector(pane, false)
		pane.set_meta("enemy_exception_ids", {})
		sync_pane_enemy_exceptions(pane)
	glass_block_original_transforms.clear()
	glass_block_active = false
	glass_block_returning = false
	glass_block_time_left = 0.0
	glass_block_perfect_timer = 0.0

# ── GLASS ARENA ──

func create_glass_arena():
	var arena_target = teleport_focus_target if valid(teleport_focus_target) else get_aim_target(finisher_target_range)
	if not valid(arena_target):
		return
	force_end_glass_block(true)
	var enemy = arena_target
	clear_teleport_followup()
	var arena_position = (global_position + enemy.global_position) * 0.5
	arena_position.y = (min(global_position.y, enemy.global_position.y) - arena_pane_vertical_offset)
	create_glass_pane(arena_position, arena_pane_size, arena_pane_lifetime, big_glass_material, big_pane_ult_charge, false)
	velocity.y = max(velocity.y, arena_player_lift)
	low_gravity_timer = max(low_gravity_timer, teleport_low_gravity_duration)
	if enemy is CharacterBody3D:
		enemy.velocity.y = max(enemy.velocity.y, arena_enemy_lift)
	teleport_camera_target = enemy
	teleport_camera_timer = 0.30

# ── E — PANE SHATTER VOLLEY ──

func cast_pane_volley():
	if elite_mini_boss_active():
		return
	if (slam_camera_active or teleport_hold_active or not homing_projectile_scene):
		return
	force_end_glass_block(true)
	var panes = get_valid_panes()
	if (panes.is_empty() or get_enemies().is_empty()):
		return
	combat_recovery_timer = ability_recovery
	var resume_glass_walk = (Input.is_action_pressed("dodge") and (not is_on_floor() or is_on_glass() or glass_walk_active))
	for pane in panes:
		if not valid(pane):
			continue
		var origin = (pane.global_position + Vector3.UP * 0.15)
		var target = get_nearest_enemy_to(origin, pane_volley_target_range)
		if valid(target):
			spawn_pane_projectile(origin, target)
		shatter_glass_pane(pane, false, pane_volley_visual_shards)
	if resume_glass_walk:
		glass_walk_active = true
		glass_walk_needs_pane = false
		glass_pane_spawn_timer = 0.0
		spawn_walk_pane(get_movement_direction())

# F — form one arena-spanning pane overhead, then drop the sky on the horde.
func cast_rift_cleave() -> void:
	if rift_cleave_timer > 0.0 or slam_camera_active or falling_pane_cast_active or combat_recovery_timer > 0.0:
		return
	rift_cleave_timer = rift_cleave_cooldown
	combat_recovery_timer = falling_pane_form_time
	falling_pane_cast_active = true
	falling_pane_saved_camera_pitch = camera_pitch_target
	velocity = Vector3.ZERO
	force_end_glass_block(true)
	var forward := global_transform.basis.z.normalized()
	var pane_center := global_position + forward * falling_pane_forward_offset
	var start := pane_center + Vector3.UP * falling_pane_spawn_height
	var destination := pane_center + Vector3.UP * 0.45
	# This cinematic pane is not a movement pane, so it cannot accidentally
	# switch right click into pane pull while it hangs overhead.
	var pane = create_glass_pane(start, falling_pane_size, falling_pane_form_time + falling_pane_crash_time + 1.2, small_glass_material, small_pane_ult_charge, false)
	if not valid(pane):
		falling_pane_cast_active = false
		camera_pitch_target = falling_pane_saved_camera_pitch
		return
	pane.rotation = Vector3(deg_to_rad(-3.0), rotation.y, deg_to_rad(-2.0))
	pane.scale = Vector3(0.015, 0.12, 0.015)
	spawn_light_flash(start, 12.0, falling_pane_explosion_light_energy, Color(0.72, 0.9, 1.0), falling_pane_form_time * 0.65)
	spawn_shard_burst(start, 72, 28.0, 0.65, falling_pane_form_time)
	var form_tween := create_tween()
	form_tween.tween_property(pane, "scale", Vector3.ONE, falling_pane_form_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await form_tween.finished
	# Control returns on the exact beat the completed pane starts falling.
	falling_pane_cast_active = false
	camera_pitch_target = falling_pane_saved_camera_pitch
	if not valid(pane):
		return
	var fall_tween := create_tween()
	fall_tween.tween_property(pane, "global_position", destination, falling_pane_crash_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	fall_tween.tween_callback(impact_falling_pane.bind(pane, destination, forward))
	camera_fov_pulse()

func update_falling_pane_camera(_delta: float) -> void:
	if not falling_pane_cast_active:
		return
	camera_pitch_target = deg_to_rad(falling_pane_camera_pitch_degrees)
	if camera:
		camera.fov = lerpf(camera.fov, 58.0, 0.12)

# E — Cathedral Pulse lifts and suspends the surrounding horde for F panes.
func cast_ruin_volley() -> void:
	if ruin_volley_timer > 0.0 or slam_camera_active or combat_recovery_timer > 0.0:
		return
	ruin_volley_timer = ruin_volley_cooldown
	combat_recovery_timer = 0.20
	var well_center := global_position + Vector3.UP
	break_panes_in_enemy_attack(well_center, fracture_well_radius)
	for enemy in get_enemies_near(well_center, fracture_well_radius):
		var pulse_direction: Vector3 = enemy.global_position - well_center
		pulse_direction.y = 0.0
		if pulse_direction.length_squared() < 0.01:
			pulse_direction = global_transform.basis.z
		if enemy.has_method("take_damage"):
			enemy.take_damage(fracture_well_damage)
		if enemy.has_method("apply_hit_effect"):
			enemy.apply_hit_effect(pulse_direction.normalized(), fracture_well_pull, suspension_pulse_launch, suspension_pulse_stun, true)
		elif enemy is CharacterBody3D:
			enemy.velocity = pulse_direction.normalized() * fracture_well_pull + Vector3.UP * suspension_pulse_launch
		set_if_has(enemy, "juggle_gravity_timer", suspension_pulse_hold_time)
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(well_center + Vector3.UP, fracture_well_radius, ult_wave_materials[1], 0.26)
		spawn_flash_sphere(well_center + Vector3.UP * 4.0, fracture_well_radius * 0.72, ult_wave_materials[2], 0.34)
		spawn_shard_burst(well_center + Vector3.UP, 72, fracture_well_radius, 0.9, 0.42)
	camera_fov_pulse()

func impact_falling_pane(pane, impact_position: Vector3, outward: Vector3) -> void:
	if not valid(pane):
		return
	for enemy in get_enemies_near(impact_position, falling_pane_impact_radius):
		var direction: Vector3 = enemy.global_position - impact_position
		direction.y = 0.0
		if direction.length_squared() < 0.01:
			direction = outward
		hit_enemy(enemy, falling_pane_explosion_damage, falling_pane_knockback, falling_pane_launch, 0.42, direction.normalized())
	# Layered glass blast makes the damaging radius readable at horde speed.
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(impact_position + Vector3.UP * 0.8, falling_pane_impact_radius, ult_wave_materials[2], 0.18)
		spawn_flash_sphere(impact_position + Vector3.UP * 0.35, falling_pane_impact_radius * 0.68, ult_wave_materials[0], 0.12)
	spawn_light_flash(impact_position + Vector3.UP * 1.2, falling_pane_impact_radius * 1.35, falling_pane_explosion_light_energy, Color(0.72, 0.9, 1.0), 0.16)
	spawn_shard_burst(impact_position, 48, falling_pane_impact_radius * 1.15, 1.0, 0.36)
	shatter_glass_pane(pane, false, 20)

func spawn_pane_projectile(origin, target):
	var projectile = (homing_projectile_scene.instantiate())
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	projectile.target = target
	projectile.damage = (pane_volley_damage)
	projectile.projectile_size = (pane_volley_size)
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
		if (not valid(enemy) or not enemy is Node3D):
			continue
		var distance = (point.distance_to(enemy.global_position))
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

func set_if_has(object, property_name, value):
	for info in object.get_property_list():
		if (String(info["name"]) == property_name):
			object.set(property_name, value)
			return

# ── GLASS CREATION ──

func make_material(color, emission):
	var material = (StandardMaterial3D.new())
	material.albedo_color = color
	material.transparency = (BaseMaterial3D.TRANSPARENCY_ALPHA)
	material.shading_mode = (BaseMaterial3D.SHADING_MODE_UNSHADED)
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = (emission)
	return material

func create_glass_pane(pane_position, size, lifetime, material, charge, is_walk_pane):
	clean_glass_panes()
	if (active_glass_panes.size() >= glass_pane_max_count):
		remove_glass_pane(active_glass_panes.pop_front())
	var pane = StaticBody3D.new()
	var shape = BoxShape3D.new()
	var collision = CollisionShape3D.new()
	var mesh = BoxMesh.new()
	var visual = MeshInstance3D.new()
	pane.collision_layer = (glass_collision_layer)
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
	# ── PROJECTILE DETECTOR ──
	var block_detector = Area3D.new()
	block_detector.name = ("BlockDetector")
	block_detector.collision_layer = 0
	# Detect projectile Areas/Bodies on every layer.
	block_detector.collision_mask = (0xFFFFFFFF)
	block_detector.monitoring = true
	block_detector.monitorable = false
	var detector_collision = (CollisionShape3D.new())
	var detector_shape = (BoxShape3D.new())
	detector_shape.size = size
	detector_collision.shape = (detector_shape)
	block_detector.add_child(detector_collision)
	block_detector.area_entered.connect(_on_glass_block_detector_area_entered.bind(pane))
	block_detector.body_entered.connect(_on_glass_block_detector_body_entered.bind(pane))
	pane.set_meta("block_detector", block_detector)
	# ── ADD PANE ──
	get_tree().current_scene.add_child(pane)
	pane.global_position = pane_position
	pane.rotation.y = rotation.y
	pane.add_child(collision)
	pane.add_child(visual)
	pane.add_child(block_detector)
	active_glass_panes.append(pane)
	sync_pane_enemy_exceptions(pane)
	update_pane_counter_ui()
	expire_glass_pane(pane, lifetime)
	return pane

# ── GLASS HELPERS ──

func get_valid_panes():
	clean_glass_panes()
	var panes = []
	for pane in active_glass_panes:
		if (valid(pane) and not pane.get_meta("shattered", false)):
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
			if (panes[j].global_position.y > panes[highest].global_position.y):
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

	while valid(pane) and pane.get_meta("slam_reserved", false):
		await get_tree().physics_frame

	if valid(pane):
		remove_glass_pane(pane)

# ── ENEMY ONE-WAY GLASS ──

func sync_pane_enemy_exceptions(pane):
	if (not valid(pane) or not pane is PhysicsBody3D or pane.get_meta("blocking", false)):
		return
	var ids: Dictionary = (pane.get_meta("enemy_exception_ids", {}))
	for enemy in get_enemies():
		if (not valid(enemy) or not enemy is PhysicsBody3D):
			continue
		var id = (enemy.get_instance_id())
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
		if (not valid(enemy) or not enemy is CharacterBody3D):
			continue
		var id = enemy.get_instance_id()
		var current_y = enemy.global_position.y
		var previous_y = float(enemy_previous_y.get(id, current_y - enemy.velocity.y * delta))
		if (panes.is_empty() or is_slam_controlled_enemy(enemy) or enemy == teleport_held_enemy or enemy.velocity.y > 0.0):
			enemy_previous_y[id] = current_y
			continue
		var best_top = -INF
		for pane in panes:
			# F wall is vertical.
			if pane.get_meta("blocking", false):
				continue
			var size = pane.get_meta("pane_size", Vector3.ONE)
			var local_position = (pane.to_local(enemy.global_position))
			if (abs(local_position.x) > size.x * 0.5 - enemy_pane_edge_margin):
				continue
			if (abs(local_position.z) > size.z * 0.5 - enemy_pane_edge_margin):
				continue
			var top = (pane.global_position.y + size.y * 0.5 + enemy_pane_stand_offset)
			var crossed = (previous_y >= top and current_y <= top)
			var resting = (abs(current_y - top) <= enemy_pane_snap_margin)
			if ((crossed or resting) and top > best_top):
				best_top = top
		if best_top > -INF:
			enemy.global_position.y = best_top
			enemy.velocity.y = max(enemy.velocity.y, 0.0)
			current_y = best_top
		enemy_previous_y[id] = current_y

func is_slam_controlled_enemy(enemy):
	return (enemy == pending_slam_target or enemy == slam_impact_target)

# ── GLASS SHATTER ──

func shatter_glass_pane(pane, give_charge = true, shard_override = -1):
	if (not valid(pane) or pane.get_meta("shattered", false)):
		return
	pane.set_meta("shattered", true)
	pane.set_meta("slam_reserved", false)
	pane.set_meta("empowered_slam_pane", false)
	var size = pane.get_meta("pane_size", Vector3.ONE)
	var scale_value = clamp(max(size.x, size.z) / 8.0, 0.65, 2.5)
	var shards = (shard_override if shard_override > 0 else pane_shatter_shard_count)
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
		if (min(start.y, finish.y) > half.y or max(start.y, finish.y) < -half.y):
			continue
		var dy = (finish.y - start.y)
		var t = (clamp(-start.y / dy, 0.0, 1.0) if abs(dy) > 0.0001 else 0.0)
		var hit = start.lerp(finish, t)
		if (abs(hit.x) <= half.x and abs(hit.z) <= half.z):
			shatter_glass_pane(pane)

func shatter_panes_at_slam_impact(position, radius):
	for pane in get_valid_panes():
		var size = pane.get_meta("pane_size", Vector3.ONE)
		var hit = (pane.to_local(position))
		if (abs(hit.x) <= size.x * 0.5 + radius and abs(hit.z) <= size.z * 0.5 + radius and abs(hit.y) <= 3.0):
			shatter_glass_pane(pane)

# ── SLAM START ──

func start_air_slam():
	if not valid(slam_target):
		return
	combat_recovery_timer = maxf(combat_recovery_timer, slam_windup_time + slam_recovery_time)

	force_end_glass_block(true)
	pending_slam_target = slam_target

	slam_final_finisher_active = can_trigger_final_enemy_finisher(
		pending_slam_target
	)

	# The old 50-movement-pane empowered attack has been retired.
	slam_chain_empowered = false

	slam_chain_progress = 0.0

	clear_teleport_followup()

	slam_enemy_was_physics_active = (
		pending_slam_target.is_physics_processing()
	)

	pending_slam_target.set_physics_process(false)

	if pending_slam_target is CharacterBody3D:
		pending_slam_target.velocity = Vector3.ZERO

	slam_windup_timer = slam_windup_time

	combo_hold_timer = max(
		combo_hold_timer,
		slam_windup_time + slam_recovery_time
	)

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
		slam_chain_empowered = false
		slam_final_finisher_active = false
		end_slam_camera()
		return

	var enemy = pending_slam_target
	pending_slam_target = null

	if slam_final_finisher_active:
		perform_final_pane_finisher(enemy)
	elif slam_chain_empowered:
		perform_empowered_slam(enemy)
	else:
		execute_normal_slam(enemy)


func execute_normal_slam(enemy):
	if not valid(enemy):
		return

	enemy.set_physics_process(slam_enemy_was_physics_active)

	if enemy.has_method("apply_hit_effect"):
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
	slam_last_position = enemy.global_position
	slam_impact_arm_timer = slam_impact_arm_delay
	slam_recovery_timer = slam_recovery_time


# ── FINAL ENEMY PANE FINISHER ──

func perform_final_pane_finisher(enemy):
	if not valid(enemy):
		return

	var panes = get_chain_panes()

	if panes.is_empty():
		slam_final_finisher_active = false
		execute_normal_slam(enemy)
		return

	slam_chain_running = true
	slam_impact_target = enemy

	enemy.set_physics_process(false)

	if enemy is CharacterBody3D:
		enemy.velocity = Vector3.ZERO

	var entry = (
		get_pane_hit_point(panes[0], enemy.global_position)
		+ Vector3.UP * final_finisher_entry_height
	)

	var tween = create_tween()

	tween.tween_property(
		enemy,
		"global_position",
		entry,
		final_finisher_entry_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

	for i in range(panes.size()):
		if not valid(enemy):
			break

		var pane = panes[i]

		if not valid(pane):
			continue

		slam_chain_progress = (
			float(i + 1)
			/ float(panes.size() + 1)
		)

		var destination = get_pane_hit_point(
			pane,
			enemy.global_position
		)

		destination.y -= 0.35

		tween = create_tween()

		tween.tween_property(
			enemy,
			"global_position",
			destination,
			final_finisher_step_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		await tween.finished

		if not valid(enemy):
			break

		if valid(pane):
			if not ult_wave_materials.is_empty():
				spawn_flash_sphere(
					pane.global_position,
					3.0,
					ult_wave_materials[
						i % ult_wave_materials.size()
					],
					0.08
				)

			shatter_glass_pane(
				pane,
				true,
				final_finisher_shards_per_pane
			)

	if not valid(enemy):
		slam_chain_running = false
		slam_impact_target = null
		slam_final_finisher_active = false
		end_slam_camera()
		return

	enemy.set_physics_process(slam_enemy_was_physics_active)

	slam_chain_running = false
	slam_chain_progress = 1.0

	if enemy is CharacterBody3D:
		enemy.velocity = Vector3(
			0.0,
			-slam_down_force * final_finisher_down_multiplier,
			0.0
		)

	slam_last_position = enemy.global_position
	slam_impact_arm_timer = slam_impact_arm_delay
	slam_recovery_timer = slam_recovery_time


# ── NEW EMPOWERED SLAM ──

func perform_empowered_slam(enemy):
	if not valid(enemy):
		return

	var panes = get_walk_panes()

	if panes.is_empty():
		slam_chain_empowered = false
		execute_normal_slam(enemy)
		return

	slam_chain_running = true
	slam_impact_target = enemy

	empowered_slam_active = true
	empowered_slam_victim = enemy
	empowered_slam_panes.clear()
	empowered_slam_next_pane = 0

	enemy.set_physics_process(false)

	if enemy is CharacterBody3D:
		enemy.velocity = Vector3.ZERO

	var ground_y = get_empowered_slam_ground_y(enemy)

	empowered_slam_ground_y_for_camera = ground_y

	var stack_height = (
		float(max(panes.size() - 1, 0))
		* empowered_slam_pane_spacing
	)

	var required_apex_y = (
		ground_y
		+ empowered_slam_pane_bottom_height
		+ stack_height
		+ empowered_slam_pane_top_gap
		+ 8.0
	)

	var apex = enemy.global_position

	apex.y = max(
		enemy.global_position.y + 24.0,
		ground_y + empowered_slam_apex_height,
		required_apex_y
	)

	empowered_slam_player_offset = Vector3(
		0.0,
		empowered_slam_player_above_height,
		0.0
	)

	var player_apex = apex + empowered_slam_player_offset

	empowered_slam_apex_y_for_camera = apex.y
	empowered_slam_player_hold_position = player_apex
	empowered_slam_return_pending = false

	# Move the stationary observer up to frame the true apex.
	if empowered_slam_camera_active:
		var delta_to_apex = (
			apex.y
			- slam_start_enemy_y
		)

		empowered_slam_camera_fixed_position.y += delta_to_apex

	velocity = Vector3.ZERO

	var lift_tween = create_tween().set_parallel(true)

	lift_tween.tween_property(
		enemy,
		"global_position",
		apex,
		empowered_slam_launch_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	lift_tween.tween_property(
		self,
		"global_position",
		player_apex,
		empowered_slam_launch_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await lift_tween.finished

	if not valid(enemy):
		cancel_empowered_slam_state()
		end_slam_camera()
		return

	slam_chain_progress = 0.25

	if ult_wave_materials.size() > 1:
		spawn_flash_sphere(
			apex,
			14.0,
			ult_wave_materials[1],
			0.14
		)

	spawn_light_flash(
		apex,
		22.0,
		18.0,
		Color(0.75, 0.92, 1.0),
		0.20
	)

	empowered_slam_panes = await arrange_empowered_slam_panes(
		panes,
		apex,
		ground_y
	)

	if not valid(enemy):
		cancel_empowered_slam_state()
		end_slam_camera()
		return

	# Tiny anticipation beat before Lucian drives the enemy downward.
	await get_tree().create_timer(0.10).timeout

	if not valid(enemy):
		cancel_empowered_slam_state()
		end_slam_camera()
		return

	slam_chain_progress = 1.0

	enemy.set_physics_process(slam_enemy_was_physics_active)
	slam_chain_running = false

	if enemy is CharacterBody3D:
		enemy.velocity = Vector3(
			0.0,
			-empowered_slam_down_force,
			0.0
		)

	slam_last_position = enemy.global_position
	slam_impact_arm_timer = slam_impact_arm_delay
	slam_recovery_timer = slam_recovery_time


func arrange_empowered_slam_panes(panes, apex, ground_y):
	var valid_panes = []

	for pane in panes:
		if valid(pane):
			valid_panes.append(pane)

	if valid_panes.is_empty():
		return []

	var bottom_y = (
		ground_y
		+ empowered_slam_pane_bottom_height
	)

	var tween = create_tween().set_parallel(true)
	var ordered = []

	for i in range(valid_panes.size()):
		var pane = valid_panes[i]

		var reverse_index = (
			valid_panes.size() - 1 - i
		)

		var pane_y = (
			bottom_y
			+ float(reverse_index)
			* empowered_slam_pane_spacing
		)

		var target_position = Vector3(
			apex.x,
			pane_y,
			apex.z
		)

		var angle = (
			deg_to_rad(26.0)
			if i % 2 == 0
			else deg_to_rad(-26.0)
		)

		var target_rotation = Vector3(
			0.0,
			rotation.y + angle,
			0.0
		)

		pane.set_meta("blocking", false)
		pane.set_meta("empowered_slam_pane", true)
		pane.set_meta("slam_reserved", true)
		pane.set_meta("base_scale", pane.scale)
		pane.set_meta("empowered_expand_started", false)

		set_pane_block_detector(pane, false)

		pane.set_meta(
			"enemy_exception_ids",
			{}
		)

		sync_pane_enemy_exceptions(pane)

		tween.tween_property(
			pane,
			"global_position",
			target_position,
			empowered_slam_pane_move_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(
			pane,
			"global_rotation",
			target_rotation,
			empowered_slam_pane_move_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		ordered.append(pane)

	await tween.finished

	var safe_ordered = []

	for pane in ordered:
		if valid(pane):
			safe_ordered.append(pane)

	for i in range(safe_ordered.size()):
		var highest_index = i

		for j in range(i + 1, safe_ordered.size()):
			if (
				valid(safe_ordered[j])
				and valid(safe_ordered[highest_index])
				and safe_ordered[j].global_position.y
					> safe_ordered[highest_index].global_position.y
			):
				highest_index = j

		if highest_index != i:
			var temp = safe_ordered[i]
			safe_ordered[i] = safe_ordered[highest_index]
			safe_ordered[highest_index] = temp

	slam_chain_progress = 0.85

	return safe_ordered


func get_empowered_slam_ground_y(enemy):
	var fallback = (
		min(
			global_position.y,
			enemy.global_position.y
		)
		- 20.0
	)

	var world = get_world_3d()

	if world == null:
		return fallback

	var from = enemy.global_position + Vector3.UP * 100.0
	var to = enemy.global_position + Vector3.DOWN * 500.0

	var query = PhysicsRayQueryParameters3D.create(from, to)

	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = camera_collision_mask
	query.exclude = [get_rid()]

	if enemy is CollisionObject3D:
		query.exclude.append(enemy.get_rid())

	var hit = world.direct_space_state.intersect_ray(query)

	if hit.is_empty():
		return fallback

	return hit["position"].y


func can_trigger_final_enemy_finisher(enemy):
	if not valid(enemy):
		return false

	if get_walk_pane_count() <= 0:
		return false

	var alive = get_alive_combat_enemies()

	if alive.size() != 1:
		return false

	if alive[0] != enemy:
		return false

	var hp = get_property_if_exists(enemy, "health")

	return (
		hp != null
		and float(hp) > 0.0
		and float(hp) <= final_finisher_damage
	)


func get_alive_combat_enemies():
	var alive = []

	for enemy in get_enemies():
		if not valid(enemy):
			continue

		if not (enemy is Node3D):
			continue

		if not enemy.has_method("take_damage"):
			continue

		var hp = get_property_if_exists(enemy, "health")

		if hp != null and float(hp) <= 0.0:
			continue

		alive.append(enemy)

	return alive


func update_empowered_slam_pane_sequence(enemy, delta):
	if empowered_slam_next_pane >= empowered_slam_panes.size():
		return

	var pane = empowered_slam_panes[
		empowered_slam_next_pane
	]

	if not valid(pane):
		empowered_slam_next_pane += 1
		return

	var pane_y = pane.global_position.y
	var previous_y = slam_last_position.y
	var current_y = enemy.global_position.y

	var distance_above = current_y - pane_y

	# Swell dramatically before impact.
	if (
		distance_above > 0.0
		and distance_above <= empowered_pane_expand_distance
	):
		var progress = clamp(
			1.0
			- distance_above / empowered_pane_expand_distance,
			0.0,
			1.0
		)

		var base_scale = pane.get_meta(
			"base_scale",
			Vector3.ONE
		)

		var dramatic_progress = progress * progress

		var horizontal_expand = lerp(
			1.0,
			empowered_pane_expand_scale,
			dramatic_progress
		)

		var thickness_expand = lerp(
			1.0,
			1.75,
			dramatic_progress
		)

		# Massive X/Z expansion, but keep the pane readable as a thin
		# sheet of glass instead of turning it into a giant cube.
		var target_scale = Vector3(
			base_scale.x * horizontal_expand,
			base_scale.y * thickness_expand,
			base_scale.z * horizontal_expand
		)

		pane.scale = pane.scale.lerp(
			target_scale,
			clamp(
				empowered_pane_expand_speed * delta,
				0.0,
				1.0
			)
		)

		if not pane.get_meta("empowered_expand_started", false):
			pane.set_meta("empowered_expand_started", true)

			if not ult_wave_materials.is_empty():
				spawn_flash_sphere(
					pane.global_position,
					12.0,
					ult_wave_materials[0],
					0.10
				)

	# Robust crossing check so high fall speed cannot skip a pane.
	var crossed = (
		previous_y >= pane_y
		and current_y <= pane_y
	)

	if (
		crossed
		or abs(distance_above) <= empowered_pane_break_distance
	):
		empowered_slam_pane_impact(pane, enemy)
		empowered_slam_next_pane += 1


func empowered_slam_pane_impact(pane, enemy):
	if not valid(pane):
		return

	var impact_position = pane.global_position

	# White core.
	if ult_wave_materials.size() > 1:
		spawn_flash_sphere(
			impact_position,
			empowered_pane_shatter_radius,
			ult_wave_materials[1],
			0.09
		)

	# Cyan outer shock.
	if not ult_wave_materials.is_empty():
		spawn_flash_sphere(
			impact_position,
			empowered_pane_shatter_radius * 0.72,
			ult_wave_materials[0],
			0.14
		)

	# Dense glass burst.
	spawn_shard_burst(
		impact_position,
		empowered_pane_shatter_shards,
		empowered_pane_shatter_distance,
		1.45,
		0.34
	)

	# Every second pane gets a light to keep the 50-pane sequence performant.
	if empowered_slam_next_pane % 2 == 0:
		spawn_light_flash(
			impact_position + Vector3.UP * 0.5,
			empowered_pane_shatter_radius,
			empowered_pane_flash_energy,
			Color(0.72, 0.94, 1.0),
			0.14
		)

	# Camera punch on every layer.
	if camera:
		camera.fov += empowered_pane_fov_punch

	if camera_pivot:
		# Add a brief impact kick, but NEVER write permanent roll directly
		# into CameraPivot.rotation.z.
		slam_camera_roll_kick = clamp(
			slam_camera_roll_kick
			+ randf_range(
				deg_to_rad(-3.5),
				deg_to_rad(3.5)
			),
			deg_to_rad(-6.0),
			deg_to_rad(6.0)
		)

	# Real pane shatters and grants its normal Ult charge.
	shatter_glass_pane(
		pane,
		true,
		empowered_pane_shatter_shards
	)

	# Keep forcing the victim downward after every crash.
	if enemy is CharacterBody3D:
		enemy.velocity.y = min(
			enemy.velocity.y,
			-empowered_slam_down_force
		)


func cancel_empowered_slam_state():
	for pane in empowered_slam_panes:
		if valid(pane):
			pane.set_meta("slam_reserved", false)
			pane.set_meta("empowered_slam_pane", false)

	empowered_slam_active = false
	empowered_slam_victim = null
	empowered_slam_panes.clear()
	empowered_slam_next_pane = 0
	empowered_slam_player_offset = Vector3.ZERO

	# Keep the hold position while the delayed empowered return is pending.
	if not empowered_slam_return_pending:
		empowered_slam_player_hold_position = Vector3.ZERO


func update_slam_impact(delta):
	if slam_chain_running:
		return

	if not valid(slam_impact_target):
		slam_impact_target = null

		# During the empowered ending, the victim may already be dead.
		# Keep the observer camera alive for the tiny impact hold until
		# update_empowered_slam_return() releases Lucian downward.
		if empowered_slam_return_pending:
			return

		if (
			slam_camera_active
			and slam_camera_hold_timer <= 0.0
			and not valid(pending_slam_target)
		):
			end_slam_camera()

		cancel_empowered_slam_state()
		return

	var enemy = slam_impact_target

	if not (enemy is CharacterBody3D):
		slam_impact_target = null
		cancel_empowered_slam_state()
		end_slam_camera()
		return

	if slam_chain_empowered:
		update_empowered_slam_pane_sequence(enemy, delta)
	else:
		shatter_panes_crossed_by_slam(
			slam_last_position,
			enemy.global_position
		)

	var force = slam_down_force

	if slam_chain_empowered:
		force = empowered_slam_down_force
	elif slam_final_finisher_active:
		force = (
			slam_down_force
			* final_finisher_down_multiplier
		)

	enemy.velocity.y = min(
		enemy.velocity.y,
		-force
	)

	if slam_impact_arm_timer > 0.0:
		slam_impact_arm_timer -= delta
		slam_last_position = enemy.global_position
		return

	if enemy.is_on_floor():
		var impact = enemy.global_position

		trigger_slam_impact(
			impact,
			enemy
		)

		slam_impact_target = null

		hold_slam_camera_on_impact(
			impact
		)

		if slam_chain_empowered:
			# Lucian has ridden the victim through the pane tower and is
			# now hovering only a few units above this impact.
			# Hold for the explosion beat, then drop him immediately.
			empowered_slam_return_pending = true
			empowered_slam_return_timer = empowered_slam_return_delay
			empowered_slam_return_impact_point = impact
		else:
			cancel_empowered_slam_state()

		return

	slam_last_position = enemy.global_position


func update_empowered_slam_return(delta):
	if not empowered_slam_return_pending:
		return

	# Lucian has already followed the victim to the bottom of the tower.
	# Hold his current position for the tiny explosion beat.
	velocity = Vector3.ZERO

	empowered_slam_return_timer -= delta

	if empowered_slam_return_timer > 0.0:
		return

	empowered_slam_return_pending = false
	empowered_slam_return_timer = 0.0
	empowered_slam_return_impact_point = Vector3.ZERO
	slam_chain_empowered = false

	# End the cinematic BEFORE giving Lucian downward velocity so the
	# camera/hold code cannot immediately zero the fall.
	end_slam_camera()
	cancel_empowered_slam_state()

	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = -abs(
		empowered_slam_player_drop_velocity
	)

	empowered_slam_player_drop_lock_timer = (
		empowered_slam_player_drop_lock_time
	)

	low_gravity_timer = 0.0
	glass_walk_active = false
	glass_walk_needs_pane = false


# ── SLAM IMPACT ──

func trigger_slam_impact(position, primary_target = null):
	if slam_final_finisher_active:
		trigger_final_enemy_finisher_impact(
			position,
			primary_target
		)

		slam_final_finisher_active = false
		slam_chain_progress = 0.0
		return

	var empowered = slam_chain_empowered

	var radius = (
		empowered_slam_aoe_radius
		if empowered
		else slam_aoe_radius
	)

	var damage = (
		empowered_slam_aoe_damage
		if empowered
		else slam_aoe_damage
	)

	var knockback = (
		empowered_slam_aoe_knockback
		if empowered
		else slam_aoe_knockback
	)

	var launch = (
		empowered_slam_aoe_launch_force
		if empowered
		else slam_aoe_launch_force
	)

	var stun = (
		empowered_slam_aoe_stun_time
		if empowered
		else slam_aoe_stun_time
	)

	shatter_panes_at_slam_impact(
		position,
		radius
	)

	var nearby = get_enemies_near(
		position,
		radius
	)

	for enemy in nearby:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

		if enemy.has_method("apply_hit_effect"):
			var direction = (
				enemy.global_position
				- position
			)

			direction.y = 0.0

			direction = (
				direction.normalized()
				if direction.length() > 0.01
				else Vector3.UP
			)

			enemy.apply_hit_effect(
				direction,
				knockback,
				launch,
				stun
			)

	slam_popup_burst(
		position,
		get_nearest_targets(
			position,
			nearby,
			slam_popup_projectile_count
		)
	)

	if empowered:
		create_empowered_slam_impact(position)
	else:
		spawn_flash_sphere(
			position + Vector3.UP * 0.2,
			slam_aoe_radius,
			ult_wave_materials[2],
			0.18
		)

	slam_chain_progress = 0.0

	if not empowered:
		slam_chain_empowered = false
		cancel_empowered_slam_state()


func trigger_final_enemy_finisher_impact(position, enemy):
	shatter_panes_at_slam_impact(
		position,
		slam_aoe_radius
	)

	if valid(enemy) and enemy.has_method("take_damage"):
		enemy.take_damage(final_finisher_damage)

	spawn_flash_sphere(
		position + Vector3.UP * 0.5,
		20.0,
		ult_wave_materials[0],
		0.24
	)

	if ult_wave_materials.size() > 2:
		spawn_flash_sphere(
			position + Vector3.UP * 0.8,
			14.0,
			ult_wave_materials[2],
			0.18
		)

	spawn_shard_burst(
		position + Vector3.UP,
		80,
		24.0,
		1.25,
		0.45
	)

	spawn_light_flash(
		position + Vector3.UP * 2.0,
		26.0,
		15.0,
		Color(0.8, 0.9, 1.0),
		0.30
	)


func create_empowered_slam_impact(position):
	# Giant outer blast.
	spawn_flash_sphere(
		position + Vector3.UP,
		empowered_slam_fx_radius,
		ult_wave_materials[0],
		0.34
	)

	# White-hot core.
	if ult_wave_materials.size() > 1:
		spawn_flash_sphere(
			position + Vector3.UP * 0.8,
			empowered_slam_fx_radius * 0.65,
			ult_wave_materials[1],
			0.24
		)

	# Magenta secondary wave.
	if ult_wave_materials.size() > 2:
		spawn_flash_sphere(
			position + Vector3.UP * 0.5,
			empowered_slam_fx_radius * 0.82,
			ult_wave_materials[2],
			0.28
		)

	spawn_shard_burst(
		position + Vector3.UP,
		150,
		empowered_slam_fx_radius * 0.85,
		1.9,
		0.68
	)

	spawn_light_flash(
		position + Vector3.UP * 3.0,
		empowered_slam_fx_radius,
		24.0,
		Color(0.65, 0.88, 1.0),
		0.50
	)

	# Strong final camera punch.
	if camera:
		camera.fov += 14.0

# ── SLAM POP-UP ──

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
		var projectile = (homing_projectile_scene.instantiate())
		var angle = (TAU * float(i) / float(max(count, 1)))
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = (position + Vector3(cos(angle), 0.0, sin(angle)) * slam_popup_projectile_radius + Vector3.UP * slam_popup_projectile_height)
		projectile.projectile_size = (slam_popup_projectile_size)
		projectile.damage = (slam_popup_projectile_damage)
		projectile.is_finisher_projectile = false
		projectile.target = enemy
		projectile.direction = (enemy.global_position - projectile.global_position).normalized()

func pop_enemy_to_lucian(enemy):
	if not enemy is CharacterBody3D:
		return
	var height = max(global_position.y - enemy.global_position.y, slam_popup_min_height)
	var speed_needed = sqrt(2.0 * slam_popup_gravity_reference * height)
	enemy.velocity.y = max(enemy.velocity.y, min(speed_needed, slam_popup_max_up_speed))

# ── ULT ──

func add_ult_charge(amount):
	if ult_ready:
		return
	ult_charge = clamp(ult_charge + amount, 0.0, ult_max_charge)
	ult_ready = (ult_charge >= ult_max_charge)
	update_ult_ui()

func try_activate_ult():
	if (not ult_ready or slam_camera_active or combat_recovery_timer > 0.0):
		return
	combat_recovery_timer = ultimate_recovery
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
	# A stained-glass rose opens under Lucian, a cathedral-like crown
	# erupts around him, then the whole shape detonates outward.
	screen_flash()
	camera_fov_pulse()

	var center = global_position + Vector3.UP * 1.0

	spawn_ult_rose_window(
		center,
		ult_rose_radius,
		ult_rose_spokes,
		0
	)

	spawn_ult_cathedral_crown(
		center,
		ult_crown_radius,
		ult_crown_expand_radius,
		ult_crown_shards,
		ult_crown_height,
		0
	)

	# A second offset layer makes the effect feel abstract and less like
	# a plain circular explosion.
	spawn_delayed_ult_style_layer(0.09)

	# Existing translucent shockwaves, now staggered more deliberately.
	for i in range(ult_wave_materials.size()):
		spawn_delayed_wave(
			0.08 + i * 0.07,
			ult_visual_radius * (0.72 + i * 0.22),
			ult_wave_materials[i]
		)

	spawn_shard_burst(
		center,
		ult_center_shard_count,
		ult_visual_radius * 0.78,
		1.65,
		0.68
	)

	spawn_light_flash(
		center + Vector3.UP * 1.5,
		ult_visual_radius,
		20.0,
		Color(0.62, 0.88, 1.0),
		0.46
	)


func spawn_delayed_ult_style_layer(delay):
	await get_tree().create_timer(delay).timeout

	if not is_inside_tree():
		return

	var center = global_position + Vector3.UP * 1.1

	spawn_ult_rose_window(
		center,
		ult_rose_radius * 0.72,
		max(12, int(ult_rose_spokes * 0.75)),
		2
	)

	spawn_ult_cathedral_crown(
		center,
		ult_crown_radius * 0.72,
		ult_crown_expand_radius * 0.82,
		max(16, int(ult_crown_shards * 0.72)),
		ult_crown_height * 0.72,
		2
	)


func spawn_ult_rose_window(center, radius, spoke_count, material_offset):
	if ult_wave_materials.is_empty():
		return

	var root = Node3D.new()
	root.name = "UltRoseWindow"
	get_tree().current_scene.add_child(root)
	root.global_position = center
	root.scale = Vector3.ONE * 0.08

	for i in range(max(spoke_count, 1)):
		var spoke = MeshInstance3D.new()
		var mesh = BoxMesh.new()

		var angle = (
			TAU
			* float(i)
			/ float(max(spoke_count, 1))
		)

		mesh.size = Vector3(
			0.16,
			ult_rose_height,
			radius
		)

		spoke.mesh = mesh
		spoke.material_override = ult_wave_materials[
			(i + material_offset)
			% ult_wave_materials.size()
		]

		root.add_child(spoke)

		spoke.position = Vector3(
			sin(angle) * radius * 0.28,
			0.0,
			cos(angle) * radius * 0.28
		)

		spoke.rotation.y = angle

	var tween = root.create_tween().set_parallel(true)

	tween.tween_property(
		root,
		"scale",
		Vector3.ONE * 1.15,
		ult_style_duration * 0.55
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		root,
		"rotation:y",
		root.rotation.y + deg_to_rad(52.0),
		ult_style_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(
		root,
		"scale",
		Vector3.ONE * 1.55,
		ult_style_duration * 0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.finished.connect(root.queue_free)


func spawn_ult_cathedral_crown(
	center,
	start_radius,
	end_radius,
	shard_count,
	height,
	material_offset
):
	if ult_wave_materials.is_empty():
		return

	var root = Node3D.new()
	root.name = "UltCathedralCrown"
	get_tree().current_scene.add_child(root)
	root.global_position = center

	var count = max(shard_count, 1)

	for i in range(count):
		var shard = MeshInstance3D.new()
		var mesh = BoxMesh.new()

		var angle = (
			TAU
			* float(i)
			/ float(count)
		)

		var height_variation = (
			height
			* randf_range(0.72, 1.18)
		)

		mesh.size = Vector3(
			randf_range(0.16, 0.34),
			height_variation,
			randf_range(0.35, 0.70)
		)

		shard.mesh = mesh
		shard.material_override = ult_wave_materials[
			(i + material_offset)
			% ult_wave_materials.size()
		]

		root.add_child(shard)

		shard.position = Vector3(
			sin(angle) * start_radius,
			height_variation * 0.34,
			cos(angle) * start_radius
		)

		shard.rotation = Vector3(
			deg_to_rad(randf_range(-11.0, 11.0)),
			angle,
			deg_to_rad(randf_range(-18.0, 18.0))
		)

		var outward = Vector3(
			sin(angle),
			randf_range(0.08, 0.28),
			cos(angle)
		).normalized()

		var target_position = Vector3(
			sin(angle) * end_radius,
			height_variation * 0.55,
			cos(angle) * end_radius
		)

		var shard_tween = shard.create_tween().set_parallel(true)

		shard_tween.tween_property(
			shard,
			"position",
			target_position,
			ult_style_duration
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		shard_tween.tween_property(
			shard,
			"rotation",
			shard.rotation
			+ Vector3(
				randf_range(0.7, 1.8),
				randf_range(1.5, 3.6),
				randf_range(0.7, 1.8)
			),
			ult_style_duration
		)

		shard_tween.tween_property(
			shard,
			"scale",
			Vector3(
				randf_range(0.25, 0.55),
				randf_range(1.15, 1.75),
				randf_range(0.25, 0.55)
			),
			ult_style_duration * 0.58
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		shard_tween.chain().tween_property(
			shard,
			"scale",
			Vector3.ZERO,
			ult_style_duration * 0.42
		)

	var root_tween = root.create_tween()

	root_tween.tween_property(
		root,
		"rotation:y",
		root.rotation.y + deg_to_rad(38.0),
		ult_style_duration
	)

	root_tween.finished.connect(root.queue_free)


func spawn_delayed_wave(delay, radius, material):
	await get_tree().create_timer(delay).timeout
	spawn_flash_sphere(global_position + Vector3.UP * 1.2, radius, material, 0.34)

func can_ult_shatter_enemy(enemy):
	if (not valid(enemy) or enemy.is_in_group("bosses") or enemy.is_in_group("elites")):
		return false
	var hp = get_property_if_exists(enemy, "max_health")
	if hp == null:
		hp = get_property_if_exists(enemy, "health")
	return (hp != null and float(hp) <= ult_weak_enemy_health)

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
	var position = (enemy.global_position + Vector3.UP)
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
		var direction = (enemy.global_position - global_position)
		direction.y = 0.0
		direction = (direction.normalized() if direction.length() > 0.01 else Vector3.UP)
		enemy.apply_hit_effect(direction, ult_knockback, ult_launch_force, ult_stun_time)
	spawn_shard_burst(enemy.global_position + Vector3.UP, 10, 6.0, 0.55, 0.35)

func get_property_if_exists(object, property_name):
	for info in object.get_property_list():
		if (String(info["name"]) == property_name):
			return object.get(property_name)
	return null

# ── TARGETING ──

func get_enemies():
	return (get_tree() .get_nodes_in_group("enemies"))

func is_usable_enemy(enemy, max_range, airborne_only = false):
	return (
		valid(enemy)
		and enemy is Node3D
		and global_position.distance_to(enemy.global_position) <= max_range
		and (not airborne_only or (enemy is CharacterBody3D and not enemy.is_on_floor()))
	)

func get_nearest_enemy(max_range, airborne_only = false):
	var nearest = null
	var nearest_distance = max_range
	for enemy in get_enemies():
		if not is_usable_enemy(enemy, max_range, airborne_only):
			continue
		var distance = (global_position.distance_to(enemy.global_position))
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func get_enemies_near(point, radius):
	var result = []
	for enemy in get_enemies():
		if (valid(enemy) and enemy is Node3D and point.distance_to(enemy.global_position) <= radius):
			result.append(enemy)
	return result

func get_nearest_targets(point, candidates, count):
	var remaining = (candidates.duplicate())
	var result = []
	while (not remaining.is_empty() and result.size() < count):
		var nearest = null
		var nearest_distance = INF
		for enemy in remaining:
			if not valid(enemy):
				continue
			var distance = (point.distance_squared_to(enemy.global_position))
			if (distance < nearest_distance):
				nearest = enemy
				nearest_distance = distance
		if nearest == null:
			break
		result.append(nearest)
		remaining.erase(nearest)
	return result

# ── LOCK ──

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
	var selected_index := 0
	var best_score := INF
	if camera:
		var screen_center := get_viewport().get_visible_rect().size * 0.5
		for i in range(lock_targets.size()):
			var target = lock_targets[i]
			var target_point: Vector3 = target.global_position + Vector3.UP * 1.2
			if camera.is_position_behind(target_point):
				continue
			var score: float = camera.unproject_position(target_point).distance_squared_to(screen_center)
			if score < best_score:
				best_score = score
				selected_index = i
	lock_index = selected_index
	locked_enemy = lock_targets[lock_index]
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
	locked_enemy = (lock_targets[ lock_index ])

func update_lock_camera(delta):
	if (slam_camera_active or teleport_hold_active or not valid(locked_enemy)):
		return
	var direction = (locked_enemy.global_position + Vector3.UP * 1.5 - global_position)
	direction.y = 0.0
	if direction.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), weight(lock_turn_speed, delta))

func update_lock_reticle():
	if not lock_reticle:
		return
	if (not valid(locked_enemy) or not camera):
		lock_reticle.hide()
		if not valid(locked_enemy):
			locked_enemy = null
		return
	lock_reticle.show()
	lock_reticle.position = (camera.unproject_position(locked_enemy.global_position + Vector3.UP * 2.5))

# ── VORTEX OF POETRY ──

func attack():
	combo_step = (1 if combo_step >= 3 else combo_step + 1)
	attacking = true
	dodge_preserved_combo = false
	combo_timer = combo_reset_time
	combo_melee_hit_ids.clear()
	var now := Time.get_ticks_msec()
	var perfectly_timed := last_combo_click_msec > 0 and float(now - last_combo_click_msec) <= perfect_click_window * 1000.0
	last_combo_click_msec = now
	# Hits one and two are always the readable core sword strings. Movement,
	# dodge, and air variants are reserved for the committed third hit.
	if combo_step == 3 and (is_dodging or dodge_chain_reset_timer > 0.0):
		await perform_dodge_cross_slash()
	elif combo_step == 3 and not is_on_floor():
		await perform_air_blade_strike(combo_step)
	elif combo_step == 3 and Vector2(velocity.x, velocity.z).length() >= running_attack_speed_threshold:
		await perform_running_glass_slash()
	else:
		await perform_melee_combo_step(combo_step, perfectly_timed)
	# A detected second click converts the opening cut into the committed
	# cyclone and owns the rest of this attack sequence.
	if sword_cyclone_active:
		return
	match combo_step:
		1:
			shoot_projectile(1)
		2:
			shoot_projectile(2)
		3:
			perform_vortex_finisher()
	var recovery: float = combo_hit_one_recovery
	if combo_step == 2:
		recovery = combo_hit_two_recovery
	elif combo_step == 3:
		recovery = combo_finisher_recovery
		attack_cancel_lock_timer = finisher_dodge_commitment
	combat_recovery_timer = recovery
	await get_tree().create_timer(recovery).timeout
	attacking = false

func perform_melee_combo_step(step: int, perfectly_timed: bool = false) -> void:
	# Acquire from Lucian's reticle, then retain that combat focus through this
	# combo. This guides only his body movement; it never takes over the camera.
	if not valid(melee_focus_target) or global_position.distance_to(melee_focus_target.global_position) > melee_focus_range:
		melee_focus_target = get_aim_target(melee_focus_range)
	var target = melee_focus_target
	var forward := global_transform.basis.z.normalized()
	if valid(target):
		var correction: Vector3 = target.global_position - global_position
		correction.y = 0.0
		if correction.length_squared() > 0.01:
			var desired_yaw := atan2(correction.normalized().x, correction.normalized().z)
			rotation.y = lerp_angle(rotation.y, desired_yaw, 0.92)
			forward = global_transform.basis.z.normalized()
	var step_distance: float = [melee_step_distances.x, melee_step_distances.y, melee_step_distances.z][step - 1]
	var side_sign: float = -1.0 if step == 1 else 1.0
	var center: Vector3 = global_position + forward * (melee_reach * 0.52 + step_distance) + global_transform.basis.x * side_sign * (1.6 if step < 3 else 0.0)
	var radius: float = melee_reach * (0.92 if step == 1 else (1.16 if step == 2 else 1.52))
	var branch_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var finisher_side: int = 0
	if step == 3 and absf(branch_input.x) >= directional_branch_threshold:
		finisher_side = -1 if branch_input.x < 0.0 else 1
	var lateral_sweep := finisher_side != 0
	var driving_finisher := step == 3 and branch_input.y <= -directional_branch_threshold
	start_sword_motion(step, forward, finisher_side, target)
	if lateral_sweep:
		# Left gathers a mob into an aerial vortex; right commits to a violent
		# arena-clearing shatter cleave.
		center = global_position + Vector3.UP
		radius *= left_finisher_gather_radius_multiplier if finisher_side < 0 else right_finisher_cleave_radius_multiplier
	spawn_stained_glass_blade(step, forward, perfectly_timed, finisher_side)
	if finisher_side < 0:
		# A second counter-rotating blade makes the left finisher read as a
		# glass vortex instead of a mirrored ordinary slash.
		spawn_stained_glass_blade(2, -forward, perfectly_timed, finisher_side)
	# Damage lands when the visible blade reaches the target, not on button
	# press. The finisher gets the clearest anticipation beat.
	var contact_delay: float = [melee_contact_delays.x, melee_contact_delays.y, melee_contact_delays.z][step - 1]
	await get_tree().create_timer(contact_delay).timeout
	# The sword's actual contact volume cuts glass as well as enemies.
	break_panes_in_enemy_attack(center, radius)
	var hit_any := false
	var primary_impact_position := Vector3.ZERO
	for enemy in get_enemies_near(center, radius):
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		if not lateral_sweep and to_enemy.length_squared() > 0.01 and forward.dot(to_enemy.normalized()) < (-0.28 if step < 3 else -0.12):
			continue
		combo_melee_hit_ids[enemy.get_instance_id()] = true
		if not hit_any:
			primary_impact_position = enemy.global_position + Vector3.UP
		hit_any = true
		var damage: float = [melee_damage_tiers.x, melee_damage_tiers.y, melee_damage_tiers.z][step - 1]
		var stagger: float = [melee_stagger_tiers.x, melee_stagger_tiers.y, melee_stagger_tiers.z][step - 1]
		var knockback: float = [melee_knockback_tiers.x, melee_knockback_tiers.y, melee_knockback_tiers.z][step - 1]
		var launch: float = [melee_launch_tiers.x, melee_launch_tiers.y, melee_launch_tiers.z][step - 1]
		# Side lanes become crowd launchers. The focused center of Swing 1 pops
		# straight up; Swing 2 keeps its center target close.
		var lateral_distance := absf(global_transform.basis.x.normalized().dot(to_enemy))
		var in_center_lane := step < 3 and forward.dot(to_enemy) > 0.0 and lateral_distance <= combo_center_lane_half_width
		if step == 1 and in_center_lane:
			# Opening Verse pops the focused target vertically for a deliberate
			# air route without throwing it away from Lucian.
			knockback = 0.0
			launch = swing_one_center_launch
		elif in_center_lane:
			knockback = combo_center_knockback
			launch = combo_center_launch
		elif step == 1:
			launch = combo_side_launch.x
		elif step == 2:
			launch = combo_side_launch.y
		if driving_finisher:
			knockback *= driving_finisher_knockback_multiplier
			launch = driving_finisher_launch
		var hit_direction: Vector3 = to_enemy.normalized() if to_enemy.length_squared() > 0.01 else forward
		if finisher_side < 0:
			# Pull the ring inward and pop it up for an aerial continuation.
			hit_direction = -hit_direction
			knockback = left_finisher_inward_force
			launch = left_finisher_launch
		elif finisher_side > 0:
			# Every victim is carved across the same side of the arena, producing
			# a readable wall of frantic airborne ragdolls.
			hit_direction = global_transform.basis.x.normalized()
			knockback = right_finisher_sweep_force
			launch = right_finisher_launch
		hit_enemy(enemy, damage, knockback, launch, stagger, hit_direction)
		if step == 3 and finisher_auto_air_carry and not driving_finisher and not valid(vortex_carry_target):
			start_vortex_air_carry(enemy)
		if enemy.has_method("apply_break_damage"):
			var break_damage: float = [melee_break_tiers.x, melee_break_tiers.y, melee_break_tiers.z][step - 1]
			enemy.apply_break_damage(break_damage * (1.35 if perfectly_timed else 1.0))
		spawn_shard_burst(enemy.global_position + Vector3.UP, blade_shard_count + step * 8, 6.0 + step * 2.0, 0.55 + step * 0.18, 0.22)
	if hit_any:
		# Briefly arrest Lucian's attack lunge to suggest resistance without
		# physically colliding or stealing movement control for long.
		velocity.x *= melee_contact_brake
		velocity.z *= melee_contact_brake
		sword_motion_velocity *= melee_contact_brake
		rift_cleave_timer = maxf(0.0, rift_cleave_timer - melee_cooldown_refund)
		ruin_volley_timer = maxf(0.0, ruin_volley_timer - melee_cooldown_refund)
		camera.fov += 1.5 + step * 1.2 if camera else 0.0
		var impact_energy: float = [melee_impact_light_energy.x, melee_impact_light_energy.y, melee_impact_light_energy.z][step - 1]
		var impact_radius: float = [melee_impact_flash_radius.x, melee_impact_flash_radius.y, melee_impact_flash_radius.z][step - 1]
		spawn_light_flash(primary_impact_position, impact_radius, impact_energy, Color(0.82, 0.92, 1.0), 0.075 if step < 3 else 0.12)

func perform_running_glass_slash() -> void:
	var forward: Vector3 = global_transform.basis.z.normalized()
	velocity.x = forward.x * 42.0
	velocity.z = forward.z * 42.0
	await perform_melee_combo_step(1, false)

func perform_dodge_cross_slash() -> void:
	var forward: Vector3 = dodge_direction if dodge_direction.length_squared() > 0.01 else global_transform.basis.z
	velocity.x = forward.normalized().x * 48.0
	velocity.z = forward.normalized().z * 48.0
	await perform_melee_combo_step(2, true)

func perform_air_blade_strike(step: int) -> void:
	velocity.y = maxf(velocity.y, aerial_suspension_speed)
	await perform_melee_combo_step(step, false)
	if step == 3:
		velocity.y = maxf(velocity.y, 8.0)

func perform_teleport_backslash() -> void:
	if not valid(slam_target):
		return
	attacking = true
	combo_step = 3
	combo_timer = maxf(combo_timer, 1.4)
	var target = slam_target
	clear_teleport_followup()
	var away: Vector3 = target.global_position - global_position
	away.y = 0.0
	if away.length_squared() > 0.01:
		rotation.y = atan2(away.normalized().x, away.normalized().z)
	await perform_melee_combo_step(3, true)
	# The combo step yields for its windup/impact timing. The selected enemy can
	# die during that window, so never dereference the cached target afterward
	# without checking that the Object still exists.
	if is_instance_valid(target) and target.has_method("apply_break_damage"):
		target.apply_break_damage(teleport_backslash_break)
	perform_vortex_finisher()
	combat_recovery_timer = combo_finisher_recovery
	await get_tree().create_timer(combo_finisher_recovery).timeout
	attacking = false

func start_vortex_air_carry(enemy: Node3D) -> void:
	if not valid(enemy):
		return
	vortex_carry_target = enemy
	vortex_carry_timer = vortex_carry_duration
	velocity.y = maxf(velocity.y, vortex_carry_vertical_speed)
	low_gravity_timer = maxf(low_gravity_timer, vortex_carry_duration + 0.25)
	combo_timer = maxf(combo_timer, vortex_carry_duration + 0.65)
	if enemy is CharacterBody3D:
		enemy.velocity.y = maxf(enemy.velocity.y, vortex_carry_vertical_speed)
	spawn_shard_burst(global_position + Vector3.UP * 1.5, blade_shard_count * 2, 12.0, 0.9, 0.32)

func update_vortex_air_carry(delta: float) -> void:
	if vortex_carry_timer <= 0.0 or not valid(vortex_carry_target):
		vortex_carry_timer = 0.0
		vortex_carry_target = null
		return
	vortex_carry_timer = maxf(0.0, vortex_carry_timer - delta)
	var from_enemy: Vector3 = global_position - vortex_carry_target.global_position
	from_enemy.y = 0.0
	if from_enemy.length_squared() < 0.01:
		from_enemy = global_transform.basis.x
	var desired_position: Vector3 = vortex_carry_target.global_position + from_enemy.normalized() * vortex_carry_side_distance + Vector3.UP * vortex_carry_height_offset
	var correction: Vector3 = desired_position - global_position
	velocity.x = move_toward(velocity.x, correction.x * 9.0, vortex_carry_follow_speed * delta)
	velocity.z = move_toward(velocity.z, correction.z * 9.0, vortex_carry_follow_speed * delta)
	if vortex_carry_target is CharacterBody3D:
		velocity.y = maxf(velocity.y, vortex_carry_target.velocity.y - 1.0)
	else:
		velocity.y = maxf(velocity.y, aerial_suspension_speed)
	aim_camera_pitch_at(vortex_carry_target.global_position + Vector3.UP, 0.72, delta)

func spawn_stained_glass_blade(step: int, forward: Vector3, empowered: bool, finisher_side: int = 0) -> void:
	var pivot := Node3D.new()
	add_child(pivot)
	# Start at the animated hand instead of a guessed body-space point. Clamp
	# it to Lucian's front plane so a backswing pose cannot originate behind him.
	var hand_origin := blade_hand_offset
	if character_skeleton:
		var hand_bone := character_skeleton.find_bone("arm_right_hand")
		if hand_bone >= 0:
			var hand_world: Vector3 = character_skeleton.to_global(character_skeleton.get_bone_global_pose(hand_bone).origin)
			hand_origin = to_local(hand_world)
			hand_origin = hand_origin.lerp(blade_hand_offset, blade_hand_anchor_stability)
	hand_origin.z = maxf(hand_origin.z, 0.55)
	pivot.position = hand_origin
	var blade := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	var blade_length := 8.5 + step * 3.0
	mesh.size = Vector3(0.72 + step * 0.28, 0.42 + step * 0.18, blade_length)
	blade.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.3, 0.75, 1.0, 0.78) if step == 1 else (Color(0.85, 0.2, 1.0, 0.82) if step == 2 else Color(1.0, 0.18, 0.48, 0.92))
	if empowered:
		material.albedo_color = Color(1.0, 0.82, 0.22, 0.95)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = blade_flash_energy
	blade.material_override = material
	pivot.add_child(blade)
	blade.position = Vector3(0.0, 0.0, blade_length * 0.5)
	# A bright narrow core gives the construct a readable cutting edge rather
	# than the silhouette of a large translucent block.
	var core := MeshInstance3D.new()
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(0.16 + step * 0.07, 0.12 + step * 0.05, blade_length * 0.94)
	core.mesh = core_mesh
	var core_material := material.duplicate() as StandardMaterial3D
	core_material.albedo_color = Color(0.92, 0.98, 1.0, 0.9)
	core_material.emission = core_material.albedo_color
	core_material.emission_energy_multiplier = blade_flash_energy * 1.25
	core.material_override = core_material
	core.position = Vector3(0.0, 0.0, blade_length * 0.5)
	pivot.add_child(core)
	var start_rotation := Vector3.ZERO
	var end_rotation := Vector3.ZERO
	if step == 1:
		start_rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(-blade_horizontal_arc_degrees), deg_to_rad(-18.0))
		end_rotation = Vector3(deg_to_rad(5.0), deg_to_rad(blade_horizontal_arc_degrees), deg_to_rad(14.0))
	elif step == 2:
		start_rotation = Vector3(deg_to_rad(5.0), deg_to_rad(blade_horizontal_arc_degrees), deg_to_rad(20.0))
		end_rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(-blade_horizontal_arc_degrees), deg_to_rad(-16.0))
	elif finisher_side < 0:
		# Rising corkscrew cut for the gathering vortex.
		pivot.position = Vector3(hand_origin.x, minf(hand_origin.y, 0.72), maxf(hand_origin.z, 0.9))
		start_rotation = Vector3(deg_to_rad(24.0), deg_to_rad(-132.0), deg_to_rad(-58.0))
		end_rotation = Vector3(deg_to_rad(-62.0), deg_to_rad(138.0), deg_to_rad(42.0))
	elif finisher_side > 0:
		# Huge shoulder-to-floor diagonal cleave with a longer silhouette.
		pivot.position = Vector3(hand_origin.x, hand_origin.y + 0.8, maxf(hand_origin.z, 0.9))
		start_rotation = Vector3(deg_to_rad(-34.0), deg_to_rad(102.0), deg_to_rad(72.0))
		end_rotation = Vector3(deg_to_rad(48.0), deg_to_rad(-118.0), deg_to_rad(-46.0))
	else:
		# Huge low-to-high sword arc, ending where the vortex orbs erupt.
		pivot.position = Vector3(hand_origin.x, minf(hand_origin.y, 0.82), maxf(hand_origin.z, 0.9))
		# Keep this as a clean forward vertical cut in Lucian's +Z convention.
		start_rotation = Vector3(deg_to_rad(78.0), 0.0, deg_to_rad(-8.0))
		end_rotation = Vector3(deg_to_rad(-82.0), 0.0, deg_to_rad(6.0))
	pivot.rotation = start_rotation
	var tween := create_tween()
	var full_scale := Vector3.ONE * (1.45 if step == 3 else 1.0)
	if finisher_side > 0:
		full_scale.z *= 1.28
	blade.scale = Vector3(0.18, 0.18, 0.05)
	core.scale = Vector3(0.1, 0.1, 0.04)
	tween.tween_property(blade, "scale", full_scale, blade_assembly_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(core, "scale", full_scale, blade_assembly_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pivot, "rotation", end_rotation, blade_cut_time if step < 3 else blade_cut_time * 1.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_interval(blade_follow_through_time)
	tween.tween_property(blade, "scale", Vector3(1.18, 0.16, 0.72), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(core, "scale", Vector3(1.4, 0.05, 0.45), 0.055)
	tween.parallel().tween_property(blade, "transparency", 1.0, 0.055)
	tween.parallel().tween_property(core, "transparency", 1.0, 0.055)
	tween.tween_callback(pivot.queue_free)

func spawn_final_word_floor_cracks(center: Vector3) -> void:
	for i in range(12):
		var crack := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var length := randf_range(4.0, 10.0)
		mesh.size = Vector3(0.11, 0.035, length)
		crack.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.72, 0.18, 1.0, 0.9)
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 9.0
		crack.material_override = material
		get_tree().current_scene.add_child(crack)
		var angle := TAU * float(i) / 12.0 + randf_range(-0.12, 0.12)
		crack.global_position = center + Vector3(cos(angle), 0.06, sin(angle)) * length * 0.42
		crack.rotation.y = -angle
		var tween := create_tween()
		crack.scale = Vector3(0.05, 1.0, 0.05)
		tween.tween_property(crack, "scale", Vector3.ONE, 0.07)
		tween.tween_interval(0.18)
		tween.tween_property(crack, "transparency", 1.0, 0.2)
		tween.tween_callback(crack.queue_free)

func perform_vortex_finisher():
	var target = get_aim_target(finisher_target_range)
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
				projectile.projectile_size = 0.46
				projectile.damage = 9
			2:
				projectile.projectile_size = 0.42
				projectile.damage = 6
			3:
				projectile.projectile_size = 1.0
				projectile.damage = finisher_projectile_damage
				projectile.is_finisher_projectile = true
				projectile.finisher_id = finisher_id
				projectile.finisher_hit_count = amount
				projectile.target = finisher_target
				projectile.orbit_index = i
				projectile.orbit_count = amount
				projectile.damage *= run_projectile_damage_multiplier
		spawn_projectile(projectile)

func create_projectile():
	var scene = homing_projectile_scene if combo_step == 3 else projectile_scene
	if not scene:
		return null
	var projectile = scene.instantiate()
	if combo_step != 3:
		# Only soft-home toward something the player is actually aiming at.
		projectile.target = get_normal_projectile_target()
		if valid(projectile.target) and combo_melee_hit_ids.has(projectile.target.get_instance_id()):
			# The blade already hit this enemy; carry the wave through to the group behind it.
			projectile.target = null
	return projectile

func get_normal_projectile_target():
	return get_aim_target(aim_assist_range)

func get_aim_target(max_range):
	# No soft/automatic lock. Attacks stay freely directional until the
	# player explicitly acquires a target with the lock button.
	if is_usable_enemy(locked_enemy, max_range):
		return locked_enemy
	return null

func get_reticle_aim_point():
	if not camera:
		return global_position + (global_transform.basis.z * aim_distance)

	# Shoot a ray directly through the exact center of the screen.
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size * 0.5
	var ray_origin = camera.project_ray_origin(center)
	var ray_direction = camera.project_ray_normal(center).normalized()
	var ray_end = ray_origin + ray_direction * aim_distance

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = aim_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]

	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit.position

	return ray_end

func spawn_projectile(projectile):
	get_tree().current_scene.add_child(projectile)
	var forward = global_transform.basis.z.normalized()
	var right = global_transform.basis.x.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * projectile_spawn_height
		+ forward * maxf(projectile_spawn_forward, melee_wave_start_distance)
		+ right * projectile_spawn_side
	)

	# Important: calculate FROM the projectile spawn TO the reticle point.
	# This removes third-person camera/parallax aiming error.
	var aim_point = get_reticle_aim_point()
	if valid(projectile.target):
		aim_point = projectile.target.global_position + Vector3.UP * 1.2
	var aim_direction = aim_point - projectile.global_position
	projectile.direction = aim_direction.normalized() if aim_direction.length() > 0.01 else forward

# ── FX ──

func spawn_shard_burst(position, count, distance, size_scale = 1.0, duration = 0.45):
	if shard_materials.is_empty():
		return
	for i in range(max(count, 1)):
		var shard = (MeshInstance3D.new())
		var mesh = BoxMesh.new()
		mesh.size = Vector3(randf_range(0.12, 0.42), randf_range(0.05, 0.16), randf_range(0.35, 0.95)) * size_scale
		shard.mesh = mesh
		shard.material_override = (shard_materials[ i % shard_materials.size() ])
		get_tree().current_scene.add_child(shard)
		var angle = (TAU * float(i) / float(max(count, 1)) + randf_range(-0.18, 0.18))
		var direction = Vector3(cos(angle), randf_range(0.15, 0.95), sin(angle)).normalized()
		shard.global_position = (position + direction * randf_range(0.1, 1.2) * size_scale)
		shard.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
		var tween = (shard.create_tween() .set_parallel(true))
		tween.tween_property(shard, "global_position", shard.global_position + direction * distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", shard.rotation + Vector3(randf_range(2.0, 6.0), randf_range(2.0, 6.0), randf_range(2.0, 6.0)), duration)
		tween.tween_property(shard, "scale", Vector3.ZERO, duration)
		tween.finished.connect(shard.queue_free)

func spawn_flash_sphere(position, radius, material, duration = 0.28):
	var sphere = (MeshInstance3D.new())
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

	flash.color = Color(
		0.70,
		0.90,
		1.0,
		1.0
	)

	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.72

	var tween = flash.create_tween().set_parallel(true)

	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		ult_screen_flash_time
	)

	tween.tween_property(
		flash,
		"color",
		Color(
			1.0,
			0.18,
			0.72,
			0.0
		),
		ult_screen_flash_time
	)

	tween.finished.connect(layer.queue_free)


func camera_fov_pulse():
	if camera:
		camera.fov += 8.0

# ── UI ──

func setup_ui():
	if health_bar:
		health_bar.hide()
	setup_reliquary_ui()
	var follow = create_meter_ui(20, Control.PRESET_CENTER_BOTTOM, Vector4(-240, -115, 240, -45), "", teleport_followup_window, Vector2(460, 8))
	followup_ui = follow[0]
	followup_label = follow[1]
	followup_bar = follow[2]
	followup_ui.hide()
	setup_aim_reticle()
	update_ult_ui()

func setup_reliquary_ui():
	var layer := CanvasLayer.new()
	layer.layer = 24
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	root.offset_left = -470.0
	root.offset_top = -250.0
	root.offset_right = -20.0
	root.offset_bottom = -20.0
	root.pivot_offset = Vector2(450.0, 230.0)
	root.scale = Vector2.ONE * 0.62
	layer.add_child(root)
	reliquary_frame = PanelContainer.new()
	reliquary_frame.position = Vector2(270, 20)
	reliquary_frame.size = Vector2(172, 180)
	reliquary_frame.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.055, 0.035, 0.07, 0.96), Color(0.82, 0.65, 0.25), 4, 28))
	root.add_child(reliquary_frame)
	var inner := PanelContainer.new()
	inner.position = Vector2(19, 22)
	inner.size = Vector2(134, 134)
	inner.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.15, 0.1, 0.17, 1.0), Color(0.48, 0.31, 0.72), 5, 67))
	reliquary_frame.add_child(inner)
	reliquary_portrait = Label.new()
	reliquary_portrait.text = "L"
	reliquary_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reliquary_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reliquary_portrait.add_theme_font_size_override("font_size", 54)
	reliquary_portrait.add_theme_color_override("font_color", Color(0.95, 0.92, 0.96))
	inner.add_child(reliquary_portrait)
	var rail_back := Polygon2D.new()
	rail_back.polygon = PackedVector2Array([Vector2(0, 164), Vector2(88, 124), Vector2(404, 124), Vector2(380, 166), Vector2(92, 166), Vector2(14, 198)])
	rail_back.color = Color(0.78, 0.6, 0.21, 1.0)
	root.add_child(rail_back)
	var rail_inner := Polygon2D.new()
	rail_inner.polygon = PackedVector2Array([Vector2(8, 166), Vector2(92, 130), Vector2(394, 130), Vector2(376, 158), Vector2(89, 158), Vector2(17, 188)])
	rail_inner.color = Color(0.055, 0.04, 0.075, 0.98)
	root.add_child(rail_inner)
	reliquary_loss_bar = ProgressBar.new()
	reliquary_loss_bar.position = Vector2(92, 138)
	reliquary_loss_bar.size = Vector2(280, 16)
	reliquary_loss_bar.max_value = max_health
	reliquary_loss_bar.value = health
	reliquary_loss_bar.show_percentage = false
	reliquary_loss_bar.add_theme_stylebox_override("background", make_reliquary_style(Color(0.05, 0.035, 0.06), Color(0.16, 0.12, 0.18), 1, 4))
	reliquary_loss_bar.add_theme_stylebox_override("fill", make_reliquary_style(Color(0.95, 0.72, 0.42), Color(1.0, 0.88, 0.58), 1, 4))
	root.add_child(reliquary_loss_bar)
	reliquary_health_bar = ProgressBar.new()
	reliquary_health_bar.position = Vector2(94, 140)
	reliquary_health_bar.size = Vector2(276, 12)
	reliquary_health_bar.max_value = max_health
	reliquary_health_bar.value = health
	reliquary_health_bar.show_percentage = false
	reliquary_health_bar.add_theme_stylebox_override("background", make_reliquary_style(Color(0.04, 0.025, 0.045), Color(0.18, 0.12, 0.2), 1, 4))
	reliquary_health_bar.add_theme_stylebox_override("fill", make_reliquary_style(Color(0.68, 0.02, 0.1), Color(1.0, 0.24, 0.28), 1, 4))
	root.add_child(reliquary_health_bar)
	ult_bar = ProgressBar.new()
	ult_bar.position = Vector2(96, 160)
	ult_bar.size = Vector2(272, 7)
	ult_bar.max_value = ult_max_charge
	ult_bar.value = ult_charge
	ult_bar.show_percentage = false
	ult_bar.add_theme_stylebox_override("background", make_reliquary_style(Color(0.025, 0.018, 0.04), Color(0.2, 0.14, 0.28), 1, 3))
	ult_bar.add_theme_stylebox_override("fill", make_reliquary_style(Color(0.48, 0.16, 0.86), Color(0.82, 0.5, 1.0), 1, 3))
	root.add_child(ult_bar)
	ult_label = Label.new()
	ult_label.text = "Q"
	ult_label.position = Vector2(372, 151)
	ult_label.add_theme_font_size_override("font_size", 10)
	ult_label.add_theme_color_override("font_color", Color(0.74, 0.52, 0.95))
	root.add_child(ult_label)
	var vitality := Label.new()
	vitality.text = "VITALITY"
	vitality.position = Vector2(12, 194)
	vitality.add_theme_font_size_override("font_size", 12)
	vitality.add_theme_color_override("font_color", Color(0.82, 0.78, 0.84))
	root.add_child(vitality)
	reliquary_critical_notch = Label.new()
	reliquary_critical_notch.text = "◀"
	reliquary_critical_notch.position = Vector2(296, 151)
	reliquary_critical_notch.add_theme_font_size_override("font_size", 10)
	root.add_child(reliquary_critical_notch)
	for i in range(4):
		var holder := Control.new()
		holder.position = Vector2(96 + i * 58, 181)
		holder.size = Vector2(42, 42)
		root.add_child(holder)
		var diamond := PanelContainer.new()
		diamond.position = Vector2(6, 6)
		diamond.size = Vector2(30, 30)
		diamond.rotation = PI * 0.25
		diamond.pivot_offset = Vector2(15, 15)
		diamond.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.12, 0.14, 0.19), Color(0.82, 0.65, 0.25), 2, 2))
		var glyph := Label.new()
		glyph.text = ["RMB", "F", "E", "Q"][i]
		glyph.rotation = -PI * 0.25
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 9)
		diamond.add_child(glyph)
		holder.add_child(diamond)
		reliquary_ability_diamonds.append(diamond)
	open_arsenal_label = Label.new()
	open_arsenal_label.position = Vector2(78, 104)
	open_arsenal_label.size = Vector2(285, 24)
	open_arsenal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	open_arsenal_label.add_theme_font_size_override("font_size", 13)
	open_arsenal_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.12))
	root.add_child(open_arsenal_label)
	reliquary_status_label = Label.new()
	reliquary_status_label.text = "◆  ◆  ◆"
	reliquary_status_label.position = Vector2(300, 91)
	reliquary_status_label.add_theme_font_size_override("font_size", 11)
	reliquary_status_label.add_theme_color_override("font_color", Color(0.66, 0.5, 0.86))
	root.add_child(reliquary_status_label)
	update_reliquary_ui()

func setup_reliquary_ui_legacy():
	var layer := CanvasLayer.new()
	layer.layer = 24
	add_child(layer)
	reliquary_frame = PanelContainer.new()
	layer.add_child(reliquary_frame)
	reliquary_frame.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	reliquary_frame.offset_left = -448.0
	reliquary_frame.offset_top = -148.0
	reliquary_frame.offset_right = -24.0
	reliquary_frame.offset_bottom = -24.0
	reliquary_frame.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.018, 0.02, 0.03, 0.9), Color(0.38, 0.4, 0.46), 2, 12))
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	reliquary_frame.add_child(root)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(330, 0)
	info.add_theme_constant_override("separation", 2)
	root.add_child(info)
	var title := Label.new()
	title.text = "LUCIAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.9, 0.91, 0.95))
	info.add_child(title)
	reliquary_loss_bar = ProgressBar.new()
	reliquary_loss_bar.max_value = max_health
	reliquary_loss_bar.value = health
	reliquary_loss_bar.show_percentage = false
	reliquary_loss_bar.custom_minimum_size = Vector2(325, 18)
	reliquary_loss_bar.add_theme_stylebox_override("background", make_reliquary_style(Color(0.035, 0.025, 0.035), Color(0.22, 0.23, 0.28), 2, 8))
	reliquary_loss_bar.add_theme_stylebox_override("fill", make_reliquary_style(Color(0.92, 0.72, 0.5), Color(1.0, 0.9, 0.68), 1, 7))
	info.add_child(reliquary_loss_bar)
	reliquary_health_bar = ProgressBar.new()
	reliquary_health_bar.max_value = max_health
	reliquary_health_bar.value = health
	reliquary_health_bar.show_percentage = false
	reliquary_health_bar.custom_minimum_size = Vector2(325, 10)
	reliquary_health_bar.add_theme_stylebox_override("background", make_reliquary_style(Color(0.025, 0.018, 0.028), Color(0.16, 0.17, 0.22), 2, 5))
	reliquary_health_bar.add_theme_stylebox_override("fill", make_reliquary_style(Color(0.62, 0.008, 0.045), Color(0.95, 0.16, 0.2), 1, 5))
	info.add_child(reliquary_health_bar)
	reliquary_critical_notch = Label.new()
	reliquary_critical_notch.text = "                         ◀ CRITICAL QUARTER"
	reliquary_critical_notch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reliquary_critical_notch.add_theme_font_size_override("font_size", 8)
	reliquary_critical_notch.add_theme_color_override("font_color", Color(0.52, 0.54, 0.6))
	info.add_child(reliquary_critical_notch)
	var ability_row := HBoxContainer.new()
	ability_row.alignment = BoxContainer.ALIGNMENT_END
	ability_row.add_theme_constant_override("separation", 7)
	info.add_child(ability_row)
	for ability_name in ["RMB", "PANE", "SLAM", "ULT"]:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(39, 39)
		ability_row.add_child(holder)
		var diamond := PanelContainer.new()
		diamond.position = Vector2(5, 5)
		diamond.size = Vector2(29, 29)
		diamond.rotation = PI * 0.25
		diamond.pivot_offset = Vector2(14.5, 14.5)
		diamond.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.12, 0.14, 0.19, 0.95), Color(0.55, 0.58, 0.68), 2, 4))
		var glyph := Label.new()
		glyph.text = ability_name
		glyph.rotation = -PI * 0.25
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 7)
		diamond.add_child(glyph)
		holder.add_child(diamond)
		reliquary_ability_diamonds.append(diamond)
	open_arsenal_label = Label.new()
	open_arsenal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	open_arsenal_label.add_theme_font_size_override("font_size", 11)
	open_arsenal_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.12))
	info.add_child(open_arsenal_label)
	var portrait_shell := PanelContainer.new()
	portrait_shell.custom_minimum_size = Vector2(82, 108)
	portrait_shell.add_theme_stylebox_override("panel", make_reliquary_style(Color(0.055, 0.04, 0.07, 0.98), Color(0.62, 0.64, 0.7), 3, 18))
	root.add_child(portrait_shell)
	reliquary_portrait = Label.new()
	reliquary_portrait.text = "♜\nL"
	reliquary_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reliquary_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reliquary_portrait.add_theme_font_size_override("font_size", 23)
	reliquary_portrait.add_theme_color_override("font_color", Color(0.83, 0.85, 0.92))
	portrait_shell.add_child(reliquary_portrait)
	reliquary_status_label = Label.new()
	reliquary_status_label.text = "◆  ◆  ◆"
	reliquary_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reliquary_status_label.add_theme_font_size_override("font_size", 9)
	reliquary_status_label.add_theme_color_override("font_color", Color(0.62, 0.66, 0.75))
	portrait_shell.add_child(reliquary_status_label)
	update_reliquary_ui()

func make_reliquary_style(fill: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func update_reliquary_ui():
	if not reliquary_frame:
		return
	var health_ratio: float = float(health) / maxf(float(max_health), 1.0)
	var critical: bool = health_ratio <= 0.25
	if reliquary_portrait:
		reliquary_portrait.modulate = Color(1.0, 0.42, 0.46) if critical else Color.WHITE
		reliquary_portrait.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.035 if critical else 1.0)
	if reliquary_critical_notch:
		reliquary_critical_notch.add_theme_color_override("font_color", Color(1.0, 0.2, 0.24) if critical else Color(0.52, 0.54, 0.6))
	# Right click changes from teleport to pane pull whenever movement panes are
	# active, so its HUD slot follows the cooldown of the action it will cast.
	var right_click_ready: bool = (
		pane_pull_cooldown_timer <= 0.0
		if get_walk_pane_count() > 0
		else teleport_cooldown_timer <= 0.0
	)
	var ready_states := [right_click_ready, rift_cleave_timer <= 0.0, ruin_volley_timer <= 0.0, ult_ready]
	for i in range(reliquary_ability_diamonds.size()):
		var diamond := reliquary_ability_diamonds[i]
		var ability_ready: bool = ready_states[i] == true
		var fill: Color = Color(0.13, 0.24, 0.34, 0.98) if ability_ready else Color(0.035, 0.035, 0.05, 0.95)
		var edge: Color = Color(0.55, 0.84, 1.0) if ability_ready else Color(0.22, 0.23, 0.28)
		if open_arsenal_active and not ability_ready:
			fill = Color(0.3, 0.18, 0.035, 0.98)
			edge = Color(1.0, 0.7, 0.12)
		diamond.add_theme_stylebox_override("panel", make_reliquary_style(fill, edge, 2, 4))

func begin_open_arsenal(duration: float):
	open_arsenal_active = true
	open_arsenal_timer = duration
	open_arsenal_saved_teleport = teleport_cooldown_timer
	teleport_cooldown_timer = 0.0
	if open_arsenal_label:
		open_arsenal_label.text = "OPEN ARSENAL  %.1f" % duration

func end_open_arsenal():
	if not open_arsenal_active:
		return
	open_arsenal_active = false
	teleport_cooldown_timer = maxf(teleport_cooldown_timer, maxf(0.0, open_arsenal_saved_teleport - 4.0))
	if open_arsenal_label:
		open_arsenal_label.text = ""

func setup_aim_reticle():
	var layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	aim_reticle = Label.new()
	aim_reticle.text = "◇"
	aim_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_reticle.add_theme_font_size_override("font_size", 34)
	aim_reticle.add_theme_color_override("font_color", Color(0.72, 0.90, 1.0, 1.0))
	aim_reticle.add_theme_color_override("font_shadow_color", Color(1.0, 0.12, 0.70, 0.85))
	aim_reticle.add_theme_constant_override("shadow_offset_x", 2)
	aim_reticle.add_theme_constant_override("shadow_offset_y", 2)
	aim_reticle.custom_minimum_size = Vector2(46.0, 46.0)
	aim_reticle.pivot_offset = Vector2(23.0, 23.0)
	layer.add_child(aim_reticle)

	# The targeting mark only exists visually while an enemy is acquired.
	aim_reticle.hide()

func update_aim_reticle():
	if not aim_reticle:
		return

	aim_reticle_target = get_aim_target(aim_assist_range)

	# No enemy acquired: disappear instead of returning to screen center.
	if not valid(aim_reticle_target) or not camera:
		aim_reticle.hide()
		return

	var target_point = aim_reticle_target.global_position + Vector3.UP * 1.2

	if camera.is_position_behind(target_point):
		aim_reticle.hide()
		return

	aim_reticle.show()

	var screen_point = camera.unproject_position(target_point)
	aim_reticle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	aim_reticle.position = screen_point - Vector2(23.0, 23.0)

	# Subtle gothic/glass pulse while locked.
	var time = float(Time.get_ticks_msec())
	var pulse = 1.0 + sin(time * 0.010) * 0.10
	aim_reticle.scale = Vector2.ONE * pulse
	aim_reticle.rotation = sin(time * 0.004) * 0.08

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
	label.horizontal_alignment = (HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_size_override("font_size", 20)
	bar.max_value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = bar_size
	root.add_child(label)
	root.add_child(bar)
	return [
		root,
		label,
		bar
	]

func update_followup_ui():
	if not followup_ui:
		return
	var available = (teleport_followup_timer > 0.0 and valid(teleport_focus_target) and slam_windup_timer <= 0.0)
	followup_ui.visible = available
	if not available:
		return
	followup_bar.max_value = (teleport_followup_window)
	followup_bar.value = (teleport_followup_timer)
	if can_trigger_final_enemy_finisher(slam_target):
		followup_label.text = "[ LMB ] FINAL PANE FINISHER      [ SPACE ] GLASS ARENA"
	else:
		followup_label.text = "[ LMB ] SLAM      [ SPACE ] GLASS ARENA"

func update_pane_counter_ui():
	# The old movement-pane counter no longer has a HUD element.
	pass

func update_ult_ui():
	if not ult_bar:
		return
	ult_bar.max_value = ult_max_charge
	ult_bar.value = ult_charge
	ult_label.text = "Q!" if ult_ready else "Q"
	ult_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.28) if ult_ready else Color(0.74, 0.52, 0.95))

# ── HEALTH / ANIMATION / FLASH ──

func _on_hurtbox_body_entered(_body):
	pass

func take_damage(amount):
	if (dodge_invincible or hit_invincible):
		return
	hit_invincible = true
	health -= amount
	if health_bar:
		health_bar.value = health
	if reliquary_health_bar:
		reliquary_health_bar.value = health
	if reliquary_loss_bar:
		var loss_tween := create_tween()
		loss_tween.tween_interval(0.45)
		loss_tween.tween_property(reliquary_loss_bar, "value", health, 0.22)
	if health <= 0:
		die()
		return
	flash_red()
	await get_tree().create_timer(hit_invincibility_time).timeout
	hit_invincible = false
	if not dodge_invincible:
		remove_flash()

func apply_enemy_knockback(direction: Vector3, strength: float, duration: float = 0.28):
	if dodge_invincible:
		return
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return
	enemy_knockback_velocity = direction.normalized() * strength
	enemy_knockback_timer = duration

func die():
	release_teleport_hold()
	force_end_glass_block(false)
	if slam_camera_active:
		end_slam_camera()
	queue_free()

func update_animation(direction):
	if not anim:
		return
	if (teleport_hold_active or slam_camera_active):
		play_animation("rig_idle")
	elif is_dodging:
		play_animation("rig_dodge")
	elif direction.length() > 0.1:
		play_animation("rig_run")
	else:
		play_animation("rig_idle")

func play_animation(animation_key: String) -> void:
	if not anim:
		return
	var animation_name: String = animation_key
	if animation_key == "rig_run" and not anim.has_animation(animation_key):
		animation_name = "movement temp/rig_run"
	if anim.has_animation(animation_name) and anim.current_animation != animation_name:
		anim.play(animation_name)

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
			var material = (mesh.get_surface_override_material(i))
			if material == null:
				var original = (mesh.mesh.surface_get_material(i))
				material = (original.duplicate() if original else StandardMaterial3D.new())
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
func apply_run_item(item_id: String):
	match item_id:

		"fractured_eye":
			run_projectile_damage_multiplier *= 1.25
			print("Fractured Eye acquired!")
			print("Projectile multiplier: ", run_projectile_damage_multiplier)


		"weightless_sin":
			speed *= 1.15
			print("Weightless Sin acquired!")
			print("Movement speed: ", speed)


		"shattered_heart":
			var old_max_health = float(max_health)

			max_health = int(
				round(float(max_health) * 1.10)
			)

			var bonus_health = float(max_health) - old_max_health

			health = min(
				float(max_health),
				health + bonus_health
			)

			if health_bar:
				health_bar.max_value = max_health
				health_bar.value = health

			print("Shattered Heart acquired!")


		"violent_reflection":
			dodge_damage *= 1.15
			dodge_end_damage *= 1.15

			dodge_knockback *= 1.30
			dodge_end_knockback *= 1.30

			print("Violent Reflection acquired!")

		"stormglass_cadence":
			combo_hold_delay *= 0.80
			combo_hit_one_recovery *= 0.80
			combo_hit_two_recovery *= 0.80
			combo_finisher_recovery *= 0.80
			blade_cut_time *= 0.80

		"living_circuit":
			teleport_cooldown *= 0.70
			pane_pull_cooldown *= 0.70
			rift_cleave_cooldown *= 0.70
			ruin_volley_cooldown *= 0.70

		"thunder_verse":
			combo_hold_delay *= 0.85
			combo_hit_one_recovery *= 0.85
			combo_hit_two_recovery *= 0.85
			combo_finisher_recovery *= 0.85
			teleport_cooldown *= 0.85
			pane_pull_cooldown *= 0.85
			rift_cleave_cooldown *= 0.85
			ruin_volley_cooldown *= 0.85

func on_enemy_killed() -> void:
	teleport_cooldown_timer = maxf(0.0, teleport_cooldown_timer - teleport_kill_refund)
