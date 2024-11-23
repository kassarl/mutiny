extends VBoxContainer

#region Node References
@onready var log_row: Label = $Input
#endregion

#region Variables
var game_time
var tag
#endregion

#region Lifecycle Methods
# Initialize the log row when entering scene tree
func _enter_tree() -> void:
	# This is called before _ready() and when the node enters the scene tree
	log_row = get_node("Input")
#endregion

#region Message Formatting
# Format and set the chat message text with timestamp and player role
func set_text(game_time, is_cap, new_text):
	# Format timestamp as [MM:SS]
	game_time = "[%d:%02d]" % [int(game_time) / 60, int(game_time) % 60]
	
	# Set appropriate player tag based on role
	if is_cap:
		tag = "You (Captain): "
	else:
		tag = "You (Imposter): "
	
	# Combine all elements into final message format
	log_row.text = " > " + game_time + ": " + tag + " " + new_text
#endregion
