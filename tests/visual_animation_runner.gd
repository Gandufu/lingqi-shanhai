extends Node

const MainScene := preload("res://scenes/main.tscn")
const WorldArena := preload("res://scripts/world/world_arena.gd")

var _lineup: Array[Node] = []


func _ready() -> void:
	GameState.save_path = "user://lingqi_visual_lineup_save.json"
	var main = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	main.audio.stop_all()
	if is_instance_valid(main.companion):
		main.companion.visible = false
		main.companion.set_physics_process(false)

	var offsets := {
		"ember_fox": Vector2(-380, -70),
		"jade_hare": Vector2(-250, 175),
		"cloud_crane": Vector2(0, -240),
		"stone_tortoise": Vector2(250, 175),
		"thunder_cub": Vector2(380, -70),
	}
	var selected := {}
	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		beast.visible = false
		beast.set_physics_process(false)
		if not selected.has(beast.species_id):
			selected[beast.species_id] = beast
	for species_id in offsets:
		var beast = selected.get(species_id)
		if not is_instance_valid(beast):
			continue
		beast.visible = true
		beast.target = null
		beast.global_position = WorldArena.SAFE_CENTER + offsets[species_id]
		beast.velocity = Vector2.RIGHT * 100.0
		_lineup.append(beast)


func _process(delta: float) -> void:
	for beast in _lineup:
		if is_instance_valid(beast):
			beast._update_generated_sprite(delta)
