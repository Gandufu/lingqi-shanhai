extends Node2D

const WORLD_SIZE := Vector2(2800.0, 1800.0)
const SAFE_CENTER := Vector2(1400.0, 900.0)
const MAP_TEXTURE := preload("res://assets/generated/core/qinglan-valley-map.png")

const ROCKS := [
	Vector2(448, 270), Vector2(336, 756), Vector2(532, 1350),
	Vector2(924, 1224), Vector2(1400, 324), Vector2(1736, 1404),
	Vector2(2408, 1314), Vector2(2436, 504),
]
const GROVES := [
	Vector2(870, 210), Vector2(980, 230), Vector2(1090, 210),
	Vector2(2070, 1280), Vector2(2180, 1320), Vector2(2290, 1280),
]


static func normalized_map_position(world_position: Vector2) -> Vector2:
	return Vector2(
		clampf(world_position.x / WORLD_SIZE.x, 0.0, 1.0),
		clampf(world_position.y / WORLD_SIZE.y, 0.0, 1.0)
	)


func _ready() -> void:
	z_index = -20
	var background := Sprite2D.new()
	background.name = "QinglanValleyGeneratedMap"
	background.texture = MAP_TEXTURE
	background.centered = false
	background.scale = WORLD_SIZE / MAP_TEXTURE.get_size()
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.z_index = -1
	add_child(background)
	_create_boundaries()
	for rock_position in ROCKS:
		_create_obstacle(rock_position, 38.0)
	for tree_position in GROVES:
		_create_obstacle(tree_position, 30.0)
	queue_redraw()


func _draw() -> void:
	# 生成整图承担地表、道路、灵泉、竹林与石阵视觉；这里只叠加玩法态青岚阵。
	for ring in range(3):
		draw_arc(SAFE_CENTER, 78.0 + ring * 18.0, 0, TAU, 64, Color(0.79, 0.72, 0.35, 0.22), 3.0)


func get_random_spawn_position(rng: RandomNumberGenerator) -> Vector2:
	for _attempt in range(30):
		var candidate := Vector2(
			rng.randf_range(140.0, WORLD_SIZE.x - 140.0),
			rng.randf_range(140.0, WORLD_SIZE.y - 140.0)
		)
		if candidate.distance_to(SAFE_CENTER) < 330.0:
			continue
		if candidate.distance_to(Vector2(2060, 420)) < 230.0:
			continue
		var blocked := false
		for point in ROCKS + GROVES:
			if candidate.distance_to(point) < 90.0:
				blocked = true
				break
		if not blocked:
			return candidate
	return Vector2(350, 350)


func _create_boundaries() -> void:
	_create_wall(Vector2(WORLD_SIZE.x * 0.5, -24), Vector2(WORLD_SIZE.x + 96, 48))
	_create_wall(Vector2(WORLD_SIZE.x * 0.5, WORLD_SIZE.y + 24), Vector2(WORLD_SIZE.x + 96, 48))
	_create_wall(Vector2(-24, WORLD_SIZE.y * 0.5), Vector2(48, WORLD_SIZE.y + 96))
	_create_wall(Vector2(WORLD_SIZE.x + 24, WORLD_SIZE.y * 0.5), Vector2(48, WORLD_SIZE.y + 96))


func _create_wall(wall_position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = wall_position
	body.collision_layer = 4
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)


func _create_obstacle(obstacle_position: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = obstacle_position
	body.collision_layer = 4
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	body.add_child(shape)
	add_child(body)
