extends RayCast3D

#region Node References
@onready var prompt = $Prompt
@onready var player = $"../../../../.."
@onready var camera: Camera3D = %"Camera3D"
@onready var chat_manager: Control = $"../../../../../ChatHUD"
#endregion

#region State Variables
var interactable
#endregion

#region Lifecycle Methods
func _ready() -> void:
	add_exception(owner)
	prompt.text = ""

func _process(_delta: float) -> void:
	# Only process interaction for the player we control
	if not player.is_multiplayer_authority():
		return
	
	handle_interaction()
#endregion

#region Interaction Logic
func handle_interaction() -> void:
	# Reset interaction state if not colliding
	if not is_colliding():
		reset_interaction_state()
		return
	
	var collider = get_collider()
	#print(collider)
	
	# Debug prints to verify roles
	#print("Collider groups: ", collider.get_groups())
	#print("Player is captain: ", player.is_in_group("captain"))
	#print("Collider is NPC: ", collider.is_in_group("npc"))
	
	# Only proceed if the collider is interactable
	if not collider.is_in_group("interactable"):
		reset_interaction_state()
		return
	
	if collider.has_method("get_prompt"):
		handle_prompt_display(collider)
	else:
		reset_interaction_state()

func handle_prompt_display(collider) -> void:
	# For NPC interactions (including player NPCs)
	if collider.is_in_group("npc"):
		if player.is_in_group("captain"):
			set_interaction_state(collider)
		else:
			reset_interaction_state()
	else:
		# For non-NPC interactables
		set_interaction_state(collider)
#endregion

#region State Management
func set_interaction_state(collider) -> void:
	interactable = collider
	prompt.text = collider.get_prompt()

func reset_interaction_state() -> void:
	prompt.text = ""
	interactable = null
#endregion

#region Interaction Handlers
func call_interact() -> void:
	# Only process interaction for the player we control
	if not player.is_multiplayer_authority():
		return
	
	# We cannot interact with item OR we are in chat
	if not can_interact() or player.chat_hud.in_chat:
		return
	
	if interactable.is_in_group("imposter"):
		chat_with_player()
	elif interactable.is_in_group("npc"):
		chat_with_npc()
	else:
		interactable.interact()

func chat_with_player():
	var peer_id = int(str(interactable.name)) 
	
	# Call the chat initialization on both players
	interactable.start_player_chat.rpc_id(peer_id, player.get_path())
	player.start_player_chat(interactable.get_path())

func chat_with_npc():
	var npc_id = int(str(interactable.name)) 

	# Call the chat initialization on both players
	#interactable.start_player_chat.rpc_id(peer_id, player.get_path())
	interactable.interact(player)
	player.start_npc_chat(interactable)


func can_interact() -> bool:
	if not interactable or not interactable.has_method("interact"):
		return false
	
	# If interacting with an NPC, only captain can interact
	if interactable.is_in_group("npc") and not player.is_in_group("captain"):
		return false
	
	# Both roles can interact with general interactables
	return true
	
func call_jail() -> void:
	# Only process jail for the player we control
	if not player.is_multiplayer_authority():
		return
	
	if not can_interact() or not interactable.is_in_group("npc") or player.chat_hud.in_chat:
		return
	
	print(interactable)
	# You'll need to implement this method in your NPC script
	interactable.jail_npc.rpc(interactable.get_path())

#endregion
