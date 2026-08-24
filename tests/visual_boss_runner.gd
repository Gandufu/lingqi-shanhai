extends Node

const MainScene := preload("res://scenes/main.tscn")
const WorldArena := preload("res://scripts/world/world_arena.gd")

var _main
var _elite
var _held_caption := ""


func _ready() -> void:
	GameState.save_path = "user://lingqi_visual_boss_save.json"
	_main = MainScene.instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().physics_frame
	_main.set_process(false)
	_main.audio.stop_all()
	_main.player.global_position = WorldArena.SAFE_CENTER
	_main.player.set_physics_process(false)
	if is_instance_valid(_main.companion):
		_main.companion.set_physics_process(false)

	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		beast.visible = false
		beast.set_physics_process(false)
		if bool(beast.is_elite):
			_elite = beast
	if not is_instance_valid(_elite):
		return
	_elite.visible = true
	_elite.global_position = WorldArena.SAFE_CENTER + Vector2(180, 0)
	_elite.target = _main.player
	_stage_phase_two()
	_main.hud.set_quest("首领试炼：雷甲用灵狐，雷行用月兔")
	_hold_phase_cutin("首领转势 · 二式 · 雷甲")
	await get_tree().create_timer(60.0).timeout
	_stage_phase_three()
	_main.hud.set_quest("首领试炼：雷行追狩 · 换月兔截停")
	_hold_phase_cutin("首领转势 · 三式 · 雷行")


func _stage_phase_two() -> void:
	while _elite.elite_phase() == 1:
		_elite.apply_link_mark("jade_hare", 10.0)
		_elite.take_damage(0.0, _main.player)
	_main.hud.show_target(_elite)


func _stage_phase_three() -> void:
	while _elite.elite_phase() == 2:
		_elite.apply_link_mark("ember_fox", 10.0)
		_elite.take_damage(0.0, _main.player)
	_main.hud.show_target(_elite)


func _hold_phase_cutin(caption: String) -> void:
	_held_caption = caption
	_main.hud.show_combat_cutin("thunder_cub", caption)
	if _main.hud._cutin_tween != null and _main.hud._cutin_tween.is_valid():
		_main.hud._cutin_tween.kill()
	_main.hud._cutin_tween = null
	_main.hud._cutin_panel.visible = true
	_main.hud._cutin_panel.modulate = Color.WHITE


func _process(_delta: float) -> void:
	if _held_caption.is_empty() or not is_instance_valid(_main):
		return
	_main.hud._cutin_panel.visible = true
	_main.hud._cutin_panel.modulate = Color.WHITE
	_main.hud._cutin_portrait.texture = _main.hud._spirit_portrait("thunder_cub")
	_main.hud._cutin_label.text = _held_caption
