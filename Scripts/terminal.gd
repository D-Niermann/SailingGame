extends Control


enum modes {PLAY, LOAD = -1}
var mode: int = modes.PLAY
var time: int = 0
var frac: float = 0.0
var updatePeriodForEconomy: float = 60.0

const PARTSIZE: float = 64.0
const EXTENDED: bool = false
const CANCROSS: bool = true
var viewport: Viewport = null
var camera: Camera = null
var walls: Dictionary = {}
var units: Dictionary = {}
var items: Dictionary = {Vector3(0, 0, 0): ["example"]}
var live: Dictionary = {}
var data: Dictionary = {"example": {"preset": "example", "xform": Transform.IDENTITY}}
var map: Dictionary = {}
var image: Image = Image.new()
var picked: Dictionary = {}
var colors: Dictionary = {"0234": {"res": "res://SceneNodes/Islands/Island_Small.tscn", "origin": Vector3(0, 0, 0)}}
var presets: Dictionary = { # constants are not copied over the instance
	"example": {"TYPE": "item", "RES": "res://exampleItem.tscn", "MAXHP": 100, "health": 100}
}


# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_node("ViewportContainer/Viewport")
	camera = viewport.get_node("Camera")
	image.load("res://icon.png")
	Utility.matrix = image


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# pause, a menu may be added later on
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
	# advancing time
	if !get_tree().paused:
		frac += delta
	if frac > 1.0:
		frac -= 1.0
		var newTime: int = time + 1
		if floor(newTime / updatePeriodForEconomy) > floor(time / updatePeriodForEconomy):
			# fluctuating prices
			Economy.cycle()
			var shopping = get_tree().get_root().get_node_or_null("Terminal/Interface/Shopping")
			if shopping.open != null:
				shopping.updateList()
		time = newTime
	# loading world
	var current: Vector3 = Utility.partitionID(camera.global_transform.origin, PARTSIZE, EXTENDED)
	var adjacent: Array = Utility.findAdjacent(current, CANCROSS, EXTENDED)
	adjacent.append(current)
	var copy: Dictionary = live.duplicate()
	for part in adjacent:
		if !live.has(part):
			insertPart(part)
			live[part] = null
			copy.erase(part)
	for part in copy.keys():
		if Utility.chebyshevDistance(current, part) > 2:
			removePart(part)
			live.erase(part)
			copy.erase(part)
	# loading image
	if image != null:
		image.lock()
		var codes: Dictionary = {}
		for part in live.keys():
			var pixel: Color = image.get_pixel(fmod(abs(part.x), image.get_width()), fmod(abs(part.z), image.get_height()))
			var code: String = str(stepify(pixel.r, 0.1) * 10) + str(stepify(pixel.g, 0.1) * 10) + str(stepify(pixel.b, 0.1) * 10)
			if pixel != Color.black && !picked.has(code):
				if !colors.has(code):
					continue
				var island = load(colors[code]["res"]).instance()
				viewport.add_child(island)
				island.global_transform.origin = colors[code]["origin"]
				picked[code] = island
			codes[code] = null
		image.unlock()
		for code in picked.keys():
			if !codes.has(code):
				picked[code].queue_free()
				picked.erase(code)
	# running behavior
	for part in units.keys():
		adjacent = Utility.findAdjacent(part, CANCROSS, EXTENDED)
		adjacent.append(part)
		# can find list of all possibly detected units and items later in here
		for unit in part:
			var holo = null
			var info: Dictionary = data[unit]
			var preset: Dictionary = presets[info["preset"]]
			if live.has(part):
				holo = viewport.get_node_or_null(unit)
			pass # run specific behavior
			# maintaining consistency
			info["xform"] = info["xform"] # update transform
			var newPart = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED)
			if newPart != part:
				part.erase(unit)
				if part.empty():
					units.erase(part)
				if !units.has(newPart):
					units[newPart] = []
				units[newPart].append(unit)
			if live.has(newPart):
				if holo == null:
					holo = load(preset["RES"]).instance()
					viewport.add_child(holo)
					holo.name = unit
					holo.global_transform = info["xform"]
			elif holo != null:
				holo.queue_free()


# Loads the given part of the world.
func insertPart(part):
	if walls.has(part):
		for wall in walls[part]:
			var info: Dictionary = data[wall]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = wall
			holo.global_transform = info["xform"]
	if units.has(part):
		for unit in units[part]:
			var info: Dictionary = data[unit]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = unit
			holo.global_transform = info["xform"]
	if items.has(part):
		for item in items[part]:
			var info: Dictionary = data[item]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = item
			holo.global_transform = info["xform"]


# Unloads the given part of the world.
func removePart(part):
	if walls.has(part):
		for wall in walls[part]:
			var holo = viewport.get_node_or_null(wall)
			if holo != null:
				holo.queue_free()
	if units.has(part):
		for unit in units[part]:
			var holo = viewport.get_node_or_null(unit)
			if holo != null:
				holo.queue_free()
	if items.has(part):
		for item in items[part]:
			var holo = viewport.get_node_or_null(item)
			if holo != null:
				holo.queue_free()


# Spawns node from data, or creates new from preset.
func spawn(key: String, at: Vector3):
	var target: Vector3 = Utility.partitionID(at, PARTSIZE, EXTENDED)
	var info = data.get(key)
	# if exists, reposition
	if info != null:
		var current = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED)
		info["xform"].origin = at
		# if parts are different, switch
		if target != current:
			var preset: Dictionary = presets[info["preset"]]
			var type: String = preset["TYPE"]
			var list: Dictionary = get(type + "s")
			if list.has(current):
				list[current].erase(key)
				if list[current].empty():
					list.erase(current)
			if !list.has(target):
				list[target] = []
			list[target].append(key)
		# if part is live, summon
		if live.has(target):
			var holo = viewport.get_node_or_null(key)
			if holo == null:
				var preset: Dictionary = presets[info["preset"]]
				holo = load(preset["RES"]).instance()
				viewport.add_child(holo)
				holo.name = key
			holo.global_transform = info["xform"]
		elif live.has(current):
			var holo = viewport.get_node_or_null(key)
			if holo != null:
				holo.queue_free()
	# if doesn't exist, create and position
	else:
		var preset = presets.get(key)
		if preset != null:
			var unique: String = findName(key)
			info = {}
			info["preset"] = key
			for entry in preset.keys():
				if entry.to_lower()[0] == entry[0]:
					info[entry] = preset[entry].duplicate(true)
			info["xform"] = Transform.IDENTITY
			info["xform"].origin = at
			data[unique] = info
			# place in part
			var type: String = preset["TYPE"]
			var list: Dictionary = get(type + "s")
			if !list.has(target):
				list[target] = []
			list[target].append(unique)
			# if part is live, summon
			if live.has(target):
				var holo = load(preset["RES"]).instance()
				viewport.add_child(holo)
				holo.name = unique
				holo.global_transform.origin = at


# Finds unique name to be used in data for a given preset name.
func findName(key: String):
	var number: int = 1
	var suggestion: String = key
	while data.has(suggestion):
		number += 1
		suggestion = key + "@" + str(number)
	return suggestion
