extends Control


const INDICATOR: PackedScene = preload("res://ControlNodes/Map/Indicator.tscn")

var mapSize: Vector2 = Vector2(10, 10) # in terms of number of partitions
var partSize: float
var data: Dictionary
var container: ReferenceRect


# Called when the node enters the scene tree for the first time.
func _ready():
	var terminal = get_tree().get_root().get_node("GameWorld")
	partSize = terminal.get("PARTSIZE")
	data = terminal.get("data")
	container = get_node("Container")

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# pause, a menu may be added later on
	if Input.is_action_just_pressed("ui_cancel"):
		visible = !visible
	for child in container.get_children():
		child.queue_free()
	for key in data.keys():
		var unit = data[key]
		var type = unit.get("type")
		if type == null:
			continue
		var location = unit["xform"].origin
		container.rect_size.x = container.rect_size.y
		container.margin_left = container.rect_size.x * -0.5
		container.margin_right = container.rect_size.x * 0.5
		var inRectPartSize = container.rect_size / mapSize
		var projected = inRectPartSize * Vector2(location.x, location.z) / partSize
		var indicator: Polygon2D = INDICATOR.instance()
		if type != "trading":
			indicator.rotate(PI * 0.5)
		var side = unit["side"]
		if side == "spanish":
			indicator.color = Color.yellow
		elif side == "french":
			indicator.color = Color.blue
		container.add_child(indicator)
		indicator.position = projected
