extends CharacterBody2D

signal command_landed(target: Node, species_id: String)

const EMBER_FOX_RUN_TEXTURE := preload("res://assets/generated/core/ember-fox-run-sheet-v6.png")
const JADE_HARE_HOP_TEXTURE := preload("res://assets/generated/core/jade-hare-hop-sheet-v5.png")
const CLOUD_CRANE_FLIGHT_TEXTURE := preload("res://assets/generated/core/cloud-crane-flight-sheet-v5.png")
const STONE_TORTOISE_CRAWL_TEXTURE := preload("res://assets/generated/core/stone-tortoise-crawl-sheet-v2.png")
const THUNDER_CUB_RUN_TEXTURE := preload("res://assets/generated/core/thunder-cub-run-sheet-v6.png")
const ALPHA_CLIP_SHADER := preload("res://shaders/sprite_alpha_clip.gdshader")

var species_id := "ember_fox"
var beast_name := "灵兽"
var level := 1
var attack_power := 10.0
var move_speed := 170.0
var body_color := Color("#e8794a")
var accent_color := Color("#ffd37a")
var follow_target: Node2D

var command_name := "御灵"
var command_style := "pounce"
var command_cost := 25.0
var command_range := 340.0
var command_windup := 0.2

var _command_target: Node2D
var _command_cooldown := 0.0
var _command_windup_timer := 0.0
var _command_travel_timer := 0.0
var _command_flash := 0.0
var _walk_animation_time := 0.0
var _visual_facing := Vector2.RIGHT
var _sprite: Sprite2D
var _outline_sprite: Sprite2D


func setup(beast: Dictionary, owner: Node2D) -> void:
	species_id = str(beast.get("species_id", "ember_fox"))
	beast_name = str(beast.get("nickname", "灵兽"))
	level = maxi(1, int(beast.get("level", 1)))
	follow_target = owner
	var data := GameState.species_data(species_id)
	body_color = Color(str(data.get("color", "#aaaaaa")))
	accent_color = Color(str(data.get("accent", "#eeeeee")))
	attack_power = float(data.get("base_attack", 10.0)) * 0.8 + level * 1.7
	move_speed = maxf(155.0, float(data.get("speed", 120.0)) + 35.0)
	command_name = str(data.get("command_name", "御灵"))
	command_style = str(data.get("command_style", "pounce"))
	command_cost = float(data.get("command_cost", 25.0))
	command_range = float(data.get("command_range", 340.0))
	command_windup = float(data.get("command_windup", 0.2))


func _ready() -> void:
	add_to_group("companions")
	collision_layer = 1
	collision_mask = 2 | 4
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	collision.shape = circle
	add_child(collision)
	_build_generated_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(follow_target):
		return
	_command_cooldown = maxf(0.0, _command_cooldown - delta)
	_command_windup_timer = maxf(0.0, _command_windup_timer - delta)
	_command_travel_timer = maxf(0.0, _command_travel_timer - delta)
	_command_flash = maxf(0.0, _command_flash - delta)

	if is_instance_valid(_command_target):
		if _command_windup_timer > 0.0:
			velocity = velocity.move_toward(Vector2.ZERO, 680.0 * delta)
		elif command_style == "snare":
			_land_command()
		else:
			var distance := global_position.distance_to(_command_target.global_position)
			if distance <= 52.0 or _command_travel_timer <= 0.0:
				_land_command()
			else:
				velocity = global_position.direction_to(_command_target.global_position) * maxf(520.0, move_speed * 2.8)
	else:
		_follow_owner(delta)
	move_and_slide()
	_update_generated_sprite(delta)
	queue_redraw()


func _build_generated_sprite() -> void:
	var generated_texture: Texture2D
	match species_id:
		"ember_fox":
			generated_texture = EMBER_FOX_RUN_TEXTURE
		"jade_hare":
			generated_texture = JADE_HARE_HOP_TEXTURE
		"cloud_crane":
			generated_texture = CLOUD_CRANE_FLIGHT_TEXTURE
		"stone_tortoise":
			generated_texture = STONE_TORTOISE_CRAWL_TEXTURE
		"thunder_cub":
			generated_texture = THUNDER_CUB_RUN_TEXTURE
	if generated_texture == null:
		return
	var visual_scale := _generated_visual_scale()
	var animated := _uses_animation_sheet()
	var sprite_y := _generated_sprite_y()
	var alpha_material := ShaderMaterial.new() if animated else null
	if alpha_material != null:
		alpha_material.shader = ALPHA_CLIP_SHADER
		alpha_material.set_shader_parameter("brightness", 1.28 if species_id == "stone_tortoise" else 1.12)
	_outline_sprite = Sprite2D.new()
	_outline_sprite.name = "GeneratedSpiritOutline"
	_outline_sprite.texture = generated_texture
	_outline_sprite.hframes = 4 if animated else 1
	_outline_sprite.vframes = 4 if animated else 1
	_outline_sprite.scale = Vector2(visual_scale * 1.07, visual_scale * 1.07)
	_outline_sprite.position = Vector2(0, sprite_y)
	_outline_sprite.modulate = Color(0.01, 0.035, 0.035, 0.76)
	_outline_sprite.z_index = -1
	_outline_sprite.material = alpha_material
	_outline_sprite.visible = not animated
	_outline_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_outline_sprite)
	_sprite = Sprite2D.new()
	_sprite.name = "GeneratedSpiritSprite"
	_sprite.texture = generated_texture
	_sprite.hframes = 4 if animated else 1
	_sprite.vframes = 4 if animated else 1
	_sprite.scale = Vector2(visual_scale, visual_scale)
	_sprite.position = Vector2(0, sprite_y)
	_sprite.material = alpha_material
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	_update_generated_sprite()


func _update_generated_sprite(delta := 0.0) -> void:
	if not is_instance_valid(_sprite):
		return
	var moving := velocity.length_squared() > 16.0
	if moving:
		_visual_facing = velocity.normalized()
	if _uses_animation_sheet():
		if moving or is_instance_valid(_command_target):
			_walk_animation_time += delta * (1.5 if is_instance_valid(_command_target) else 1.0)
		else:
			_walk_animation_time = 0.0
		_sprite.frame_coords = Vector2i(int(_walk_animation_time * 8.0) % 4, _direction_row(_visual_facing))
		_sprite.flip_h = false
	elif absf(velocity.x) > 2.0:
		_sprite.flip_h = velocity.x < 0.0
	var visual_scale := _generated_visual_scale()
	var commanding := is_instance_valid(_command_target)
	_sprite.scale = Vector2(visual_scale * (1.08 if commanding else 1.0), visual_scale * (0.94 if commanding else 1.0))
	_sprite.rotation = clampf(velocity.x / 5200.0, -0.11, 0.11)
	var base_y := _generated_sprite_y()
	_sprite.position.y = base_y + sin(Time.get_ticks_msec() * 0.018) * 1.2
	if is_instance_valid(_outline_sprite):
		_outline_sprite.flip_h = _sprite.flip_h
		_outline_sprite.frame_coords = _sprite.frame_coords
		_outline_sprite.position = _sprite.position
		_outline_sprite.rotation = _sprite.rotation
		_outline_sprite.scale = _sprite.scale * 1.07


func _generated_visual_scale() -> float:
	match species_id:
		"cloud_crane":
			return 0.25
		"stone_tortoise":
			return 0.24
		"thunder_cub":
			return 0.24
	return 0.235


func _generated_sprite_y() -> float:
	return -42.0 if species_id == "cloud_crane" else -36.0


func _uses_animation_sheet() -> bool:
	return species_id in ["jade_hare", "ember_fox", "cloud_crane", "stone_tortoise", "thunder_cub"]


func _direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		if species_id == "cloud_crane":
			return 2 if direction.x > 0.0 else 1
		return 1 if direction.x > 0.0 else 2
	return 0 if direction.y >= 0.0 else 3


func command(target: Node2D) -> bool:
	if not is_command_ready() or not is_instance_valid(target):
		return false
	var target_direction := global_position.direction_to(target.global_position)
	if target_direction.length_squared() > 0.01:
		_visual_facing = target_direction
	_command_target = target
	_command_windup_timer = command_windup
	_command_travel_timer = 0.72
	_command_cooldown = 1.05 if command_style == "snare" else 1.2
	_command_flash = command_windup + 0.2
	queue_redraw()
	return true


func is_command_ready() -> bool:
	return _command_cooldown <= 0.0 and not is_instance_valid(_command_target)


func command_cooldown_remaining() -> float:
	return _command_cooldown


func _land_command() -> void:
	var landed_target := _command_target
	_command_target = null
	_command_travel_timer = 0.0
	velocity = Vector2.ZERO
	_command_flash = 0.24
	if not is_instance_valid(landed_target):
		return
	if landed_target.has_method("apply_link_mark"):
		landed_target.call("apply_link_mark", species_id, attack_power)
	command_landed.emit(landed_target, species_id)


func _follow_owner(delta: float) -> void:
	var desired_position := follow_target.global_position + Vector2(-38.0, 38.0)
	var distance_to_owner := global_position.distance_to(desired_position)
	if distance_to_owner > 520.0:
		global_position = desired_position
		velocity = Vector2.ZERO
	elif distance_to_owner > 38.0:
		velocity = global_position.direction_to(desired_position) * minf(move_speed, distance_to_owner * 3.2)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)


func _draw() -> void:
	draw_circle(Vector2(2, 12), 18.0, Color(0.01, 0.02, 0.03, 0.3))
	if not is_instance_valid(_sprite):
		draw_circle(Vector2.ZERO, 17.0, body_color)
		draw_circle(Vector2(-11, -12), 7.0, accent_color)
		draw_circle(Vector2(11, -12), 7.0, accent_color)
		draw_circle(Vector2(-6, -2), 2.0, Color("#15282b"))
		draw_circle(Vector2(6, -2), 2.0, Color("#15282b"))
	var aura_radius := 35.0 if is_instance_valid(_sprite) else 23.0
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 28, Color(accent_color, 0.6), 2.0)
	if is_instance_valid(_command_target):
		var local_target := to_local(_command_target.global_position)
		draw_dashed_line(Vector2.ZERO, local_target, Color(accent_color, 0.75), 3.0, 10.0)
	if _command_flash > 0.0:
		draw_arc(Vector2.ZERO, aura_radius + 7.0 + _command_flash * 12.0, 0.0, TAU, 28, Color(accent_color, 0.9), 4.0)
