extends CharacterBody3D
class_name NPC

## Movement Configuration
@export_group("Movement Settings")
@export var movement_speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var movement_target_threshold: float = 0.1

## Node References
@onready var nav_map: NavigationRegion3D = $"../Ship/NavigationRegion3D"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer: Timer

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
	initialize_timer()
	initialize_navigation()
	prompt = "Press E to start conversation"

func _physics_process(_delta: float) -> void:
	if not paused:
		handle_movement(_delta)
#endregion

#region Initialization
## Sets up the timer for destination changes
func initialize_timer() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(on_wait_timer_timeout)
	
	resume_timer = Timer.new()
	resume_timer.one_shot = true
	add_child(resume_timer)

## Initializes navigation points and starting position
func initialize_navigation() -> void:
	next_location = nav_map.generate_random_points(1)[0]
	nav_agent.set_target_position(next_location)
	#print("initial target is: ", next_location)
#endregion

var target_rotation := 0.0
#region Movement
## Handles NPC movement using NavigationAgent
func handle_movement(delta) -> void:
	if nav_agent.is_navigation_finished():
		#print("WAITING")
		if timer.is_stopped():  # Only start timer if it's not already running
			timer.wait_time = randf_range(0.5, 3.0)
			timer.start()
			#print("Starting Timer for %f" % timer.wait_time)
		return
	
	var next_position := nav_agent.get_next_path_position()
	var direction := (next_position - global_position).normalized()
	
	direction.y = 0

	velocity = direction * movement_speed

	if direction.length() > 0.1:# Get the target rotation in radians
		var new_target_rotation = direction.angle_to(Vector3.FORWARD)

		# Use lerp_angle to smoothly rotate from the current rotation to the target rotation
		var target_rotation = lerp_angle(target_rotation, new_target_rotation, rotation_speed * delta)

		var target_position = global_position + direction
		look_at(target_position, Vector3.UP)
	# Ensure the NPC stays grounded (testing with a small downward force)
	if is_on_floor():
		move_and_slide()
	else:
		# Apply a small downward velocity if not on the floor, to keep the NPC grounded
		velocity.y = -1  # Force a small downward velocity to avoid floating
		move_and_slide()

## Timer timeout handler - sets new destination
func on_wait_timer_timeout() -> void:
	next_location = nav_map.gen_rand_pt_dist_away(position, randi_range(5, 20))
	nav_agent.set_target_position(next_location)
	#print("Next location is: ", next_location)

## Pause movement
func pause_movement():
	#print("Pausing NPC")
	paused = true
	velocity = Vector3.ZERO
	timer.paused = true  # Pause the wait timer when NPC is paused
	
## Resume movement
func resume_movement():
	#print("Resuming NPC")
	paused = false
	timer.paused = false  # Unpause the timer
	
	# Disconnect the signal to prevent multiple connections
	if resume_timer.timeout.is_connected(resume_movement):
		resume_timer.timeout.disconnect(resume_movement)
	
	# 50% chance to generate new destination
	if randf() > 0.5:
		next_location = nav_map.gen_rand_pt_dist_away(position, randi_range(5, 20))
		nav_agent.set_target_position(next_location)
		print("Generated new destination")
	else:
		print("Keeping original destination")
	
	# Reset timer state
	if timer.is_stopped():
		timer.wait_time = randf_range(0.5, 3.0)
		timer.start()
#endregion

#region Interaction
func get_prompt():
	return prompt

func interact():
	print("Interacted with %s" % name)
	
	if !multiplayer.is_server():
		return
		
	if not paused:
		pause_movement()
		prompt = "Press E to leave this conversation"
		print("Talked to NPC")
		openai_client.send_message("Hi are you an npc?")
	else:
		# Disconnect any existing connections first
		if resume_timer.timeout.is_connected(resume_movement):
			resume_timer.timeout.disconnect(resume_movement)
			
		resume_timer.wait_time = randf_range(0.0, 2)
		resume_timer.timeout.connect(resume_movement)
		resume_timer.start()
		#print("Time to resume movement: ", resume_timer.wait_time)
		prompt = "Press E to start conversation"
#endregion
