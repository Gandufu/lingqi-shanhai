extends Node2D

const InputSetup = preload("res://scripts/input_setup.gd")
const AudioController = preload("res://scripts/audio/audio_manager.gd")
const WorldArena = preload("res://scripts/world/world_arena.gd")
const PlayerActor = preload("res://scripts/entities/player.gd")
const SpiritBeast = preload("res://scripts/entities/spirit_beast.gd")
const Companion = preload("res://scripts/entities/companion.gd")
const Mentor = preload("res://scripts/entities/mentor.gd")
const SealProjectile = preload("res://scripts/combat/seal_projectile.gd")
const EnemyProjectile = preload("res://scripts/combat/enemy_projectile.gd")
const HUD = preload("res://scripts/ui/hud.gd")

const SPECIES_ORDER := ["ember_fox", "jade_hare", "cloud_crane", "stone_tortoise", "thunder_cub"]
const TARGET_WILD_COUNT := 15

var world
var audio
var player
var companion
var hud
var mentor
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _autosave_timer := 0.0
var _sanctuary_tick := 0.0
var _target_tick := 0.0
var _show_save_feedback := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure_actions()
	_rng.randomize()
	GameState.load_game()
	var starter_granted := GameState.grant_starter_beast()
	_build_audio()
	_build_world()
	_build_player()
	_build_mentor()
	_build_hud()
	_spawn_initial_beasts()
	_spawn_active_companion()
	GameState.collection_changed.connect(_on_collection_changed)
	GameState.save_completed.connect(_on_save_completed)
	_update_quest()
	if starter_granted.is_empty():
		hud.flash_message("踏入青岚谷 · 右键御灵，左键追击破势")
	else:
		hud.flash_message("清虚散人借予碧玉月兔 · 右键御灵，左键追击")
		call_deferred("_show_starter_cutin")


func _show_starter_cutin() -> void:
	await get_tree().create_timer(0.55).timeout
	if is_instance_valid(hud):
		hud.show_combat_cutin("jade_hare", "灵契初启 · 月影缚")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_world_map"):
		if hud.is_world_map_visible() or not get_tree().paused:
			_toggle_world_map()
	if Input.is_action_just_pressed("pause_game"):
		if hud.is_world_map_visible():
			_toggle_world_map()
		else:
			_toggle_pause()
	if get_tree().paused:
		return
	_spawn_timer -= delta
	_autosave_timer += delta
	_sanctuary_tick -= delta
	_target_tick -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 3.0
		_maintain_wild_population()
	if _autosave_timer >= 30.0:
		_autosave_timer = 0.0
		_sync_and_save()
	if _sanctuary_tick <= 0.0 and is_instance_valid(player):
		_sanctuary_tick = 0.25
		if player.global_position.distance_to(WorldArena.SAFE_CENTER) < 96.0:
			var old_health: float = player.health
			player.health = minf(player.max_health, player.health + player.max_health * 0.025)
			player.qi = minf(player.max_qi, player.qi + player.max_qi * 0.08)
			if not is_equal_approx(old_health, player.health):
				player.state_changed.emit()
	if Input.is_action_just_pressed("toggle_journal"):
		hud.toggle_journal()
		audio.play("journal", -6.0)
	if Input.is_action_just_pressed("save_game"):
		_sync_and_save(true)
	if _target_tick <= 0.0:
		_target_tick = 0.08
		_refresh_aim_target()
		_refresh_mentor_interaction()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		if is_instance_valid(audio):
			audio.stop_all()
		_sync_and_save()
		get_tree().quit()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if is_instance_valid(hud):
		hud.set_paused(get_tree().paused)


func _toggle_world_map() -> void:
	if not is_instance_valid(hud):
		return
	var opening: bool = not bool(hud.is_world_map_visible())
	if opening and get_tree().paused:
		return
	if opening:
		_refresh_world_map()
	hud.toggle_world_map()
	get_tree().paused = opening
	hud.set_paused(false)


func _refresh_world_map() -> void:
	if not is_instance_valid(player) or not is_instance_valid(mentor):
		return
	var markers: Array = []
	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		if not is_instance_valid(beast):
			continue
		markers.append({
			"position": beast.global_position,
			"species_id": beast.species_id,
			"elite": beast.is_elite,
		})
	hud.refresh_world_map(player.global_position, mentor.global_position, markers)


func _build_world() -> void:
	world = WorldArena.new()
	world.name = "青岚谷"
	add_child(world)


func _build_audio() -> void:
	audio = AudioController.new()
	audio.name = "AudioManager"
	add_child(audio)


func _build_player() -> void:
	player = PlayerActor.new()
	player.name = "Player"
	player.configure(GameState.player_level, GameState.player_xp)
	player.global_position = WorldArena.SAFE_CENTER
	add_child(player)
	player.request_throw_seal.connect(_on_player_throw_seal)
	player.request_cycle_companion.connect(_on_cycle_companion)
	player.request_companion_command.connect(_on_companion_command)
	player.combat_message.connect(_on_combat_message)
	player.sound_requested.connect(_on_sound_requested)
	player.died.connect(_on_player_died)
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WorldArena.WORLD_SIZE.x)
	camera.limit_bottom = int(WorldArena.WORLD_SIZE.y)
	player.add_child(camera)


func _build_hud() -> void:
	hud = HUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.bind_player(player)
	hud.refresh_collection()


func _build_mentor() -> void:
	mentor = Mentor.new()
	mentor.name = Mentor.MENTOR_NAME
	mentor.global_position = WorldArena.SAFE_CENTER + Vector2(110, -12)
	add_child(mentor)


func _spawn_initial_beasts() -> void:
	# 首只灵狐固定在青岚阵东侧，让新玩家能在十秒内验证月兔的主动协同语法。
	_spawn_beast("ember_fox", 1, WorldArena.SAFE_CENTER + Vector2(305, 0))
	# 两个固定战性目标组成短教学路线：焰尾破玄甲，月缚定御风。
	_spawn_beast("stone_tortoise", 1, WorldArena.SAFE_CENTER + Vector2(625, 35))
	_spawn_beast("cloud_crane", 1, WorldArena.SAFE_CENTER + Vector2(610, 300))
	for index in range(TARGET_WILD_COUNT - 3):
		var species_id: String = SPECIES_ORDER[(index + 1) % SPECIES_ORDER.size()]
		var beast_level := 1 + int(index >= 9)
		_spawn_beast(species_id, beast_level, world.get_random_spawn_position(_rng))
	# 谷底精英提供一个明确的高风险目标，并在击败后永久记录。
	if not GameState.elite_defeated:
		_spawn_beast("thunder_cub", 4, Vector2(2440, 300), true)


func _spawn_beast(species_id: String, beast_level: int, position: Vector2, elite := false) -> void:
	var beast := SpiritBeast.new()
	beast.name = "%s_Lv%d" % [species_id, beast_level]
	beast.setup(species_id, beast_level, position, player, elite)
	beast.defeated.connect(_on_beast_defeated)
	beast.captured.connect(_on_beast_captured)
	beast.capture_failed.connect(_on_capture_failed)
	beast.link_struck.connect(_on_link_struck)
	beast.elite_phase_changed.connect(_on_elite_phase_changed)
	beast.request_projectile.connect(_on_beast_projectile)
	add_child(beast)


func _maintain_wild_population() -> void:
	var current := get_tree().get_nodes_in_group("wild_beasts").size()
	if current >= TARGET_WILD_COUNT:
		return
	for _index in range(mini(2, TARGET_WILD_COUNT - current)):
		var species_id: String = SPECIES_ORDER[_rng.randi_range(0, SPECIES_ORDER.size() - 1)]
		var scaled_level := clampi(player.level + _rng.randi_range(-1, 1), 1, 8)
		_spawn_beast(species_id, scaled_level, world.get_random_spawn_position(_rng))


func _refresh_aim_target() -> void:
	var cursor := get_global_mouse_position()
	var nearest
	var nearest_cursor_distance := 78.0
	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		if not is_instance_valid(beast):
			continue
		if player.global_position.distance_to(beast.global_position) > 470.0:
			continue
		var cursor_distance: float = cursor.distance_to(beast.global_position)
		if cursor_distance < nearest_cursor_distance:
			nearest = beast
			nearest_cursor_distance = cursor_distance
	if nearest == null:
		hud.hide_target()
	else:
		hud.show_target(nearest)


func _refresh_mentor_interaction() -> void:
	if not is_instance_valid(mentor) or not is_instance_valid(player):
		return
	if player.global_position.distance_to(mentor.global_position) <= 112.0:
		hud.set_interaction_hint("E  与 %s 交谈" % Mentor.MENTOR_NAME)
		if Input.is_action_just_pressed("interact"):
			audio.play("dialogue", -7.0)
			hud.show_dialogue(Mentor.MENTOR_NAME, mentor.dialogue_for(GameState.quest_capture_count, GameState.quest_defeat_count, player.level, GameState.elite_defeated, GameState.quest_link_count, GameState.quest_switch_count, GameState.quest_armor_break_count, GameState.quest_wind_bind_count))
	else:
		hud.set_interaction_hint("")


func _on_player_throw_seal(origin: Vector2, direction: Vector2) -> void:
	var seal := SealProjectile.new()
	seal.setup(origin, direction)
	add_child(seal)


func _on_companion_command(target_position: Vector2) -> void:
	if not is_instance_valid(companion):
		hud.flash_message("尚无可响应的灵契伙伴", Color("#f0a28c"))
		return
	if not companion.is_command_ready():
		hud.flash_message("%s 尚在回气 %.1f 秒" % [companion.command_name, companion.command_cooldown_remaining()], Color("#f2d87c"))
		return
	var target = _find_command_target(target_position, companion.command_range)
	if target == null:
		hud.flash_message("御灵范围内没有目标", Color("#f0a28c"))
		return
	if target.can_contract():
		hud.flash_message("契机已现 · 无需再御灵，按 Q 结契", Color("#8cf0c3"))
		return
	if target.has_link_mark():
		hud.flash_message("灵印尚在 · 立即以左键剑诀追击", Color("#f2d87c"))
		return
	if not player.spend_resonance(companion.command_cost):
		hud.flash_message("同契不足：%s 需要 %.0f" % [companion.command_name, companion.command_cost], Color("#f0a28c"))
		return
	if not companion.command(target):
		player.gain_resonance(companion.command_cost)
		return
	audio.play("seal_throw", -5.0, 0.02)
	hud.show_combat_cutin(companion.species_id, "御灵 · %s" % companion.command_name)
	hud.flash_message("御灵 · %s → %s" % [companion.command_name, target.beast_name], Color("#b7efd1"))


func _find_command_target(target_position: Vector2, maximum_range: float):
	var nearest
	var nearest_cursor_distance := 92.0
	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		if not is_instance_valid(beast):
			continue
		if player.global_position.distance_to(beast.global_position) > maximum_range:
			continue
		var cursor_distance: float = target_position.distance_to(beast.global_position)
		if cursor_distance < nearest_cursor_distance:
			nearest = beast
			nearest_cursor_distance = cursor_distance
	return nearest


func _on_beast_projectile(origin: Vector2, direction: Vector2, damage: float, color: Color, speed: float, label: String) -> void:
	var projectile := EnemyProjectile.new()
	projectile.name = label
	projectile.setup(origin, direction, damage, color, speed, label)
	add_child(projectile)


func _on_beast_defeated(beast, xp_reward: int) -> void:
	if not is_instance_valid(beast):
		return
	var defeated_name: String = str(beast.beast_name)
	var defeated_elite: bool = bool(beast.is_elite)
	audio.play("defeat", -5.0)
	GameState.quest_defeat_count += 1
	GameState.spirit_stones += 2 + beast.level
	if defeated_elite:
		GameState.elite_defeated = true
		GameState.spirit_stones += 50
	var player_leveled: bool = player.add_xp(xp_reward)
	var companion_leveled := GameState.grant_active_beast_xp(int(xp_reward * 0.7))
	hud.flash_message("击退 %s · 修为 +%d · 灵石 +%d" % [defeated_name, xp_reward, 2 + beast.level])
	beast.queue_free()
	if player_leveled:
		audio.play("level_up", -1.0, 0.02)
		hud.flash_message("境界突破！炼气 %d 层" % player.level, Color("#8cf0c3"))
	if defeated_elite:
		audio.play("level_up", 0.0, 0.01)
		hud.flash_message("首领已平息：紫电狻猊 · 额外灵石 +50", Color("#f2d87c"))
	if companion_leveled:
		_spawn_active_companion()
	_sync_runtime_state()
	_update_quest()
	hud.refresh_collection()
	if defeated_elite:
		_sync_and_save()


func _on_beast_captured(beast) -> void:
	if not is_instance_valid(beast):
		return
	var captured_name: String = str(beast.beast_name)
	var captured_level: int = int(beast.level)
	var captured_id: String = str(beast.species_id)
	var captured_elite: bool = bool(beast.is_elite)
	GameState.add_captured_beast(captured_id, captured_level)
	if captured_elite:
		GameState.elite_defeated = true
	GameState.spirit_stones += 51 if captured_elite else 1
	audio.play("capture_success", -1.0, 0.025)
	hud.show_combat_cutin(captured_id, "灵契已成 · %s" % captured_name)
	if captured_elite:
		hud.flash_message("首领灵契已成：%s Lv.%d · 雷髓灵石 +50" % [captured_name, captured_level], Color("#f2d87c"))
	else:
		hud.flash_message("灵契已成：%s Lv.%d · 按 R 换兽体验新战语" % [captured_name, captured_level], Color("#8cf0c3"))
	beast.queue_free()
	_spawn_active_companion()
	_sync_and_save()
	_update_quest()


func _on_capture_failed(beast) -> void:
	if not is_instance_valid(beast):
		return
	audio.play("capture_fail", -4.0)
	hud.flash_message("%s 执念未破 · 先右键御灵，再以剑诀追击" % beast.beast_name, Color("#f0a28c"))


func _on_link_struck(beast, partner_species: String, effect: String, resolve_damage: float, matchup: String) -> void:
	if not is_instance_valid(beast):
		return
	GameState.quest_link_count += 1
	player.gain_resonance(16.0)
	hud.show_player_cutin("剑诀 · 同契破势")
	var partner_data := GameState.species_data(partner_species)
	if matchup == "armor_break":
		GameState.quest_armor_break_count += 1
		hud.flash_message("战性相克 · 焰尾碎玄甲 · %s -%.0f 执念" % [beast.beast_name, resolve_damage], Color("#ffbf78"))
	elif matchup == "wind_bind":
		GameState.quest_wind_bind_count += 1
		player.restore_health(10.0 + player.level * 2.0)
		hud.flash_message("战性相克 · 月影定御风 · %s -%.0f 执念" % [beast.beast_name, resolve_damage], Color("#8cf0c3"))
	elif matchup == "storm_armor_break":
		hud.flash_message("首领相克 · 焰尾贯雷甲 · %s -%.0f 执念" % [beast.beast_name, resolve_damage], Color("#ffbf78"))
	elif matchup == "storm_bind":
		player.restore_health(10.0 + player.level * 2.0)
		hud.flash_message("首领相克 · 月影锁雷行 · %s -%.0f 执念" % [beast.beast_name, resolve_damage], Color("#8cf0c3"))
	elif effect == "heal":
		player.restore_health(10.0 + player.level * 2.0)
		hud.flash_message("同契破势 · %s -%.0f 执念 · 月华回命" % [beast.beast_name, resolve_damage], Color("#aeeed0"))
	else:
		hud.flash_message("同契破势 · %s -%.0f 执念 · %s爆发" % [beast.beast_name, resolve_damage, str(partner_data.get("element", "灵"))], Color("#f2d87c"))
	audio.play("capture_success", -7.0, 0.03)
	_update_quest()


func _on_elite_phase_changed(beast, phase: int, title: String, hint: String) -> void:
	if not is_instance_valid(beast):
		return
	audio.play("level_up", -4.0, 0.02)
	hud.show_combat_cutin(str(beast.species_id), "首领转势 · %s" % title)
	hud.flash_message("雷封第%d式 · %s" % [phase, hint], Color("#f2d87c"))


func _on_companion_command_landed(target: Node, partner_species: String) -> void:
	if not is_instance_valid(target):
		return
	var data := GameState.species_data(partner_species)
	hud.flash_message("灵印已成 · %.1f 秒内以剑诀追击" % float(data.get("link_window", 1.4)), Color("#f2d87c"))


func _on_cycle_companion() -> void:
	if GameState.collection.is_empty():
		hud.flash_message("尚未收服可出战的灵兽")
		return
	if GameState.collection.size() < 2:
		hud.flash_message("目前只有一位伙伴 · 先完成破势结契")
		return
	var active := GameState.cycle_active_beast(1)
	GameState.quest_switch_count += 1
	_spawn_active_companion()
	hud.flash_message("出战：%s" % str(active.get("nickname", "灵兽")))
	_sync_and_save()
	_update_quest()


func _spawn_active_companion() -> void:
	if is_instance_valid(companion):
		companion.queue_free()
	companion = null
	var active := GameState.get_active_beast()
	if active.is_empty() or not is_instance_valid(player):
		return
	companion = Companion.new()
	companion.name = "ActiveCompanion"
	companion.setup(active, player)
	companion.global_position = player.global_position + Vector2(-40, 36)
	add_child(companion)
	companion.command_landed.connect(_on_companion_command_landed)
	hud.refresh_collection()


func _on_player_died() -> void:
	var lost := mini(GameState.spirit_stones, maxi(1, int(GameState.spirit_stones * 0.1)))
	GameState.spirit_stones -= lost
	player.global_position = WorldArena.SAFE_CENTER
	player.heal_full()
	hud.flash_message("神魂归位青岚阵 · 遗失灵石 %d" % lost, Color("#ef9f8f"))
	_sync_and_save()


func _on_combat_message(text: String) -> void:
	hud.flash_message(text)


func _on_sound_requested(cue: String) -> void:
	audio.play(cue)


func _on_collection_changed() -> void:
	if is_instance_valid(hud):
		hud.refresh_collection()


func _on_save_completed(success: bool) -> void:
	var should_show := _show_save_feedback or not success
	_show_save_feedback = false
	if should_show and is_instance_valid(hud):
		hud.flash_message("云简已保存" if success else "保存失败", Color("#b8decf") if success else Color("#ef9f8f"))


func _update_quest() -> void:
	if GameState.quest_link_count < 1:
		hud.set_quest("同契初悟：右键御灵后，以剑诀追击灵印（%d/1）" % GameState.quest_link_count)
	elif GameState.quest_capture_count < 1:
		hud.set_quest("破执结契：反复协同破势，契机出现时按 Q")
	elif GameState.quest_switch_count < 1:
		hud.set_quest("战语有别：按 R 换上新伙伴，比较御灵节奏")
	elif GameState.quest_armor_break_count < 1:
		hud.set_quest("择兽破势：以赤焰灵狐协同击破玄岩灵龟的玄甲")
	elif GameState.quest_wind_bind_count < 1:
		hud.set_quest("择兽破势：换碧玉月兔，以月影缚定住流云仙鹤")
	elif GameState.quest_defeat_count < 3:
		hud.set_quest("谷中历练：击退野生灵兽（%d/3）" % GameState.quest_defeat_count)
	elif player.level < 2:
		hud.set_quest("凝练修为：突破至炼气 2 层")
	elif not GameState.elite_defeated:
		hud.set_quest("谷底雷鸣：破三式雷封 · 雷甲用灵狐，雷行用月兔")
	else:
		hud.set_quest("青岚谷试炼完成 ✓  山海之路即将展开")


func _sync_runtime_state() -> void:
	GameState.player_level = player.level
	GameState.player_xp = player.xp
	hud.refresh_player()


func _sync_and_save(show_feedback := false) -> void:
	_sync_runtime_state()
	_show_save_feedback = show_feedback
	GameState.save_game()
