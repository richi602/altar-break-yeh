class_name RaycastCamera extends Camera3D


func _get_result(ray_length: float) -> Dictionary:
	var point := get_viewport().get_visible_rect().size / 2
	
	var state := get_world_3d().direct_space_state
	var from := project_ray_origin(point)
	var to := from + project_ray_normal(point) * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	
	var result := state.intersect_ray(query)
	
	return result
