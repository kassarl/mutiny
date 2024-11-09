extends NavigationRegion3D
class_name CustomNavigationRegion

## Configuration Constants
const DEFAULT_MIN_DISTANCE: float = 2.0
const MAX_GENERATION_ATTEMPTS: int = 100
#const NAVIGATION_HEIGHT: float = 6.664  # Fixed height for navigation points

## Debug Options
@export_group("Debug Settings")
@export var debug_draw_points: bool = false
@export var debug_draw_bounds: bool = false
@export var debug_point_color: Color = Color.GREEN
@export var debug_bounds_color: Color = Color.RED

#region Point Generation
## Generates random valid navigation points
## [param num_points] Number of points to generate
## [param min_distance] Minimum distance between points
## Returns: Array of valid Vector3 positions on the navigation mesh
func generate_random_points(num_points: int, min_distance: float = DEFAULT_MIN_DISTANCE) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var vertices = navigation_mesh.get_vertices()
	
	if vertices.is_empty():
		push_warning("Navigation mesh has no vertices!")
		return points
		
	# Calculate bounds from vertices
	var min_bounds = Vector3(1000,1000,1000)
	var max_bounds = Vector3(-1000,-1000,-1000)
	
	# Get the actual bounds of the mesh
	for vertex in vertices:
		min_bounds.x = min(min_bounds.x, vertex.x)
		min_bounds.z = min(min_bounds.z, vertex.z)
		max_bounds.x = max(max_bounds.x, vertex.x)
		max_bounds.z = max(max_bounds.z, vertex.z)
	
	var nav_map = get_world_3d().get_navigation_map()
	var attempts = 0
	
	while points.size() < num_points and attempts < MAX_GENERATION_ATTEMPTS:
		# Generate random X and Z coordinates within bounds
		var random_point = Vector3(
			randf_range(min_bounds.x, max_bounds.x),
			randf_range(min_bounds.y, max_bounds.y),
			randf_range(min_bounds.z, max_bounds.z)
		)
		
		# Get the closest point on the navigation mesh
		var nav_point = NavigationServer3D.map_get_closest_point(nav_map, random_point)
		
		# Check if point is far enough from other points
		var valid_point = true
		for existing_point in points:
			if nav_point.distance_to(existing_point) < min_distance:
				valid_point = false
				break
		
		if valid_point:
			points.append(nav_point)
		
		attempts += 1
	
	if attempts >= MAX_GENERATION_ATTEMPTS:
		push_warning("Hit maximum attempts while generating navigation points")
	
	return points
#endregion

#region Helper Functions
## Calculates the bounds of the navigation mesh
## Returns: Dictionary containing min and max bounds
func _calculate_navigation_bounds() -> Dictionary:
	var vertices := navigation_mesh.get_vertices()
	
	if vertices.is_empty():
		return {}
	
	var min_bounds := vertices[0]
	var max_bounds := vertices[0]
	
	for vertex in vertices:
		min_bounds.x = min(min_bounds.x, vertex.x)
		min_bounds.y = min(min_bounds.y, vertex.y)
		min_bounds.z = min(min_bounds.z, vertex.z)
		max_bounds.x = max(max_bounds.x, vertex.x)
		max_bounds.y = max(max_bounds.y, vertex.y)
		max_bounds.z = max(max_bounds.z, vertex.z)
	
	return {
		"min": min_bounds,
		"max": max_bounds
	}

## Checks if the navigation mesh is valid
## [param bounds] The calculated navigation bounds
## Returns: true if navigation mesh is valid
func _is_navigation_valid(bounds: Dictionary) -> bool:
	return !bounds.is_empty() and navigation_mesh != null

## Generates the specified number of valid navigation points
## [param num_points] Number of points to generate
## [param min_distance] Minimum distance between points
## [param bounds] The calculated navigation bounds
## Returns: Array of valid Vector3 positions
func _generate_points(num_points: int, min_distance: float, bounds: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var attempts := 0
	var nav_map := get_world_3d().get_navigation_map()
	
	while points.size() < num_points and attempts < MAX_GENERATION_ATTEMPTS:
		var candidate_point := _generate_random_point(bounds)
		var closest_point := NavigationServer3D.map_get_closest_point(nav_map, candidate_point)
		
		if _is_point_valid(closest_point, points, min_distance):
			points.append(candidate_point)
		
		attempts += 1
	
	if attempts >= MAX_GENERATION_ATTEMPTS:
		push_warning("Hit maximum attempts while generating navigation points")
	
	return points

## Generates a random point within the navigation bounds
## [param bounds] The calculated navigation bounds
## Returns: A random Vector3 position
func _generate_random_point(bounds: Dictionary) -> Vector3:
	return Vector3(
		randf_range(bounds.min.x, bounds.max.x),
		randf_range(bounds.min.y, bounds.max.y),
		randf_range(bounds.min.z, bounds.max.z)
	)

## Checks if a point is valid (far enough from other points)
## [param point] The point to check
## [param existing_points] Already generated points
## [param min_distance] Minimum required distance
## Returns: true if point is valid
func _is_point_valid(point: Vector3, existing_points: Array[Vector3], min_distance: float) -> bool:
	for existing_point in existing_points:
		if existing_point.distance_to(point) < min_distance:
			return false
	return true
#endregion
