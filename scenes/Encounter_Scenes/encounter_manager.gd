extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal reward_phase_started()
signal elite_defeated()
signal area_unlocked()
signal encounter_completed(encounter_kind: EncounterKind)
signal stage_cleared()

enum State { WAITING, WAVE, REWARD, COMPLETE }
enum EncounterKind { NORMAL, ELITE, BOSS }

@export_category("Encounter")
@export var encounter_kind: EncounterKind = EncounterKind.NORMAL
@export var enemy_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var elite_enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var wave_enemy_counts: Array[int] = [6, 10, 15]
@export var auto_start := true

@export_category("Spawn Points")
@export var spawn_points_root: Node3D
@export var spawn_delay := 0.35
@export var wave_clear_delay := 0.80
@export var max_simultaneous_enemies: int = 26
@export var reinforcement_spawn_delay: float = 0.08

@export_category("Developer Testing")
@export var enable_kill_all_button := true

@export_category("Elite Godshards")
@export var reward_scene: PackedScene
@export var reward_spawn_points_root: Node3D
@export_enum("Random", "Electric") var reward_theme: int = 0

var state: State = State.WAITING
var current_wave_index := 0
var alive_enemies: Dictionary = {}
var spawning_wave := false
var refilling_wave := false
var transition_pending := false
var active_rewards: Array[Node] = []
var wave_label: Label
var kill_all_button: Button
var pending_wave_enemy_count := 0
var next_wave_spawn_index := 0
var pending_wave_scene: PackedScene
var pending_wave_is_final := false

const REWARD_POOL = [
	{"id": "fractured_eye", "title": "FRACTURED EYE", "description": "+25% projectile damage"},
	{"id": "weightless_sin", "title": "WEIGHTLESS SIN", "description": "+15% movement speed"},
	{"id": "shattered_heart", "title": "SHATTERED HEART", "description": "+10% max health + heal"},
	{"id": "violent_reflection", "title": "VIOLENT REFLECTION", "description": "stronger dash impact"}
]

const ELECTRIC_REWARD_POOL = [
	{"id": "stormglass_cadence", "title": "STORMGLASS CADENCE", "description": "+25% attack speed"},
	{"id": "living_circuit", "title": "LIVING CIRCUIT", "description": "-30% ability cooldowns"},
	{"id": "thunder_verse", "title": "THUNDER VERSE", "description": "+15% attack speed, -15% cooldowns"}
]

func _ready() -> void:
	setup_wave_ui()
	if auto_start:
		call_deferred("start_encounter")

func _unhandled_key_input(event: InputEvent) -> void:
	if not enable_kill_all_button:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_K:
		kill_all_enemies()
		get_viewport().set_input_as_handled()

func start_encounter() -> void:
	if state != State.WAITING:
		return
	if not validate_setup():
		return
	current_wave_index = 0
	await begin_wave()

func validate_setup() -> bool:
	if enemy_scene == null and enemy_scenes.is_empty():
		push_error("EncounterManager: Assign Enemy Scene or Enemy Scenes.")
		return false
	if spawn_points_root == null or spawn_points_root.get_child_count() == 0:
		push_error("EncounterManager: Spawn Points Root has no Marker3D children.")
		return false
	if wave_enemy_counts.is_empty():
		push_error("EncounterManager: Wave Enemy Counts is empty.")
		return false
	if encounter_kind == EncounterKind.ELITE:
		if elite_enemy_scene == null:
			push_error("EncounterManager: Elite encounters require Elite Enemy Scene.")
			return false
		if reward_scene == null:
			push_error("EncounterManager: Elite encounters require Reward Scene.")
			return false
		if reward_spawn_points_root == null or reward_spawn_points_root.get_child_count() < 3:
			push_error("EncounterManager: Elite encounters need at least 3 reward spawn points.")
			return false
	if encounter_kind == EncounterKind.BOSS and boss_scene == null:
		push_error("EncounterManager: Boss encounters require Boss Scene.")
		return false
	return true

func begin_wave() -> void:
	state = State.WAVE
	transition_pending = false
	spawning_wave = true
	var wave_number := current_wave_index + 1
	var is_final_wave := current_wave_index >= wave_enemy_counts.size() - 1
	var scene_to_spawn := enemy_scene
	var enemy_count := wave_enemy_counts[current_wave_index]
	if is_final_wave and encounter_kind == EncounterKind.ELITE:
		scene_to_spawn = elite_enemy_scene
		enemy_count = 1
	elif is_final_wave and encounter_kind == EncounterKind.BOSS:
		scene_to_spawn = boss_scene
		enemy_count = 1
	set_wave_text(get_wave_title(wave_number, is_final_wave))
	wave_started.emit(wave_number)
	pending_wave_enemy_count = enemy_count
	next_wave_spawn_index = 0
	pending_wave_scene = scene_to_spawn
	pending_wave_is_final = is_final_wave
	await refill_active_horde(spawn_delay)
	spawning_wave = false
	check_wave_cleared()

func refill_active_horde(delay_between: float = -1.0) -> void:
	if refilling_wave or state != State.WAVE:
		return
	refilling_wave = true
	var active_cap := maxi(max_simultaneous_enemies, 1)
	var delay := reinforcement_spawn_delay if delay_between < 0.0 else delay_between
	while alive_enemies.size() < active_cap and next_wave_spawn_index < pending_wave_enemy_count:
		var selected_scene := pending_wave_scene
		if not pending_wave_is_final or encounter_kind == EncounterKind.NORMAL:
			selected_scene = get_normal_enemy_scene(next_wave_spawn_index)
		spawn_enemy(selected_scene, next_wave_spawn_index)
		next_wave_spawn_index += 1
		if delay > 0.0 and alive_enemies.size() < active_cap and next_wave_spawn_index < pending_wave_enemy_count:
			await get_tree().create_timer(delay).timeout
	refilling_wave = false
	check_wave_cleared()

func get_normal_enemy_scene(spawn_index: int) -> PackedScene:
	if enemy_scenes.is_empty():
		return enemy_scene
	# Shuffle through the pool without allowing a wave to accidentally become
	# one-note. The offset varies each wave while modulo guarantees a mix.
	var offset := current_wave_index % enemy_scenes.size()
	return enemy_scenes[(spawn_index + offset) % enemy_scenes.size()]

func get_wave_title(wave_number: int, is_final_wave: bool) -> String:
	if is_final_wave and encounter_kind == EncounterKind.ELITE:
		return "ELITE"
	if is_final_wave and encounter_kind == EncounterKind.BOSS:
		return "BOSS"
	return "WAVE %d" % wave_number

func spawn_enemy(scene_to_spawn: PackedScene, spawn_index: int) -> void:
	var spawn_points := spawn_points_root.get_children()
	if spawn_points.is_empty():
		return
	var spawn_point := spawn_points[spawn_index % spawn_points.size()]
	var enemy := scene_to_spawn.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.add_to_group("enemies")
	if enemy is Node3D and spawn_point is Node3D:
		enemy.global_transform = spawn_point.global_transform
	var enemy_id := enemy.get_instance_id()
	alive_enemies[enemy_id] = true
	enemy.tree_exited.connect(on_spawned_enemy_exited.bind(enemy_id), CONNECT_ONE_SHOT)

func on_spawned_enemy_exited(enemy_id: int) -> void:
	alive_enemies.erase(enemy_id)
	if state == State.WAVE and next_wave_spawn_index < pending_wave_enemy_count:
		call_deferred("refill_active_horde")
	check_wave_cleared()

func check_wave_cleared() -> void:
	if state != State.WAVE or spawning_wave or refilling_wave or next_wave_spawn_index < pending_wave_enemy_count or not alive_enemies.is_empty() or transition_pending:
		return
	transition_pending = true
	call_deferred("finish_wave")

func finish_wave() -> void:
	if state != State.WAVE:
		return
	var cleared_wave_number := current_wave_index + 1
	var is_final_wave := current_wave_index >= wave_enemy_counts.size() - 1
	wave_cleared.emit(cleared_wave_number)
	if not is_final_wave:
		set_wave_text("WAVE %d CLEARED" % cleared_wave_number)
		await get_tree().create_timer(wave_clear_delay).timeout
		current_wave_index += 1
		await begin_wave()
		return
	match encounter_kind:
		EncounterKind.ELITE:
			elite_defeated.emit()
			set_wave_text("ELITE DEFEATED")
			await get_tree().create_timer(wave_clear_delay).timeout
			start_reward_phase()
		EncounterKind.BOSS:
			complete_boss_encounter()
		_:
			complete_area_encounter()

func start_reward_phase() -> void:
	state = State.REWARD
	transition_pending = false
	clear_active_rewards()
	reward_phase_started.emit()
	set_wave_text("CHOOSE A GODSHARD")
	var reward_points := reward_spawn_points_root.get_children()
	var pool := (ELECTRIC_REWARD_POOL if reward_theme == 1 else REWARD_POOL).duplicate(true)
	pool.shuffle()
	var choice_count: int = mini(3, mini(reward_points.size(), pool.size()))
	for i in range(choice_count):
		var reward_data: Dictionary = pool[i]
		var reward := reward_scene.instantiate()
		get_tree().current_scene.add_child(reward)
		if reward is Node3D and reward_points[i] is Node3D:
			reward.global_transform = reward_points[i].global_transform
		if reward.has_method("configure"):
			reward.configure(reward_data["id"], reward_data["title"], reward_data["description"])
		reward.connect("chosen", on_reward_chosen.bind(reward), CONNECT_ONE_SHOT)
		active_rewards.append(reward)

func on_reward_chosen(reward_id: String, picker: Node, _chosen_reward: Node) -> void:
	if state != State.REWARD:
		return
	state = State.COMPLETE
	if is_instance_valid(picker) and picker.has_method("apply_run_item"):
		picker.apply_run_item(reward_id)
	clear_active_rewards()
	set_wave_text("GODSHARD TAKEN")
	emit_area_completion()

func clear_active_rewards() -> void:
	for reward in active_rewards:
		if is_instance_valid(reward):
			reward.queue_free()
	active_rewards.clear()

func complete_area_encounter() -> void:
	state = State.COMPLETE
	transition_pending = false
	set_wave_text("AREA SECURED")
	emit_area_completion()

func emit_area_completion() -> void:
	encounter_completed.emit(encounter_kind)
	area_unlocked.emit()

func complete_boss_encounter() -> void:
	state = State.COMPLETE
	transition_pending = false
	set_wave_text("STAGE CLEARED")
	encounter_completed.emit(encounter_kind)
	stage_cleared.emit()

func setup_wave_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	wave_label = Label.new()
	layer.add_child(wave_label)
	wave_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wave_label.offset_left = -300.0
	wave_label.offset_right = 300.0
	wave_label.offset_top = 40.0
	wave_label.offset_bottom = 90.0
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 34)
	wave_label.add_theme_color_override("font_color", Color(0.78, 0.90, 1.0, 1.0))
	wave_label.add_theme_color_override("font_shadow_color", Color(0.95, 0.12, 0.70, 0.80))
	wave_label.add_theme_constant_override("shadow_offset_x", 2)
	wave_label.add_theme_constant_override("shadow_offset_y", 2)
	if enable_kill_all_button:
		kill_all_button = Button.new()
		layer.add_child(kill_all_button)
		kill_all_button.text = "KILL ALL ENEMIES  [CTRL+K]"
		kill_all_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		kill_all_button.offset_left = -260.0
		kill_all_button.offset_right = -24.0
		kill_all_button.offset_top = 24.0
		kill_all_button.offset_bottom = 70.0
		kill_all_button.add_theme_font_size_override("font_size", 18)
		kill_all_button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.82, 1.0))
		kill_all_button.add_theme_color_override("font_hover_color", Color.WHITE)
		kill_all_button.pressed.connect(kill_all_enemies)

func kill_all_enemies() -> void:
	if state != State.WAVE:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.queue_free()
	if kill_all_button:
		kill_all_button.release_focus()

func set_wave_text(text: String) -> void:
	if wave_label:
		wave_label.text = text
