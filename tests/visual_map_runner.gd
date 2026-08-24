extends Node

const MainScene := preload("res://scenes/main.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.save_path = "user://lingqi_visual_map_save.json"
	var main = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	main.audio.stop_all()
	main.player.global_position = Vector2(1860, 1080)
	main._toggle_world_map()

