extends Control

const LEVEL_PATH := "res://scenes/level1 testing.tscn"

var selected_character := "lucian"
var confirm_button: Button
var character_card: Button


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	build_interface()
	character_card.grab_focus()


func build_interface() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.018, 0.035, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var border := PanelContainer.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left = 26.0
	border.offset_top = 24.0
	border.offset_right = -26.0
	border.offset_bottom = -24.0
	border.add_theme_stylebox_override("panel", make_style(Color(0.035, 0.025, 0.045, 0.72), Color(0.34, 0.22, 0.39), 3, 3))
	add_child(border)
	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 80.0
	layout.offset_top = 30.0
	layout.offset_right = -80.0
	layout.offset_bottom = -30.0
	layout.add_theme_constant_override("separation", 12)
	border.add_child(layout)
	var eyebrow := Label.new()
	eyebrow.text = "ALTAR BREAK"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color(0.78, 0.61, 0.24))
	layout.add_child(eyebrow)
	var title := Label.new()
	title.text = "CHOOSE YOUR VESSEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.94, 0.91, 0.96))
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A soul enters the altar carrying one discipline."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.58, 0.55, 0.64))
	layout.add_child(subtitle)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 28)
	layout.add_child(cards)
	character_card = create_character_card("LUCIAN", "THE GLASS HERETIC", "Velocity • Panes • Ruin", true)
	character_card.pressed.connect(select_lucian)
	cards.add_child(character_card)
	cards.add_child(create_character_card("SEALED", "VESSEL UNKNOWN", "Locked", false))
	cards.add_child(create_character_card("SEALED", "VESSEL UNKNOWN", "Locked", false))
	var hint := Label.new()
	hint.text = "ENTER / CONFIRM     •     ESC / QUIT"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.48, 0.46, 0.54))
	layout.add_child(hint)
	confirm_button = Button.new()
	confirm_button.text = "ENTER THE FIRST ALTAR"
	confirm_button.custom_minimum_size = Vector2(340, 48)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.add_theme_font_size_override("font_size", 19)
	confirm_button.add_theme_stylebox_override("normal", make_style(Color(0.18, 0.045, 0.09), Color(0.78, 0.59, 0.2), 2, 7))
	confirm_button.add_theme_stylebox_override("hover", make_style(Color(0.34, 0.055, 0.12), Color(1.0, 0.76, 0.25), 3, 7))
	confirm_button.add_theme_stylebox_override("focus", make_style(Color(0.28, 0.045, 0.11), Color(0.72, 0.43, 0.92), 3, 7))
	confirm_button.pressed.connect(confirm_selection)
	layout.add_child(confirm_button)


func create_character_card(character_name: String, epithet: String, description: String, available: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(250, 285)
	card.disabled = not available
	card.text = ("◇\n\n%s\n%s\n\n%s" % [character_name, epithet, description]) if available else ("♢\n\n%s\n%s\n\n%s" % [character_name, epithet, description])
	card.add_theme_font_size_override("font_size", 18)
	card.add_theme_color_override("font_color", Color(0.93, 0.9, 0.96))
	card.add_theme_color_override("font_disabled_color", Color(0.25, 0.23, 0.29))
	card.add_theme_stylebox_override("normal", make_style(Color(0.075, 0.045, 0.085), Color(0.48, 0.3, 0.58), 2, 14))
	card.add_theme_stylebox_override("hover", make_style(Color(0.13, 0.055, 0.1), Color(0.82, 0.64, 0.22), 3, 14))
	card.add_theme_stylebox_override("focus", make_style(Color(0.15, 0.055, 0.11), Color(0.95, 0.7, 0.22), 4, 14))
	card.add_theme_stylebox_override("disabled", make_style(Color(0.035, 0.03, 0.045), Color(0.15, 0.13, 0.18), 1, 14))
	return card


func make_style(fill: Color, edge: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


func select_lucian() -> void:
	selected_character = "lucian"
	confirm_button.grab_focus()


func confirm_selection() -> void:
	if selected_character != "lucian":
		return
	confirm_button.disabled = true
	confirm_button.text = "OPENING THE ALTAR..."
	get_tree().change_scene_to_file(LEVEL_PATH)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		confirm_selection()
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
