extends RayCast3D

#region Node References
@onready var prompt = $Prompt
@onready var player = $"../../../../.."
@onready var camera: Camera3D = %"Camera3D"
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
	
	if not can_interact():
		return
	
	interactable.interact()

func can_interact() -> bool:
	if not interactable or not interactable.has_method("interact"):
		return false
	
	# If interacting with an NPC, only captain can interact
	if interactable.is_in_group("npc") and not player.is_in_group("captain"):
		return false
	
	# Both roles can interact with general interactables
	return true
#endregion
