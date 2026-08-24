extends CanvasLayer

const PANEL_BORDER_TEXTURE := preload("res://assets/third_party/kenney/fantasy_ui_borders/panel-border-024.png")
const QINGLAN_MAP_TEXTURE := preload("res://assets/generated/core/qinglan-valley-map.png")
const WorldArena := preload("res://scripts/world/world_arena.gd")
const WANDERER_PORTRAIT := preload("res://assets/generated/core/wanderer-portrait.png")
const MENTOR_PORTRAIT := preload("res://assets/generated/core/mentor-portrait.png")
const EMBER_FOX_PORTRAIT := preload("res://assets/generated/core/ember-fox-world.png")
const JADE_HARE_PORTRAIT := preload("res://assets/generated/core/jade-hare-world.png")
const CLOUD_CRANE_PORTRAIT := preload("res://assets/generated/core/cloud-crane-world.png")
const STONE_TORTOISE_PORTRAIT := preload("res://assets/generated/core/stone-tortoise-world.png")
const THUNDER_CUB_PORTRAIT := preload("res://assets/generated/core/thunder-cub-world.png")

var _player
var _root: Control
var _health_bar: ProgressBar
var _qi_bar: ProgressBar
var _resonance_bar: ProgressBar
var _resonance_label: Label
var _level_label: Label
var _currency_label: Label
var _companion_label: Label
var _quest_label: Label
var _message_label: Label
var _target_panel: Panel
var _target_label: Label
var _target_health: ProgressBar
var _target_resolve: ProgressBar
var _target_capture: Label
var _interaction_label: Label
var _dialogue_panel: Panel
var _dialogue_label: RichTextLabel
var _dialogue_portrait: TextureRect
var _dialogue_tween: Tween
var _pause_overlay: ColorRect
var _journal_panel: Panel
var _journal_text: RichTextLabel
var _world_map_panel: Panel
var _world_map_backdrop: ColorRect
var _world_map_texture: TextureRect
var _world_map_marker_layer: Control
var _message_tween: Tween
var _cutin_panel: Panel
var _cutin_portrait: TextureRect
var _cutin_label: Label
var _cutin_tween: Tween


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_player_panel()
	_build_quest_panel()
	_build_companion_panel()
	_build_controls()
	_build_message()
	_build_target_panel()
	_build_dialogue()
	_build_combat_cutin()
	_build_journal()
	_build_world_map()
	_build_pause_overlay()


func bind_player(player) -> void:
	_player = player
	if _player.has_signal("state_changed"):
		_player.state_changed.connect(refresh_player)
	refresh_player()


func refresh_player() -> void:
	if not is_instance_valid(_player) or _health_bar == null:
		return
	_health_bar.max_value = _player.max_health
	_health_bar.value = _player.health
	_qi_bar.max_value = _player.max_qi
	_qi_bar.value = _player.qi
	_resonance_bar.max_value = _player.max_resonance
	_resonance_bar.value = _player.resonance
	_resonance_label.text = "同契  %.0f / %.0f" % [_player.resonance, _player.max_resonance]
	_level_label.text = "炼气 %d 层   修为 %d/%d" % [_player.level, _player.xp, _player.xp_for_next_level()]
	_currency_label.text = "灵石  ◈ %d" % GameState.spirit_stones


func refresh_collection() -> void:
	if _companion_label == null:
		return
	var active := GameState.get_active_beast()
	if active.is_empty():
		_companion_label.text = "灵契伙伴\n尚未缔结"
	else:
		var species := GameState.species_data(str(active.get("species_id", "")))
		_companion_label.text = "%s  Lv.%d · 羁绊 %d\n%s\n%s · 同契 %.0f" % [
			str(active.get("nickname", species.get("name", "灵兽"))),
			int(active.get("level", 1)),
			int(active.get("bond", 1)),
			str(species.get("command_name", "御灵")),
			str(species.get("command_hint", "右键主动御灵")),
			float(species.get("command_cost", 25.0)),
		]
	_refresh_journal_text()


func set_quest(text: String) -> void:
	if _quest_label != null:
		_quest_label.text = "道途指引\n" + text


func flash_message(text: String, color := Color("#f4df9b")) -> void:
	if _message_label == null:
		return
	if _message_tween != null and _message_tween.is_valid():
		_message_tween.kill()
	_message_label.text = text
	_message_label.modulate = Color(color, 1.0)
	_message_tween = create_tween()
	_message_tween.tween_interval(1.35)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.55)


func toggle_journal() -> void:
	if _journal_panel == null:
		return
	_journal_panel.visible = not _journal_panel.visible
	if _journal_panel.visible:
		_refresh_journal_text()


func toggle_world_map() -> bool:
	if _world_map_panel == null:
		return false
	_world_map_panel.visible = not _world_map_panel.visible
	if _world_map_backdrop != null:
		_world_map_backdrop.visible = _world_map_panel.visible
	if _world_map_panel.visible and _journal_panel != null:
		_journal_panel.visible = false
	return _world_map_panel.visible


func is_world_map_visible() -> bool:
	return _world_map_panel != null and _world_map_panel.visible


func refresh_world_map(player_position: Vector2, mentor_position: Vector2, beast_markers: Array) -> void:
	if _world_map_marker_layer == null:
		return
	for child in _world_map_marker_layer.get_children():
		child.free()
	_add_world_map_marker("sanctuary", WorldArena.SAFE_CENTER, Color("#62e5c0"), 16.0, "青岚阵")
	_add_world_map_marker("mentor", mentor_position, Color("#e8e6c7"), 11.0, "清虚")
	for marker in beast_markers:
		var elite := bool(marker.get("elite", false))
		var species := GameState.species_data(str(marker.get("species_id", "")))
		var marker_color := Color("#bc78ed") if elite else Color(str(species.get("color", "#d7c78c")))
		_add_world_map_marker("elite" if elite else "beast", marker.get("position", Vector2.ZERO), marker_color, 17.0 if elite else 7.0, "紫电狻猊" if elite else "")
	_add_world_map_marker("player", player_position, Color("#ffe18a"), 15.0, "你")


func world_map_marker_count(kind: String) -> int:
	if _world_map_marker_layer == null:
		return 0
	var count := 0
	for marker in _world_map_marker_layer.get_children():
		if str(marker.get_meta("marker_kind", "")) == kind:
			count += 1
	return count


func show_target(beast) -> void:
	if _target_panel == null or not is_instance_valid(beast):
		return
	var species := GameState.species_data(str(beast.species_id))
	var trait_name: String = beast.combat_trait_name()
	_target_panel.visible = true
	_target_label.text = "%s  Lv.%d  ·  %s系%s" % [str(beast.beast_name), int(beast.level), str(species.get("element", "无")), "  ·  " + trait_name if not trait_name.is_empty() else ""]
	_target_health.max_value = beast.max_health
	_target_health.value = beast.health
	_target_resolve.max_value = beast.max_resolve
	_target_resolve.value = beast.resolve
	var hint: String = beast.combat_hint()
	_target_capture.text = beast.contract_status() + ("\n" + hint if not hint.is_empty() else "")
	_target_capture.add_theme_color_override("font_color", Color("#8cf0c3") if beast.can_contract() else Color("#f2d87c") if beast.has_link_mark() else Color("#d6b3e4"))


func hide_target() -> void:
	if _target_panel != null:
		_target_panel.visible = false


func set_interaction_hint(text: String) -> void:
	if _interaction_label == null:
		return
	_interaction_label.text = text
	_interaction_label.visible = not text.is_empty()


func show_dialogue(speaker: String, text: String) -> void:
	if _dialogue_panel == null:
		return
	if _dialogue_tween != null and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	_dialogue_panel.visible = true
	_dialogue_panel.modulate = Color.WHITE
	_dialogue_portrait.texture = MENTOR_PORTRAIT
	_dialogue_label.text = "[b][color=#b6e8cd]%s[/color][/b]\n%s" % [speaker, text]
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_interval(5.0)
	_dialogue_tween.tween_property(_dialogue_panel, "modulate:a", 0.0, 0.45)
	_dialogue_tween.tween_callback(func() -> void: _dialogue_panel.visible = false)


func show_combat_cutin(species_id: String, caption: String) -> void:
	var portrait := _spirit_portrait(species_id)
	if portrait == null:
		return
	_show_cutin(portrait, caption)


func show_player_cutin(caption: String) -> void:
	_show_cutin(WANDERER_PORTRAIT, caption)


func _show_cutin(portrait: Texture2D, caption: String) -> void:
	if _cutin_panel == null:
		return
	if _cutin_tween != null and _cutin_tween.is_valid():
		_cutin_tween.kill()
	_cutin_portrait.texture = portrait
	_cutin_label.text = caption
	_cutin_panel.visible = true
	_cutin_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_cutin_tween = create_tween()
	_cutin_tween.tween_property(_cutin_panel, "modulate:a", 1.0, 0.1)
	_cutin_tween.tween_interval(0.32)
	_cutin_tween.tween_property(_cutin_panel, "modulate:a", 0.0, 0.16)
	_cutin_tween.tween_callback(func() -> void: _cutin_panel.visible = false)


func _spirit_portrait(species_id: String) -> Texture2D:
	match species_id:
		"ember_fox":
			return EMBER_FOX_PORTRAIT
		"jade_hare":
			return JADE_HARE_PORTRAIT
		"cloud_crane":
			return CLOUD_CRANE_PORTRAIT
		"stone_tortoise":
			return STONE_TORTOISE_PORTRAIT
		"thunder_cub":
			return THUNDER_CUB_PORTRAIT
	return null


func set_paused(paused: bool) -> void:
	if _pause_overlay != null:
		_pause_overlay.visible = paused


func _build_player_panel() -> void:
	var panel := _panel(Rect2(24, 22, 330, 158))
	var title := _label("云游修士", Vector2(18, 11), 20)
	panel.add_child(title)
	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(18, 43)
	_health_bar.size = Vector2(294, 23)
	_health_bar.show_percentage = false
	_health_bar.modulate = Color("#e36b63")
	panel.add_child(_health_bar)
	var health_caption := _label("气血", Vector2(25, 43), 14)
	health_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(health_caption)
	_qi_bar = ProgressBar.new()
	_qi_bar.position = Vector2(18, 72)
	_qi_bar.size = Vector2(294, 17)
	_qi_bar.show_percentage = false
	_qi_bar.modulate = Color("#55cdb5")
	panel.add_child(_qi_bar)
	_resonance_bar = ProgressBar.new()
	_resonance_bar.position = Vector2(18, 95)
	_resonance_bar.size = Vector2(294, 13)
	_resonance_bar.show_percentage = false
	_resonance_bar.modulate = Color("#d8a9ed")
	panel.add_child(_resonance_bar)
	_resonance_label = _label("同契  55 / 100", Vector2(18, 90), 12)
	_resonance_label.size = Vector2(294, 18)
	_resonance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resonance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_resonance_label)
	_level_label = _label("炼气 1 层", Vector2(18, 122), 15)
	panel.add_child(_level_label)
	_currency_label = _label("灵石  ◈ 0", Vector2(200, 122), 15)
	panel.add_child(_currency_label)


func _build_quest_panel() -> void:
	var panel := _panel(Rect2(926, 22, 330, 104))
	_quest_label = _label("道途指引\n初试灵契", Vector2(18, 13), 17)
	_quest_label.size = Vector2(294, 76)
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_quest_label)


func _build_companion_panel() -> void:
	var panel := _panel(Rect2(24, 562, 280, 132))
	_companion_label = _label("灵契伙伴\n尚未缔结", Vector2(18, 13), 17)
	_companion_label.size = Vector2(245, 108)
	panel.add_child(_companion_label)


func _build_controls() -> void:
	var panel := _panel(Rect2(320, 642, 640, 52), Color(0.02, 0.05, 0.06, 0.78))
	var label := _label("WASD 移动  左键剑诀  右键御灵  Space 闪避  Q 结契  R 换伴  Tab 兽谱  M 全图", Vector2(16, 14), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(608, 24)
	panel.add_child(label)


func _build_message() -> void:
	_message_label = _label("", Vector2(390, 164), 24)
	_message_label.size = Vector2(500, 40)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_message_label.add_theme_constant_override("shadow_offset_x", 2)
	_message_label.add_theme_constant_override("shadow_offset_y", 2)
	_root.add_child(_message_label)


func _build_target_panel() -> void:
	_target_panel = _panel(Rect2(460, 22, 360, 148), Color(0.02, 0.055, 0.065, 0.92))
	_target_panel.visible = false
	_target_label = _label("灵兽", Vector2(18, 11), 18)
	_target_label.size = Vector2(324, 26)
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_panel.add_child(_target_label)
	_target_health = ProgressBar.new()
	_target_health.position = Vector2(30, 39)
	_target_health.size = Vector2(300, 13)
	_target_health.show_percentage = false
	_target_health.modulate = Color("#76cf83")
	_target_panel.add_child(_target_health)
	_target_resolve = ProgressBar.new()
	_target_resolve.position = Vector2(30, 60)
	_target_resolve.size = Vector2(300, 11)
	_target_resolve.show_percentage = false
	_target_resolve.modulate = Color("#d8a9ed")
	_target_panel.add_child(_target_resolve)
	_target_capture = _label("执念", Vector2(18, 81), 14)
	_target_capture.size = Vector2(324, 53)
	_target_capture.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_capture.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_panel.add_child(_target_capture)


func _build_dialogue() -> void:
	_interaction_label = _label("", Vector2(440, 594), 17)
	_interaction_label.size = Vector2(400, 32)
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.add_theme_color_override("font_color", Color("#f2d87c"))
	_interaction_label.visible = false
	_root.add_child(_interaction_label)
	_dialogue_panel = _panel(Rect2(270, 432, 740, 178), Color(0.018, 0.05, 0.06, 0.96))
	_dialogue_panel.visible = false
	_dialogue_portrait = TextureRect.new()
	_dialogue_portrait.position = Vector2(16, 10)
	_dialogue_portrait.size = Vector2(150, 158)
	_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(_dialogue_portrait)
	_dialogue_label = RichTextLabel.new()
	_dialogue_label.position = Vector2(174, 20)
	_dialogue_label.size = Vector2(538, 138)
	_dialogue_label.bbcode_enabled = true
	_dialogue_label.fit_content = false
	_dialogue_label.scroll_active = false
	_dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_label.add_theme_font_size_override("normal_font_size", 18)
	_dialogue_label.add_theme_font_size_override("bold_font_size", 20)
	_dialogue_panel.add_child(_dialogue_label)


func _build_combat_cutin() -> void:
	_cutin_panel = _panel(Rect2(916, 166, 340, 400), Color(0.015, 0.035, 0.045, 0.94))
	_cutin_panel.visible = false
	_cutin_portrait = TextureRect.new()
	_cutin_portrait.position = Vector2(10, 10)
	_cutin_portrait.size = Vector2(320, 330)
	_cutin_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cutin_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cutin_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin_panel.add_child(_cutin_portrait)
	_cutin_label = _label("同契破势", Vector2(12, 350), 22)
	_cutin_label.size = Vector2(316, 34)
	_cutin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cutin_label.add_theme_color_override("font_color", Color("#f2d87c"))
	_cutin_panel.add_child(_cutin_label)


func _build_journal() -> void:
	_journal_panel = _panel(Rect2(330, 132, 620, 456), Color(0.025, 0.07, 0.075, 0.96))
	_journal_panel.visible = false
	_journal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var title := _label("灵 兽 谱", Vector2(24, 18), 27)
	title.size = Vector2(572, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_journal_panel.add_child(title)
	_journal_text = RichTextLabel.new()
	_journal_text.position = Vector2(34, 74)
	_journal_text.size = Vector2(552, 338)
	_journal_text.bbcode_enabled = true
	_journal_text.fit_content = false
	_journal_text.scroll_active = true
	_journal_text.add_theme_font_size_override("normal_font_size", 18)
	_journal_text.add_theme_font_size_override("bold_font_size", 20)
	_journal_panel.add_child(_journal_text)
	var hint := _label("R 切换出战伙伴 · Tab 关闭", Vector2(24, 419), 14)
	hint.size = Vector2(572, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_journal_panel.add_child(hint)


func _build_world_map() -> void:
	_world_map_backdrop = ColorRect.new()
	_world_map_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_map_backdrop.color = Color(0.004, 0.012, 0.016, 0.86)
	_world_map_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_world_map_backdrop.visible = false
	_root.add_child(_world_map_backdrop)
	_world_map_panel = _panel(Rect2(160, 42, 960, 636), Color(0.012, 0.035, 0.04, 0.98))
	_world_map_panel.visible = false
	_world_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var title := _label("青 岚 谷 · 山 河 全 图", Vector2(24, 13), 25)
	title.size = Vector2(912, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_map_panel.add_child(title)
	_world_map_texture = TextureRect.new()
	_world_map_texture.name = "CompleteQinglanValleyMap"
	_world_map_texture.position = Vector2(70, 54)
	_world_map_texture.size = Vector2(820, 527)
	_world_map_texture.texture = QINGLAN_MAP_TEXTURE
	_world_map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_world_map_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_world_map_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_world_map_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map_panel.add_child(_world_map_texture)
	var map_border := ReferenceRect.new()
	map_border.position = _world_map_texture.position
	map_border.size = _world_map_texture.size
	map_border.border_color = Color("#8fc8a7")
	map_border.border_width = 2.0
	map_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map_panel.add_child(map_border)
	_world_map_marker_layer = Control.new()
	_world_map_marker_layer.name = "DynamicMapMarkers"
	_world_map_marker_layer.position = _world_map_texture.position
	_world_map_marker_layer.size = _world_map_texture.size
	_world_map_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map_panel.add_child(_world_map_marker_layer)
	var legend := _label("◆ 你   ● 青岚阵   ● 清虚散人   • 野生灵兽   ✦ 首领试炼                     M / Esc 关闭", Vector2(34, 594), 15)
	legend.size = Vector2(892, 26)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_color_override("font_color", Color("#dceade"))
	_world_map_panel.add_child(legend)


func _add_world_map_marker(kind: String, world_position: Vector2, color: Color, diameter: float, caption: String) -> void:
	var normalized := WorldArena.normalized_map_position(world_position)
	var marker := Panel.new()
	marker.name = "MapMarker_%s" % kind
	marker.set_meta("marker_kind", kind)
	marker.position = Vector2(normalized.x * _world_map_marker_layer.size.x, normalized.y * _world_map_marker_layer.size.y) - Vector2.ONE * diameter * 0.5
	marker.size = Vector2.ONE * diameter
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 3 if kind == "player" else 2 if kind == "elite" else 1
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.015, 0.025, 0.03, 0.9)
	style.set_border_width_all(2 if diameter >= 11.0 else 1)
	style.set_corner_radius_all(int(diameter * 0.5))
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 3
	marker.add_theme_stylebox_override("panel", style)
	_world_map_marker_layer.add_child(marker)
	if not caption.is_empty():
		var caption_position := Vector2(diameter + 4.0, -4.0)
		if kind == "sanctuary":
			caption_position = Vector2(-62.0, -4.0)
		elif kind == "elite":
			caption_position = Vector2(-82.0, -4.0)
		var label := _label(caption, caption_position, 13)
		label.size = Vector2(100, 22)
		label.add_theme_color_override("font_color", color.lightened(0.18))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		marker.add_child(label)


func _build_pause_overlay() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.color = Color(0.008, 0.018, 0.025, 0.76)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.visible = false
	_root.add_child(_pause_overlay)
	var panel := Panel.new()
	panel.position = Vector2(390, 236)
	panel.size = Vector2(500, 248)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.05, 0.06, 0.97)
	style.border_color = Color("#8fc8a7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	_pause_overlay.add_child(panel)
	var title := _label("云 游 暂 歇", Vector2(20, 28), 34)
	title.size = Vector2(460, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var body := _label("青岚谷的时间已凝止\n\nWASD 移动  ·  左键剑诀  ·  右键主动御灵\nSpace 踏风  ·  Q 契机结契  ·  R 换伙伴  ·  M 全图", Vector2(25, 91), 18)
	body.size = Vector2(450, 96)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(body)
	var resume := _label("按 Esc 继续", Vector2(20, 204), 18)
	resume.size = Vector2(460, 28)
	resume.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume.add_theme_color_override("font_color", Color("#f2d87c"))
	panel.add_child(resume)


func _refresh_journal_text() -> void:
	if _journal_text == null:
		return
	if GameState.collection.is_empty():
		_journal_text.text = "[center][color=#9cb6ae]尚未缔结灵兽。\n先右键御灵制造灵印，再以剑诀追击破势。[/color][/center]"
		return
	var lines: Array[String] = []
	for beast in GameState.collection:
		var species := GameState.species_data(str(beast.get("species_id", "")))
		var marker := "[color=#f2d87c]◆ 出战[/color]" if str(beast.get("uid", "")) == GameState.active_beast_uid else "◇ 待命"
		lines.append("%s  [b]%s[/b]  Lv.%d  ·  %s系  ·  羁绊 %d  ·  [color=#b7efd1]%s[/color]  ·  修为 %d/%d" % [
			marker,
			str(beast.get("nickname", species.get("name", "灵兽"))),
			int(beast.get("level", 1)),
			str(species.get("element", "无")),
			int(beast.get("bond", 1)),
			str(species.get("command_name", "御灵")),
			int(beast.get("xp", 0)),
			int(beast.get("level", 1)) * 45,
		])
	_journal_text.text = "\n\n".join(lines)


func _panel(rect: Rect2, color := Color(0.02, 0.055, 0.065, 0.9)) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#6f9f87")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	var ornament := NinePatchRect.new()
	ornament.name = "KenneyBorder"
	ornament.position = Vector2.ZERO
	ornament.size = rect.size
	ornament.texture = PANEL_BORDER_TEXTURE
	ornament.patch_margin_left = 16
	ornament.patch_margin_top = 16
	ornament.patch_margin_right = 16
	ornament.patch_margin_bottom = 16
	ornament.draw_center = false
	ornament.modulate = Color(0.58, 0.82, 0.68, 0.72)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ornament)
	return panel


func _label(text: String, position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#e7eee9"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
