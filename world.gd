extends Node
#class_name GameWorld

## Network and Scene Constants
const PORT: int = 9990
const PLAYER_SCENE: PackedScene = preload("res://player.tscn")
const NPC_SCENE: PackedScene = preload("res://npc.tscn")
const NPC_COUNT: int = 1

## UI References
@onready var main_menu: Control = $CanvasLayer/MainMenu
@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var nav_mesh: NavigationRegion3D = $Ship/NavigationRegion3D

# LLM References
@export var chat_controller: OpenAIClient

## Networking
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

#region Input Handling
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
#endregion

#region Network Management
## Handles server creation and initialization
func _on_host_button_pressed() -> void:
	main_menu.hide()
	
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
	main_menu.hide()
	
	# Create client and connect to server
	var error := enet_peer.create_client(address_entry.text, PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return
		
	multiplayer.multiplayer_peer = enet_peer
	print("Connecting to: ", address_entry.text)

## Sets up network connection signals
func _setup_network_connections() -> void:
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
#endregion

#region Player Management
## Adds a player to the game world
## [param peer_id] The network ID of the player to add
func add_player(peer_id: int) -> void:
	print("Adding player: %d" % peer_id)
	
	var player_instance := PLAYER_SCENE.instantiate()
	player_instance.name = str(peer_id)
	add_child(player_instance)

## Removes a player from the game world
## [param peer_id] The network ID of the player to remove
func remove_player(peer_id: int) -> void:
	print("Removing player: %d" % peer_id)
	
	var player := get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
#endregion

#region UPNP Setup
## Sets up UPNP for internet connectivity
func upnp_setup() -> void:
	var upnp := UPNP.new()
	
	# Try to discover UPNP gateway
	var discover_result := upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, 
		"UPNP Discover Failed! Error %s" % discover_result)
	
	# Verify gateway validity
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), 
		"UPNP Invalid Gateway!")
	
	# Setup port forwarding
	var map_result := upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, 
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Host launch Success! Join IP Address: %s\n" % upnp.query_external_address())
#endregion

#region NPC Management
## Spawns multiple NPCs in the game world
## [param npc_count] The number of NPCs to spawn
func spawn_npcs(npc_count: int) -> void:
	print("Spawning in %d NPC's" % npc_count)
	if !multiplayer.is_server():
		return
		
	var spawn_points = nav_mesh.generate_random_points(npc_count)
	
	for i in range(len(spawn_points)):
		spawn_points[i][1] += .2
	
	for i in range(npc_count):
		spawn_npc.rpc(i, spawn_points[i])

## RPC to spawn a single NPC across all clients
## [param npc_id] Unique identifier for the NPC
## [param spawn_position] World position to spawn the NPC
@rpc("authority", "call_local", "reliable")
func spawn_npc(npc_id: int, spawn_position: Vector3) -> void:
	var npc_instance := NPC_SCENE.instantiate()
	npc_instance.name = str("NPC_", npc_id)
	npc_instance.position = spawn_position
	npc_instance.openai_client = chat_controller
	#print("adding npc at position")
	#print(spawn_position)
	add_child(npc_instance, true)
#endregion


## Initializes the game world
func main() -> void:
	spawn_npcs(NPC_COUNT)
