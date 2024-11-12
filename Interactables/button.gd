# button.gd
class_name button
extends Interactable

@onready var game_manager = $"../../GameManager"

func _ready():
	mutiny_value = 10
	prompt = "Press E to press button " + "(+" + str(mutiny_value) + " mutiny)"


func interact() -> void:
	print("PRESSED BUTTON AND GAINED " + str(mutiny_value) + " MUTINY")
	game_manager.mutiny_index += mutiny_value