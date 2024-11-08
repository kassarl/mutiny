extends CharacterBody3D


@export var movement_speed: float = 5.0
@export var movement_target_threshold: float = 0.1

@onready var nav_map: NavigationRegion3D = $'../Ship/NavigationRegion3D'
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer: Timer = $Timer

# Array of Vector3 positions the NPC can walk to
var available_points: Array[Vector3] = []

func _ready():
	# First, verify the Timer node exists
	if !timer:
		# Create timer if it doesn't exist
		timer = Timer.new()
		add_child(timer)
	
	# Set up timer for point changes
	timer.wait_time = 1.3
	timer.timeout.connect(pick_new_destination)
	timer.start()
	
	# Pick initial rand points from ship
	available_points = nav_map.generate_random_points()
	
	print(available_points)
	
	# Initial destination
	pick_new_destination()

func _physics_process(delta):
	if nav_agent.is_navigation_finished():
		return
		
	# Get next path position
	var next_position: Vector3 = nav_agent.get_next_path_position()
	
	# Calculate movement direction
	var direction = (next_position - global_position).normalized()
	
	# Set velocity
	velocity = direction * movement_speed
	
	# Move the agent
	move_and_slide()

func pick_new_destination():
	print("GOING TO NEW POINT")
	
	if available_points.is_empty():
		return
		
	# Pick a random point from available destinations
	var random_index = randi() % available_points.size()
	var target_position = available_points[random_index]
	print(target_position)
	
	# Set the new target
	nav_agent.set_target_position(target_position)
