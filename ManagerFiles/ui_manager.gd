# UIManager.gd
extends Node

@onready var game_manager: Node = $"../GameManager"
@onready var timer_label: Label = $"../CanvasLayer/HUD/TimerLabel"
@onready var timer: Timer = $"../CanvasLayer/HUD/Timer"
@onready var mutiny_label: Label = $"../CanvasLayer/HUD/MutinyLabel"
@onready var main_menu: Control = $"../CanvasLayer/MainMenu"
@onready var address_entry: LineEdit = $"../CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry"

func _ready() -> void:
	initialize_GUI()
	timer.wait_time = game_manager.GAME_TIME

func initialize_GUI() -> void:
	timer_label.text = ""
	mutiny_label.text = ""

func sync_display(mutiny: int, time: float) -> void:
	print("SYNCING Display now")
	print("new mutiny value ", mutiny)
	update_mutiny_display(mutiny)
	print("Client starting local timer...")
	timer.wait_time = time
	timer.start()
	update_timer_display()

func start_game_ui() -> void:
	if multiplayer.is_server():
		print("Host starting timer...")
		timer.start()
	
	update_mutiny_display(0)

func _process(_delta: float) -> void:
	if game_manager.in_game:
		update_timer_display()

func update_mutiny_display(mutiny):
	print("New mutiny")
	print(mutiny)
	mutiny_label.text = "Mutiny Index: %d/100" % mutiny

func update_timer_display() -> void:
	timer_label.text = "IMPOSTER\n%d:%02d" % [int(timer.time_left) / 60, int(timer.time_left) % 60]
	if multiplayer.is_server():
		timer_label.text = "CAPTAIN\n%d:%02d" % [int(timer.time_left) / 60, int(timer.time_left) % 60]

func show_main_menu() -> void:
	main_menu.show()

func hide_main_menu() -> void:
	main_menu.hide()

func get_address_entry() -> String:
	return address_entry.text
