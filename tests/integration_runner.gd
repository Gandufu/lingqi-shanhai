extends Node

const MainScene := preload("res://scenes/main.tscn")
const CompanionActor := preload("res://scripts/entities/companion.gd")

var _checks := 0
var _failures := 0
var _main
var _original_save_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_original_save_path = GameState.save_path
	GameState.save_path = "user://lingqi_integration_test_save.json"
	_cleanup_test_save()
	_main = MainScene.instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().physics_frame

	_check(is_instance_valid(_main.player), "main scene creates player")
	_check(is_instance_valid(_main.world), "main scene creates world arena")
	_check(is_instance_valid(_main.audio), "main scene creates audio manager")
	_check(is_instance_valid(_main.hud), "main scene creates HUD")
	_check(is_instance_valid(_main.mentor), "main scene creates mentor")
	_check(_main.world.has_node("QinglanValleyGeneratedMap"), "world uses the complete generated Qinglan Valley map")
	_check(InputMap.has_action("toggle_world_map"), "RPG overview map has a dedicated input action")
	_main._toggle_world_map()
	_check(get_tree().paused and _main.hud.is_world_map_visible(), "opening the overview map safely freezes real-time combat")
	_check(_main.hud._world_map_texture.texture != null, "overview map reuses the complete painted Qinglan Valley")
	_check(_main.hud._world_map_marker_layer.get_child_count() >= 5, "overview map plots the cultivator, sanctuary, mentor, wild beasts and boss")
	_check(_main.hud.world_map_marker_count("player") == 1, "overview map has exactly one readable player marker")
	_check(_main.hud.world_map_marker_count("elite") == 1, "fresh overview map reveals the explicit elite trial")
	_main._toggle_world_map()
	_check(not get_tree().paused and not _main.hud.is_world_map_visible(), "closing the overview map resumes combat without leaving an overlay")
	_check(is_instance_valid(_main.player._outline_sprite), "cultivator sprite has a contrast outline on the painted map")
	_check(is_instance_valid(_main.mentor._outline_sprite), "mentor sprite has a contrast outline on the painted map")
	_check(_main.player._sprite.hframes == 4 and _main.player._sprite.vframes == 4, "cultivator uses a real sixteen-frame directional walk sheet")
	var player_rows: Array[int] = []
	for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]:
		_main.player._facing = direction
		_main.player.velocity = direction * 100.0
		_main.player._update_sprite()
		player_rows.append(_main.player._sprite.frame_coords.y)
	_check(player_rows == [0, 1, 2, 3], "cultivator selects distinct down, right, left and up rows")
	_main.player._walk_animation_time = 0.0
	_main.player._update_sprite(0.13)
	var first_walk_frame: int = _main.player._sprite.frame_coords.x
	_main.player._update_sprite(0.13)
	_check(_main.player._sprite.frame_coords.x != first_walk_frame, "cultivator advances through distinct footfall frames while moving")
	_main.player.velocity = Vector2.ZERO
	_main.player._facing = Vector2.RIGHT
	_main.player._update_sprite()
	_check(get_tree().get_nodes_in_group("wild_beasts").size() >= 15, "main scene populates wild beasts")
	_check(get_tree().get_nodes_in_group("wild_beasts").any(func(beast) -> bool: return bool(beast.is_elite)), "fresh world contains one explicit elite")
	_check(get_tree().get_nodes_in_group("wild_beasts").all(func(beast) -> bool: return is_instance_valid(beast._sprite)), "all five wild species use generated world sprites")
	_check(get_tree().get_nodes_in_group("wild_beasts").all(func(beast) -> bool: return is_instance_valid(beast._outline_sprite)), "all wild beasts keep a readable silhouette against the full map")
	_check(get_tree().get_nodes_in_group("wild_beasts").all(func(beast) -> bool: return beast._sprite.hframes == 4 and beast._sprite.vframes == 4), "all five wild species use sixteen-frame directional animation sheets")
	var wild_direction_cycles_valid := true
	var wild_windups_valid := true
	for species_id in ["ember_fox", "jade_hare", "cloud_crane", "stone_tortoise", "thunder_cub"]:
		var animated_beast = get_tree().get_nodes_in_group("wild_beasts").filter(func(beast) -> bool: return beast.species_id == species_id)[0]
		animated_beast.velocity = Vector2.RIGHT * 100.0
		animated_beast._walk_animation_time = 0.0
		animated_beast._update_generated_sprite(0.13)
		var first_species_frame: int = animated_beast._sprite.frame_coords.x
		animated_beast._update_generated_sprite(0.13)
		var expected_right_row := 2 if species_id == "cloud_crane" else 1
		wild_direction_cycles_valid = wild_direction_cycles_valid and animated_beast._sprite.frame_coords.y == expected_right_row and animated_beast._sprite.frame_coords.x != first_species_frame
		animated_beast.velocity = Vector2.ZERO
		animated_beast._visual_facing = Vector2.RIGHT
		animated_beast._attack_windup = 0.3
		animated_beast._update_generated_sprite()
		wild_windups_valid = wild_windups_valid and animated_beast._sprite.frame_coords.x >= 2
		animated_beast._attack_windup = 0.0
		animated_beast._pending_attack = ""
		animated_beast._update_generated_sprite()
	_check(wild_direction_cycles_valid, "all five wild species turn correctly and advance through distinct movement frames")
	_check(wild_windups_valid, "all five wild species switch to readable anticipation frames during attack windup")
	_check(GameState.collection.size() == 1 and str(GameState.collection[0].get("species_id", "")) == "jade_hare", "fresh journey starts with the loaned jade hare")
	_check(is_instance_valid(_main.companion), "starter is active immediately so the core loop is available")
	_check(is_instance_valid(_main.companion._outline_sprite), "active companion keeps a readable silhouette against the full map")
	_check(_main.companion._sprite.hframes == 4 and _main.companion._sprite.vframes == 4, "starter hare uses a real sixteen-frame directional hop sheet")
	_main.companion._visual_facing = Vector2.LEFT
	_main.companion.velocity = Vector2.LEFT * 100.0
	_main.companion._walk_animation_time = 0.0
	_main.companion._update_generated_sprite(0.13)
	var first_hop_frame: int = _main.companion._sprite.frame_coords.x
	_main.companion._update_generated_sprite(0.13)
	_check(_main.companion._sprite.frame_coords.y == 2 and _main.companion._sprite.frame_coords.x != first_hop_frame, "starter hare turns left and advances through a hop cycle")
	_main.companion.velocity = Vector2.ZERO
	_main.companion._update_generated_sprite()
	var all_companion_sheets_valid := true
	for species_id in ["ember_fox", "jade_hare", "cloud_crane", "stone_tortoise", "thunder_cub"]:
		var preview_companion = CompanionActor.new()
		preview_companion.setup({"species_id": species_id, "nickname": "动画验收", "level": 1}, _main.player)
		add_child(preview_companion)
		all_companion_sheets_valid = all_companion_sheets_valid and preview_companion._sprite.hframes == 4 and preview_companion._sprite.vframes == 4
		preview_companion.queue_free()
	_check(all_companion_sheets_valid, "all five captured species retain directional animation as active companions")
	_main.hud.show_combat_cutin("jade_hare", "测试御灵切入")
	_check(_main.hud._cutin_panel.visible and _main.hud._cutin_portrait.texture != null, "companion command can show a non-blocking high-resolution cut-in")
	_main.hud.show_player_cutin("测试剑诀切入")
	_check(_main.hud._cutin_portrait.texture == _main.hud.WANDERER_PORTRAIT, "confirmed link can switch the cut-in to the cultivator portrait")
	_main.hud.show_dialogue("清虚散人", "测试导师立绘")
	_check(_main.hud._dialogue_portrait.texture == _main.hud.MENTOR_PORTRAIT, "mentor dialogue uses the high-resolution portrait layer")

	var first_beast = get_tree().get_nodes_in_group("wild_beasts")[0]
	first_beast.global_position = _main.player.global_position + Vector2(300, 0)
	_main._on_companion_command(first_beast.global_position)
	for _index in range(30):
		await get_tree().physics_frame
	_check(first_beast.has_link_mark(), "right-click command places a visible link mark")
	var resonance_before_repeat: float = _main.player.resonance
	_main._on_companion_command(first_beast.global_position)
	_check(is_equal_approx(_main.player.resonance, resonance_before_repeat), "repeated command cannot waste resonance while a link mark is active")
	first_beast.take_damage(0.0, _main.player)
	_check(GameState.quest_link_count == 1, "player follow-up records a link strike")
	while not first_beast.can_contract():
		first_beast.apply_link_mark("jade_hare", 10.0)
		first_beast.take_damage(0.0, _main.player)
	_check(first_beast.can_contract(), "resolve break creates a deterministic capture opening")
	first_beast.try_capture()
	await get_tree().process_frame
	_check(GameState.collection.size() == 2, "contracted beast enters collection beside starter")
	_check(is_instance_valid(_main.companion), "capturing preserves an active companion")
	_check(FileAccess.file_exists(GameState.save_path), "capture writes isolated save")
	_main._on_cycle_companion()
	await get_tree().process_frame
	_check(GameState.quest_switch_count == 1, "switching after capture advances grammar comparison")
	_check(_main.companion.species_id == "ember_fox" and _main.companion.command_name == "焰尾突", "switching exposes the fox's short-window grammar")
	_check(_main.companion._sprite.hframes == 4 and _main.companion._sprite.vframes == 4, "captured ember fox uses a real sixteen-frame directional run sheet")
	_main.companion._visual_facing = Vector2.RIGHT
	_main.companion.velocity = Vector2.RIGHT * 100.0
	_main.companion._walk_animation_time = 0.0
	_main.companion._update_generated_sprite(0.13)
	var first_fox_frame: int = _main.companion._sprite.frame_coords.x
	_main.companion._update_generated_sprite(0.13)
	_check(_main.companion._sprite.frame_coords.y == 1 and _main.companion._sprite.frame_coords.x != first_fox_frame, "captured ember fox turns right and advances through its run cycle")
	_main.companion.velocity = Vector2.ZERO
	_main.companion._update_generated_sprite()

	var tortoise = get_tree().get_nodes_in_group("wild_beasts").filter(func(beast) -> bool: return beast.species_id == "stone_tortoise")[0]
	_main.hud.show_target(tortoise)
	_check(_main.hud._target_panel.size.y >= 148.0, "expanded target panel leaves room for a readable combat hint")
	_check(_main.hud._target_label.text.contains("玄甲"), "target title exposes the tortoise combat trait")
	_check(_main.hud._target_capture.text.contains("焰尾"), "target panel explains the fox counter before engagement")
	tortoise.global_position = _main.player.global_position + Vector2(300, 0)
	_main._on_companion_command(tortoise.global_position)
	for _index in range(60):
		await get_tree().physics_frame
	_check(tortoise.has_link_mark(), "fox command can reach the fixed armor lesson")
	tortoise.take_damage(0.0, _main.player)
	_check(tortoise.is_armor_broken(), "fox confirmation breaks tortoise armor in the main scene")
	_check(GameState.quest_armor_break_count == 1, "armor counter lesson advances from a real link signal")

	_main._on_cycle_companion()
	await get_tree().process_frame
	_check(_main.companion.species_id == "jade_hare", "second switch returns to the hare grammar")
	var crane = get_tree().get_nodes_in_group("wild_beasts").filter(func(beast) -> bool: return beast.species_id == "cloud_crane")[0]
	_main.hud.show_target(crane)
	_check(_main.hud._target_label.text.contains("御风"), "target title exposes the crane combat trait")
	_check(_main.hud._target_capture.text.contains("月影"), "target panel explains the hare counter before engagement")
	crane.global_position = _main.player.global_position + Vector2(300, 0)
	_main._on_companion_command(crane.global_position)
	for _index in range(30):
		await get_tree().physics_frame
	_check(crane.has_link_mark() and crane.is_wind_bound(), "hare command pins the fixed wind lesson")
	crane.take_damage(0.0, _main.player)
	_check(GameState.quest_wind_bind_count == 1, "wind counter lesson advances from a real link signal")

	var elite = get_tree().get_nodes_in_group("wild_beasts").filter(func(beast) -> bool: return bool(beast.is_elite))[0]
	_main.hud.show_target(elite)
	_check(_main.hud._target_label.text.contains("雷狩"), "elite target panel starts with a readable phase-one title")
	while elite.elite_phase() == 1:
		elite.apply_link_mark("jade_hare", 10.0)
		elite.take_damage(0.0, _main.player)
	await get_tree().process_frame
	_main.hud.show_target(elite)
	_check(elite.elite_phase() == 2 and _main.hud._target_label.text.contains("雷甲"), "boss transition updates the target title to phase two")
	_check(_main.hud._target_capture.text.contains("焰尾"), "phase-two HUD names the fox counter")
	_check(_main.hud._cutin_panel.visible and _main.hud._cutin_label.text.contains("首领转势"), "boss phase transition triggers a non-blocking portrait cut-in")
	while elite.elite_phase() == 2:
		elite.apply_link_mark("ember_fox", 10.0)
		elite.take_damage(0.0, _main.player)
	await get_tree().process_frame
	_main.hud.show_target(elite)
	_check(elite.elite_phase() == 3 and _main.hud._target_label.text.contains("雷行"), "fox counter advances the boss into its final phase")
	_check(_main.hud._target_capture.text.contains("月影"), "final-phase HUD names the hare counter")
	elite.apply_link_mark("jade_hare", 10.0)
	_check(elite.is_storm_bound(), "hare command stops final-phase pursuit in the live scene")
	elite.take_damage(0.0, _main.player)
	while not elite.can_contract():
		elite.apply_link_mark("jade_hare", 10.0)
		elite.take_damage(0.0, _main.player)
	var stones_before_elite_contract: int = GameState.spirit_stones
	_main._on_beast_captured(elite)
	await get_tree().process_frame
	_check(GameState.elite_defeated, "contracting the elite records the same permanent victory as defeating it")
	_check(GameState.spirit_stones == stones_before_elite_contract + 51, "elite contract grants the capture stone plus the full fifty-stone boss reward")

	var next_beast = get_tree().get_nodes_in_group("wild_beasts")[0]
	var defeats_before: int = GameState.quest_defeat_count
	_main._on_beast_defeated(next_beast, 36)
	await get_tree().process_frame
	_check(GameState.quest_defeat_count == defeats_before + 1, "defeat advances quest counter")

	var child_count_before: int = _main.get_child_count()
	_main._on_beast_projectile(Vector2(100, 100), Vector2.RIGHT, 8.0, Color.WHITE, 200.0, "测试术法")
	_check(_main.get_child_count() == child_count_before + 1, "enemy projectile enters world")

	_main._toggle_pause()
	_check(get_tree().paused, "pause freezes scene tree")
	_main._toggle_pause()
	_check(not get_tree().paused, "pause toggle resumes scene tree")

	_main.audio.stop_all()
	_main.queue_free()
	for _index in range(12):
		await get_tree().process_frame
	_cleanup_test_save()
	GameState.save_path = _original_save_path
	if _failures == 0:
		print("INTEGRATION PASS: %d checks" % _checks)
	else:
		push_error("INTEGRATION FAIL: %d of %d checks failed" % [_failures, _checks])
	get_tree().quit(_failures)


func _cleanup_test_save() -> void:
	if FileAccess.file_exists(GameState.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("INTEGRATION ASSERTION FAILED: " + label)
