extends Node3D

@export var encounter_manager: Node
@export var disperse_time := 1.25
@export var unlock_signal: StringName = &"area_unlocked"

@export_category("Area Blending")
@export var gate_size: Vector3 = Vector3(84.0, 20.0, 5.0)
@export var visual_blend_depth: float = 16.0
@export var storm_color: Color = Color(0.73, 0.54, 0.33, 0.78)
@export var storm_core_color: Color = Color(0.28, 0.20, 0.16, 0.62)
@export_range(0.1, 3.0, 0.05) var density_multiplier: float = 1.0
@export var particle_size_range: Vector2 = Vector2(2.0, 6.0)
@export var wind_velocity: Vector3 = Vector3(8.0, 1.5, 0.0)
@export var turbulence_strength: float = 8.0

@onready var storm_particles := get_node_or_null("StormParticles") as GPUParticles3D
@onready var blocker := get_node_or_null("Blocker/CollisionShape3D") as CollisionShape3D

var dispersed := false


func _ready() -> void:
	apply_area_blend_style()
	if encounter_manager == null and get_parent():
		encounter_manager = get_parent().get_node_or_null("EncounterManager")
	if encounter_manager == null:
		push_error("SandstormGate: Encounter Manager is not assigned.")
		return
	if not encounter_manager.has_signal(unlock_signal):
		push_error("SandstormGate: Encounter Manager has no %s signal." % unlock_signal)
		return
	encounter_manager.connect(unlock_signal, dispel, CONNECT_ONE_SHOT)

func apply_area_blend_style() -> void:
	if blocker and blocker.shape is BoxShape3D:
		var collision_shape := blocker.shape.duplicate() as BoxShape3D
		collision_shape.size = gate_size
		blocker.shape = collision_shape
	if not storm_particles:
		return
	storm_particles.amount = maxi(24, int(900.0 * density_multiplier))
	var process := storm_particles.process_material.duplicate() as ParticleProcessMaterial
	process.emission_box_extents = Vector3(gate_size.x * 0.5, gate_size.y * 0.5, maxf(visual_blend_depth, gate_size.z) * 0.5)
	process.gravity = wind_velocity
	process.scale_min = particle_size_range.x
	process.scale_max = particle_size_range.y
	process.turbulence_noise_strength = turbulence_strength
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(storm_color.r, storm_color.g, storm_color.b, 0.0),
		storm_color,
		storm_core_color,
		Color(storm_core_color.r, storm_core_color.g, storm_core_color.b, 0.0)
	])
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	storm_particles.process_material = process
	if storm_particles.draw_pass_1:
		var particle_mesh := storm_particles.draw_pass_1.duplicate() as PrimitiveMesh
		var particle_material := particle_mesh.material.duplicate() as StandardMaterial3D
		particle_material.albedo_color = storm_color
		particle_mesh.material = particle_material
		storm_particles.draw_pass_1 = particle_mesh


func dispel() -> void:
	if dispersed:
		return
	dispersed = true
	if blocker:
		blocker.set_deferred("disabled", true)
	if storm_particles:
		storm_particles.emitting = false
	await get_tree().create_timer(disperse_time).timeout
	queue_free()
