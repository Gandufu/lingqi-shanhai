extends Node

signal collection_changed
signal save_completed(success: bool)

var save_path := "user://lingqi_save.json"


func _ready() -> void:
	var visual_qa_path := OS.get_environment("LINGQI_SAVE_PATH")
	if not visual_qa_path.is_empty():
		save_path = visual_qa_path

const SPECIES := {
	"ember_fox": {
		"name": "赤焰灵狐",
		"element": "火",
		"color": "#e8794a",
		"accent": "#ffd37a",
		"base_health": 58.0,
		"base_attack": 12.0,
		"speed": 128.0,
		"temper": 0.72,
		"command_name": "焰尾突",
		"command_hint": "短窗 · 高破势爆发",
		"command_style": "pounce",
		"command_cost": 28.0,
		"command_range": 360.0,
		"command_windup": 0.16,
		"link_window": 1.15,
		"resolve_damage": 48.0,
		"link_effect": "burst",
	},
	"jade_hare": {
		"name": "碧玉月兔",
		"element": "木",
		"color": "#65b889",
		"accent": "#d7f7d0",
		"base_health": 66.0,
		"base_attack": 9.0,
		"speed": 152.0,
		"temper": 0.38,
		"command_name": "月影缚",
		"command_hint": "长窗 · 追击回命",
		"command_style": "snare",
		"command_cost": 22.0,
		"command_range": 330.0,
		"command_windup": 0.28,
		"link_window": 2.2,
		"resolve_damage": 34.0,
		"link_effect": "heal",
	},
	"cloud_crane": {
		"name": "流云仙鹤",
		"element": "风",
		"color": "#d9e8ea",
		"accent": "#78b8c7",
		"base_health": 52.0,
		"base_attack": 13.0,
		"speed": 164.0,
		"temper": 0.5,
		"command_name": "风翎引",
		"command_hint": "中窗 · 远距突袭",
		"command_style": "pounce",
		"command_cost": 26.0,
		"command_range": 430.0,
		"command_windup": 0.22,
		"link_window": 1.5,
		"resolve_damage": 40.0,
		"link_effect": "burst",
		"wild_trait": "御风",
		"wild_hint": "御风拉距 · 月影缚可定身并增幅破势",
	},
	"stone_tortoise": {
		"name": "玄岩灵龟",
		"element": "土",
		"color": "#8a8567",
		"accent": "#c8bd82",
		"base_health": 94.0,
		"base_attack": 8.0,
		"speed": 76.0,
		"temper": 0.28,
		"command_name": "玄甲镇",
		"command_hint": "长窗 · 稳定回命",
		"command_style": "snare",
		"command_cost": 20.0,
		"command_range": 280.0,
		"command_windup": 0.34,
		"link_window": 2.4,
		"resolve_damage": 38.0,
		"link_effect": "heal",
		"wild_trait": "玄甲",
		"wild_hint": "玄甲减免剑伤 · 焰尾协同可破甲",
	},
	"thunder_cub": {
		"name": "紫电狻猊",
		"element": "雷",
		"color": "#7866b7",
		"accent": "#f5de61",
		"base_health": 76.0,
		"base_attack": 16.0,
		"speed": 142.0,
		"temper": 0.86,
		"command_name": "雷痕落",
		"command_hint": "短窗 · 雷印爆发",
		"command_style": "pounce",
		"command_cost": 32.0,
		"command_range": 400.0,
		"command_windup": 0.2,
		"link_window": 1.25,
		"resolve_damage": 46.0,
		"link_effect": "burst",
	},
}

var player_level := 1
var player_xp := 0
var spirit_stones := 0
var collection: Array[Dictionary] = []
var active_beast_uid := ""
var quest_capture_count := 0
var quest_defeat_count := 0
var quest_link_count := 0
var quest_switch_count := 0
var quest_armor_break_count := 0
var quest_wind_bind_count := 0
var elite_defeated := false


func new_game() -> void:
	player_level = 1
	player_xp = 0
	spirit_stones = 0
	collection.clear()
	active_beast_uid = ""
	quest_capture_count = 0
	quest_defeat_count = 0
	quest_link_count = 0
	quest_switch_count = 0
	quest_armor_break_count = 0
	quest_wind_bind_count = 0
	elite_defeated = false
	collection_changed.emit()


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		new_game()
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		new_game()
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		new_game()
		return false
	player_level = maxi(1, int(parsed.get("player_level", 1)))
	player_xp = maxi(0, int(parsed.get("player_xp", 0)))
	spirit_stones = maxi(0, int(parsed.get("spirit_stones", 0)))
	quest_capture_count = maxi(0, int(parsed.get("quest_capture_count", 0)))
	quest_defeat_count = maxi(0, int(parsed.get("quest_defeat_count", 0)))
	quest_link_count = maxi(0, int(parsed.get("quest_link_count", 0)))
	quest_switch_count = maxi(0, int(parsed.get("quest_switch_count", 0)))
	quest_armor_break_count = maxi(0, int(parsed.get("quest_armor_break_count", 0)))
	quest_wind_bind_count = maxi(0, int(parsed.get("quest_wind_bind_count", 0)))
	elite_defeated = bool(parsed.get("elite_defeated", false))
	collection.clear()
	var loaded_collection: Variant = parsed.get("collection", [])
	if loaded_collection is Array:
		for entry: Variant in loaded_collection:
			if entry is Dictionary and SPECIES.has(str(entry.get("species_id", ""))):
				collection.append(entry.duplicate(true))
	active_beast_uid = str(parsed.get("active_beast_uid", ""))
	if not active_beast_uid.is_empty() and get_beast_by_uid(active_beast_uid).is_empty():
		active_beast_uid = ""
	collection_changed.emit()
	return true


func save_game() -> bool:
	var payload := {
		"version": 3,
		"player_level": player_level,
		"player_xp": player_xp,
		"spirit_stones": spirit_stones,
		"collection": collection,
		"active_beast_uid": active_beast_uid,
		"quest_capture_count": quest_capture_count,
		"quest_defeat_count": quest_defeat_count,
		"quest_link_count": quest_link_count,
		"quest_switch_count": quest_switch_count,
		"quest_armor_break_count": quest_armor_break_count,
		"quest_wind_bind_count": quest_wind_bind_count,
		"elite_defeated": elite_defeated,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	save_completed.emit(true)
	return true


func add_captured_beast(species_id: String, level: int) -> Dictionary:
	return _append_beast(species_id, level, true)


func grant_starter_beast() -> Dictionary:
	if not collection.is_empty():
		return {}
	return _append_beast("jade_hare", 1, false)


func _append_beast(species_id: String, level: int, count_as_capture: bool) -> Dictionary:
	if not SPECIES.has(species_id):
		return {}
	var uid := "%s-%s-%s" % [species_id, Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	var beast := {
		"uid": uid,
		"species_id": species_id,
		"nickname": str(SPECIES[species_id]["name"]),
		"level": maxi(1, level),
		"xp": 0,
		"bond": 1,
	}
	collection.append(beast)
	if count_as_capture:
		quest_capture_count += 1
	if active_beast_uid.is_empty():
		active_beast_uid = uid
	collection_changed.emit()
	return beast


func cycle_active_beast(direction := 1) -> Dictionary:
	if collection.is_empty():
		active_beast_uid = ""
		return {}
	var current_index := 0
	for index in collection.size():
		if str(collection[index].get("uid", "")) == active_beast_uid:
			current_index = index
			break
	current_index = posmod(current_index + direction, collection.size())
	active_beast_uid = str(collection[current_index]["uid"])
	collection_changed.emit()
	return collection[current_index]


func get_active_beast() -> Dictionary:
	return get_beast_by_uid(active_beast_uid)


func get_beast_by_uid(uid: String) -> Dictionary:
	for beast in collection:
		if str(beast.get("uid", "")) == uid:
			return beast
	return {}


func grant_active_beast_xp(amount: int) -> bool:
	var beast := get_active_beast()
	if beast.is_empty():
		return false
	beast["xp"] = int(beast.get("xp", 0)) + maxi(0, amount)
	var leveled := false
	var needed := int(beast.get("level", 1)) * 45
	while int(beast["xp"]) >= needed:
		beast["xp"] = int(beast["xp"]) - needed
		beast["level"] = int(beast.get("level", 1)) + 1
		beast["bond"] = int(beast.get("bond", 1)) + 1
		leveled = true
		needed = int(beast["level"]) * 45
	if leveled:
		collection_changed.emit()
	return leveled


func species_data(species_id: String) -> Dictionary:
	return SPECIES.get(species_id, {})
