extends Control


var time: int = 0
var frac: float = 0.0
var updatePeriodForEconomy: float = 64.0

const PROXMARK: PackedScene = preload("res://ControlNodes/Indicators/mark.tscn")
const CELLSIZE: float = 16.0 # width of each cell
const PARTSIZE: float = 64.0 # width of each partition
const EXTENDED: bool = false # if the grid is 3D, or 2D
const CANCROSS: bool = true # if moving crosswise is possible
var viewport: Viewport = null
# var camera: Camera = null
var indicators: Control = null
var walls: Dictionary = {} # arrays of partitions, filled with static stuff
var units: Dictionary = {} # arrays of partitions, filled with dynamic stuff which are intelligent (self-driving)
var items: Dictionary = {} # {Vector3(0, 0, 0): ["example"]} # arrays of partitions, filled with dynamic stuff which are dumb (can be picked up and dropped)
var live: Dictionary = {} # partitions that are live/spawned already
var data: Dictionary = {} # {"example": {"preset": "example", "xform": Transform.IDENTITY}} # names and properties of every single scene in the world
var refs: Dictionary = {} # names, references, and loaders
var occd: Dictionary = {} # occupied cells and occupying unit
var wars: Dictionary = {
	"spanish": ["french"],
	"french": ["spanish"]
}
var flags: Dictionary = {
	Color(1.0, 1.0, 0.0): "spanish",
	Color(0.0, 0.0, 1.0): "french",
	Color(0.0, 0.0, 0.0): "pirates"
}
var dominions: Image = Image.new() # what we use for defining regions, like what part of the world belongs to whom
var topograph: Image = Image.new() # what we use for maintaining multi-partition stuff, like islands
var picked: Dictionary = {} # like live, but for the multi-partition stuff
var colors: Dictionary = { # like data, but for the multi-partition stuff
	"010": {"pre": "ISLAND01", "res": "res://SceneNodes/Islands/Island1.tscn", "origin": Vector3(2, 0, 1)},
	"020": {"pre": "ISLAND02", "res": "res://SceneNodes/Islands/Island2.tscn", "origin": Vector3(5, 0, 2)},
	"030": {"pre": "ISLAND03", "res": "res://SceneNodes/Islands/Island3.tscn", "origin": Vector3(7, 0, 5)}
}
var ISLAND01: PackedScene = preload("res://SceneNodes/Islands/Island1.tscn")
var ISLAND02: PackedScene = preload("res://SceneNodes/Islands/Island2.tscn")
var ISLAND03: PackedScene = preload("res://SceneNodes/Islands/Island3.tscn")
var presets: Dictionary = { # constants are not copied over the instance, this is where we summon stuff from, and also check some constant variables from
	"border": {"CON": "walls", "RES": "res://SceneNodes/Borders/skullAndBones.tscn"},
	"exampleNPC": {"CON": "units", "PRE": "NPC01", "RES": "res://ObjectNodes/NPCShips/NPC1/NPC1Ship.tscn", "SPEED": 1, "weight": 1, "side": "pirates", "type": "wanderer", "pack": [], "gold": 100, "mode": "sell"}
}
var NPC01: PackedScene = preload("res://ObjectNodes/NPCShips/NPC1/NPC1Ship.tscn")
var wantedUnitsPerPreset: Dictionary = {"exampleNPC": 10}

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_node("ViewportContainer/Viewport")
	# camera = viewport.get_node("GameCamera")
	indicators = get_node("Interface/Indicators")
	var topographTexture: Texture = load("res://SceneNodes/OpenWorldManager/topograph.png")
	var dominionsTexture: Texture = load("res://SceneNodes/OpenWorldManager/dominions.png")
	topograph = topographTexture.get_data()
	dominions = dominionsTexture.get_data()
	GlobalObjectReferencer.viewport = get_tree().get_root().get_viewport() # set the viewport in global refs (viewport has no script attached so it needs to be set here)
	Utility.topograph = topograph # map for loading islands and also for pathfinding
	Utility.dominions = dominions # map for goalfinding and pathfinding, shows regions
#	spawn("exampleNPC", Utility.partitionLocation(Vector3(0, 0, 0), CELLSIZE, false))
#	spawn("exampleNPC", Utility.partitionLocation(Vector3(1, 0, 0), CELLSIZE, false))
#	spawn("exampleNPC", Utility.partitionLocation(Vector3(0, 0, 1), CELLSIZE, false))
	if Utility.lastSlot != null:
		loadGame(Utility.lastSlot)
	else:
		var suggestion: int = 0
		var file: File = File.new()
		while file.file_exists("user://" + str(suggestion) + ".png"):
			suggestion += 1
		Utility.lastSlot = suggestion
		createBorderSigns()
	createBorderSigns() # remove this line later, as signs should only be created on a new game


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# cleaning offscreen indicators
	for child in indicators.get_children():
		child.queue_free()
	# warning for getting out of the playable area
	var playerPart: Vector3 = Utility.partitionID(GlobalObjectReferencer.playerShip.global_transform.origin, PARTSIZE, false)
	var clampedPart: Vector2 = Vector2(clamp(playerPart.x, 0, topograph.get_width() - 1), clamp(playerPart.z, 0, topograph.get_height() - 1))
	var partDifference: Vector2 = clampedPart - Vector2(playerPart.x, playerPart.z)
	if partDifference != Vector2.ZERO:
		print("warning, turn towards: "+str(partDifference))
		pass
	# randomizing number generator for further use
	randomize()
	# advancing time
	if !get_tree().paused:
		frac += delta
	if frac > 1.0:
		frac -= 1.0
		var newTime: int = time + 1
		if floor(newTime / updatePeriodForEconomy) > floor(time / updatePeriodForEconomy):
			# fluctuating prices
			Economy.cycle()
			var shopping = get_tree().get_root().get_node_or_null("GameWorld/Interface/Shopping")
			if shopping.open != null:
				shopping.updateList()
		time = newTime
	# loading world
	var current: Vector3 = Utility.partitionID(GlobalObjectReferencer.camera.global_transform.origin, PARTSIZE, EXTENDED) # current partition
	#print("current partition: " + str(current))
	var adjacent: Array = Utility.findAdjacent(current, CANCROSS, EXTENDED) # adjacent partitions
	adjacent.append(current) # plus the current partition
	var copy: Dictionary = live.duplicate()
	for part in adjacent: # here we check and load any "not live yet" adjacent partitions
		if !live.has(part):
			insertPart(part)
			live[part] = null
			copy.erase(part)
	for part in copy.keys(): # here we check and unload any "live yet needs to die" partitions, partitions that are far away
		if Utility.chebyshevDistance(current, part) > 2:
			removePart(part)
			live.erase(part)
			copy.erase(part)
	# loading image
	if topograph != null: # here we do the same loading/unloading thing for multi-partition stuff, like items, it uses the image
		var codes: Dictionary = {}
		topograph.lock()
		for part in live.keys():
			if part.x < 0 || part.z < 0 || part.x > topograph.get_width() - 1 || part.z > topograph.get_height() - 1:
				continue
			var pixel: Color = topograph.get_pixel(part.x, part.z)
			var code: String = str(stepify(pixel.r, 0.1) * 10) + str(stepify(pixel.g, 0.1) * 10) + str(stepify(pixel.b, 0.1) * 10)
			if pixel != Color.black && !picked.has(code):
				if !colors.has(code):
					continue
				var island = null
				var pre = colors[code].get("pre")
				if pre != null:
					island = get(pre).instance()
					print("instanced island from preload")
				else:
					island = load(colors[code]["res"]).instance()
				viewport.add_child(island)
				island.global_transform.origin = Utility.partitionLocation(colors[code]["origin"], PARTSIZE, false)
				picked[code] = island
				#print("loaded: " + str(code))
			codes[code] = null
		topograph.unlock()
		for code in picked.keys():
			if !codes.has(code):
				picked[code].queue_free()
				picked.erase(code)
				#print("unloaded: " + str(code))
	# running behavior
	var unitsPerPreset: Dictionary = {}
	for part in units.keys(): # for all partitions that include at least one unit inside
		# getting the array of the units in proximity, that is units in this and adjacent partitions, also calculating power of each faction inside
		adjacent = Utility.findAdjacent(part, CANCROSS, EXTENDED)
		adjacent.append(part)
		var occupied: Array = []
		var sides: Dictionary = {}
		var inProx: Dictionary = {}
		topograph.lock()
		for partition in adjacent:
			if partition.x < 0 || partition.x >= topograph.get_width() || partition.z < 0 || partition.z >= topograph.get_height() || topograph.get_pixel(partition.x, partition.z) != Color.black:
				var occupiedPartitionLocation: Vector3 = Utility.partitionLocation(partition, PARTSIZE, false)
				occupied.append(Vector2(occupiedPartitionLocation.x, occupiedPartitionLocation.z))
			sides[partition] = {}
			if units.has(partition):
				for unit in units[partition]:
					inProx[unit] = data[unit]
					var side = data[unit]["side"]
					if !sides[partition].has(side):
						sides[partition][side] = 0
					sides[partition][side] += 1 # this "1" can be replaced with scoring of power of that ship
		topograph.unlock()
		var sidesSpread: Dictionary = sides.duplicate(true)
		for partition in sides.keys():
			for partitionTwo in sides.keys():
				if Utility.chebyshevDistance(partition, partitionTwo) == 1:
					for side in sides[partition].keys():
						if !sidesSpread[partitionTwo].has(side):
							sidesSpread[partitionTwo][side] = 0
						sidesSpread[partitionTwo][side] += sides[partition][side] * 0.5
		for partition in sidesSpread.keys():
			if Utility.isOccupied(partition):
				sidesSpread.erase(partition)
		var sidesOrganized: Dictionary = {}
		for flag in flags.keys():
			var side = flags[flag]
			sidesOrganized[side] = {}
			for partition in sidesSpread.keys():
				sidesOrganized[side][partition] = Vector2.ZERO
				for sideTwo in sidesSpread[partition].keys():
					var value = sidesSpread[partition][sideTwo]
					if sideTwo == side:
						sidesOrganized[side][partition].x += value
					elif wars.has(side) && wars[side].has(sideTwo):
						sidesOrganized[side][partition].y += value
		# iterating units
		for unit in units[part]: # for each unit in this part, note that, the inProx array above will be same for all units in this part, so can be used by any
			var holo = runAI(unit, part, sidesOrganized, inProx, occupied, delta)
			# maintaining consistency, we update all necessary data after the behavior, so things don't fall apart
			var info: Dictionary = data[unit]
			var preset = info["preset"]
			if !unitsPerPreset.has(preset):
				unitsPerPreset[preset] = 0
			unitsPerPreset[preset] += 1
			var newCell = Utility.partitionID(info["xform"].origin, CELLSIZE, EXTENDED) # new cell of this unit
			var cell = info.get("cell")
			if cell != newCell:
				if cell != null && occd.get(cell) == unit:
					occd.erase(cell)
				occd[newCell] = unit
				info["cell"] = newCell
			var newPart = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED) # new partition of this unit
			if newPart != part: # if partition has changed, we update and load/unload if necessary
				units[part].erase(unit)
				if units[part].empty():
					units.erase(part)
				if !units.has(newPart):
					units[newPart] = []
				units[newPart].append(unit)
			if live.has(newPart): # if new partition is live but unit is not spawned, we spawn it
				if holo == null:
					# print("spawned")
					var pre = presets[info["preset"]].get("PRE")
					if pre != null:
						# print("using preloaded NPC")
						holo = get(pre).instance()
					else:
						holo = load(presets[info["preset"]]["RES"]).instance()
					viewport.add_child(holo)
					holo.name = unit
					holo.global_transform = info["xform"]
					refs[unit] = {"holo": holo}
			elif holo != null: # if new partition is not live, we kill holo, but it keeps living in the database
				holo.queue_free()
				refs.erase(unit)
				print("terminal : destroyed")
			if holo != null && live.has(newPart): # creating offscreen indicator
				var pos = GlobalObjectReferencer.camera.unproject_position(holo.global_transform.origin)
				var facing = -1 * GlobalObjectReferencer.camera.global_transform.basis.z.normalized()
				if facing.dot((holo.global_transform.origin - GlobalObjectReferencer.camera.global_transform.origin).normalized()) > 0:
					var guiOffset: float = 32
					var guiPosition: Vector2 = Vector2(clamp(pos.x, 0.0 + guiOffset, get_viewport().size.x - guiOffset), clamp(pos.y, 0.0 + guiOffset, get_viewport().size.y - guiOffset))
					if guiPosition != pos: # only if unit is outside of the screen, we create an indicator for it
						var gui: Sprite = PROXMARK.instance()
						indicators.add_child(gui)
						gui.position = guiPosition
	# adding more units if number of units for a preset is lower than it's set
	for preset in wantedUnitsPerPreset.keys():
		if !unitsPerPreset.has(preset) || unitsPerPreset[preset] < wantedUnitsPerPreset[preset]:
			var randomTile: Vector3 = Vector3(randi() % topograph.get_width(), 0, randi() % topograph.get_height())
			topograph.lock()
			var randomTileColor: Color = topograph.get_pixel(randomTile.x, randomTile.z)
			topograph.unlock()
			if randomTileColor == Color.black:
				var randomTileCoords: Vector3 = Utility.partitionLocation(randomTile, PARTSIZE, EXTENDED)
				var randomCell: Vector3 = Utility.partitionID(randomTileCoords, CELLSIZE, EXTENDED)
				if !occd.has(randomCell):
					spawn(preset, randomTileCoords)


# Loads the given part of the world.
func insertPart(part):
	if walls.has(part):
		for wall in walls[part]:
			var info: Dictionary = data[wall]
			var preset: Dictionary = presets[info["preset"]]
			var holo = null
			var pre = preset.get("PRE")
			if pre != null:
				holo = get(pre).instance()
			else:
				holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = wall
			holo.global_transform = info["xform"]
			refs[wall] = {"holo": holo}
	if units.has(part):
		for unit in units[part]:
			var info: Dictionary = data[unit]
			var preset: Dictionary = presets[info["preset"]]
			var holo = null
			var pre = preset.get("PRE")
			if pre != null:
				holo = get(pre).instance()
			else:
				holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = unit
			holo.global_transform = info["xform"]
			refs[unit] = {"holo": holo}
	if items.has(part):
		for item in items[part]:
			var info: Dictionary = data[item]
			var preset: Dictionary = presets[info["preset"]]
			var holo = null
			var pre = preset.get("PRE")
			if pre != null:
				holo = get(pre).instance()
			else:
				holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = item
			holo.global_transform = info["xform"]
			refs[item] = {"holo": holo}


# Unloads the given part of the world.
func removePart(part):
	if walls.has(part):
		for wall in walls[part]:
			if refs.has(wall):
				var holo = refs[wall]["holo"]
				holo.queue_free()
				refs.erase(wall)
	if units.has(part):
		for unit in units[part]:
			if refs.has(unit):
				var holo = refs[unit]["holo"]
				holo.queue_free()
				refs.erase(unit)
	if items.has(part):
		for item in items[part]:
			if refs.has(item):
				var holo = refs[item]["holo"]
				holo.queue_free()
				refs.erase(item)


# Spawns node from data, or creates new from preset. Everytime you create/spawn something that should persist as data, use this.
func spawn(key: String, at: Vector3):
	var result = null
	var atPart: Vector3 = Utility.partitionID(at, PARTSIZE, EXTENDED)
	var atCell: Vector3 = Utility.partitionID(at, CELLSIZE, EXTENDED)
	var info = data.get(key)
	# if exists, reposition
	if info != null:
		result = key
		var fromPart = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED)
		var fromCell = Utility.partitionID(info["xform"].origin, CELLSIZE, EXTENDED)
		info["xform"].origin = at
		# if cells are different, switch
		if atCell != fromCell:
			if occd.get(fromCell) == key:
				occd.erase(fromCell)
			info["cell"] = atCell
			occd[atCell] = key
		# if parts are different, switch
		if atPart != fromPart:
			var preset: Dictionary = presets[info["preset"]]
			var type: String = preset["CON"]
			var list: Dictionary = get(type)
			if list.has(fromPart):
				list[fromPart].erase(key)
				if list[fromPart].empty():
					list.erase(fromPart)
			if !list.has(atPart):
				list[atPart] = []
			list[atPart].append(key)
		# if part is live, summon
		if live.has(atPart):
			var holo = refs.get(key)
			if holo == null:
				var preset: Dictionary = presets[info["preset"]]
				var pre = preset.get("PRE")
				if pre != null:
					holo = get(pre).instance()
				else:
					holo = load(presets["RES"]).instance()
				viewport.add_child(holo)
				holo.name = key
			holo.global_transform = info["xform"]
			refs[key] = {"holo": holo}
		elif live.has(fromPart):
			var holo = refs.get(key)
			if holo != null:
				holo.queue_free()
				refs.erase(key)
	# if doesn't exist, create and position
	else:
		var preset = presets.get(key)
		if preset != null:
			var unique: String = findName(key)
			result = unique
			info = {}
			info["preset"] = key
			for entry in preset.keys():
				if entry.to_lower()[0] == entry[0]:
					if preset[entry] is Array || preset[entry] is Dictionary:
						info[entry] = preset[entry].duplicate(true)
					else:
						info[entry] = preset[entry]
			info["xform"] = Transform.IDENTITY
			info["xform"].origin = at
			info["cell"] = atCell
			data[unique] = info
			# place in cell
			occd[atCell] = unique
			# place in part
			var type: String = preset["CON"]
			var list: Dictionary = get(type)
			if !list.has(atPart):
				list[atPart] = []
			list[atPart].append(unique)
			# if part is live, summon
			if live.has(atPart):
				var holo = null
				var pre = preset.get("PRE")
				if pre != null:
					holo = get(pre).instance()
				else:
					holo = load(presets["RES"]).instance()
				viewport.add_child(holo)
				holo.name = unique
				holo.global_transform.origin = at
				refs[unique] = {"holo": holo}
	return result


# Finds unique name to be used in data for a given preset name. Simply checks database and tries to make up a unique name for a new entity.
func findName(key: String):
	var number: int = 1
	var suggestion: String = key
	while data.has(suggestion + str(number)):
		number += 1
	return suggestion + str(number)


# Runs artificial intelligence for the given unit.
func runAI(unit: String, part: Vector3, sides: Dictionary, inProx: Dictionary, islands: Array, delta: float):
#	If I was a ship:
#	- I'd have a class like pirate, trade, military; and a faction like spanish, french, whatnot
#	- I'd have an end goal depending on my class or faction or current cargo or health
#	- I'd get list of ships nearby
#	- I'd categorize them as ally, neutral, enemy
#	- I'd do some risk management depending on total powers or perhaps powers at directions
#	- If I could, I'd like to keep pursuing my goal, (follow route if trading, attack enemy if pirate or military)
#	- If my goal doesn't seem plausible, I'd create a temporary goal to follow till the conditions change (flee or fight, probably trying to flee, but also shooting whenever possible, as you have suggested once)
	# loading information about this unit
	var boost = 1 # speed boost for debugging purposes
	var dest = null
	var holo = null # holo stands for physical representations of units, that is actual scenes in the world, loaded
	var info: Dictionary = data[unit] # info stands for variables of this unit, like health and transform (xform)
	var preset: Dictionary = presets[info["preset"]] # preset has constants of this unit, like max health and resource path
	var side: String = info["side"]
	var type: String = info["type"]
#	var task: String = info["task"]
	var pack: Array = info["pack"]
	if live.has(part): # if part of this unit is live, we can find its holo
		#holo = viewport.get_node_or_null(unit)
		if refs.has(unit):
			holo = refs[unit]["holo"]
		
	var follow = info.get("follow")
	# override behavior, includes fight or flee
	if follow == null:
		var weakestEnemyPart = null
		var weakestEnemyValue = 999999999
		var leastDangerousPart = null
		var leastDangerousValue = 999999999
		var total: Vector2 = Vector2.ZERO
		for partition in sides[side].keys():
			var value = sides[side][partition]
			total += value
			if value.y < leastDangerousValue:
				leastDangerousValue = value.y
				leastDangerousPart = partition
			if value.y > 0 && value.y < weakestEnemyValue:
				weakestEnemyPart = partition
		if side == "pirates": # if enemy is weaker than allies, fight
			if total.y != 0:
				if total.x / total.y > 1.1:
					dest = weakestEnemyPart
				else:
					dest = leastDangerousPart
		elif type == "trade": # if enemy is stronger than allies, flee
			if total.y > total.x:
				dest = leastDangerousPart
		elif type == "military": # if enemy is weaker than allies, fight
			if total.y != 0:
				if total.x / total.y > 0.9:
					dest = weakestEnemyPart
				else:
					dest = leastDangerousPart
	# standard behavior, includes goalfinding and pathfinding
	if dest == null:
		var wait = info.get("wait")
		if wait != null: # waits if set to wait
			# print("waiting: " + str(wait))
			wait -= delta
			info["wait"] = wait
			if wait <= 0:
				info.erase("wait")
		else:
			var goal = info.get("goal")
			if follow != null:
				print("following")
				var followUnit = units.get(follow)
				if followUnit != null:
					var followPart = Utility.partitionID(followUnit["xform"].origin, PARTSIZE, false)
					if followPart != goal:
						goal = followPart
			if goal == null: # finds goal if doesn't have one
				# print("goalfinding")
				dominions.lock()
				topograph.lock()
				if type == "trade": # go to the closest shop with the highest profit for the current cargo hold
					var targetShop = null
					var targetPart = null
					var targetDistance = 999999999
					var highestProfit: float = -1
					for mallName in Economy.malls.keys():
						var profit: float = 0
						var mall: Dictionary = Economy.malls[mallName]
						var mallPart: Vector3 = mall["part"]
						var pixelColor: Color = dominions.get_pixel(mallPart.x, mallPart.z)
						var mallSide: String = flags[pixelColor]
						if wars.has(side) && wars[side].has(mallSide):
							continue
						for item in pack:
							profit += Economy.getPrice(item, mallName)
						var dist = Utility.chebyshevDistance(part, mallPart)
						if profit > highestProfit || (profit == highestProfit && dist < targetDistance):
							highestProfit = profit
							targetDistance = dist
							targetShop = mallName
							targetPart = mallPart
					info["goal"] = targetPart
					info["shop"] = targetShop
				elif type == "interceptor": # patrol to hunt trade ships, for this go to a random trading route partition
					var malls: Array = Economy.malls.keys()
					malls.shuffle()
					var mallTwoPart = null
					var mallOne = malls[0]
					var mallOnePart: Vector3 = mallOne["part"]
					var pixelColor: Color = dominions.get_pixel(mallOnePart.x, mallOnePart.z)
					var mallOneSide: String = flags[pixelColor]
					if !wars.has(mallOneSide):
						var mallTwo = malls[1]
						mallTwoPart = mallTwo["part"]
					else:
						for mallIndex in range(1, malls.size()):
							var mallTemp = malls[mallIndex]
							var mallTempPart: Vector3 = mallTemp["part"]
							pixelColor = dominions.get_pixel(mallTempPart.x, mallTempPart.z)
							var mallTempSide: String = flags[pixelColor]
							if wars[mallOneSide].has(mallTempSide):
								continue
							else:
								mallTwoPart = mallTempPart
								break
					var path = Utility.findPath(mallOnePart, mallTwoPart, true, false, [])
					if path != null:
						info["goal"] = path[floor((path.size() - 1) * 0.5)]
				elif type == "wanderer": # patrol to hunt trade ships, for this go to a totally random partition
					var randomPart = Vector2(floor(rand_range(0, topograph.get_width() - 1)), floor(rand_range(0, topograph.get_height() - 1)))
					var randomPixel: Color = topograph.get_pixel(randomPart.x, randomPart.y)
					if randomPixel == Color.black:
						info["goal"] = Vector3(randomPart.x, 0, randomPart.y)
				elif type == "military": # patrol to hunt enemy and pirate ships, for this go to a random trading spot partition
					var malls: Array = Economy.malls.keys()
					malls.shuffle()
					for mallName in malls:
						var mall = malls[0]
						var mallPart: Vector3 = mall["part"]
						var pixelColor: Color = dominions.get_pixel(mallPart.x, mallPart.z)
						var mallSide: String = flags[pixelColor]
						if mallSide != side && (!wars.has(side) || !wars[side].has(mallSide)):
							continue
						else:
							info["goal"] = mallPart
							break
				dominions.unlock()
				topograph.unlock()
			elif goal != part: # needs path if is not at goal
				var path = info.get("path")
				if path == null: # finds path if doesn't have one
					var filter: Array = []
					if wars.has(side):
						filter = wars[side].duplicate()
					info["path"] = Utility.findPath(part, goal, true, false, filter)
#					print("pathfinding: "+str(info["path"].size())+" to: "+str(goal)+" from: "+str(part))
#				elif path[0] != goal: # changes goal if can't reach
#					pass
				else: # follows path
					var dist: int = Utility.chebyshevDistance(part, path[-1])
					if dist == 0: # if reached, remove waypoint
						path.pop_back()
						if path.empty():
							info.erase("path")
					elif dist > 1: # if distant, clear path, so can search from scratch
						info.erase("path")
					else: # go towards the next waypoint
						dest = path[-1]
			else: # works at goal
				if info.has("path"):
					info.erase("path")
				if type == "trade":
					# sell goods which profit more than some percentage compared to the base price
					if info["mode"] == "sell":
						for index in range(info["pack"].size() - 1, -1, -1):
							var item = info["pack"][index]
							if !Economy.canSell(item, info["shop"]):
								continue
							var basePrice = Economy.goods[item]["price"]
							var shopPrice = Economy.getPrice(item, info["shop"])
							if shopPrice / basePrice >= 1.1 && shopPrice <= Economy.malls[info["shop"]]["money"]:
								var stock: Dictionary = Economy.malls[info["shop"]]["goods"]
								if !stock.has(item):
									stock[item] = 0
								stock[item] += 1
								Economy.malls[info["shop"]]["money"] -= shopPrice
								info["gold"] += shopPrice
								print("sold " + str(item))
								info["pack"].remove(index)
								return
						info["mode"] = "buy"
					# buy goods that are cheaper than some percentage compared to the base price
					var cheapest = null
					var price = 999999999
					for item in Economy.malls[info["shop"]]["goods"].keys():
						if !Economy.canBuy(item, info["shop"]):
							continue
						var basePrice = Economy.goods[item]["price"]
						var shopPrice = Economy.getPrice(item, info["shop"])
						if shopPrice / basePrice <= 0.9 && shopPrice <= info["gold"]:
							if shopPrice < price:
								price = shopPrice
								cheapest = item
					if cheapest != null:
						var stock: Dictionary = Economy.malls[info["shop"]]["goods"]
						stock[cheapest] -= 1
						if stock[cheapest] == 0:
							stock.erase(cheapest)
						var shopPrice = Economy.getPrice(cheapest, info["shop"])
						Economy.malls[info["shop"]]["money"] += shopPrice
						info["gold"] -= shopPrice
						info["pack"].append(cheapest)
						print("purchased " + str(cheapest))
						return
					info["mode"] = "sell"
					# wait for short time
					info["wait"] = 180
				elif type == "interceptor":
					# wait for long time
					info["wait"] = 600
				elif type == "wanderer":
					# wait for a bit
					info["wait"] = 1
				elif type == "military":
					# repair (if ally port)
					# wait for some time
					info["wait"] = 180
				info["goal"] = null
			
		
	# find destination cell location
	if dest == null:
		dest = part
	var diff = dest - part
	var cell = Utility.partitionID(info["xform"].origin, CELLSIZE, EXTENDED)
	dest = Utility.partitionLocation(cell, CELLSIZE, EXTENDED)
	if !occd.has(cell + diff) || occd.get(cell + diff) == unit:
		var locationOfDestinationCell = Utility.partitionLocation(cell + diff, CELLSIZE, EXTENDED)
		dest = locationOfDestinationCell
	else:
		var overlaps: Array = Utility.findOverlapping(Utility.findAdjacent(cell, CANCROSS, EXTENDED), Utility.findAdjacent(cell + diff, CANCROSS, EXTENDED))
		for overlap in overlaps:
			var locationOfOverlappingCell = Utility.partitionLocation(overlap, CELLSIZE, EXTENDED)
			var partOfOverlappingCell = Utility.partitionID(locationOfOverlappingCell, PARTSIZE, EXTENDED)
			if Utility.isOccupied(partOfOverlappingCell):
				continue
			var occupiedBy = occd.get(overlap)
			if occupiedBy != null && occupiedBy != unit:
				continue
			dest = locationOfOverlappingCell
			break
		
	if holo != null: # runs when unit is live
		var results: Dictionary
		var controller = holo.get_node_or_null("AIController")
		if controller != null:
			var temp: Vector3 = Utility.partitionLocation(dest, PARTSIZE, false)
			results = controller.update(Vector2(temp.x, temp.z), inProx, islands)
		info["xform"] = holo.global_transform # at the end, update transform
	else: # runs when unit is offscreen
		# move transform
		var squaredLimit = pow(preset["SPEED"] / info["weight"], 2)
		var direction: Vector3 = dest - info["xform"].origin
		if direction.length_squared() > squaredLimit:
			direction = direction.normalized() * squaredLimit
		if direction != Vector3.ZERO:
			info["xform"].origin += direction * delta * boost * preset["SPEED"] / info["weight"]
			info["xform"] = info["xform"].looking_at(info["xform"].origin + direction * 1000, Vector3.UP)
	return holo


# Loads the saved game with the given name.
func loadGame(slot: String):
	var opt = null
	var big = 0
	var file = File.new()
	if file.file_exists("user://" + slot + ".one"):
		var last = null
		file.open("user://" + slot + ".one", File.READ)
		while file.get_position() < file.get_len():
			last = file.get_line()
		file.close()
		if last != null:
			last = int(last)
			if last > big:
				opt = "one"
				big = last
	if file.file_exists("user://" + slot + ".two"):
		var last = null
		file.open("user://" + slot + ".two", File.READ)
		while file.get_position() < file.get_len():
			last = file.get_line()
		file.close()
		if last != null:
			last = int(last)
			if last > big:
				opt = "two"
				big = last
	if opt != null:
		file.open("user://" + slot + "." + opt, File.READ)
		var content: Dictionary = {}
		while file.get_position() < file.get_len():
			var line: String = file.get_line()
			var json: JSONParseResult = JSON.parse(line)
			if json.error == OK:
				print(json.error)
				content = json.result
				print(content)
			break
		file.close()
		for key in content.keys():
			if get(key) != null:
				set(key, content[key])
			elif Economy.get(key) != null:
				Economy.set(key, content[key])


# Overwrites the data for the saved game with the given name. If can't find the corresponding files, then creates one.
func saveGame(slot: String):
	var opt = "one"
	var big = 0
	var file = File.new()
	if file.file_exists("user://" + slot + ".one"):
		var last = null
		file.open("user://" + slot + ".one", File.READ)
		while file.get_position() < file.get_len():
			last = file.get_line()
		file.close()
		if last != null:
			last = int(last)
			if last > big:
				opt = "two"
				big = last
	if file.file_exists("user://" + slot + ".two"):
		var last = null
		file.open("user://" + slot + ".two", File.READ)
		while file.get_position() < file.get_len():
			last = file.get_line()
		file.close()
		if last != null:
			last = int(last)
			if last > big:
				opt = "one"
				big = last
	var content: Dictionary = {"time": time, "frac": frac, "data": data, "walls": walls, "units": units, "wars": wars, "malls": Economy.malls}
	file.open("user://" + slot + "." + opt, File.WRITE)
	file.store_line(JSON.print(content))
	file.store_line(str(OS.get_unix_time()))
	file.close()
	var image: Image = get_node("ViewportContainer/Viewport").get_texture().get_data()
	image.flip_y()
	image.resize(image.get_width() * 0.125, image.get_height() * 0.125)
	image.save_png("user://" + slot + ".png")


# Creates border signs and adds to data for their corresponding partitions.
func createBorderSigns():
	var width = topograph.get_width()
	var height = topograph.get_height()
	print(width)
	print(height)
	for x in range(-1, width + 1):
		for y in [-1, height]:
			var result = spawn("border", Utility.partitionLocation(Vector3(x, 0, y), PARTSIZE, false))
			var info = data.get(result)
			if y == -1:
				if x == -1:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(1, 0, 1), Vector3.UP)
				elif x == width:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(-1, 0, 1), Vector3.UP)
				else:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(0, 0, 1), Vector3.UP)
			elif y == height:
				if x == -1:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(1, 0, -1), Vector3.UP)
				elif x == width:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(-1, 0, -1), Vector3.UP)
				else:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(0, 0, -1), Vector3.UP)
	for y in range(-1, height + 1):
		for x in [-1, width]:
			var result = spawn("border", Utility.partitionLocation(Vector3(x, 0, y), PARTSIZE, false))
			var info = data.get(result)
			if x == -1:
				if y == -1:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(1, 0, 1), Vector3.UP)
				elif y == height:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(1, 0, -1), Vector3.UP)
				else:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(1, 0, 0), Vector3.UP)
			elif x == width:
				if y == -1:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(-1, 0, 1), Vector3.UP)
				elif y == height:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(-1, 0, -1), Vector3.UP)
				else:
					info["xform"] = info["xform"].looking_at(info["xform"].origin + Vector3(-1, 0, 0), Vector3.UP)
