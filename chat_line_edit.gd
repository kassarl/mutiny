extends LineEdit

@onready var open_ai_client: OpenAIClient = $"../../../OpenAIClient"


func show_input_box():
	visible = true
	grab_focus()  # Focus the input field to allow immediate typing

func hide_input_box():
	visible = false
	text = ""  # Optionally, clear the text after hiding

func _on_text_submitted(new_text: String) -> void:
	print("Player entered:", new_text)
	#Fire the send_message
	#do something with response?
	open_ai_client.send_message("new_text")
	hide_input_box()
	
