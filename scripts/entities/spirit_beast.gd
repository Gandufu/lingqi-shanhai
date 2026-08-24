extends CharacterBody2D

signal defeated(beast: Node, xp_reward: int)
signal captured(beast: Node)
signal capture_failed(beast: Node)
signal link_struck(beast: Node, partner_species: String, effect: String, resolve_damage: float, matchup: String)
signal elite_phase_changed(beast: Node, phase: int, title: String, hint: String)
signal request_projectile(origin: Vector2, direction: Vector2, damage: float, color: Color, speed: float, label: String)

enum BrainState { WANDER, ALERT, ATTACK, STAGGER }

const SANCTUARY_CENTER := Vector2(1400.0, 900.0)
const SANCTUARY_RADIUS := 250.0
const EMBER_FOX_RUN_TEXTURE := preload("res://assets/generated/core/ember-fox-run-sheet-v6.png")
const JADE_HARE_HOP_TEXTURE := preload("res://assets/generated/core/jade-hare-hop-sheet-v5.png")
const CLOUD_CRANE_FLIGHT_TEXTURE := preload("res://assets/generated/core/cloud-crane-flight-sheet-v5.png")
const STONE_TORTOISE_CRAWL_TEXTURE := preload("res://assets/generated/core/stone-tortoise-crawl-sheet-v2.png")
const THUNDER_CUB_RUN_TEXTURE := preload("res://assets/generated/core/thunder-cub-run-sheet-v6.png")
const ALPHA_CLIP_SHADER := preload("res://shaders/sprite_alpha_clip.gdshader")

var species_id := "ember_fox"
var beast_name := "灵兽"
var level := 1
var max_health := 60.0
var health := 60.0
var attack_power := 10.0
var move_speed := 110.0
var temper := 0.5
var is_elite := false
var max_resolve := 90.0
var resolve := 90.0
var body_color := Color("#e8794a")
var accent_color := Color("#ffd37a")
var target

var _state := BrainState.WANDER
var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _think_timer := 0.0
var _attack_cooldown := 0.0
var _stagger_timer := 0.0
var _hurt_flash := 0.0
var _hostile_timer := 0.0
var _cast_flash := 0.0
var _attack_windup := 0.0
var _pending_attack := ""
var _pending_aim := Vector2.RIGHT
var _link_window := 0.0
var _link_species := ""
var _link_power := 0.0
var _contract_window := 0.0
var _wind_bind_timer := 0.0
var _armor_broken_timer := 0.0
var _elite_phase := 1
var _storm_armor_broken_timer := 0.0
var _storm_bind_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _walk_animation_time := 0.0
var _visual_facing := Vector2.RIGHT
var _sprite: Sprite2D
var _outline_sprite: Sprite2D


func setup(id: String, beast_level: int, spawn_position: Vector2, chase_target: Node2D, elite := false) -> void:
	species_id = id
	level = maxi(1, beast_level)
	global_position = spawn_position
	_home = spawn_position
	target = chase_target
	is_elite = elite
	var data := GameState.species_data(species_id)
	beast_name = str(data.get("name", "无名灵兽"))
	body_color = Color(str(data.get("color", "#aaaaaa")))
	accent_color = Color(str(data.get("accent", "#eeeeee")))
	max_health = float(data.get("base_health", 60.0)) + (level - 1) * 9.0
	health = max_health
	attack_power = float(data.get("base_attack", 10.0)) + (level - 1) * 1.6
	move_speed = float(data.get("speed", 110.0)) + minf(24.0, level * 1.5)
	temper = float(data.get("temper", 0.5))
	max_resolve = (82.0 + level * 8.0) * (1.25 if is_elite else 1.0)
	resolve = max_resolve
	_elite_phase = 1
	_storm_armor_broken_timer = 0.0
	_storm_bind_timer = 0.0


func _ready() -> void:
	add_to_group("wild_beasts")
	collision_layer = 2
	collision_mask = 1 | 2 | 4
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 19.0
	collision.shape = circle
	add_child(collision)
	_build_generated_sprite()
	_rng.seed = hash("%s:%s:%s" % [species_id, global_position, Time.get_ticks_usec()])
	_pick_wander_target()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_think_timer = maxf(0.0, _think_timer - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_stagger_timer = maxf(0.0, _stagger_timer - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	_hostile_timer = maxf(0.0, _hostile_timer - delta)
	_cast_flash = maxf(0.0, _cast_flash - delta)
	var attack_was_winding_up := _attack_windup > 0.0
	_attack_windup = maxf(0.0, _attack_windup - delta)
	if attack_was_winding_up and _attack_windup <= 0.0:
		_execute_pending_attack()
	_link_window = maxf(0.0, _link_window - delta)
	_wind_bind_timer = maxf(0.0, _wind_bind_timer - delta)
	_armor_broken_timer = maxf(0.0, _armor_broken_timer - delta)
	_storm_armor_broken_timer = maxf(0.0, _storm_armor_broken_timer - delta)
	_storm_bind_timer = maxf(0.0, _storm_bind_timer - delta)
	_update_generated_sprite(delta)
	var contract_was_open := _contract_window > 0.0
	_contract_window = maxf(0.0, _contract_window - delta)
	if _link_window <= 0.0:
		_link_species = ""
		_link_power = 0.0
	if contract_was_open and _contract_window <= 0.0:
		resolve = maxf(resolve, max_resolve * 0.45)
	if not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, 320.0 * delta)
		move_and_slide()
		return
	if global_position.distance_to(SANCTUARY_CENTER) < SANCTUARY_RADIUS:
		velocity = SANCTUARY_CENTER.direction_to(global_position) * move_speed * 1.35
		move_and_slide()
		queue_redraw()
		return

	if _stagger_timer > 0.0:
		_state = BrainState.STAGGER
		velocity = velocity.move_toward(Vector2.ZERO, 540.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	if _attack_windup > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 620.0 * delta)
		move_and_slide()
		queue_redraw()
		return

	var target_distance := global_position.distance_to(target.global_position)
	var detection := 185.0 + temper * 145.0
	if _hostile_timer > 0.0 or target_distance < detection:
		var attack_range := 250.0 if _is_ranged() else 58.0
		_state = BrainState.ATTACK if target_distance < attack_range else BrainState.ALERT
	else:
		_state = BrainState.WANDER

	match _state:
		BrainState.WANDER:
			if is_movement_bound():
				velocity = velocity.move_toward(Vector2.ZERO, 620.0 * delta)
				move_and_slide()
			else:
				_wander(delta)
		BrainState.ALERT:
			velocity = Vector2.ZERO if is_movement_bound() else global_position.direction_to(target.global_position) * move_speed
			move_and_slide()
		BrainState.ATTACK:
			if _is_ranged():
				_ranged_combat(delta, target_distance)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 480.0 * delta)
				move_and_slide()
				if _attack_cooldown <= 0.0 and not is_movement_bound() and target.has_method("take_damage"):
					_begin_melee_attack()
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
	_outline_sprite.position = Vector2(0, _generated_sprite_y())
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
	_sprite.position = Vector2(0, _generated_sprite_y())
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
		if moving:
			_walk_animation_time += delta
		else:
			_walk_animation_time = 0.0
		var frame_index := 2 + int(_attack_windup * 12.0) % 2 if _attack_windup > 0.0 else int(_walk_animation_time * 8.0) % 4
		_sprite.frame_coords = Vector2i(frame_index, _direction_row(_visual_facing))
		_sprite.flip_h = false
	elif absf(velocity.x) > 2.0:
		_sprite.flip_h = velocity.x < 0.0
	var visual_scale := _generated_visual_scale()
	var pulse := 1.0 + (sin(Time.get_ticks_msec() * 0.03) * 0.045 if _attack_windup > 0.0 else 0.0)
	_sprite.scale = Vector2(visual_scale * pulse, visual_scale / pulse)
	_sprite.rotation = sin(Time.get_ticks_msec() * 0.04) * 0.055 if _stagger_timer > 0.0 else 0.0
	_sprite.position.y = _generated_sprite_y() + sin(Time.get_ticks_msec() * 0.015 + float(get_instance_id() % 17)) * 1.3
	_sprite.modulate = Color(1.0, 0.62, 0.62) if _hurt_flash > 0.0 else Color.WHITE
	if is_instance_valid(_outline_sprite):
		_outline_sprite.flip_h = _sprite.flip_h
		_outline_sprite.frame_coords = _sprite.frame_coords
		_outline_sprite.position = _sprite.position
		_outline_sprite.rotation = _sprite.rotation
		_outline_sprite.scale = _sprite.scale * 1.07


func _generated_visual_scale() -> float:
	var scale_value := 0.061
	match species_id:
		"ember_fox":
			scale_value = 0.235
		"jade_hare":
			scale_value = 0.235
		"cloud_crane":
			scale_value = 0.25
		"stone_tortoise":
			scale_value = 0.24
		"thunder_cub":
			scale_value = 0.24
	return scale_value * (1.18 if is_elite else 1.0)


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


func _wander(delta: float) -> void:
	if _think_timer <= 0.0 or global_position.distance_to(_wander_target) < 18.0:
		_pick_wander_target()
	var desired := global_position.direction_to(_wander_target) * move_speed * 0.42
	velocity = velocity.move_toward(desired, 140.0 * delta)
	move_and_slide()


func _pick_wander_target() -> void:
	_think_timer = _rng.randf_range(1.4, 3.2)
	_wander_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(35.0, 145.0)


func _is_ranged() -> bool:
	return species_id == "cloud_crane" or species_id == "thunder_cub"


func _ranged_combat(delta: float, target_distance: float) -> void:
	var desired_velocity := Vector2.ZERO
	if is_movement_bound():
		desired_velocity = Vector2.ZERO
	elif target_distance < 105.0:
		desired_velocity = target.global_position.direction_to(global_position) * move_speed * 0.8
	elif target_distance > 205.0:
		desired_velocity = global_position.direction_to(target.global_position) * move_speed * 0.55
	velocity = velocity.move_toward(desired_velocity, 360.0 * delta)
	move_and_slide()
	if _attack_cooldown > 0.0 or is_movement_bound():
		return
	_begin_ranged_attack()


func _begin_melee_attack() -> void:
	if not is_instance_valid(target):
		return
	_pending_attack = "melee"
	_pending_aim = global_position.direction_to(target.global_position)
	_visual_facing = _pending_aim
	_attack_windup = 0.3 if is_elite else 0.38
	_cast_flash = _attack_windup
	_attack_cooldown = 0.95 + (1.0 - temper) * 0.4


func _begin_ranged_attack() -> void:
	if not is_instance_valid(target):
		return
	_pending_attack = "ranged"
	_pending_aim = global_position.direction_to(target.global_position)
	_visual_facing = _pending_aim
	if is_elite and species_id == "thunder_cub":
		match _elite_phase:
			2:
				_attack_windup = 0.58
			3:
				_attack_windup = 0.28
			_:
				_attack_windup = 0.42
	else:
		_attack_windup = 0.42
	_cast_flash = _attack_windup
	if species_id == "cloud_crane":
		_attack_cooldown = 1.45
	elif is_elite:
		match _elite_phase:
			2:
				_attack_cooldown = 1.65
			3:
				_attack_cooldown = 0.78
			_:
				_attack_cooldown = 1.25
	else:
		_attack_cooldown = 1.25


func _execute_pending_attack() -> void:
	var attack_kind := _pending_attack
	_pending_attack = ""
	if attack_kind.is_empty() or not is_instance_valid(target):
		return
	if attack_kind == "melee":
		if global_position.distance_to(target.global_position) <= 72.0 and target.has_method("take_damage"):
			target.call("take_damage", attack_power, self)
		return
	if species_id == "cloud_crane":
		request_projectile.emit(global_position + _pending_aim * 22.0, _pending_aim, attack_power * 0.82, accent_color, 355.0, "流云风刃")
	else:
		var shot_count := elite_shot_count() if is_elite else 1
		var spread := 0.19 if _elite_phase == 2 else 0.12 if _elite_phase == 3 else 0.2 if is_elite else 0.0
		var projectile_speed := 455.0 if is_elite and _elite_phase == 3 else 405.0
		for index in range(shot_count):
			var offset := (index - (shot_count - 1) * 0.5) * spread
			request_projectile.emit(global_position + _pending_aim * 23.0, _pending_aim.rotated(offset), attack_power * 0.72, accent_color, projectile_speed, "紫电雷丸")


func has_attack_windup() -> bool:
	return _attack_windup > 0.0


func _cancel_pending_attack() -> void:
	_attack_windup = 0.0
	_pending_attack = ""


func take_damage(amount: float, source: Node = null) -> bool:
	if health <= 0.0:
		return false
	var completed_link := source != null and source.is_in_group("player") and _link_window > 0.0
	if completed_link:
		_complete_link_strike()
	var applied_amount := amount
	if species_id == "stone_tortoise" and not is_armor_broken():
		applied_amount *= 0.32
	elif is_elite and species_id == "thunder_cub" and _elite_phase == 2 and not is_storm_armor_broken():
		applied_amount *= 0.42
	var minimum_health := 1.0 if can_contract() else 0.0
	health = maxf(minimum_health, health - applied_amount)
	_hurt_flash = 0.2
	_stagger_timer = maxf(_stagger_timer, 0.16)
	if completed_link:
		_cancel_pending_attack()
	_hostile_timer = 8.0
	if source is Node2D:
		velocity = source.global_position.direction_to(global_position) * 290.0
	queue_redraw()
	if health <= 0.0:
		defeated.emit(self, 24 + level * 12)
	return completed_link


func try_capture() -> void:
	if health <= 0.0:
		return
	if can_contract():
		captured.emit(self)
	else:
		_hostile_timer = 12.0
		_stagger_timer = 0.3
		capture_failed.emit(self)


func apply_link_mark(partner_species: String, companion_power: float) -> void:
	if health <= 0.0 or can_contract():
		return
	var data := GameState.species_data(partner_species)
	_link_species = partner_species
	_link_power = companion_power
	_link_window = float(data.get("link_window", 1.4))
	if species_id == "cloud_crane" and partner_species == "jade_hare":
		_wind_bind_timer = maxf(_wind_bind_timer, _link_window + 0.55)
	if is_elite and species_id == "thunder_cub" and _elite_phase == 3 and partner_species == "jade_hare":
		_storm_bind_timer = maxf(_storm_bind_timer, _link_window + 0.55)
		_cancel_pending_attack()
	var chip_damage := maxf(1.0, companion_power * 0.24)
	if species_id == "stone_tortoise" and partner_species != "ember_fox" and not is_armor_broken():
		chip_damage *= 0.32
	health = maxf(1.0, health - chip_damage)
	_hostile_timer = 10.0
	_stagger_timer = maxf(_stagger_timer, 0.12)
	queue_redraw()


func has_link_mark() -> bool:
	return _link_window > 0.0 and not _link_species.is_empty()


func can_contract() -> bool:
	return _contract_window > 0.0 and health > 0.0


func resolve_ratio() -> float:
	return resolve / max_resolve if max_resolve > 0.0 else 0.0


func is_wind_bound() -> bool:
	return species_id == "cloud_crane" and _wind_bind_timer > 0.0


func is_armor_broken() -> bool:
	return species_id == "stone_tortoise" and _armor_broken_timer > 0.0


func is_storm_armor_broken() -> bool:
	return is_elite and species_id == "thunder_cub" and _storm_armor_broken_timer > 0.0


func is_storm_bound() -> bool:
	return is_elite and species_id == "thunder_cub" and _storm_bind_timer > 0.0


func is_movement_bound() -> bool:
	return is_wind_bound() or is_storm_bound()


func elite_phase() -> int:
	return _elite_phase if is_elite and species_id == "thunder_cub" else 0


func elite_shot_count() -> int:
	if not is_elite or species_id != "thunder_cub":
		return 1
	return 5 if _elite_phase == 2 else 3


func combat_trait_name() -> String:
	if is_elite and species_id == "thunder_cub":
		match _elite_phase:
			2:
				return "雷甲"
			3:
				return "雷行"
			_:
				return "雷狩"
	return str(GameState.species_data(species_id).get("wild_trait", ""))


func combat_hint() -> String:
	if is_elite and species_id == "thunder_cub":
		match _elite_phase:
			2:
				return "雷甲卸剑 · 焰尾协同可破甲并推进雷封"
			3:
				return "雷行追狩 · 月影缚可停步并放大破势"
			_:
				return "雷狩试探 · 观察三连雷丸，协同破开第一道雷封"
	return str(GameState.species_data(species_id).get("wild_hint", ""))


func contract_status() -> String:
	if can_contract():
		return "契机已现 · 按 Q 结契（必成）"
	if has_link_mark():
		return "灵印将散 · 立即以剑诀追击"
	return "执念 %.0f/%.0f · 右键御灵后追击" % [resolve, max_resolve]


func _complete_link_strike() -> void:
	var partner_species := _link_species
	var companion_power := _link_power
	var data := GameState.species_data(partner_species)
	var resolve_damage := float(data.get("resolve_damage", 36.0))
	var effect := str(data.get("link_effect", "burst"))
	var matchup := ""
	if species_id == "stone_tortoise":
		if partner_species == "ember_fox":
			resolve_damage *= 1.45
			_armor_broken_timer = 5.0
			matchup = "armor_break"
		else:
			resolve_damage *= 0.6
	elif species_id == "cloud_crane":
		if partner_species == "jade_hare":
			resolve_damage *= 1.35
			_wind_bind_timer = maxf(_wind_bind_timer, 2.8)
			matchup = "wind_bind"
		else:
			resolve_damage *= 0.68
	elif is_elite and species_id == "thunder_cub":
		if _elite_phase == 2:
			if partner_species == "ember_fox":
				resolve_damage *= 1.45
				_storm_armor_broken_timer = 5.0
				matchup = "storm_armor_break"
			else:
				resolve_damage *= 0.72
		elif _elite_phase == 3:
			if partner_species == "jade_hare":
				resolve_damage *= 1.35
				_storm_bind_timer = maxf(_storm_bind_timer, 3.0)
				_cancel_pending_attack()
				matchup = "storm_bind"
			else:
				resolve_damage *= 0.74
	resolve = maxf(0.0, resolve - resolve_damage)
	var bonus_damage := companion_power * (0.58 if effect == "burst" else 0.22)
	health = maxf(1.0, health - bonus_damage)
	_link_window = 0.0
	_link_species = ""
	_link_power = 0.0
	_stagger_timer = 0.58 if effect == "heal" else 0.34
	var phase_transition := _advance_elite_phase_if_needed()
	if resolve <= 0.0:
		_contract_window = 4.5 if not is_elite else 3.5
		_stagger_timer = _contract_window
	link_struck.emit(self, partner_species, effect, resolve_damage, matchup)
	if not phase_transition.is_empty():
		elite_phase_changed.emit(self, _elite_phase, str(phase_transition["title"]), str(phase_transition["hint"]))
	queue_redraw()


func _advance_elite_phase_if_needed() -> Dictionary:
	if not is_elite or species_id != "thunder_cub":
		return {}
	if _elite_phase == 1 and resolve <= max_resolve * 0.66:
		_elite_phase = 2
		resolve = max_resolve * 0.66
		_storm_armor_broken_timer = 0.0
		_attack_cooldown = maxf(_attack_cooldown, 1.0)
		_cancel_pending_attack()
		_stagger_timer = maxf(_stagger_timer, 0.9)
		return {"title": "二式 · 雷甲", "hint": "换赤焰灵狐，以焰尾协同击穿雷甲"}
	if _elite_phase == 2 and resolve <= max_resolve * 0.33:
		_elite_phase = 3
		resolve = max_resolve * 0.33
		_attack_cooldown = maxf(_attack_cooldown, 0.8)
		_cancel_pending_attack()
		_stagger_timer = maxf(_stagger_timer, 0.75)
		return {"title": "三式 · 雷行", "hint": "换碧玉月兔，以月影缚截停追狩"}
	return {}


func health_ratio() -> float:
	return health / max_health if max_health > 0.0 else 0.0


func _draw() -> void:
	var blink := _hurt_flash > 0.0 and int(_hurt_flash * 90.0) % 2 == 0
	var color := Color.WHITE if blink else body_color
	_draw_oval(Vector2(2, 18), Vector2(24, 9), Color(0.01, 0.02, 0.03, 0.32))
	if not is_instance_valid(_sprite):
		match species_id:
			"ember_fox":
				_draw_fox(color)
			"jade_hare":
				_draw_hare(color)
			"cloud_crane":
				_draw_crane(color)
			"stone_tortoise":
				_draw_tortoise(color)
			"thunder_cub":
				_draw_cub(color)
			_:
				draw_circle(Vector2.ZERO, 20.0, color)

	var visual_radius := 42.0 if is_instance_valid(_sprite) else 29.0
	if _state == BrainState.ALERT or _state == BrainState.ATTACK:
		draw_arc(Vector2.ZERO, visual_radius, 0.0, TAU, 28, Color(accent_color, 0.55), 2.0)
	if species_id == "stone_tortoise" and not is_armor_broken():
		draw_arc(Vector2.ZERO, 31.0, -2.8, -0.34, 22, Color("#dccd8e"), 5.0)
		draw_arc(Vector2.ZERO, 31.0, 0.34, 2.8, 22, Color("#dccd8e"), 5.0)
	elif is_armor_broken():
		draw_line(Vector2(-25, -22), Vector2(-8, -5), Color("#ff9f72"), 4.0)
		draw_line(Vector2(25, -22), Vector2(8, -5), Color("#ff9f72"), 4.0)
	if is_elite and species_id == "thunder_cub" and _elite_phase == 2:
		if is_storm_armor_broken():
			draw_line(Vector2(-31, -25), Vector2(-10, -5), Color("#ff9f72"), 4.0)
			draw_line(Vector2(31, -25), Vector2(10, -5), Color("#ff9f72"), 4.0)
		else:
			draw_arc(Vector2.ZERO, 45.0, -2.9, -0.25, 24, Color("#f5de61"), 5.0)
			draw_arc(Vector2.ZERO, 45.0, 0.25, 2.9, 24, Color("#8f83e8"), 5.0)
	elif is_elite and species_id == "thunder_cub" and _elite_phase == 3:
		var pursuit_radius := 45.0 + sin(Time.get_ticks_msec() * 0.02) * 4.0
		draw_arc(Vector2.ZERO, pursuit_radius, 0.0, TAU, 32, Color("#a08cf5"), 4.0)
	if is_wind_bound():
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 28, Color("#91f0c7"), 4.0)
		draw_line(Vector2(-24, 24), Vector2(24, 24), Color("#91f0c7"), 4.0)
	if is_storm_bound():
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 28, Color("#91f0c7"), 4.0)
		draw_line(Vector2(-31, 28), Vector2(31, 28), Color("#91f0c7"), 5.0)
	if _cast_flash > 0.0:
		draw_circle(Vector2.ZERO, 33.0 + _cast_flash * 16.0, Color(accent_color, _cast_flash * 1.8))
	if has_attack_windup():
		var telegraph_length := 150.0 if _pending_attack == "ranged" else 72.0
		draw_line(Vector2.ZERO, _pending_aim * telegraph_length, Color(1.0, 0.38, 0.3, 0.82), 5.0)
		draw_arc(Vector2.ZERO, 31.0, -0.8 + _pending_aim.angle(), 0.8 + _pending_aim.angle(), 18, Color(1.0, 0.48, 0.34, 0.9), 4.0)
	if has_link_mark():
		draw_arc(Vector2.ZERO, visual_radius + 5.0 + sin(Time.get_ticks_msec() * 0.012) * 3.0, 0.0, TAU, 30, Color("#f6d56b"), 4.0)
	if can_contract():
		for ring in range(3):
			draw_arc(Vector2.ZERO, visual_radius + 4.0 + ring * 6.0, 0.0, TAU, 32, Color(0.45, 1.0, 0.72, 0.82 - ring * 0.18), 3.0)
	if is_elite:
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32, Color("#f4d94f"), 3.0)
	var bar_y := -70.0 if is_instance_valid(_sprite) else -48.0
	if resolve < max_resolve:
		draw_rect(Rect2(-24, bar_y, 48, 4), Color(0.05, 0.08, 0.08, 0.8))
		draw_rect(Rect2(-23, bar_y + 1.0, 46 * resolve_ratio(), 2), Color("#d8a9ed"))
	if health < max_health:
		draw_rect(Rect2(-24, bar_y + 8.0, 48, 5), Color(0.05, 0.08, 0.08, 0.8))
		draw_rect(Rect2(-23, bar_y + 9.0, 46 * health_ratio(), 3), Color("#74d67a") if health_ratio() > 0.35 else Color("#e86755"))


func _draw_fox(color: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(-18, -9), Vector2(-12, -30), Vector2(-2, -15), Vector2(12, -30), Vector2(18, -8)]), PackedColorArray([color]))
	draw_circle(Vector2.ZERO, 21.0, color)
	draw_circle(Vector2(21, 12), 10.0, accent_color)
	_draw_eyes(8.0, -4.0)


func _draw_hare(color: Color) -> void:
	_draw_oval(Vector2(-9, -22), Vector2(6, 20), color)
	_draw_oval(Vector2(9, -22), Vector2(6, 20), color)
	draw_circle(Vector2.ZERO, 20.0, color)
	draw_circle(Vector2(18, 13), 7.0, accent_color)
	_draw_eyes(7.0, -3.0)


func _draw_crane(color: Color) -> void:
	_draw_oval(Vector2.ZERO, Vector2(24, 15), color)
	draw_polygon(PackedVector2Array([Vector2(-8, 2), Vector2(-34, -14), Vector2(-22, 12)]), PackedColorArray([accent_color]))
	draw_polygon(PackedVector2Array([Vector2(8, 2), Vector2(34, -14), Vector2(22, 12)]), PackedColorArray([accent_color]))
	draw_line(Vector2(11, -6), Vector2(22, -22), color, 7.0)
	draw_circle(Vector2(23, -23), 6.0, accent_color)
	draw_circle(Vector2(25, -24), 1.5, Color("#17252b"))


func _draw_tortoise(color: Color) -> void:
	_draw_oval(Vector2.ZERO, Vector2(27, 20), color)
	draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 20, accent_color, 3.0)
	draw_line(Vector2(-15, -12), Vector2(15, 12), accent_color, 2.0)
	draw_line(Vector2(15, -12), Vector2(-15, 12), accent_color, 2.0)
	draw_circle(Vector2(27, -2), 8.0, color)
	draw_circle(Vector2(30, -4), 1.7, Color("#17252b"))


func _draw_cub(color: Color) -> void:
	draw_circle(Vector2.ZERO, 21.0, color)
	draw_circle(Vector2(-14, -16), 8.0, accent_color)
	draw_circle(Vector2(14, -16), 8.0, accent_color)
	for index in range(4):
		var angle := index * TAU / 4.0 + 0.35
		var start := Vector2.from_angle(angle) * 22.0
		var middle := Vector2.from_angle(angle + 0.2) * 31.0
		var finish := Vector2.from_angle(angle) * 38.0
		draw_polyline(PackedVector2Array([start, middle, finish]), accent_color, 2.5)
	_draw_eyes(7.0, -3.0)


func _draw_eyes(spacing: float, y: float) -> void:
	draw_circle(Vector2(-spacing, y), 2.3, Color("#17252b"))
	draw_circle(Vector2(spacing, y), 2.3, Color("#17252b"))


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
