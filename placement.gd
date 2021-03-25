extends Node


# Declare member variables here.
var tile = 1
export var path: NodePath # this is the path to floor body which you want to place stuff on
var target = null
var highlight = null
var selected = null
var parent = null
var coords = null
var angle = 0.0
var rot = 0.0
var size = Vector3.ONE # in terms of tile size given above, each component must be an integer
var rotSize = Vector3.ONE
export var extra = -0.45 # height offset for three dimensional sprites and such
export var switch: bool = true


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	target = get_node_or_null(path)
	if switch != true || target == null:
		if highlight != null:
			var sprite = highlight.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
		return
	var viewport: Viewport = get_viewport()
	var camera: Camera = viewport.get_camera()
	var spaceState: PhysicsDirectSpaceState = camera.get_world().direct_space_state
	var cursor = viewport.get_mouse_position()
	var hit: Dictionary
	var from = camera.project_ray_origin(cursor)
	var toward = camera.project_ray_normal(cursor)
	var upward = target.global_transform.basis.y.normalized()
	var intersection = Plane(upward, target.global_transform.origin.length()).intersects_ray(from, toward)
	if intersection != null:
		hit = spaceState.intersect_ray(from, intersection, [selected], 0b1)
	var newHighlight = null
	if selected != null:
		if Input.is_action_just_pressed("ui_left"):
			rot += PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		elif Input.is_action_just_pressed("ui_right"):
			rot -= PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		var canPlace = false
		if !hit.empty() && hit.collider == target:
			var offset = Vector3(fmod(rotSize.x, 2), 0, fmod(rotSize.z, 2)) * tile * 0.5 + tile * Vector3.UP * (size.y + extra)
			var partition: Vector3 = (target.global_transform.xform_inv(hit.position) / tile).floor()
			selected.global_transform.origin = target.global_transform.xform(partition + offset)
			selected.global_transform.basis = target.global_transform.basis.rotated(upward, angle + rot)
			var downward = -selected.global_transform.basis.y.normalized() * (size.y * tile * 0.5 + tile * 0.05)
			var backward = selected.global_transform.basis.z.normalized() * (size.z * 0.5 * tile - 0.05 * tile)
			var leftward = selected.global_transform.basis.x.normalized() * (size.x * 0.5 * tile - 0.05 * tile)
			var originOfRay = selected.global_transform.origin - leftward
			hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [selected], 0b1)
			if !hit.empty() && hit.collider == target:
				originOfRay = selected.global_transform.origin - backward
				hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [selected], 0b1)
				if !hit.empty() && hit.collider == target:
					originOfRay = selected.global_transform.origin + leftward
					hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [selected], 0b1)
					if !hit.empty() && hit.collider == target:
						originOfRay = selected.global_transform.origin + backward
						hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [selected], 0b1)
						if !hit.empty() && hit.collider == target:
							var coll = selected.move_and_collide(Vector3(0.0,0,0), false,false,true)
							print(coll.collider_id)
							if !coll || coll.collider == target:
								canPlace = true
		if Input.is_action_just_pressed("ui_cancel"):
			if parent != null:
				placeOrDestroy()
		elif canPlace:
			var sprite = selected.get_node("Sprite3D")
			sprite.modulate = Color(0.0, 1.0, 0.0, 0.5)
			if Input.is_action_just_pressed("ui_accept"):
				parent = target
				coords = selected.global_transform.origin -  parent.global_transform.origin
				angle = angle + rot
				placeOrDestroy()
		else:
			var sprite = selected.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 0.0, 0.0, 0.5)
	else:
		if !hit.empty():
			var temp = hit.collider.get_parent()
			if temp != null && temp == target:
				if Input.is_action_just_pressed("ui_accept"):
					selected = hit.collider
					parent = temp
					coords = selected.global_transform.origin - parent.global_transform.origin
					angle = -signedAngle(parent.global_transform.basis.x.normalized(), selected.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
					setSize()
					rot = 0.0
				else:
					newHighlight = hit.collider
	if highlight != null:
		var sprite = highlight.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		highlight = null
	if newHighlight != null:
		highlight = newHighlight
	if highlight != null:
		var sprite = highlight.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 0.0, 1.0)


# Sets an external body as the selected node to be placed. May be useful at store/market.
func selectOther(thing: KinematicBody):
	selected = thing
	parent = null
	coords = null
	angle = 0.0
	var sprite: Sprite3D = selected.get_node("Sprite3D")
	var dimensions: Vector2 = sprite.texture.get_size() / 64.0
	size = Vector3(dimensions.x, 1.0, dimensions.y)
	selected.global_transform.basis = target.global_transform.basis
	rotSize = size
	rot = 0.0


# Places an object, or destroys is if no parent is available.
func placeOrDestroy():
	if parent != null: # if there is no parent, it'll be destroyed
		if selected.get_parent() != parent:
			parent.add_child(selected)
		selected.global_transform.origin = coords + parent.global_transform.origin
		selected.global_transform.basis = parent.global_transform.basis.rotated(parent.global_transform.basis.y.normalized(), angle)
		var sprite = selected.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		selected.queue_free()
	selected = null
	parent = null
	coords = null
	angle = null
	size = null
	rot = null
	rotSize = null


# Sets size and rotated size for the selected item.
func setSize():
	var sprite: Sprite3D = selected.get_node("Sprite3D")
	var dimensions: Vector2 = sprite.texture.get_size() / 64.0
	size = Vector3(dimensions.x, 1.0, dimensions.y)
	var temp = -signedAngle(parent.global_transform.basis.x.normalized(), selected.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
	dimensions = dimensions.rotated(temp).round().abs()
	rotSize = Vector3(dimensions.x, 1.0, dimensions.y)
	print(rotSize)


# Returns signed angle between two three dimensional vectors.
func signedAngle(from: Vector3, to: Vector3, up: Vector3):
	return atan2(to.cross(from).dot(up), from.dot(to))
