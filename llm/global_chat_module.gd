extends Node

class_name global_chat_module

## LLM Client
@export var openai_client: Node


func _ready() -> void:
	openai_client.response_received.connect(captain_received_response)
## Code
func captain_submitted_message(message: String):
	openai_client.send_message(message)
	
func captain_received_response(message: String):
	print("RECEIVED")
	print(message)

func update_imposter_message_boards(messages: Array):
	emit_signal("messages_updated", messages)
	
