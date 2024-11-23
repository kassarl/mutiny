extends CanvasLayer

var game_paused: bool = false

# Called when the node enters the scene tree for the first time
func _ready():
	# Initially hide the menu
	visible = false

	# Connect the buttons to their respective functions
	$PausePanel/Resume.pressed.connect(_on_resume_pressed)
	$PausePanel/Quit.pressed.connect(_on_quit_pressed)

# This method is called every frame to check for input
func _unhandled_input(event: InputEvent) -> void:
	# Check if Escape key is pressed
	if Input.is_action_just_pressed("ui_cancel"):
		print("escape clicked game state:", game_paused)
		if game_paused:
			unpause_game()
		else:
			pause_game()

# Pauses the game and shows the pause menu
func pause_game() -> void:
	game_paused = true
	visible = true  # Show the pause menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Unpauses the game and hides the pause menu
func unpause_game() -> void:
	game_paused = false
	visible = false  # Hide the pause menu
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called when the Resume button is pressed
func _on_resume_pressed() -> void:
	unpause_game()


# Called when the Quit button is pressed
func _on_quit_pressed() -> void:
	get_tree().quit()  # Quit the game
