extends Control
class_name SpikeHud

signal next_wave_requested
signal restart_requested
signal scenario_selected(scenario_id: String)
signal build_requested(spot_id: String, tower_type_id: String)

var _game_state_adapter: Node = null
var _wave_state_adapter: Node = null
var _combat_adapter: Node = null
var _wave_count := 0
var _hud_bar: ColorRect = null
var _state_value_label: Label = null
var _wave_value_label: Label = null
var _lives_value_label: Label = null
var _breaches_value_label: Label = null
var _enemies_value_label: Label = null
var _scenario_entries: Array = []
var _active_scenario_id := ""
var _scenario_select: OptionButton = null
var _action_button: Button = null
var _build_gold := 0
var _build_spot_entries: Array = []
var _tower_option_entries: Array = []
var _active_build_spot_id := ""
var _active_tower_type_id := ""
var _build_spot_select: OptionButton = null
var _tower_type_select: OptionButton = null
var _gold_value_label: Label = null
var _build_button: Button = null
var _cached_text := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = 16.0
	offset_top = 16.0
	offset_right = -16.0
	offset_bottom = 80.0
	custom_minimum_size = Vector2(360.0, 64.0)

	_ensure_nodes()
	refresh()

func bind_adapters(game_state_adapter: Node, wave_state_adapter: Node, combat_adapter: Node, wave_count: int = 0) -> void:
	_game_state_adapter = game_state_adapter
	_wave_state_adapter = wave_state_adapter
	_combat_adapter = combat_adapter
	_wave_count = maxi(wave_count, 0)
	refresh()

func bind_scenarios(entries: Array, active_scenario_id: String) -> void:
	_scenario_entries = []
	for entry_variant: Variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			_scenario_entries.append((entry_variant as Dictionary).duplicate(true))
	_active_scenario_id = active_scenario_id
	_ensure_nodes()
	_rebuild_scenario_select()
	_layout_hud_bar()

func active_scenario_id() -> String:
	return _active_scenario_id

func bind_build_state(gold: int, build_spots: Array, tower_options: Array) -> void:
	_build_gold = maxi(gold, 0)
	_build_spot_entries = _copy_dictionary_entries(build_spots)
	_tower_option_entries = _copy_dictionary_entries(tower_options)
	_ensure_nodes()
	_rebuild_build_spot_select()
	_rebuild_tower_type_select()
	_update_build_controls()
	_layout_hud_bar()

func active_build_spot_id() -> String:
	return _active_build_spot_id

func active_tower_type_id() -> String:
	return _active_tower_type_id

func refresh() -> void:
	_ensure_nodes()
	_cached_text = _build_debug_text()
	_update_hud_values()

func debug_text() -> String:
	return _cached_text

func _ensure_nodes() -> void:
	if _hud_bar == null:
		_hud_bar = get_node_or_null("HudBar") as ColorRect
	if _hud_bar == null:
		_hud_bar = ColorRect.new()
		_hud_bar.name = "HudBar"
		_hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_bar.color = Color(0.035, 0.028, 0.022, 0.76)
		_hud_bar.anchor_left = 0.0
		_hud_bar.anchor_top = 0.0
		_hud_bar.anchor_right = 1.0
		_hud_bar.anchor_bottom = 0.0
		_hud_bar.offset_left = 0.0
		_hud_bar.offset_top = 0.0
		_hud_bar.offset_right = 0.0
		_hud_bar.offset_bottom = 64.0
		add_child(_hud_bar)

	_state_value_label = _ensure_value_label(_state_value_label, "StateValue")
	_wave_value_label = _ensure_value_label(_wave_value_label, "WaveValue")
	_lives_value_label = _ensure_value_label(_lives_value_label, "LivesValue")
	_breaches_value_label = _ensure_value_label(_breaches_value_label, "BreachesValue")
	_enemies_value_label = _ensure_value_label(_enemies_value_label, "EnemiesValue")
	_ensure_scenario_select()
	_ensure_action_button()
	_ensure_build_controls()
	_layout_hud_bar()

func _ensure_value_label(label: Label, label_name: String) -> Label:
	if label == null:
		label = _hud_bar.get_node_or_null(label_name) as Label
	if label == null:
		label = Label.new()
		label.name = label_name
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.74, 1.0))
		_hud_bar.add_child(label)

	var caption_name := label_name.replace("Value", "Label")
	var caption := _hud_bar.get_node_or_null(caption_name) as Label
	if caption == null:
		caption = Label.new()
		caption.name = caption_name
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.clip_text = true
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.add_theme_font_size_override("font_size", 10)
		caption.add_theme_color_override("font_color", Color(0.68, 0.61, 0.45, 1.0))
		caption.text = label_name.replace("Value", "").to_upper()
		_hud_bar.add_child(caption)

	return label

func _ensure_scenario_select() -> void:
	if _scenario_select == null:
		_scenario_select = _hud_bar.get_node_or_null("ScenarioSelect") as OptionButton
	if _scenario_select == null:
		_scenario_select = OptionButton.new()
		_scenario_select.name = "ScenarioSelect"
		_scenario_select.mouse_filter = Control.MOUSE_FILTER_STOP
		_scenario_select.focus_mode = Control.FOCUS_NONE
		_scenario_select.add_theme_font_size_override("font_size", 13)
		_hud_bar.add_child(_scenario_select)

	var callback := Callable(self, "_on_scenario_select_item_selected")
	if not _scenario_select.is_connected("item_selected", callback):
		_scenario_select.connect("item_selected", callback)
	_rebuild_scenario_select()

func _rebuild_scenario_select() -> void:
	if _scenario_select == null:
		return

	_scenario_select.clear()
	var selected_index := 0
	for index in range(_scenario_entries.size()):
		var entry := _scenario_entries[index] as Dictionary
		var scenario_id := str(entry.get("id", ""))
		var scenario_name := str(entry.get("name", scenario_id))
		_scenario_select.add_item(scenario_name, index)
		_scenario_select.set_item_metadata(index, scenario_id)
		if scenario_id == _active_scenario_id:
			selected_index = index
	if _scenario_entries.is_empty():
		_scenario_select.visible = false
	else:
		_scenario_select.visible = true
		_scenario_select.select(selected_index)

func _ensure_action_button() -> void:
	if _action_button == null:
		_action_button = _hud_bar.get_node_or_null("ActionButton") as Button
	if _action_button == null:
		_action_button = Button.new()
		_action_button.name = "ActionButton"
		_action_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_action_button.focus_mode = Control.FOCUS_NONE
		_action_button.visible = false
		_action_button.add_theme_font_size_override("font_size", 14)
		_action_button.add_theme_color_override("font_color", Color(0.98, 0.9, 0.72, 1.0))
		_hud_bar.add_child(_action_button)

	var pressed_callback := Callable(self, "_on_action_button_pressed")
	if not _action_button.is_connected("pressed", pressed_callback):
		_action_button.connect("pressed", pressed_callback)

func _ensure_build_controls() -> void:
	if _build_spot_select == null:
		_build_spot_select = _hud_bar.get_node_or_null("BuildSpotSelect") as OptionButton
	if _build_spot_select == null:
		_build_spot_select = OptionButton.new()
		_build_spot_select.name = "BuildSpotSelect"
		_build_spot_select.mouse_filter = Control.MOUSE_FILTER_STOP
		_build_spot_select.focus_mode = Control.FOCUS_NONE
		_build_spot_select.add_theme_font_size_override("font_size", 13)
		_hud_bar.add_child(_build_spot_select)

	var spot_callback := Callable(self, "_on_build_spot_item_selected")
	if not _build_spot_select.is_connected("item_selected", spot_callback):
		_build_spot_select.connect("item_selected", spot_callback)

	if _tower_type_select == null:
		_tower_type_select = _hud_bar.get_node_or_null("TowerTypeSelect") as OptionButton
	if _tower_type_select == null:
		_tower_type_select = OptionButton.new()
		_tower_type_select.name = "TowerTypeSelect"
		_tower_type_select.mouse_filter = Control.MOUSE_FILTER_STOP
		_tower_type_select.focus_mode = Control.FOCUS_NONE
		_tower_type_select.add_theme_font_size_override("font_size", 13)
		_hud_bar.add_child(_tower_type_select)

	var tower_callback := Callable(self, "_on_tower_type_item_selected")
	if not _tower_type_select.is_connected("item_selected", tower_callback):
		_tower_type_select.connect("item_selected", tower_callback)

	if _gold_value_label == null:
		_gold_value_label = _hud_bar.get_node_or_null("GoldValue") as Label
	if _gold_value_label == null:
		_gold_value_label = Label.new()
		_gold_value_label.name = "GoldValue"
		_gold_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_gold_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_gold_value_label.clip_text = true
		_gold_value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_gold_value_label.add_theme_font_size_override("font_size", 15)
		_gold_value_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.74, 1.0))
		_hud_bar.add_child(_gold_value_label)

	if _build_button == null:
		_build_button = _hud_bar.get_node_or_null("BuildButton") as Button
	if _build_button == null:
		_build_button = Button.new()
		_build_button.name = "BuildButton"
		_build_button.text = "Build"
		_build_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_build_button.focus_mode = Control.FOCUS_NONE
		_build_button.add_theme_font_size_override("font_size", 14)
		_build_button.add_theme_color_override("font_color", Color(0.98, 0.9, 0.72, 1.0))
		_hud_bar.add_child(_build_button)

	var pressed_callback := Callable(self, "_on_build_button_pressed")
	if not _build_button.is_connected("pressed", pressed_callback):
		_build_button.connect("pressed", pressed_callback)

	_rebuild_build_spot_select()
	_rebuild_tower_type_select()
	_update_build_controls()

func _layout_hud_bar() -> void:
	if _hud_bar == null:
		return

	var viewport_width := 1280.0
	if is_inside_tree():
		viewport_width = get_viewport_rect().size.x
	_layout_hud_bar_for_width(viewport_width)

func _layout_hud_bar_for_width(viewport_width: float) -> void:
	if _hud_bar == null:
		return

	var bar_width := maxf(viewport_width - 32.0, 360.0)
	var gap := 8.0
	var padding := 10.0
	var selector_width := 170.0
	var action_width := 120.0
	var minimum_cell_width := 72.0
	var required_desktop_width := padding * 2.0 + selector_width + action_width + minimum_cell_width * 5.0 + gap * 6.0
	if bar_width < required_desktop_width:
		_layout_mobile_hud_bar(bar_width)
		return

	_hud_bar.offset_bottom = 96.0
	offset_bottom = offset_top + _hud_bar.offset_bottom
	var cell_width := maxf((bar_width - padding * 2.0 - gap * 6.0 - selector_width - action_width) / 5.0, minimum_cell_width)
	var x := padding
	if _scenario_select != null:
		_scenario_select.visible = not _scenario_entries.is_empty()
		_scenario_select.position = Vector2(x, 17.0)
		_scenario_select.size = Vector2(selector_width, 30.0)
	x += selector_width + gap
	for label_name in ["State", "Wave", "Lives", "Breaches", "Enemies"]:
		_layout_field(label_name, x, cell_width, 8.0, 25.0, 28.0)
		x += cell_width + gap
	_layout_action_button(bar_width - padding - action_width, 17.0, action_width, 30.0)
	_layout_build_controls(bar_width, padding, gap)

func _layout_mobile_hud_bar(bar_width: float) -> void:
	_hud_bar.offset_bottom = 92.0
	offset_bottom = offset_top + _hud_bar.offset_bottom

	var gap := 8.0
	var padding := 10.0
	var row_one_cell_width := (bar_width - padding * 2.0 - gap) / 2.0
	var action_width := 100.0
	var row_two_cell_width := (bar_width - padding * 2.0 - gap * 3.0 - action_width) / 3.0

	if _scenario_select != null:
		_scenario_select.visible = false
		_scenario_select.position = Vector2(padding, 58.0)
		_scenario_select.size = Vector2(112.0, 26.0)

	_layout_field("State", padding, row_one_cell_width, 6.0, 21.0, 24.0)
	_layout_field("Wave", padding + row_one_cell_width + gap, row_one_cell_width, 6.0, 21.0, 24.0)
	_layout_field("Lives", padding, row_two_cell_width, 49.0, 64.0, 24.0)
	_layout_field("Breaches", padding + row_two_cell_width + gap, row_two_cell_width, 49.0, 64.0, 24.0)
	_layout_field("Enemies", padding + (row_two_cell_width + gap) * 2.0, row_two_cell_width, 49.0, 64.0, 24.0)
	_layout_action_button(bar_width - padding - action_width, 58.0, action_width, 26.0)
	_set_build_controls_visible(false)

func _layout_field(field_name: String, x: float, field_width: float, caption_y: float, value_y: float, value_height: float) -> void:
	var caption := _hud_bar.get_node_or_null("%sLabel" % field_name) as Label
	var value := _hud_bar.get_node_or_null("%sValue" % field_name) as Label
	if caption != null:
		caption.position = Vector2(x, caption_y)
		caption.size = Vector2(field_width, 16.0)
	if value != null:
		value.position = Vector2(x, value_y)
		value.size = Vector2(field_width, value_height)

func _layout_action_button(x: float, y: float, width: float, height: float) -> void:
	if _action_button == null:
		return
	_action_button.position = Vector2(x, y)
	_action_button.size = Vector2(width, height)

func _layout_build_controls(bar_width: float, padding: float, gap: float) -> void:
	var has_build_state := _build_gold > 0 or not _build_spot_entries.is_empty() or not _tower_option_entries.is_empty()
	_set_build_controls_visible(has_build_state)
	if not has_build_state:
		return

	var gold_width := 76.0
	var button_width := 96.0
	var available_width := maxf(bar_width - padding * 2.0 - gap * 3.0 - gold_width - button_width, 240.0)
	var spot_width := maxf(available_width * 0.44, 112.0)
	var tower_width := maxf(available_width - spot_width, 128.0)
	var y := 58.0
	var height := 28.0
	var x := padding

	if _gold_value_label != null:
		_gold_value_label.position = Vector2(x, y)
		_gold_value_label.size = Vector2(gold_width, height)
	x += gold_width + gap
	if _build_spot_select != null:
		_build_spot_select.position = Vector2(x, y)
		_build_spot_select.size = Vector2(spot_width, height)
	x += spot_width + gap
	if _tower_type_select != null:
		_tower_type_select.position = Vector2(x, y)
		_tower_type_select.size = Vector2(tower_width, height)
	if _build_button != null:
		_build_button.position = Vector2(bar_width - padding - button_width, y)
		_build_button.size = Vector2(button_width, height)

func _set_build_controls_visible(is_visible: bool) -> void:
	for control in [_build_spot_select, _tower_type_select, _gold_value_label, _build_button]:
		if control != null:
			control.visible = is_visible

func _update_hud_values() -> void:
	if _state_value_label != null:
		_state_value_label.text = _game_state_value("get_state", "idle")
	if _wave_value_label != null:
		_wave_value_label.text = _wave_label()
	if _lives_value_label != null:
		_lives_value_label.text = str(_game_state_int("get_base_lives", 0))
	if _breaches_value_label != null:
		_breaches_value_label.text = str(_game_state_int("get_path_breach_count", 0))
	if _enemies_value_label != null:
		_enemies_value_label.text = str(_active_enemy_count())
	_update_action_button()

func _build_debug_text() -> String:
	return "\n".join([
		"State: %s" % _game_state_value("get_state", "idle"),
		"Wave: %s" % _wave_label(),
		"Lives: %d" % _game_state_int("get_base_lives", 0),
		"Breaches: %d" % _game_state_int("get_path_breach_count", 0),
		"Active enemies: %d" % _active_enemy_count(),
	])

func _wave_label() -> String:
	var wave_id := _game_state_value("active_wave_id", "")
	if wave_id == "":
		wave_id = "-"

	var wave_index := _game_state_int("get_current_wave_index", -1)
	if wave_index < 0:
		return "%s (0/%d)" % [wave_id, _wave_count]

	return "%s (%d/%d)" % [wave_id, wave_index + 1, _wave_count]

func _active_enemy_count() -> int:
	if _wave_state_adapter != null and _wave_state_adapter.has_method("get_active_enemy_count"):
		return int(_wave_state_adapter.call("get_active_enemy_count"))
	if _combat_adapter != null and _combat_adapter.has_method("get_tracked_enemy_count"):
		return int(_combat_adapter.call("get_tracked_enemy_count"))
	return 0

func _game_state_value(method_name: String, fallback: String) -> String:
	if _game_state_adapter == null or not _game_state_adapter.has_method(method_name):
		return fallback
	return str(_game_state_adapter.call(method_name))

func _game_state_int(method_name: String, fallback: int) -> int:
	if _game_state_adapter == null or not _game_state_adapter.has_method(method_name):
		return fallback
	return int(_game_state_adapter.call(method_name))

func _update_action_button() -> void:
	if _action_button == null:
		return

	var state := _game_state_value("get_state", "idle")
	if state == "wave_clear":
		_action_button.text = "Next wave"
		_action_button.visible = true
	elif state == "basic_win" or state == "basic_loss":
		_action_button.text = "Restart"
		_action_button.visible = true
	else:
		_action_button.visible = false

func _rebuild_build_spot_select() -> void:
	if _build_spot_select == null:
		return

	var previous_id := _active_build_spot_id
	_build_spot_select.clear()
	var selected_index := -1
	for index in range(_build_spot_entries.size()):
		var spot := _build_spot_entries[index] as Dictionary
		var spot_id := str(spot.get("id", ""))
		if spot_id == "":
			continue
		_build_spot_select.add_item(spot_id, index)
		var item_index := _build_spot_select.item_count - 1
		_build_spot_select.set_item_metadata(item_index, spot_id)
		if spot_id == previous_id:
			selected_index = item_index

	if _build_spot_select.item_count == 0:
		_active_build_spot_id = ""
		return

	if selected_index < 0:
		selected_index = 0
	_build_spot_select.select(selected_index)
	_active_build_spot_id = str(_build_spot_select.get_item_metadata(selected_index))

func _rebuild_tower_type_select() -> void:
	if _tower_type_select == null:
		return

	var previous_id := _active_tower_type_id
	_tower_type_select.clear()
	var selected_index := -1
	for index in range(_tower_option_entries.size()):
		var tower := _tower_option_entries[index] as Dictionary
		var tower_id := str(tower.get("id", ""))
		if tower_id == "":
			continue
		var tower_name := str(tower.get("name", tower_id))
		var cost := maxi(int(tower.get("cost", 0)), 0)
		_tower_type_select.add_item("%s (%d)" % [tower_name, cost], index)
		var item_index := _tower_type_select.item_count - 1
		_tower_type_select.set_item_metadata(item_index, tower_id)
		if tower_id == previous_id:
			selected_index = item_index

	if _tower_type_select.item_count == 0:
		_active_tower_type_id = ""
		return

	if selected_index < 0:
		selected_index = 0
	_tower_type_select.select(selected_index)
	_active_tower_type_id = str(_tower_type_select.get_item_metadata(selected_index))

func _update_build_controls() -> void:
	if _gold_value_label != null:
		_gold_value_label.text = str(_build_gold)
	if _build_button != null:
		_build_button.disabled = _active_build_spot_id == "" or _active_tower_type_id == ""

func _copy_dictionary_entries(entries: Array) -> Array:
	var copied: Array = []
	for entry_variant: Variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			copied.append((entry_variant as Dictionary).duplicate(true))
	return copied

func _on_action_button_pressed() -> void:
	var state := _game_state_value("get_state", "idle")
	if state == "wave_clear":
		next_wave_requested.emit()
	elif state == "basic_win" or state == "basic_loss":
		restart_requested.emit()

func _on_scenario_select_item_selected(index: int) -> void:
	if _scenario_select == null or index < 0 or index >= _scenario_select.item_count:
		return
	var metadata: Variant = _scenario_select.get_item_metadata(index)
	var scenario_id := str(metadata)
	if scenario_id == "" or scenario_id == _active_scenario_id:
		return
	_active_scenario_id = scenario_id
	scenario_selected.emit(scenario_id)

func _on_build_spot_item_selected(index: int) -> void:
	if _build_spot_select == null or index < 0 or index >= _build_spot_select.item_count:
		return
	_active_build_spot_id = str(_build_spot_select.get_item_metadata(index))
	_update_build_controls()

func _on_tower_type_item_selected(index: int) -> void:
	if _tower_type_select == null or index < 0 or index >= _tower_type_select.item_count:
		return
	_active_tower_type_id = str(_tower_type_select.get_item_metadata(index))
	_update_build_controls()

func _on_build_button_pressed() -> void:
	if _active_build_spot_id == "" or _active_tower_type_id == "":
		return
	build_requested.emit(_active_build_spot_id, _active_tower_type_id)
