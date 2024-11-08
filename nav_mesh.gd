# Place this script on your NavigationRegion3D node
extends NavigationRegion3D

# JANK NOTES:
# Had to do some jank shit where nav mesh was being elevated OVER the real 
# mesh so characters were "float walking" instead of walking on surface
# "FIX" was to offset real mesh up to match the floating nav mesh...

# Function to get random points on the navigation mesh
func generate_random_points(num_points, min_distance: float = 2.0) -> Array[Vector3]:
	var points: Array[Vector3] = []
	
	# Get the navigation map
	var nav_map = get_world_3d().get_navigation_map()
	
	# Get the mesh vertices to determine bounds
	var vertices = navigation_mesh.get_vertices()
	
	if vertices.is_empty():
		return points
	
	# Calculate bounds from vertices
	var min_bounds = vertices[0]
	var max_bounds = vertices[0]
	
	for vertex in vertices:
		min_bounds.x = min(min_bounds.x, vertex.x)
		min_bounds.y = min(min_bounds.y, vertex.y)
		min_bounds.z = min(min_bounds.z, vertex.z)
		max_bounds.x = max(max_bounds.x, vertex.x)
		max_bounds.y = max(max_bounds.y, vertex.y)
		max_bounds.z = max(max_bounds.z, vertex.z)
	
	var tries = 0
	var max_tries = 100  # Prevent infinite loops
	
	while points.size() < num_points and tries < max_tries:
		# Generate a random point within the bounds
		var random_point = Vector3(
			randf_range(min_bounds.x, max_bounds.x),
			6.664,
			randf_range(min_bounds.z, max_bounds.z)
		)
		
		# Get closest point on navigation mesh
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, random_point)
		
		# Check if point is far enough from other points
		var is_point_valid = true
		for existing_point in points:
			if existing_point.distance_to(closest_point) < min_distance:
				is_point_valid = false
				break
		
		if is_point_valid:
			points.append(random_point)
		
		tries += 1
	
	return points
