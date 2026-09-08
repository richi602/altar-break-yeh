extends Node3D

signal area_revealed()

@export var encounter_manager: Node
@export var next_area_root: Node3D
@export var hide_next_area_until_unlocked := true
@export var remove_gate_when_unlocked := true

var unlocked := false

func _ready() -> void:
	if hide_next_area_until_unlocked and is_instance_valid(next_area_root):
		set_area_enabled(next_area_root, false)
	if encounter_manager == null:
		push_error("AreaGate: Encounter Manager is not assigned.")
		return
	if not encounter_manager.has_signal("area_unlocked"):
		push_error("AreaGate: Assigned manager has no area_unlocked signal.")
		return
	encounter_manager.area_unlocked.connect(unlock_area, CONNECT_ONE_SHOT)

func unlock_area() -> void:
	if unlocked:
		return
	unlocked = true
	if is_instance_valid(next_area_root):
		set_area_enabled(next_area_root, true)
	area_revealed.emit()
	if remove_gate_when_unlocked:
		queue_free()

func set_area_enabled(area: Node3D, enabled: bool) -> void:
	area.visible = enabled
	area.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	set_collisions_enabled(area, enabled)

func set_collisions_enabled(root: Node, enabled: bool) -> void:
	if root is CollisionShape3D or root is CollisionPolygon3D:
		root.set_deferred("disabled", not enabled)
	for child in root.get_children():
		set_collisions_enabled(child, enabled)
