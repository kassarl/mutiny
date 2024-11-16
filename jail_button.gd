extends StaticBody3D

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

var prompt
var isOpen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prompt = "Press E to open jail"
	isOpen = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_prompt():
	return prompt

func interact():
	if isOpen:
		anim_player.play('moveDoor')
	else:
		anim_player.play_backwards('moveDoor')
	
	isOpen = !isOpen
