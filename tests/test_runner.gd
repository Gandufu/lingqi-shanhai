extends Node

const InputSetup = preload("res://scripts/input_setup.gd")
const AudioController = preload("res://scripts/audio/audio_manager.gd")
const PlayerActor = preload("res://scripts/entities/player.gd")
const SpiritBeast = preload("res://scripts/entities/spirit_beast.gd")
const Companion = preload("res://scripts/entities/companion.gd")
const Mentor = preload("res://scripts/entities/mentor.gd")
const WorldArena = preload("res://scripts/world/world_arena.gd")

var _failures := 0
var _checks := 0


func _ready() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	_test_collection_and_growth()
	_test_save_round_trip()
	_test_player_growth()
	_test_link_contract()
	_test_companion_grammar()
	_test_enemy_matchups()
	_test_elite_phase_counterplay()
	_test_attack_telegraphs()
	_test_mentor_guidance()
	_test_input_registration()
	_test_audio_cue_registry()
	_test_world_spawn_contract()
	if _failures == 0:
		print("TEST PASS: %d checks" % _checks)
	else:
		push_error("TEST FAIL: %d of %d checks failed" % [_failures, _checks])
	get_tree().quit(_failures)


func _test_collection_and_growth() -> void:
	GameState.new_game()
	_check(GameState.collection.is_empty(), "new game starts with an empty collection")
	var starter := GameState.grant_starter_beast()
	_check(str(starter.get("species_id", "")) == "jade_hare", "empty collection receives the jade hare starter")
	_check(GameState.quest_capture_count == 0, "loaned starter does not count as a capture")
	_check(GameState.grant_starter_beast().is_empty() and GameState.collection.size() == 1, "starter can only be granted once")
	GameState.new_game()
	var first := GameState.add_captured_beast("ember_fox", 1)
	_check(not first.is_empty(), "valid species can be captured")
	_check(GameState.active_beast_uid == str(first.get("uid", "")), "first capture becomes active")
	var invalid := GameState.add_captured_beast("missing_species", 1)
	_check(invalid.is_empty(), "invalid species is rejected")
	var second := GameState.add_captured_beast("jade_hare", 1)
	var cycled := GameState.cycle_active_beast(1)
	_check(str(cycled.get("uid", "")) == str(second.get("uid", "")), "cycling selects the next beast")
	var leveled := GameState.grant_active_beast_xp(50)
	_check(leveled, "active beast levels when XP crosses threshold")
	_check(int(second.get("level", 0)) == 2, "beast level increments")
	_check(int(second.get("xp", -1)) == 5, "overflow beast XP is preserved")


func _test_save_round_trip() -> void:
	var original_path: String = GameState.save_path
	GameState.save_path = "user://lingqi_automated_test_save.json"
	GameState.new_game()
	GameState.player_level = 5
	GameState.player_xp = 27
	GameState.spirit_stones = 91
	GameState.quest_link_count = 3
	GameState.quest_switch_count = 2
	GameState.quest_armor_break_count = 4
	GameState.quest_wind_bind_count = 5
	GameState.elite_defeated = true
	var captured := GameState.add_captured_beast("cloud_crane", 3)
	_check(GameState.save_game(), "save file can be written")
	GameState.new_game()
	_check(GameState.load_game(), "save file can be loaded")
	_check(GameState.player_level == 5 and GameState.player_xp == 27, "player progression survives save round trip")
	_check(GameState.spirit_stones == 91, "currency survives save round trip")
	_check(GameState.quest_link_count == 3, "link-strike tutorial progress survives save round trip")
	_check(GameState.quest_switch_count == 2, "companion-switch tutorial progress survives save round trip")
	_check(GameState.quest_armor_break_count == 4, "armor-break mastery survives save round trip")
	_check(GameState.quest_wind_bind_count == 5, "wind-bind mastery survives save round trip")
	_check(GameState.elite_defeated, "elite victory survives save round trip")
	_check(GameState.collection.size() == 1 and str(GameState.collection[0].get("uid", "")) == str(captured.get("uid", "")), "collection survives save round trip")
	_check(GameState.active_beast_uid == str(captured.get("uid", "")), "active companion survives save round trip")
	var legacy_file := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"version": 1, "player_level": 2, "collection": [], "active_beast_uid": ""}))
	legacy_file = null
	GameState.quest_link_count = 9
	GameState.quest_switch_count = 9
	GameState.quest_armor_break_count = 9
	GameState.quest_wind_bind_count = 9
	_check(GameState.load_game(), "version-one save remains readable after core-loop migration")
	_check(GameState.quest_link_count == 0 and GameState.quest_switch_count == 0 and GameState.quest_armor_break_count == 0 and GameState.quest_wind_bind_count == 0, "missing version-one tutorial fields migrate to safe defaults")
	var absolute_test_path := ProjectSettings.globalize_path(GameState.save_path)
	if FileAccess.file_exists(GameState.save_path):
		_check(DirAccess.remove_absolute(absolute_test_path) == OK, "temporary save is cleaned up")
	GameState.save_path = original_path


func _test_player_growth() -> void:
	var actor := PlayerActor.new()
	actor.configure(3, 7)
	_check(actor.level == 3, "player restores level")
	_check(is_equal_approx(actor.max_health, 148.0), "player derived health scales by level")
	var leveled := actor.add_xp(actor.xp_for_next_level())
	_check(leveled and actor.level == 4, "player can break through one realm")
	_check(actor.xp == 7, "player XP overflow is preserved")
	_check(actor.spend_resonance(30.0), "player can spend resonance on a companion command")
	_check(is_equal_approx(actor.resonance, 25.0), "resonance spend is exact")
	actor.gain_resonance(200.0)
	_check(is_equal_approx(actor.resonance, actor.max_resonance), "resonance gain respects its cap")
	actor.free()


func _test_link_contract() -> void:
	var beast := SpiritBeast.new()
	beast.setup("stone_tortoise", 1, Vector2.ZERO, null)
	_check(not beast.can_contract(), "capture is impossible before resolve breaks")
	var cultivator := Node2D.new()
	cultivator.add_to_group("player")
	var link_count := 0
	while not beast.can_contract() and link_count < 5:
		beast.apply_link_mark("ember_fox", 12.0)
		_check(beast.has_link_mark(), "companion command creates a timed link mark")
		beast.take_damage(0.0, cultivator)
		link_count += 1
	_check(link_count == 2, "fox grammar breaks a level-one beast in two confirmed links")
	_check(beast.can_contract(), "resolve break opens a deterministic contract window")
	_check(beast.can_contract(), "contract is guaranteed inside the opening")
	_check(beast.health >= 1.0, "resolve break cannot accidentally kill the contract target")
	var normal_resolve := beast.max_resolve
	cultivator.free()
	beast.free()
	var elite := SpiritBeast.new()
	elite.setup("thunder_cub", 4, Vector2.ZERO, null, true)
	_check(elite.is_elite, "elite identity is explicit rather than inferred from level")
	_check(elite.max_resolve > normal_resolve, "elite has a larger resolve budget")
	var elite_cultivator := Node2D.new()
	elite_cultivator.add_to_group("player")
	var elite_links := 0
	while not elite.can_contract() and elite_links < 8:
		elite.apply_link_mark("jade_hare", 10.0)
		elite.take_damage(18.0, elite_cultivator)
		elite_links += 1
	_check(elite.can_contract() and elite.health >= 1.0, "elite can be subdued nonlethally with repeated confirmed links")
	elite_cultivator.free()
	elite.free()


func _test_companion_grammar() -> void:
	var fox_data := GameState.species_data("ember_fox")
	var hare_data := GameState.species_data("jade_hare")
	_check(float(fox_data.get("link_window", 0.0)) < float(hare_data.get("link_window", 0.0)), "fox asks for a faster follow-up than hare")
	_check(float(fox_data.get("resolve_damage", 0.0)) > float(hare_data.get("resolve_damage", 0.0)), "fox trades timing risk for more resolve damage")
	_check(str(fox_data.get("link_effect", "")) == "burst" and str(hare_data.get("link_effect", "")) == "heal", "fox and hare create different link rewards")
	var companion := Companion.new()
	companion.setup({"species_id": "jade_hare", "nickname": "试炼月兔", "level": 1}, Node2D.new())
	_check(companion.command_name == "月影缚" and companion.command_style == "snare", "companion loads its active grammar from species data")
	companion.follow_target.free()
	companion.free()


func _test_enemy_matchups() -> void:
	var cultivator := Node2D.new()
	cultivator.add_to_group("player")
	var armored := SpiritBeast.new()
	armored.setup("stone_tortoise", 1, Vector2.ZERO, null)
	var armored_health := armored.health
	armored.take_damage(20.0, cultivator)
	_check(is_equal_approx(armored_health - armored.health, 6.4), "intact tortoise armor visibly reduces ordinary sword damage")
	_check(armored.combat_trait_name() == "玄甲" and armored.combat_hint().contains("焰尾"), "tortoise exposes a readable fox counter hint")

	var hare_tortoise := SpiritBeast.new()
	hare_tortoise.setup("stone_tortoise", 1, Vector2.ZERO, null)
	var hare_tortoise_resolve := hare_tortoise.resolve
	hare_tortoise.apply_link_mark("jade_hare", 10.0)
	hare_tortoise.take_damage(0.0, cultivator)
	var hare_armor_damage := hare_tortoise_resolve - hare_tortoise.resolve
	_check(not hare_tortoise.is_armor_broken(), "hare remains viable but does not break玄甲")

	var fox_tortoise := SpiritBeast.new()
	fox_tortoise.setup("stone_tortoise", 1, Vector2.ZERO, null)
	var fox_tortoise_resolve := fox_tortoise.resolve
	fox_tortoise.apply_link_mark("ember_fox", 10.0)
	fox_tortoise.take_damage(0.0, cultivator)
	var fox_armor_damage := fox_tortoise_resolve - fox_tortoise.resolve
	_check(fox_tortoise.is_armor_broken(), "fox link opens a five-second armor break window")
	_check(fox_armor_damage > hare_armor_damage * 3.0, "fox decisively outperforms hare against玄甲")
	var broken_health := fox_tortoise.health
	fox_tortoise.take_damage(20.0, cultivator)
	_check(is_equal_approx(broken_health - fox_tortoise.health, 20.0), "sword damage is restored while玄甲 is broken")

	var hare_crane := SpiritBeast.new()
	hare_crane.setup("cloud_crane", 1, Vector2.ZERO, null)
	var hare_crane_resolve := hare_crane.resolve
	hare_crane.apply_link_mark("jade_hare", 10.0)
	_check(hare_crane.is_wind_bound(), "hare command immediately pins a retreating crane")
	hare_crane.take_damage(0.0, cultivator)
	var hare_wind_damage := hare_crane_resolve - hare_crane.resolve
	_check(hare_crane.combat_trait_name() == "御风" and hare_crane.combat_hint().contains("月影"), "crane exposes a readable hare counter hint")

	var fox_crane := SpiritBeast.new()
	fox_crane.setup("cloud_crane", 1, Vector2.ZERO, null)
	var fox_crane_resolve := fox_crane.resolve
	fox_crane.apply_link_mark("ember_fox", 10.0)
	fox_crane.take_damage(0.0, cultivator)
	var fox_wind_damage := fox_crane_resolve - fox_crane.resolve
	_check(hare_wind_damage > fox_wind_damage, "hare decisively outperforms fox against御风")

	armored.free()
	hare_tortoise.free()
	fox_tortoise.free()
	hare_crane.free()
	fox_crane.free()
	cultivator.free()


func _test_elite_phase_counterplay() -> void:
	var cultivator := Node2D.new()
	cultivator.add_to_group("player")
	var boss := SpiritBeast.new()
	boss.setup("thunder_cub", 4, Vector2.ZERO, cultivator, true)
	var phase_events: Array[int] = []
	var matchups: Array[String] = []
	var projectiles: Array[String] = []
	boss.elite_phase_changed.connect(func(_beast: Node, phase: int, _title: String, _hint: String) -> void: phase_events.append(phase))
	boss.link_struck.connect(func(_beast: Node, _partner: String, _effect: String, _resolve_damage: float, matchup: String) -> void: matchups.append(matchup))
	boss.request_projectile.connect(func(_origin: Vector2, _direction: Vector2, _damage: float, _color: Color, _speed: float, label: String) -> void: projectiles.append(label))

	_check(boss.elite_phase() == 1 and boss.combat_trait_name() == "雷狩", "elite begins in a readable observation phase")
	boss._pending_attack = "ranged"
	boss._pending_aim = Vector2.RIGHT
	boss._execute_pending_attack()
	_check(projectiles.size() == 3, "phase-one elite opens with a readable three-bolt fan")

	while boss.elite_phase() == 1:
		boss.apply_link_mark("jade_hare", 10.0)
		boss.take_damage(0.0, cultivator)
	_check(boss.elite_phase() == 2 and phase_events == [2], "resolve threshold gates the elite into phase two exactly once")
	_check(is_equal_approx(boss.resolve, boss.max_resolve * 0.66), "phase-two gate preserves its full雷甲 lesson")
	_check(boss.combat_trait_name() == "雷甲" and boss.combat_hint().contains("焰尾"), "phase two exposes the fox counter before the player commits")
	projectiles.clear()
	boss._pending_attack = "ranged"
	boss._pending_aim = Vector2.RIGHT
	boss._execute_pending_attack()
	_check(projectiles.size() == 5, "雷甲 phase changes the attack into a wider five-bolt fan")
	var armored_health := boss.health
	boss.take_damage(20.0, cultivator)
	_check(is_equal_approx(armored_health - boss.health, 8.4), "雷甲 reduces ordinary sword damage while intact")
	var wrong_partner_resolve := boss.resolve
	boss.apply_link_mark("jade_hare", 10.0)
	boss.take_damage(0.0, cultivator)
	_check(boss.resolve < wrong_partner_resolve and not boss.is_storm_armor_broken(), "wrong partner remains viable but does not break雷甲")
	boss.apply_link_mark("ember_fox", 10.0)
	boss.take_damage(0.0, cultivator)
	_check(boss.is_storm_armor_broken() and matchups.has("storm_armor_break"), "fox confirmation breaks elite雷甲")
	_check(boss.elite_phase() == 3 and phase_events == [2, 3], "second resolve gate enters the final pursuit phase")
	_check(is_equal_approx(boss.resolve, boss.max_resolve * 0.33), "phase-three gate preserves its full雷行 lesson")
	_check(boss.combat_trait_name() == "雷行" and boss.combat_hint().contains("月影"), "phase three exposes the hare counter")
	boss.apply_link_mark("jade_hare", 10.0)
	_check(boss.is_storm_bound(), "hare command immediately arrests the elite pursuit")
	boss.take_damage(0.0, cultivator)
	_check(matchups.has("storm_bind"), "hare confirmation records the final-phase counter")
	while not boss.can_contract():
		boss.apply_link_mark("jade_hare", 10.0)
		boss.take_damage(0.0, cultivator)
	_check(boss.can_contract() and boss.health >= 1.0, "three-phase elite remains deterministically contractible")

	boss.free()
	cultivator.free()


func _test_attack_telegraphs() -> void:
	var target_actor := PlayerActor.new()
	target_actor.add_to_group("player")
	var beast := SpiritBeast.new()
	beast.setup("jade_hare", 1, Vector2.ZERO, target_actor)
	var health_before := target_actor.health
	beast._begin_melee_attack()
	_check(beast.has_attack_windup(), "melee enemy advertises a dodgeable windup before damage")
	_check(is_equal_approx(target_actor.health, health_before), "starting a telegraph does not deal immediate damage")
	beast._execute_pending_attack()
	_check(target_actor.health < health_before, "telegraphed melee resolves only after its windup")
	beast._begin_melee_attack()
	beast.apply_link_mark("jade_hare", 10.0)
	beast.take_damage(0.0, target_actor)
	_check(not beast.has_attack_windup(), "confirmed link strike interrupts a pending enemy attack")
	beast.free()
	target_actor.free()


func _test_mentor_guidance() -> void:
	var guide := Mentor.new()
	_check(guide.dialogue_for(0, 0, 1, false, 0).contains("右键"), "mentor teaches command then follow-up before first link")
	_check(guide.dialogue_for(0, 0, 1, false, 1).contains("必成"), "mentor explains deterministic capture after first link")
	_check(guide.dialogue_for(1, 0, 1, false, 1, 0).contains("按 R"), "mentor asks player to compare the newly contracted grammar")
	_check(guide.dialogue_for(1, 0, 1, false, 1, 1, 0, 0).contains("玄甲"), "mentor directs fox toward the armored counter lesson")
	_check(guide.dialogue_for(1, 0, 1, false, 1, 1, 1, 0).contains("月影缚"), "mentor directs hare toward the mobile counter lesson")
	_check(guide.dialogue_for(1, 0, 1, false, 1, 1, 1, 1).contains("主动"), "mentor explains active companion grammar after both matchup lessons")
	_check(guide.dialogue_for(1, 3, 1, false, 1, 1, 1, 1).contains("突破"), "mentor explains breakthrough when combat task is done")
	_check(guide.dialogue_for(1, 3, 2, false, 1, 1, 1, 1).contains("紫电狻猊"), "mentor points to elite challenge after tutorial")
	_check(guide.dialogue_for(1, 3, 2, true, 1, 1, 1, 1).contains("平息"), "mentor acknowledges elite victory")
	guide.free()


func _test_input_registration() -> void:
	InputSetup.ensure_actions()
	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "companion_command", "dash", "throw_seal", "cycle_companion", "toggle_journal", "interact", "pause_game", "save_game"]:
		_check(InputMap.has_action(action), "input action exists: %s" % action)


func _test_audio_cue_registry() -> void:
	var controller := AudioController.new()
	_check(controller.cue_count() == 9, "audio controller exposes exactly nine selected cues")
	_check(controller.has_cue("capture_success") and controller.has_cue("level_up"), "critical magic cues are registered")
	controller.free()


func _test_world_spawn_contract() -> void:
	var arena := WorldArena.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260824
	_check(WorldArena.normalized_map_position(Vector2.ZERO).is_equal_approx(Vector2.ZERO), "world-map origin maps to the upper-left corner")
	_check(WorldArena.normalized_map_position(WorldArena.SAFE_CENTER).is_equal_approx(Vector2(0.5, 0.5)), "sanctuary center maps to the middle of the complete valley map")
	_check(WorldArena.normalized_map_position(Vector2(-20, 9999)).is_equal_approx(Vector2(0.0, 1.0)), "world-map markers clamp safely to the painted map bounds")
	for index in range(20):
		var spawn := arena.get_random_spawn_position(rng)
		_check(spawn.x >= 0.0 and spawn.x <= WorldArena.WORLD_SIZE.x, "spawn %d stays inside horizontal bounds" % index)
		_check(spawn.y >= 0.0 and spawn.y <= WorldArena.WORLD_SIZE.y, "spawn %d stays inside vertical bounds" % index)
		_check(spawn.distance_to(WorldArena.SAFE_CENTER) >= 330.0, "spawn %d stays outside sanctuary" % index)
	arena.free()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("ASSERTION FAILED: " + label)
