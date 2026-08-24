extends RefCounted


static func ensure_actions() -> void:
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("dash", KEY_SPACE)
	_add_key_action("throw_seal", KEY_Q)
	_add_key_action("cycle_companion", KEY_R)
	_add_key_action("toggle_journal", KEY_TAB)
	_add_key_action("toggle_world_map", KEY_M)
	_add_key_action("interact", KEY_E)
	_add_key_action("pause_game", KEY_ESCAPE)
	_add_key_action("save_game", KEY_F5)
	_add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	_add_mouse_action("companion_command", MOUSE_BUTTON_RIGHT)


static func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


static func _add_mouse_action(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
