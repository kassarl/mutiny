# GameManager.gd
extends Node

@onready var root: GameWorld = $".."
@onready var ui_manager: Node = $"../UIManager"

var in_game = false
var mutiny_index = 0
const GAME_TIME = 300.0  # 5 minutes for example
var captain_set = false

# Syncs host and clients
@rpc("authority", "call_local")
func sync_game_state(current_mutiny: int, remaining_time: float):
	mutiny_index = current_mutiny

	ui_manager.sync_display(current_mutiny, remaining_time)

# For clients to request mutiny changes
@rpc("any_peer")
func request_mutiny_update(requested_change: int) -> void:
	# Only server should process the request
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		print("Received mutiny update request from peer: ", peer_id)
		
		# Here you can add validation if needed
		var new_index = mutiny_index + requested_change
		new_index = clamp(new_index, 0, 100)  # Ensure it stays within bounds
		
		# Update and sync to all clients
		update_mutiny_index(new_index)

# Called by host to update mutiny index
func update_mutiny_index(new_index: int) -> void:
	if multiplayer.is_server():
		print("Server is telling clients to update now")
		mutiny_index = new_index
		# Sync current mutiny and remaining time to all clients and self
		sync_game_state.rpc(
			mutiny_index, 
			ui_manager.timer.time_left
		)
