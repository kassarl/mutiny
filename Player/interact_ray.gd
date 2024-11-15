extends RayCast3D

@onready var prompt = $Prompt
@onready var player = $"../../../../.."
@onready var camera: Camera3D = %"Camera3D"
var interactable

func _ready() -> void:
	add_exception(owner)
	prompt.text = ""

func _process(_delta: float) -> void:
	# Only process interaction for the player we control
	if not player.is_multiplayer_authority():
		return
	handle_interaction()

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
		# For NPC interactions (including player NPCs)
		if collider.is_in_group("npc"):
			if player.is_in_group("captain"):
				interactable = collider
				prompt.text = collider.get_prompt()
			else:
				reset_interaction_state()
		else:
			# For non-NPC interactables
			interactable = collider
			prompt.text = collider.get_prompt()
	else:
		reset_interaction_state()

func reset_interaction_state() -> void:
	prompt.text = ""
	interactable = null

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
#extends RayCast3D
#
#@onready var prompt = $Prompt
#@onready var player = $"../../../../.."
#@onready var camera: Camera3D = %"Camera3D"
#
#var interactable
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#add_exception(owner)
	#prompt.text = ""
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if is_colliding() and get_collider().is_in_group("interactable"):
		#interactable = get_collider()
		#if interactable and interactable.has_method("interact"):
			#print("interactable")
			#print(interactable)
			## Make NPC prompt invisible if you are an imposter
			#if player.is_in_group("npc") and interactable.is_in_group("npc"):
				#print("EEE")
				#interactable = null
				#prompt.text = ""
			#else:
				#print("CCC")
				#prompt.text = interactable.get_prompt()
	#else:
		#prompt.text = ""
		#interactable = null
#
#func call_interact():
	#print(player.get_groups())
	#if interactable != null and interactable.has_method("interact"):
		#interactable.interact()
