# button.gd
class_name button
extends Interactable

@onready var game_manager = $"../../GameManager"

func _ready():
	mutiny_value = 10
	prompt = "Press E to press button " + "(+" + str(mutiny_value) + " mutiny)"


func interact() -> void:
	print("PRESSED BUTTON AND GAINED " + str(mutiny_value) + " MUTINY")
	if !multiplayer.is_server():
		# Request to increase mutiny by 5
		game_manager.request_mutiny_update.rpc(mutiny_value)
