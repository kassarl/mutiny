extends Node2D

func _ready() -> void:
	
	GlobalEvents.messages_updated.connect(on_messages_updated)
	
func on_messages_updated(messages: Array):
	print("HERE")
	print(messages)
