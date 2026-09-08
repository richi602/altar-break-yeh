extends Node

@export var area_managers: Array[Node] = []

var current_area := 0


func _ready() -> void:
	for i in range(area_managers.size()):
		var manager := area_managers[i]
		if not is_instance_valid(manager):
			continue
		manager.auto_start = false
		manager.area_unlocked.connect(_on_area_unlocked.bind(i), CONNECT_ONE_SHOT)
	if not area_managers.is_empty():
		call_deferred("_start_area", 0)


func _start_area(index: int) -> void:
	if index < 0 or index >= area_managers.size():
		return
	current_area = index
	var manager := area_managers[index]
	if is_instance_valid(manager):
		manager.start_encounter()


func _on_area_unlocked(index: int) -> void:
	if index != current_area:
		return
	var next_area := index + 1
	if next_area < area_managers.size():
		call_deferred("_start_area", next_area)
