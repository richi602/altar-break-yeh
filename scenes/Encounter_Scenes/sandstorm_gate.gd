extends Node3D

@export var encounter_manager: Node
@export var disperse_time := 1.25
@export var unlock_signal: StringName = &"area_unlocked"

@onready var storm_particles := get_node_or_null("StormParticles") as GPUParticles3D
@onready var blocker := get_node_or_null("Blocker/CollisionShape3D") as CollisionShape3D

var dispersed := false


func _ready() -> void:
	if encounter_manager == null and get_parent():
		encounter_manager = get_parent().get_node_or_null("EncounterManager")
	if encounter_manager == null:
		push_error("SandstormGate: Encounter Manager is not assigned.")
		return
	if not encounter_manager.has_signal(unlock_signal):
		push_error("SandstormGate: Encounter Manager has no %s signal." % unlock_signal)
		return
	encounter_manager.connect(unlock_signal, dispel, CONNECT_ONE_SHOT)


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
