extends Node2D

const MENTOR_NAME := "清虚散人"
const MENTOR_WORLD_TEXTURE := preload("res://assets/generated/core/mentor-portrait.png")

var _sprite: Sprite2D
var _outline_sprite: Sprite2D


func _ready() -> void:
	z_index = 2
	_outline_sprite = Sprite2D.new()
	_outline_sprite.name = "GeneratedMentorOutline"
	_outline_sprite.texture = MENTOR_WORLD_TEXTURE
	_outline_sprite.scale = Vector2(0.068, 0.068)
	_outline_sprite.position = Vector2(0, -49)
	_outline_sprite.modulate = Color(0.01, 0.035, 0.035, 0.76)
	_outline_sprite.z_index = -1
	_outline_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_outline_sprite)
	_sprite = Sprite2D.new()
	_sprite.name = "GeneratedMentorSprite"
	_sprite.texture = MENTOR_WORLD_TEXTURE
	_sprite.scale = Vector2(0.064, 0.064)
	_sprite.position = Vector2(0, -49)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	queue_redraw()


func _process(_delta: float) -> void:
	if is_instance_valid(_sprite):
		_sprite.position.y = -49.0 + sin(Time.get_ticks_msec() * 0.009) * 1.1
		if is_instance_valid(_outline_sprite):
			_outline_sprite.position = _sprite.position


func dialogue_for(capture_count: int, defeat_count: int, cultivator_level: int, elite_defeated := false, link_count := 0, switch_count := 0, armor_break_count := 0, wind_bind_count := 0) -> String:
	if link_count < 1:
		return "灵契先求同心，不求强夺。以右键命月兔施展月影缚，灵印亮起时再用左键剑诀追击，方能破除执念。"
	if capture_count < 1:
		return "一次协同还不足以破尽执念。反复御灵、追击；待契机化作青色灵环，再按 Q 投符，结契必成。"
	if switch_count < 1:
		return "你已拥有两种战语。按 R 换上灵狐：焰尾突的灵印更短，却能削去更多执念；与月兔的稳健回命不同。"
	if armor_break_count < 1:
		return "东行可见玄岩灵龟。寻常剑诀会被玄甲卸力；换赤焰灵狐，以焰尾突协同追击，方能碎甲。"
	if wind_bind_count < 1:
		return "再往东南寻流云仙鹤。它御风拉距，灵狐难以贴身确认；换回碧玉月兔，以月影缚定风后再追击。"
	if defeat_count < 3:
		return "伙伴不再自行替你作战。灵狐的焰尾突窗口短而爆发高，月兔的月影缚窗口长且能回命，依战况主动下令。"
	if cultivator_level < 2:
		return "修为已近关隘。继续实战，待灵气圆满，自会突破下一层境界。"
	if elite_defeated:
		return "你已平息谷底雷息，也懂得灵契在于同行而非占有。青岚谷外，真正的山海正等着你。"
	return "谷底紫电狻猊有三式雷封：先读雷丸；雷甲现时换灵狐以焰尾贯甲；雷行追狩时换月兔，以月影缚截停。错契亦可磨破，只是风险更高。"


func _draw() -> void:
	_draw_oval(Vector2(2, 18), Vector2(21, 8), Color(0.01, 0.02, 0.03, 0.34))
	draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(0.68, 0.88, 0.81, 0.24), 2.0)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
