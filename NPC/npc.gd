extends CharacterBody3D
class_name NPC

## Movement Configuration
@export_group("Movement Settings")
@export var movement_speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var movement_target_threshold: float = 0.1

## Node References
@onready var nav_map: NavigationRegion3D = $"../BigShip/NavigationRegion3D"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer: Timer

## LLM Client
@export var openai_client: Node

## Navigation Variables
@onready var jail_area: Area3D = $"../Ship/Jail/Area3D"
var available_points: Array[Vector3] = []
var next_location = null

# Face Player Variables
@export var turn_speed: float = 5.0  # Adjust for faster/slower turning
var target_node: Node3D = null
var is_rotating: bool = false

# Interact Variables
var prompt = null
var paused = false
var resume_timer = null

#region Lifecycle Methods
func _ready() -> void:
	initialize_timer()
	initialize_navigation()
	prompt = "Press E to start conversation\nPress R to jail this NPC"

func _physics_process(_delta: float) -> void:
	if is_rotating and target_node:
		rotate_to_face_target(_delta)
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

# Syncs host and clients
@rpc("authority", "call_local")
func jail_npc(NPCpath):
	print("In NPC JAIL")
	position = get_random_pt_in_jail(jail_area)
	print("Position is")
	print(position)
	velocity = Vector3.ZERO
	
	# Make the agent stay still by setting its target to its new position
	nav_agent.target_position = position
	
	# Optional: disable navigation temporarily
	nav_agent.set_velocity(Vector3.ZERO)
	
	timer.paused = true
	paused = true

func interact(player):
	print("Interacted with %s" % name)
	
	if !multiplayer.is_server():
		return
		
	if not paused:
		pause_movement()
		start_facing_target(player)
		prompt = "Press ESC twice to leave this conversation"
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
		prompt = "Press E to start conversation\nPress R to jail this NPC"
#endregion

#region Helper Function
func get_random_pt_in_jail(area: Area3D) -> Vector3:
	var collision_shape = area.get_node("CollisionShape3D")  # Adjust path if needed
	var shape = collision_shape.shape as BoxShape3D
	
	# Get the box extents (half-size)
	var extents = shape.size / 2
	
	# Generate random point within the box
	var random_point = Vector3(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y),
		randf_range(-extents.z, extents.z)
	)
	
	# Add the area's global position to get the final world position
	return random_point + collision_shape.global_position
#endregion

#region Face Player
func start_facing_target(new_target: Node3D) -> void:
	target_node = new_target
	is_rotating = true

func rotate_to_face_target(delta: float) -> void:
	# Get direction to target
	var direction = target_node.global_position - global_position
	
	# Calculate target rotation
	var target_transform = transform.looking_at(target_node.global_position, Vector3.UP)
	var target_basis = target_transform.basis
	
	# Smoothly interpolate rotation
	transform.basis = transform.basis.slerp(target_basis, turn_speed * delta)
	
	# Optional: Check if we're close enough to target rotation to stop
	if transform.basis.is_equal_approx(target_basis):
		is_rotating = false
#endregion
