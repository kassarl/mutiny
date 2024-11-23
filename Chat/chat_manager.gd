extends Control

@onready var player: Player = $"../"
@onready var input_area: PanelContainer = $Background/MarginContainer/Rows/InputArea
@onready var line_edit: LineEdit = $Background/MarginContainer/Rows/InputArea/HBoxContainer/LineEdit
@onready var caret: Label = $Background/MarginContainer/Rows/InputArea/HBoxContainer/Caret
@onready var chat_log_rows: VBoxContainer = $Background/MarginContainer/Rows/GameInfo/ChatLogRows
@onready var ui_manager: Node = $"../../UIManager"

var in_chat = false
var placeholder_text = "What do you want to say?"
const input_response = preload("res://Chat/input_response.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("READYING CHAT BOX")
	set_chat_state(false)
	# Connect to necessary signals
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	# Prevent line_edit from handling input when not in chat
	line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_chat_state(enabled: bool) -> void:
	in_chat = enabled
	caret.visible = enabled
	line_edit.placeholder_text = placeholder_text if enabled else ""
	line_edit.editable = enabled
	line_edit.clear()
	
	if enabled:
		line_edit.grab_focus()
	else:
		line_edit.release_focus()

func call_chat(peer_id, path):
	rpc_id(peer_id, "start_player_chat", path)

#func toggleHUD():
	#print("Is CAPTAIN? ", player.is_captain)
	#
	#in_chat = !in_chat
	#
	#caret.visible = !caret.visible
	#
	#line_edit.placeholder_text = placeholder_text
	#
	#line_edit.grab_focus()
	#
	## Clearing line
	#line_edit.clear()


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() != "":
		print("USER ENTERED -> ", new_text)
		# Handle the chat message here
	
	var input = input_response.instantiate()
	chat_log_rows.add_child(input)
	input.set_text(ui_manager.timer.time_left, player.is_captain, new_text)
	
	# Wait for the next frame to ensure the node is ready
	#await get_tree().process_frame
	
	# Return to State 1 instead of State 0
	line_edit.clear()
	line_edit.grab_focus()
