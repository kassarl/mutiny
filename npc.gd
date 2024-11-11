extends CharacterBody3D
class_name NPC

## Movement Configuration
@export_group("Movement Settings")
@export var movement_speed: float = 5.0
@export var movement_target_threshold: float = 0.1

## Node References
@onready var nav_map: NavigationRegion3D = $"../Ship/NavigationRegion3D"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer

## LLM Client
@export var openai_client: Node

## Navigation Variables
var available_points: Array[Vector3] = []
var next_location = null

# Interact Variables
var prompt = null
var paused = false
var resume_timer = null

#region Lifecycle Methods
func _ready() -> void:
	_initialize_timer()
	_initialize_navigation()
	prompt = "Press E to start conversation"

func _physics_process(_delta: float) -> void:
	if not paused:
		_handle_movement()
#endregion

#region Initialization
## Sets up the timer for destination changes
func _initialize_timer() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(on_wait_timer_timeout)  # Connect timeout signal
	
	resume_timer = Timer.new()
	resume_timer.one_shot = true
	add_child(resume_timer)

## Initializes navigation points and starting position
func _initialize_navigation() -> void:
	next_location =  nav_map.generate_random_points(1)[0]
	nav_agent.set_target_position(next_location)
	print("initial target is: ", next_location)
#endregion

#region Movement
## Handles NPC movement using NavigationAgent
func _handle_movement() -> void:
	if nav_agent.is_navigation_finished():
		if timer.is_stopped():  # Only start timer if it's not already running
			timer.wait_time = randf_range(0.5, 3.0)
			timer.start()
			print("Starting Timer for %f" % timer.wait_time)
		return
	
	var next_position := nav_agent.get_next_path_position()
	var direction := (next_position - global_position).normalized()
	
	velocity = direction * movement_speed
	velocity = velocity.move_toward(velocity, 25)
	
	move_and_slide()

## Timer timeout handler - sets new destination
func on_wait_timer_timeout() -> void:
	next_location = nav_map.gen_rand_pt_dist_away(position, randi_range(5, 20))
	nav_agent.set_target_position(next_location)
	print("Next location is")
	print(next_location)

## Pause movement
func pause_movement():
	print("Pausing NPC")
	paused = true
	velocity = Vector3.ZERO
	timer.paused = true  # Pause the wait timer when NPC is paused	

## Resume movement
func resume_movement():
	print("Resuming NPC")
	paused = false
	nav_agent.get_next_path_position()
#endregion

#region Interaction
func get_prompt():
	return prompt

func interact():
	print("Interacted with %s" % name)
	
	if not paused:
		pause_movement()
		prompt = "Press E to leave this conversation"
		print("Talked to NPC")
		#openai_client.send_message("Hi are you an npc?")
	else:
		resume_timer.wait_time = randf_range(0.0, 2)
		resume_timer.timeout.connect(resume_movement)
		resume_timer.start()
		prompt = "Press E to start conversation"
#endregion
