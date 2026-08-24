extends Node

const CUES := {
	"attack": preload("res://assets/third_party/kenney/rpg_audio/knifeSlice.ogg"),
	"dash": preload("res://assets/third_party/kenney/rpg_audio/cloth3.ogg"),
	"defeat": preload("res://assets/third_party/kenney/rpg_audio/chop.ogg"),
	"capture_fail": preload("res://assets/third_party/kenney/rpg_audio/metalClick.ogg"),
	"journal": preload("res://assets/third_party/kenney/rpg_audio/bookOpen.ogg"),
	"dialogue": preload("res://assets/third_party/kenney/rpg_audio/bookFlip1.ogg"),
	"seal_throw": preload("res://assets/third_party/opengameart/magic_spell_sfx/magical_1.ogg"),
	"capture_success": preload("res://assets/third_party/opengameart/magic_spell_sfx/magical_3.ogg"),
	"level_up": preload("res://assets/third_party/opengameart/magic_spell_sfx/magical_7.ogg"),
}

var _players: Array[AudioStreamPlayer] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for index in range(10):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%02d" % index
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	stop_all()


func play(cue: String, volume_db := -3.0, pitch_variation := 0.055) -> bool:
	if not CUES.has(cue) or _players.is_empty():
		return false
	var selected := _players[0]
	for player in _players:
		if not player.playing:
			selected = player
			break
	if selected.playing:
		selected.stop()
	selected.stream = CUES[cue]
	selected.volume_db = volume_db
	selected.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	selected.play()
	return true


func has_cue(cue: String) -> bool:
	return CUES.has(cue)


func cue_count() -> int:
	return CUES.size()


func stop_all() -> void:
	for player in _players:
		if not is_instance_valid(player):
			continue
		player.stop()
		player.stream = null
