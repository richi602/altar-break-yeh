extends Node

## Coordinates normal enemies so their major attacks remain readable.
@export var shared_attack_gap: float = 0.32
@export var nearby_reaction_radius: float = 18.0
@export var ally_reaction_time: float = 0.28

var active_attacker: WeakRef
var next_attack_time_msec: int = 0

func request_attack(enemy: Node) -> bool:
	if Time.get_ticks_msec() < next_attack_time_msec:
		return false
	if active_attacker != null:
		var current: Object = active_attacker.get_ref()
		if is_instance_valid(current) and current != enemy:
			return false
	active_attacker = weakref(enemy)
	return true

func release_attack(enemy: Node, extra_gap: float = -1.0) -> void:
	if active_attacker != null and active_attacker.get_ref() == enemy:
		active_attacker = null
	var gap: float = shared_attack_gap if extra_gap < 0.0 else extra_gap
	next_attack_time_msec = Time.get_ticks_msec() + int(gap * 1000.0)

func notify_ally_disrupted(source: Node3D, incoming_force: Vector3 = Vector3.ZERO) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == source or not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		if source.global_position.distance_to(enemy.global_position) > nearby_reaction_radius:
			continue
		if enemy.has_method("react_to_ally_event"):
			enemy.react_to_ally_event(source.global_position, incoming_force, ally_reaction_time)
