extends Area2D

var direction := Vector2.RIGHT
var speed := 320.0
var damage := 10.0
var projectile_color := Color("#a991f0")
var source_name := "灵兽术法"
var _life := 2.2
var _pulse := 0.0
var _resolved := false


func setup(origin: Vector2, travel_direction: Vector2, amount: float, color: Color, travel_speed: float, label: String) -> void:
	global_position = origin
	direction = travel_direction.normalized()
	damage = amount
	projectile_color = color
	speed = travel_speed
	source_name = label


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = false
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	global_position += direction * speed * delta
	_life -= delta
	_pulse += delta * 9.0
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _resolved or not body.is_in_group("player"):
		return
	_resolved = true
	if body.has_method("take_damage"):
		body.call("take_damage", damage, self)
	queue_free()


func _draw() -> void:
	var radius := 10.0 + sin(_pulse) * 2.0
	draw_circle(Vector2.ZERO, radius + 7.0, Color(projectile_color, 0.16))
	draw_circle(Vector2.ZERO, radius, projectile_color)
	draw_circle(-direction * 5.0, radius * 0.45, Color.WHITE)
	for index in range(3):
		var trail_position := -direction * (17.0 + index * 9.0)
		draw_circle(trail_position, 5.0 - index, Color(projectile_color, 0.45 - index * 0.1))

