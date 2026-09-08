extends Area3D

@export var speed := 115.0
@export var homing_strength := 18.0
@export var damage := 16.0
@export var lifetime := 8.0
@export var explosion_radius := 3.25

var target: Node3D
var launch_delay := 1.0
var age := 0.0
var launched := false
var direction := Vector3.ZERO
var origin_y := 0.0
var phase := 0.0
var hit := false
var base_scale := Vector3.ONE
var ring_angle := 0.0
var ring_radius := 7.5
var ring_height := 7.5
var ring_rotation_speed := 1.6
var orbit_while_waiting := true
var trailing_distance := 0.0
var closest_target_distance := INF
var missed_target := false
var miss_detonation_timer := 0.0
const WARNING_TIME := 0.65
const FINAL_FLASH_TIME := 0.16
const FLYBY_ARM_DISTANCE := 5.0
const FLYBY_DISTANCE_MARGIN := 0.35
const MISS_DETONATION_DELAY := 0.18


func _ready() -> void:
	add_to_group("enemy_projectiles")
	origin_y = global_position.y
	phase = randf() * TAU
	base_scale = scale
	$Mesh.material_override = $Mesh.material_override.duplicate()
	$Ring.material_override = $Ring.material_override.duplicate()
	# Hovering orbs are visual warnings only. They cannot touch the player
	# until launch() explicitly arms collision.


func arm(new_target: Node3D, delay: float, projectile_damage: float, slot_angle: float = 0.0, slot_radius: float = 7.5, slot_height: float = 7.5, should_orbit: bool = true) -> void:
	target = new_target
	launch_delay = delay
	damage = projectile_damage
	ring_angle = slot_angle
	ring_radius = slot_radius
	ring_height = slot_height
	orbit_while_waiting = should_orbit
	origin_y = global_position.y


func set_trailing_target(distance: float) -> void:
	trailing_distance = distance


func get_aim_position() -> Vector3:
	if not is_instance_valid(target):
		return global_position
	var aim := target.global_position + Vector3.UP * 1.2
	if trailing_distance > 0.0 and target is CharacterBody3D:
		var travel := Vector3(target.velocity.x, 0.0, target.velocity.z)
		if travel.length_squared() > 1.0:
			aim -= travel.normalized() * trailing_distance
	return aim


func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	if not launched:
		update_ring_position(delta)
		rotation.y += delta * 4.0
		update_launch_telegraph()
		if age >= launch_delay:
			launch()
		return
	if missed_target:
		miss_detonation_timer -= delta
		global_position += direction * speed * delta
		if miss_detonation_timer <= 0.0:
			explode()
		return
	if is_instance_valid(target):
		var aim := get_aim_position()
		var target_distance := global_position.distance_to(aim)
		if target_distance < closest_target_distance:
			closest_target_distance = target_distance
		elif closest_target_distance <= FLYBY_ARM_DISTANCE and target_distance > closest_target_distance + FLYBY_DISTANCE_MARGIN:
			# The player beat the shot. Commit to the miss instead of allowing the
			# orb to loop around and reacquire them from behind.
			missed_target = true
			miss_detonation_timer = MISS_DETONATION_DELAY
			target = null
			return
		var desired := (aim - global_position).normalized()
		direction = direction.lerp(desired, clamp(homing_strength * delta, 0.0, 1.0)).normalized()
	global_position += direction * speed * delta


func update_ring_position(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if not orbit_while_waiting:
		global_position.y = origin_y + sin(age * 8.0 + phase) * 0.18
		return
	ring_angle += ring_rotation_speed * delta
	var center := target.global_position
	global_position = center + Vector3(
		cos(ring_angle) * ring_radius,
		ring_height + sin(age * 4.0 + phase) * 0.22,
		sin(ring_angle) * ring_radius
	)


func launch() -> void:
	launched = true
	closest_target_distance = INF
	missed_target = false
	set_deferred("monitoring", true)
	$CollisionShape3D.set_deferred("disabled", false)
	if is_instance_valid(target):
		direction = (get_aim_position() - global_position).normalized()
	else:
		direction = -global_transform.basis.z
	$Mesh.scale = Vector3.ONE * 1.35
	$Ring.scale = Vector3.ONE * 1.8


func update_launch_telegraph() -> void:
	var time_left := launch_delay - age
	var mesh_material := $Mesh.material_override as StandardMaterial3D
	var ring_material := $Ring.material_override as StandardMaterial3D
	if time_left > WARNING_TIME:
		var breathe := 1.0 + sin(age * 7.0 + phase) * 0.12
		$Mesh.scale = base_scale * breathe
		$Ring.scale = base_scale * (1.0 + sin(age * 5.0) * 0.18)
		return
	var warning_progress := clampf(1.0 - time_left / WARNING_TIME, 0.0, 1.0)
	var pulse_speed := lerpf(12.0, 38.0, warning_progress)
	var pulse := sin(age * pulse_speed) * 0.5 + 0.5
	$Mesh.scale = base_scale * lerpf(1.15, 2.15, warning_progress) * lerpf(0.86, 1.14, pulse)
	$Ring.scale = base_scale * lerpf(1.4, 2.8, warning_progress)
	if mesh_material:
		if time_left <= FINAL_FLASH_TIME:
			var flash_on := fmod(time_left, 0.06) < 0.03
			mesh_material.albedo_color = Color.WHITE if flash_on else Color(1.0, 0.02, 0.0, 1.0)
			mesh_material.emission = Color.WHITE if flash_on else Color(1.0, 0.01, 0.0, 1.0)
			mesh_material.emission_energy_multiplier = 28.0
		else:
			mesh_material.emission_energy_multiplier = lerpf(7.0, 18.0, warning_progress)
			mesh_material.albedo_color = Color(1.0, lerpf(0.55, 0.04, warning_progress), 0.01, 1.0)
	if ring_material:
		ring_material.emission_energy_multiplier = 28.0 if time_left <= FINAL_FLASH_TIME else lerpf(7.0, 18.0, warning_progress)


func _on_body_entered(body: Node3D) -> void:
	if hit or not launched or body.is_in_group("enemies"):
		return
	if body.has_method("take_damage") or body is StaticBody3D:
		explode()


func explode() -> void:
	if hit:
		return
	hit = true
	set_deferred("monitoring", false)
	$CollisionShape3D.set_deferred("disabled", true)
	apply_explosion_damage()
	spawn_explosion_visual()
	queue_free()


func apply_explosion_damage() -> void:
	var shape := SphereShape3D.new()
	shape.radius = explosion_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var results := get_world_3d().direct_space_state.intersect_shape(query, 16)
	var damaged: Dictionary = {}
	for result in results:
		var collider = result.get("collider")
		if not is_instance_valid(collider) or collider.is_in_group("enemies"):
			continue
		var collider_id: int = collider.get_instance_id()
		if damaged.has(collider_id):
			continue
		if collider.has_method("take_damage"):
			damaged[collider_id] = true
			collider.take_damage(damage)


func spawn_explosion_visual() -> void:
	var blast := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	blast.mesh = sphere
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.24, 0.015, 0.78)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.055, 0.005, 1.0)
	material.emission_energy_multiplier = 12.0
	blast.material_override = material
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position
	blast.scale = Vector3.ONE * 0.2
	var tween := blast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(blast, "scale", Vector3.ONE * explosion_radius, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color", Color(1.0, 0.06, 0.0, 0.0), 0.2)
	tween.chain().tween_callback(blast.queue_free)
