extends CharacterBody3D
class_name Player

#region Configuration Variables
# Camera Settings
@export var look_sensitivity : float = 0.002

# Movement Settings
@export var jump_velocity := 6.5
@export var auto_bhop := true

# Ground Movement
@export var walk_speed := 5.5
@export var sprint_speed := 7.0
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Air Movement
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0
#endregion

#region Constants
const INITIAL_SPAWN_POSITION := Vector3(0, 5.5, 0)
const CROUCH_TRANSLATE = 0.75
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9
const MAX_STEP_HEIGHT = 0.5
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
#endregion

#region State Variables
# Movement State
var wish_dir := Vector3.ZERO
var is_crouched := false
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF
var _saved_camera_global_pos = null
var headbob_time := 0.0

# Multiplayer State
var is_my_cam := false
@export var is_captain = false
var is_initialized = false
var is_chatting = false
var is_chat_turn

# Interaction State
var prompt = ""
#endregion

#region Node References
@onready var raycast: RayCast3D = $HeadOG/Head/CameraSmooth/Camera3D/RayCast3D
@onready var model = %WorldModel
@onready var game_manager = $"../GameManager"
@onready var _original_capsule_height = $Collider.shape.height
@onready var captain_hat: MeshInstance3D = $Collider/WorldModel/CaptainHat
@onready var text_mesh: Label3D = $Collider/WorldModel/TextMesh
@onready var jail_area: Area3D = $"../Ship/Jail/Area3D"
@onready var chat_hud: Control = $ChatHUD

# Preload the Pause Menu scene
var pause_menu_instance: CanvasLayer
#endregion

#region Lifecycle Methods
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	
	var pause_menu_scene: PackedScene = preload("res://Environment/PauseMenu.tscn")
	pause_menu_instance  = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.visible = false
	pause_menu_instance.get_node("PausePanel").visible = true
	
	is_my_cam = is_multiplayer_authority()
	
	captain_hat.visible = false
	
	if is_my_cam:
		set_model_visible(false)
	else:
		set_model_visible(true)
	
	_initialize_player()

func _initialize_player() -> void:
	position = INITIAL_SPAWN_POSITION
	
	#print("ARE WE SERVER")
	#print(multiplayer.is_server())
	#print("ARE WE CAPTAIN?")
	#print(is_captain)
	
	if multiplayer.is_server() and !game_manager.captain_set:
		#print("WE ARE SERVER AND NOT CAPTAIN YET")
		is_captain = true
		game_manager.captain_set = true
		add_to_group("captain")
		captain_hat.visible = true
		text_mesh.text = "CAPTAIN"
	else:
		#print("WE ARE NOT SERVER OR THE CAPTAIN HAS ALREADY BEEN DEFINED")
		if is_captain:
			#print("WE ARE CAPTAIN THOUGH REMOTELY")
			add_to_group("captain")
			is_chat_turn = true
			captain_hat.visible = true
			text_mesh.text = "CAPTAIN"
			text_mesh.modulate = Color.RED  # Changes the main text color
			
			
		else:
			#print("WE ARE NOT CAPTAIN THOUGH")
			is_captain = false
			is_chat_turn = false
			add_to_group("interactable")
			add_to_group("npc")
			add_to_group("imposter")
			prompt = "Press E to start conversation\nPress R to jail this NPC"
	
	#print("IS CAPTAIN?")
	#print(is_captain)
	
	if not is_multiplayer_authority():
		return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	%Camera3D.current = true
#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("interact"):
		raycast.call_interact()
	
	if Input.is_action_just_pressed("jail"):
		raycast.call_jail()

func _unhandled_input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
#endregion

#region Physics Processing
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or chat_hud.in_chat:
		return
	if is_on_floor(): 
		_last_frame_was_on_floor = Engine.get_physics_frames()
	
	var input_dir = Input.get_vector("left","right","forward","back").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	_handle_crouch(delta)
	
	if is_on_floor() or _snapped_to_stairs_last_frame:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_just_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
		
	if not _snap_up_stairs_check(delta):
		move_and_slide()
		_snap_down_to_stairs_check() 
	
	_slide_camera_smooth_back_to_origin(delta)
	_handle_network_sync()
#endregion

#region Movement Methods
func get_move_speed() -> float:
	if is_crouched:
		return walk_speed * 0.8
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	_headbob_effect(delta)

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir

func _handle_crouch(delta) -> void:
	var was_crouched_last_frame = is_crouched
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	elif is_crouched and not self.test_move(self.global_transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouched = false
	
	var translate_y_if_possible := 0.0
	if was_crouched_last_frame != is_crouched and not is_on_floor() and not _snapped_to_stairs_last_frame:
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
	
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.global_transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		%Head.position.y -= result.get_travel().y
		%Head.position.y = clamp(%Head.position.y, -CROUCH_TRANSLATE, 0)
	
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouched else 0, 7.0 * delta)
	%Collider.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height
	%Collider.position.y = $Collider.shape.height / 2
#endregion

#region Camera Effects
func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length() 
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %CameraSmooth.global_position

func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	%CameraSmooth.global_position.y = _saved_camera_global_pos.y
	%CameraSmooth.position.y = clamp(%CameraSmooth.position.y, -0.7, 0.7)
	var move_amount = max(self.velocity.length() * delta, walk_speed/2 * delta)
	%CameraSmooth.position.y = move_toward(%CameraSmooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %CameraSmooth.global_position
	if %CameraSmooth.position.y == 0:
		_saved_camera_global_pos = null
#endregion

#region Stair Movement
func _snap_down_to_stairs_check() -> void:
	var did_snap = false
	var floor_below : bool = %StairsBelow.is_colliding() and not is_surface_too_steep(%StairsBelow.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	var expected_move_motion = self.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if (_run_body_test_motion(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT*2, 0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAhead.global_position = down_check_result.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
		%StairsAhead.force_raycast_update()
		if %StairsAhead.is_colliding() and not is_surface_too_steep(%StairsAhead.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false

func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _run_body_test_motion(from : Transform3D, motion : Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionParameters3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)
#endregion

#region Networking
@rpc
func set_model_visible(is_visible: bool):
	model.visible = is_visible

func _handle_network_sync() -> void:
	rpc("sync_position", position, rotation)

@rpc("any_peer", "unreliable")
func sync_position(new_position: Vector3, new_rotation: Vector3) -> void:
	position = new_position
	rotation = new_rotation
#endregion

#region Interaction
func get_prompt():
	return prompt


# Syncs host and clients
@rpc("any_peer")
func jail_npc(NPCpath):
	position = get_random_pt_in_jail(jail_area)

@rpc("any_peer")
func start_npc_chat(chat_path: NodePath):
	if not chat_hud.in_chat:
		# Prevent the 'E' key from being captured in the line_edit
		await get_tree().process_frame
		chat_hud.set_chat_state(true)

@rpc("any_peer")
func start_player_chat(other_player_path: NodePath):
	print(name)
	if is_captain:
		print("Captain is talking to ", other_player_path)
	else:
		print("Imposter is talking to ", other_player_path)
		prompt = "Press ESC to leave conversation"
	
	print("Toggling HUD")
	chat_hud.toggleHUD()
	
	if not is_multiplayer_authority():
		return
		
	var other_player = get_node(other_player_path)
	#print("Other"other_player)

@rpc("any_peer")
func interact(path):
	#print("PATH")
	#print(path)
	#if multiplayer.is_server():
		#print("IS SERVER")
	#else:
		#print("IS CLIENT")
	print("Interacted with player")
	

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
