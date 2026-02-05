extends Node

var streams = {
	"click": [preload("res://assets/audio/interface/click.ogg"), "Interface"],
	"switch": [preload("res://assets/audio/interface/switch.ogg"), "Interface"],
	"open": [preload("res://assets/audio/interface/open.ogg"), "Interface"],
	"close": [preload("res://assets/audio/interface/close.ogg"), "Interface"],
	"slider": [preload("res://assets/audio/interface/slider.ogg"), "Interface"],
	"dream_main": [preload("res://assets/audio/music/dream_main.ogg"), "Music"],
	"dream_bass": [preload("res://assets/audio/music/dream_bass.ogg"), "Music"],
	"dream_synth": [preload("res://assets/audio/music/dream_synth.ogg"), "Music"],
	"dream_extra": [preload("res://assets/audio/music/dream_extra.ogg"), "Music"]
}
var music_names = ["dream_main", "dream_bass", "dream_synth", "dream_extra"]
var music_volume: Array[float] = [0.0, 0.0, 0.0, 0.0]
var music_target_volume: Array[float] = [0.0, 0.0, 0.0, 0.0]
var music_speed: float = 1.0
var music_target_speed: float = 1.0
var stream_players = {}

func _ready():
	for id in streams:
		var stream_player = AudioStreamPlayer.new()
		stream_player.stream = streams[id][0]
		stream_player.bus = streams[id][1]
		add_child(stream_player)
		stream_players[id] = stream_player
	
	stream_players["dream_main"].finished.connect(start_music)
	
func _process(delta):
	update_music(delta)

func skip_music_fade():
	update_music(INF)

func update_music(delta):
	for i in music_volume.size():
		var rate = 15.0 if music_volume[i] > -15.0 else 60.0
		music_volume[i] = move_toward(music_volume[i], music_target_volume[i], delta * rate)
	music_speed = move_toward(music_speed, music_target_speed, delta)
	
	var music_pitch = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0)
	music_pitch.pitch_scale = 1.0 / music_speed
	
	for i in music_names.size():
		var stream_player = stream_players[music_names[i]]
		stream_player.volume_db = music_volume[i] - 15.0
		stream_player.pitch_scale = music_speed

func start_music():
	for music_name in music_names:
		play_sound(music_name)

func set_music_volume(array: Array[float]):
	music_target_volume = array

func set_music_speed(speed):
	music_target_speed = speed

func play_sound(id):
	stream_players[id].play()
