extends VBoxContainer

@onready var log_row: Label = $Input

var game_time
var tag

func _enter_tree() -> void:
	# This is called before _ready() and when the node enters the scene tree
	log_row = get_node("Input")

func set_text(game_time, is_cap, new_text):
	game_time = "[%d:%02d]" % [int(game_time) / 60, int(game_time) % 60]
	if is_cap:
		tag = "You (Captain): "
	else:
		tag = "You (Imposter): "
	
	log_row.text = " > " + game_time + ": " + tag + " " + new_text
