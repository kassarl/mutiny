extends CharacterBody3D
class_name NPC

## Movement Configuration
@export_group("Movement Settings")
@export var movement_speed: float = 5.0
@export var movement_target_threshold: float = 0.1
@export var point_change_interval: float = 1.3
@export var num_navigation_points: int = 5

## Node References
@onready var nav_map: NavigationRegion3D = $"../Ship/NavigationRegion3D"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer: Timer = $Timer

## Navigation Variables
var available_points: Array[Vector3] = []

#region Lifecycle Methods
func _ready() -> void:
	_initialize_timer()
	_initialize_navigation()

func _physics_process(_delta: float) -> void:
	_handle_movement()
#endregion

#region Initialization
## Sets up the timer for destination changes
func _initialize_timer() -> void:
	if !timer:
		timer = Timer.new()
		add_child(timer)
	
	timer.wait_time = point_change_interval
	timer.timeout.connect(pick_new_destination)
	timer.start()

## Initializes navigation points and starting position
func _initialize_navigation() -> void:
	# Generate random navigation points
	available_points = nav_map.generate_random_points(num_navigation_points)
	
	# Set initial destination
	pick_new_destination()
#endregion

#region Movement
## Handles NPC movement using NavigationAgent
func _handle_movement() -> void:
	if nav_agent.is_navigation_finished():
		return
	
	var next_position := nav_agent.get_next_path_position()
	var direction := (next_position - global_position).normalized()
	
	velocity = direction * movement_speed
	move_and_slide()

## Selects and sets a new destination from available points
func pick_new_destination() -> void:
	
	if available_points.is_empty():
		return
	
	var random_index := randi() % available_points.size()
	var target_position := available_points[random_index]
	
	nav_agent.set_target_position(target_position)
	
	timer.wait_time = randf_range(1.0, 4.0)
	print(timer.wait_time)
#endregion
