# interactable.gd (base class)
class_name Interactable
extends Node

var prompt: String
var mutiny_value: int

# Virtual method that child classes will implement
func interact() -> void:
	pass

func get_prompt():
	return prompt

func get_mutiny_value():
	return mutiny_value
