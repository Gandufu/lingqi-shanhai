extends Area2D

signal expired

var direction := Vector2.RIGHT
var speed := 510.0
var _life := 1.15
var _spin := 0.0
var _resolved := false


func setup(origin: Vector2, travel_direction: Vector2) -> void:
	global_position = origin
	direction = travel_direction.normalized()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = false
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	global_position += direction * speed * delta
	_spin += delta * 8.0
	_life -= delta
	if _life <= 0.0:
		_resolved = true
		expired.emit()
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _resolved or not body.is_in_group("wild_beasts"):
		return
	_resolved = true
	if body.has_method("try_capture"):
		body.try_capture()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color(0.96, 0.83, 0.35, 0.16))
	var points := PackedVector2Array()
	for index in range(4):
		points.append(Vector2.from_angle(_spin + PI * 0.25 + index * PI * 0.5) * 9.0)
	draw_colored_polygon(points, Color("#f4dc77"))
	draw_line(Vector2(-5, 0).rotated(_spin), Vector2(5, 0).rotated(_spin), Color("#6f3e32"), 2.0)
	draw_line(Vector2(0, -5).rotated(_spin), Vector2(0, 5).rotated(_spin), Color("#6f3e32"), 2.0)
