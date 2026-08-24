extends CharacterBody2D

signal state_changed
signal request_throw_seal(origin: Vector2, direction: Vector2)
signal request_cycle_companion
signal request_companion_command(target_position: Vector2)
signal combat_message(text: String)
signal sound_requested(cue: String)
signal died

const BASE_SPEED := 235.0
const DASH_SPEED := 610.0
const DASH_DURATION := 0.17
const DASH_COOLDOWN := 0.72
const PLAYER_WALK_TEXTURE := preload("res://assets/generated/core/wanderer-walk-sheet-v2.png")
const ALPHA_CLIP_SHADER := preload("res://shaders/sprite_alpha_clip.gdshader")

var level := 1
var xp := 0
var max_health := 120.0
var health := 120.0
var max_qi := 100.0
var qi := 100.0
var max_resonance := 100.0
var resonance := 55.0
var attack_power := 18.0

var _attack_cooldown := 0.0
var _dash_cooldown := 0.0
var _dash_timer := 0.0
var _invulnerable_timer := 0.0
var _hurt_flash := 0.0
var _facing := Vector2.DOWN
var _walk_animation_time := 0.0
var _sprite: Sprite2D
var _outline_sprite: Sprite2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 2 | 4
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15.0
	capsule.height = 42.0
	collision.shape = capsule
	add_child(collision)
	var alpha_material := ShaderMaterial.new()
	alpha_material.shader = ALPHA_CLIP_SHADER
	_outline_sprite = Sprite2D.new()
	_outline_sprite.name = "GeneratedCultivatorOutline"
	_outline_sprite.texture = PLAYER_WALK_TEXTURE
	_outline_sprite.hframes = 4
	_outline_sprite.vframes = 4
	_outline_sprite.scale = Vector2(0.374, 0.374)
	_outline_sprite.position = Vector2(0, -52)
	_outline_sprite.modulate = Color(0.01, 0.035, 0.035, 0.78)
	_outline_sprite.z_index = -1
	_outline_sprite.material = alpha_material
	_outline_sprite.visible = false
	_outline_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_outline_sprite)
	_sprite = Sprite2D.new()
	_sprite.name = "GeneratedCultivatorSprite"
	_sprite.texture = PLAYER_WALK_TEXTURE
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.scale = Vector2(0.355, 0.355)
	_sprite.position = Vector2(0, -52)
	_sprite.material = alpha_material
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	_update_sprite()
	state_changed.emit()
	queue_redraw()


func configure(saved_level: int, saved_xp: int) -> void:
	level = maxi(1, saved_level)
	xp = maxi(0, saved_xp)
	max_health = 120.0 + (level - 1) * 14.0
	health = max_health
	max_qi = 100.0 + (level - 1) * 6.0
	qi = max_qi
	resonance = 55.0
	attack_power = 18.0 + (level - 1) * 2.5
	state_changed.emit()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_invulnerable_timer = maxf(0.0, _invulnerable_timer - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	qi = minf(max_qi, qi + 12.0 * delta)

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.01:
		_facing = input_vector.normalized()
	if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and qi >= 18.0:
		_dash_timer = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN
		_invulnerable_timer = DASH_DURATION + 0.05
		qi -= 18.0
		combat_message.emit("身法 · 踏风")
		sound_requested.emit("dash")
		state_changed.emit()
	if _dash_timer > 0.0:
		velocity = _facing * DASH_SPEED
	else:
		velocity = input_vector * BASE_SPEED
	move_and_slide()

	if Input.is_action_pressed("attack") and _attack_cooldown <= 0.0:
		_perform_attack()
	if Input.is_action_just_pressed("throw_seal"):
		_throw_seal()
	if Input.is_action_just_pressed("companion_command"):
		request_companion_command.emit(get_global_mouse_position())
	if Input.is_action_just_pressed("cycle_companion"):
		request_cycle_companion.emit()
	_update_sprite(delta)
	queue_redraw()


func _update_sprite(delta := 0.0) -> void:
	if not is_instance_valid(_sprite):
		return
	var moving := velocity.length_squared() > 16.0
	if moving:
		_walk_animation_time += delta * (1.7 if _dash_timer > 0.0 else 1.0)
	else:
		_walk_animation_time = 0.0
	var frame_index := int(_walk_animation_time * 8.0) % 4 if moving else 0
	_sprite.frame_coords = Vector2i(frame_index, _direction_row(_facing))
	_sprite.flip_h = false
	var base_scale := 0.355
	if _attack_cooldown > 0.22:
		_sprite.scale = Vector2(base_scale * 1.08, base_scale * 0.94)
	else:
		_sprite.scale = Vector2(base_scale, base_scale)
	_sprite.rotation = -_facing.x * 0.11 if _dash_timer > 0.0 else 0.0
	_sprite.position.y = -52.0 + (sin(Time.get_ticks_msec() * 0.016) * 1.0 if moving else 0.0)
	_sprite.modulate = Color(1.0, 0.62, 0.62) if _hurt_flash > 0.0 else Color.WHITE
	if is_instance_valid(_outline_sprite):
		_outline_sprite.frame_coords = _sprite.frame_coords
		_outline_sprite.position = _sprite.position
		_outline_sprite.rotation = _sprite.rotation
		_outline_sprite.scale = _sprite.scale * 1.052


func _direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x > 0.0 else 2
	return 0 if direction.y >= 0.0 else 3


func _perform_attack() -> void:
	_attack_cooldown = 0.38
	sound_requested.emit("attack")
	var aim := global_position.direction_to(get_global_mouse_position())
	if aim.length_squared() > 0.01:
		_facing = aim
	var hits := 0
	var link_hits := 0
	for beast in get_tree().get_nodes_in_group("wild_beasts"):
		if not is_instance_valid(beast):
			continue
		var offset: Vector2 = beast.global_position - global_position
		if offset.length() > 82.0:
			continue
		if offset.normalized().dot(_facing) < 0.1:
			continue
		if beast.take_damage(attack_power, self):
			link_hits += 1
		hits += 1
	if hits > 0:
		gain_resonance(6.0 + hits * 3.0)
		if link_hits == 0:
			combat_message.emit("剑诀命中 ×%d" % hits)
	queue_redraw()


func _throw_seal() -> void:
	if qi < 16.0:
		combat_message.emit("灵力不足")
		return
	qi -= 16.0
	var direction := global_position.direction_to(get_global_mouse_position())
	if direction.length_squared() < 0.01:
		direction = _facing
	_facing = direction
	sound_requested.emit("seal_throw")
	request_throw_seal.emit(global_position + direction * 28.0, direction)
	state_changed.emit()


func take_damage(amount: float, source: Node = null) -> void:
	if _invulnerable_timer > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_hurt_flash = 0.18
	_invulnerable_timer = 0.34
	if source is Node2D:
		velocity = source.global_position.direction_to(global_position) * 280.0
	state_changed.emit()
	queue_redraw()
	if health <= 0.0:
		died.emit()


func heal_full() -> void:
	health = max_health
	qi = max_qi
	state_changed.emit()


func restore_health(amount: float) -> void:
	health = minf(max_health, health + maxf(0.0, amount))
	state_changed.emit()


func gain_resonance(amount: float) -> void:
	resonance = minf(max_resonance, resonance + maxf(0.0, amount))
	state_changed.emit()


func spend_resonance(amount: float) -> bool:
	if amount < 0.0 or resonance < amount:
		return false
	resonance -= amount
	state_changed.emit()
	return true


func add_xp(amount: int) -> bool:
	xp += maxi(0, amount)
	var leveled := false
	var needed := xp_for_next_level()
	while xp >= needed:
		xp -= needed
		level += 1
		max_health += 14.0
		max_qi += 6.0
		attack_power += 2.5
		health = max_health
		qi = max_qi
		leveled = true
		needed = xp_for_next_level()
	state_changed.emit()
	return leveled


func xp_for_next_level() -> int:
	return 80 + (level - 1) * 55


func _draw() -> void:
	_draw_oval(Vector2(2, 17), Vector2(20, 9), Color(0.01, 0.02, 0.03, 0.35))
	if _dash_timer > 0.0:
		for index in range(3):
			draw_arc(Vector2.ZERO - _facing * (18.0 + index * 11.0), 15.0, -1.2, 1.2, 12, Color(0.5, 0.95, 0.82, 0.45 - index * 0.1), 2.0)
	if _attack_cooldown > 0.22:
		var angle := _facing.angle()
		draw_arc(Vector2.ZERO, 57.0, angle - 0.85, angle + 0.85, 24, Color("#f6df91"), 7.0)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
