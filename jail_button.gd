extends StaticBody3D

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@export var doorOpen: bool

var prompt

func _ready() -> void:
	prompt = "Press E to open jail"
	doorOpen = false

func _process(delta: float) -> void:
	pass

# For clients to request jail door state change
@rpc("any_peer")
func request_door_state_change() -> void:
	# Only server should process the request
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		print("Received door update request from peer: ", peer_id)
		
		# Update and sync to all clients
		sync_door_state.rpc(!doorOpen)  # Toggle the current state

# Syncs host and clients
@rpc("authority", "call_local")
func sync_door_state(newState: bool):
	
	if doorOpen:
		anim_player.play('moveDoor')
	else:
		anim_player.play_backwards('moveDoor')
	
	
	doorOpen = newState  # Set the state after playing animation

func get_prompt():
	return prompt

func interact():
	if multiplayer.is_server():
		print("Calling door sync to clients")
		print("Is door open?")
		print(doorOpen)
		print("Syncing to clients:")
		# Server directly syncs the new state
		sync_door_state.rpc(!doorOpen)
	else:
		# Clients request a state change
		request_door_state_change.rpc()
