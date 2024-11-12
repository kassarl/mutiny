extends Node

@onready var stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Intro Music
const COLD_SUNDAY = preload("res://Audio/coldSunday.mp3")
const CRASH = preload("res://Audio/crash.mp3")
const PROMOTION = preload("res://Audio/promotion.mp3")

# Ocean Sounds
const OCEAN_SOUNDS = preload("res://Audio/ocean_sounds.wav")

# Intro Arr
var intro_themes = [COLD_SUNDAY, CRASH, PROMOTION]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_intro_music()

func start_intro_music():
	var intro_song = intro_themes[randi_range(0,2)]

	stream_player.stream = intro_song
	stream_player.play()

func stop_stream():
	stream_player.stop()
	
func start_ocean_sounds():
	stream_player.stream = OCEAN_SOUNDS
	stream_player.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
