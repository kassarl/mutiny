extends RayCast3D

@onready var prompt = $Prompt
@onready var player: CharacterBody3D = $"../../../../.."
@onready var camera: Camera3D = $"Camera3D"

var interactable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_exception(owner)
	prompt.text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_colliding():
		interactable = get_collider()
		if interactable and interactable.has_method("interact"):
			#print(interactable)
			prompt.text = interactable.get_prompt()
	else:
		prompt.text = ""
		

func call_interact():
	if interactable != null and interactable.has_method("interact"):
		interactable.interact()
