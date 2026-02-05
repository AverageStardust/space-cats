extends AudioStreamPlayer

@export var path := "res://assets/audio/file_%03d.ogg"
@export var amount := 1

var audio_streams: Array[AudioStream] = []
var last_stream: AudioStream

func _ready():
	for i in amount:
		audio_streams.append(load(path % [i]))

func play_random(from_position: float = 0.0):
	for i in 100:
		stream = audio_streams.pick_random()
		if stream != last_stream: break
	play(from_position)
	last_stream = stream
