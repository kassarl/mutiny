extends CharacterBody3D
class_name Player

## Movement Constants
const JUMP_VELOCITY: float = 4.5
const BASE_SPEED: float = 4.0
const SPRINT_SPEED: float = 8.0
const MOUSE_SENSITIVITY: float = 0.002
const LERP_SPEED: float = 10.0
const INITIAL_SPAWN_POSITION := Vector3(0, 5.5, 0)

## Camera Rotation Limits (in radians)
const MAX_LOOK_ANGLE: float = deg_to_rad(85)
const MIN_LOOK_ANGLE: float = deg_to_rad(-85)

## Node References
@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head

## Movement Variables
var current_speed: float = BASE_SPEED
var movement_direction: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

#region Lifecycle Methods
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	_initialize_player()

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	_handle_camera_input(event)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_handle_movement(delta)
	_handle_network_sync()
#endregion

#region Initialization
## Sets up initial player state
func _initialize_player() -> void:
	position = INITIAL_SPAWN_POSITION
	
	if not is_multiplayer_authority():
		return
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
#endregion

#region Input Handling
## Handles camera movement from mouse input
## [param event] The input event to process
func _handle_camera_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
		
	# Rotate player (left/right)
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Rotate camera (up/down)
	head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	head.rotation.x = clamp(head.rotation.x, MIN_LOOK_ANGLE, MAX_LOOK_ANGLE)
#endregion

#region Movement
## Handles all movement-related updates
## [param delta] Time since last frame
func _handle_movement(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_sprint()
	_update_velocity(delta)
	
	move_and_slide()

## Applies gravity to the player
## [param delta] Time since last frame
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

## Handles jump input
func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

## Handles sprint input and speed changes
func _handle_sprint() -> void:
	current_speed = SPRINT_SPEED if Input.is_action_pressed("sprint") and is_on_floor() else BASE_SPEED

## Updates velocity based on input
## [param delta] Time since last frame
func _update_velocity(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	movement_direction = lerp(
		movement_direction,
		(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
		delta * LERP_SPEED
	)
	
	if movement_direction:
		velocity.x = movement_direction.x * current_speed
		velocity.z = movement_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Handle quit action
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()
#endregion

#region Networking
## Syncs player position and rotation across the network
func _handle_network_sync() -> void:
	rpc("sync_position", position, rotation)

## Updates position and rotation on all clients
## [param new_position] The position to sync to
## [param new_rotation] The rotation to sync to
@rpc("any_peer", "unreliable")
func sync_position(new_position: Vector3, new_rotation: Vector3) -> void:
	position = new_position
	rotation = new_rotation
#endregion
