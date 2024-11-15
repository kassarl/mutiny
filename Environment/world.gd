extends Node
class_name GameWorld

# Manager Nodes
@onready var game_manager: Node = $GameManager
@onready var ui_manager: Node = $UIManager
@onready var audio_manager: Node = $AudioManager
@onready var nav_mesh: NavigationRegion3D = $Ship/NavigationRegion3D

## Game Configs
const PLAYER_SCENE: PackedScene = preload("res://Player/player.tscn")
const NPC_SCENE: PackedScene = preload("res://NPC/npc.tscn")
const NPC_COUNT: int = 5

## LLM
@export var chat_controller: OpenAIClient

## Networking
const PORT: int = 9990
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

#region Network Management
## Handles server creation and initialization
func _on_host_button_pressed() -> void:
	# Handle UI and Audio for hosting game
	audio_manager.stop_stream()
	ui_manager.hide_main_menu()
	
	# Setup server
	var error := enet_peer.create_server(PORT)
	if error != OK:
		print("Failed to create server: ", error)
		return
	
	# Setup networking
	_setup_network_connections()
	
	# Setup UPNP for internet connectivity
	upnp_setup()
	
	# Spawn host player
	add_player(multiplayer.get_unique_id())
	
	# Initialize game
	main()

## Handles client connection to server
func _on_join_button_pressed() -> void:
	# Handle UI and Audio for hosting game
	audio_manager.stop_stream()
	ui_manager.hide_main_menu()
	
	# Create client and connect to server
	var error := enet_peer.create_client(ui_manager.get_address_entry(), PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return
		
	multiplayer.multiplayer_peer = enet_peer
	print("Connecting to: ", ui_manager.get_address_entry())
	
	main()

## Sets up network connection signals
func _setup_network_connections() -> void:
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
#endregion

#region Player Management
func add_player(peer_id: int) -> void:
	print("Adding player: %d" % peer_id)
	
	var player_instance := PLAYER_SCENE.instantiate()
	player_instance.name = str(peer_id)
	
	add_child(player_instance)
	
	# Only sync if we're the server and it's not us
	if multiplayer.is_server() and peer_id != multiplayer.get_unique_id():
		game_manager.sync_game_state.rpc(
			game_manager.mutiny_index,
			ui_manager.timer.time_left
		)

func remove_player(peer_id: int) -> void:
	print("Removing player: %d" % peer_id)
	
	var player := get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
#endregion

#region UPNP Setup
func upnp_setup() -> void:
	var upnp := UPNP.new()
	
	var discover_result := upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, 
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), 
		"UPNP Invalid Gateway!")
	
	var map_result := upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, 
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Host launch Success! Join IP Address: %s\n" % upnp.query_external_address())
#endregion

#region NPC Management
func spawn_npcs(npc_count: int) -> void:
	print("Spawning in %d NPC's" % npc_count)
	if !multiplayer.is_server():
		return
		
	var spawn_points = nav_mesh.generate_random_points(npc_count)
	
	for i in range(len(spawn_points)):
		spawn_points[i][1] += .2
	
	for i in range(npc_count):
		spawn_npc.rpc(i, spawn_points[i])

@rpc("authority", "call_local", "reliable")
func spawn_npc(npc_id: int, spawn_position: Vector3) -> void:
	var npc_instance := NPC_SCENE.instantiate()
	npc_instance.name = str("NPC_", npc_id)
	npc_instance.position = spawn_position
	npc_instance.openai_client = chat_controller
	add_child(npc_instance, true)
#endregion

#region Game Loop
func main() -> void:
	spawn_npcs(NPC_COUNT)
	game_manager.in_game = true
	
	if multiplayer.is_server():
		ui_manager.start_game_ui()
	
	audio_manager.start_ocean_sounds()
#endregion
