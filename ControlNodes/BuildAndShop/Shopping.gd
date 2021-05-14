extends Control


const CURRENCY: String = "g"
const ITEM: PackedScene = preload("res://ControlNodes/BuildAndShop/listItem.tscn")
const TYPE: PackedScene = preload("res://ControlNodes/BuildAndShop/tabsType.tscn")

var speedLimit: float = 9 # square units that shops get closed automatically when passed beyond
var distanceLimit: float = 1024 # square units that shops get closed automatically when passed beyond

var open = null
var tabs = null
var list = null
var filter = null
var seller = null
var selected = null
var indicator = null
var viewport: Viewport

const TILEWIDTH: float = 0.2 # width of one tile which all items must be designed accordingly
const STACKED: bool = false
var target = null
var highlight = null
var hologram = null
var resource = null
var parent = null
var pos = null
var rot: Vector2
var tempRot: Vector2
var dim = Vector3.ONE # in terms of tile size given above, each component must be an integer
var rotDim = Vector3.ONE
var switch: bool = true

var leftClick: bool = false
var rightClick: bool = false
var scrollUp: bool = false
var scrollDown: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalObjectReferencer.shopping = self
	seller = get_node("Shop/Sell")
	indicator = get_node("Indicator")
	indicator.visible = false
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabs = get_node("Shop/Tabs/Container")
	list = get_node("Shop/List/Container")
	viewport = get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport")

# Catches only the input which has not been handled yet.
func _unhandled_input(event):
	if event.is_action_pressed("leftClick") && !event.is_echo():
		leftClick = true
	if event.is_action_pressed("rightClick") && !event.is_echo():
		rightClick = true
	if event.is_action_released("rotateItemLeft"):
		scrollUp = true
	if event.is_action_released("rotateItemRight"):
		scrollDown = true


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	target = null
	var selectedDeckNumber: int = GlobalObjectReferencer.cursor.selectedDeckNumber
	if selectedDeckNumber != -1:
		target = get_tree().get_nodes_in_group("PlayerDeck")[selectedDeckNumber]
	if target != null && !is_instance_valid(target):
		target = null
	if target == null && open != null:
		closeShop()
	var player: RigidBody = GlobalObjectReferencer.playerShip
	if player.linear_velocity.length_squared() > speedLimit:
		closeShop()
	if open != null && player.global_transform.origin.distance_squared_to(Economy.malls[open]["loci"]) > distanceLimit:
		closeShop()
	if selected != null && (rightClick || switch == false):
		selected = null
	if open == null || selected == null:
		deselect()
	elif resource == null:
		var itemName: String = selected.get_node("Name").text
		var good: Dictionary = Economy.goods[itemName]
		hologramFromResource(good["res"])
	if switch == true && target == null:
		if is_instance_valid(highlight):
			var sprite = highlight.get_node("Sprite3D")
			# sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
			placeOrDestroyHologram()
		return
	if open == null:
		if is_instance_valid(highlight):
			var sprite = highlight.get_node("Sprite3D")
			# sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
		if resource != null || is_instance_valid(hologram):
			placeOrDestroyHologram()
	var upward = target.global_transform.basis.y.normalized()
	var hit: Dictionary = GlobalObjectReferencer.cursor.hit
	var newHighlight = null
	if is_instance_valid(hologram):
		if scrollUp || scrollDown:
			if scrollUp:
				rotate(false)
			elif scrollDown:
				rotate(true)
			if tempRot.y == 0:
				rotDim = Vector3(dim.z, dim.y, dim.x)
			else:
				rotDim = dim
		var canPlace = false
		# orienting hologram over hit
		if !hit.empty() && hit.collider is Spatial:
			var offset = Vector3(fmod(rotDim.x, 2), 0, fmod(rotDim.z, 2)) * TILEWIDTH * 0.5 + TILEWIDTH * Vector3.UP * (dim.y/2)
			var partition: Vector3 = (target.global_transform.xform_inv(hit.position) / TILEWIDTH).floor()
			hologram.global_transform.origin = target.global_transform.xform(partition * TILEWIDTH + offset)
			lookAtLocal(hologram, target, tempRot, upward)
		# checking if hit is target and if item can be placed
		if !hit.empty() && (STACKED || hit.collider == target):
#			var offset = Vector3(fmod(rotDim.x, 2), 0, fmod(rotDim.z, 2)) * TILEWIDTH * 0.5 + TILEWIDTH * Vector3.UP * (dim.y/2)
#			var partition: Vector3 = (target.global_transform.xform_inv(hit.position) / TILEWIDTH).floor()
#			hologram.global_transform.origin = target.global_transform.xform(partition * TILEWIDTH + offset)
#			lookAtLocal(hologram, target, tempRot, upward)
			var tempCoords = target.to_local(hologram.global_transform.origin)
			tempCoords = Vector3(stepify(tempCoords.x, 0.1), stepify(tempCoords.y, 0.1), stepify(tempCoords.z, 0.1))
			#var tempName: String = Utility.resName(hologram.name) # keeping this as backup for now
			var tempName: String = hologram.databaseName
			var occupation: Array = tiles4(tempCoords, tempRot, Economy.getSize(tempName))
#			print(occupation)
			if target.checkIfFree(occupation):
				canPlace = true
			#	print("canPlace")
			# collision based check, in case it comes useful later
			#var collision: KinematicCollision = hologram.move_and_collide(Vector3(0,0.01,0), false, false, true)
			#if !collision:
			#	canPlace = true
			#	print("canPlace")
		# returning item to its old place
		if rightClick:
			if parent != null:
#				print("returnedTo: "+str(pos))
				placeOrDestroyHologram()
		elif canPlace:
			var sprite = hologram.get_node("Sprite3D")
			# sprite.modulate = Color(0.0, 1.0, 0.0, 0.5)
			# placing item
			if leftClick:
				parent = target
				pos = parent.to_local(hologram.global_transform.origin)
				pos = Vector3(stepify(pos.x, 0.1), stepify(pos.y, 0.1), stepify(pos.z, 0.1))
#				print("placedAt: "+str(pos))
				rot = tempRot
				placeOrDestroyHologram()
		else:
			var sprite = hologram.get_node("Sprite3D")
			# sprite.modulate = Color(1.0, 0.0, 0.0, 0.5)
	# checking if item can be picked up
	elif !hit.empty() && hit.collider.get("movable") != null:
		if open != null && hit.collider.get("movable") == true:
			var temp = hit.collider.get_parent()
			if temp != null && temp == target:
				# picking item up
				if leftClick:
					resource = null
					hologram = hit.collider
					var mall: Dictionary = Economy.malls[open]
					var itemName: String = hologram.databaseName
					var itemPrice = Economy.getPrice(itemName, open)
					if itemPrice <= mall["money"] && !mall["black"].has(itemName) && mall["white"].has(Economy.goods[itemName]["type"]):
						seller.text = str(itemPrice) + CURRENCY
						seller.disabled = false
					else:
						seller.disabled = true
					parent = temp
#					print("pickedFromParent: "+str(parent.name))
					pos = parent.to_local(hologram.global_transform.origin)
					pos = Vector3(stepify(pos.x, 0.1), stepify(pos.y, 0.1), stepify(pos.z, 0.1))
					var currentRot = hologram.transform.basis.z * -1
					rot = Vector2(currentRot.x, currentRot.z).round()
					tempRot = rot
					setSize()
#					print("pickedFrom: "+str(pos))
					var occupation: Array = tiles4(pos, rot, Economy.getSize(itemName))
#					print("occupation: "+str(occupation))
					hologram.onRemove()
					target.freeTiles(occupation)
					if is_instance_valid(hologram.get_parent()):
						hologram.get_parent().remove_child(hologram)
						viewport.add_child(hologram)
				else:
					newHighlight = hit.collider
	if is_instance_valid(highlight):
		var sprite = highlight.get_node("Sprite3D")
		if sprite!=null:
			pass
			# sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		highlight = null
	if is_instance_valid(newHighlight):
		highlight = newHighlight
	if is_instance_valid(highlight):
		var sprite = highlight.get_node("Sprite3D")
		if sprite!=null:
			pass
			# sprite.modulate = Color(1.0, 1.0, 0.0, 1.0)
	leftClick = false
	rightClick = false
	scrollUp = false
	scrollDown = false


# Spawns and sets an external body as the hologram to be placed. May be useful at store/market.
func hologramFromResource(path: String):
	seller.text = "SELL"
	seller.disabled = true
	if resource != null:
		hologram.queue_free()
		hologram = null
	resource = path
	hologram = load(path).instance()
	viewport.add_child(hologram)
	parent = null
	pos = null
	var itemName: String = hologram.databaseName
	dim = Economy.getSize(itemName)
	if dim is Vector2:
		dim = Vector3(dim.x, 1.0, dim.y)
	hologram.global_transform.basis = target.global_transform.basis
	rotDim = dim
	tempRot = Vector2(0, -1)
	var shape = hologram.get_node("CollisionShape").shape
	if shape is BoxShape:
		shape.extents = Vector3(dim.x, dim.y, dim.z) * 0.5 * TILEWIDTH - Vector3.ONE * 0.01
	var gridMesh = hologram.get_node_or_null("GridShowMesh")
	if gridMesh != null:
		gridMesh.visible = true
		gridMesh.scale = Vector3(dim.x, dim.y, dim.z) * TILEWIDTH - Vector3.ONE * 0.005


# Destroys any hologram or resource.
func destroyHologram():
	parent = null
	placeOrDestroyHologram()


# Places current hologram or destroys it.
func placeOrDestroyHologram():
	get_tree().set_input_as_handled()
	seller.text = "SELL"
	seller.disabled = true
	if resource != null:
		if parent != null:
			var duplicate = load(resource).instance()
			if duplicate.get_parent() != parent:
				parent.add_child(duplicate)
			duplicate.global_transform.origin = parent.to_global(pos)
			lookAtLocal(duplicate, parent, rot, parent.global_transform.basis.y)
			parent = null
			var itemName: String = selected.get_node("Name").text
			var occupation: Array = tiles4(pos, rot, Economy.getSize(itemName))
#			print("occupation: "+str(occupation))
			duplicate.onPlacement()
			target.occupyTiles(occupation)
			purchase(duplicate)
		else:
			resource = null
			if hologram != null:
				hologram.queue_free()
				hologram = null
			pos = null
		return
	elif parent != null:
		if !is_instance_valid(hologram.get_parent()) || hologram.get_parent() != parent:
			if is_instance_valid(hologram.get_parent()):
				hologram.get_parent().remove_child(hologram)
			parent.add_child(hologram)
		hologram.global_transform.origin = parent.to_global(pos)
		lookAtLocal(hologram, parent, rot, parent.global_transform.basis.y)
		var sprite = hologram.get_node("Sprite3D")
		# sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var itemName: String = hologram.databaseName
		var occupation: Array = tiles4(pos, rot, Economy.getSize(itemName))
#		print("occupation: "+str(occupation))
		hologram.onPlacement()
		target.occupyTiles(occupation)
	elif hologram != null:
		hologram.queue_free()
		hologram = null
	hologram = null
	parent = null
	pos = null


# Rotates the given spatial towards the given local direction according to the given reference spatial.
func lookAtLocal(subject: Spatial, reference: Spatial, direction: Vector2, upward: Vector3):
	if direction == Vector2(0, -1):
		subject.look_at(subject.global_transform.origin + reference.global_transform.basis.z * -999, upward)
	elif direction == Vector2(0, 1):
		subject.look_at(subject.global_transform.origin + reference.global_transform.basis.z * 999, upward)
	elif direction == Vector2(1, 0):
		subject.look_at(subject.global_transform.origin + reference.global_transform.basis.x * 999, upward)
	elif direction == Vector2(-1, 0):
		subject.look_at(subject.global_transform.origin + reference.global_transform.basis.x * -999, upward)


# Rotates the selected item.
func rotate(clockwise: bool):
	if clockwise:
		tempRot = (tempRot.rotated(PI * 0.5)).round()
	else:
		tempRot = (tempRot.rotated(PI * -0.5)).round()


# Sets size and rotated size for the selected item.
func setSize():
	var itemName: String = hologram.databaseName
	dim = Economy.getSize(itemName)
	if dim is Vector2:
		dim = Vector3(dim.x, 1.0, dim.y)
	rotDim = dim
	if rot.y == 0:
		rotDim = Vector3(rotDim.z, rotDim.y, rotDim.x)
	var shape = hologram.get_node("CollisionShape").shape
	if shape is BoxShape:
		shape.extents = Vector3(dim.x, dim.y, dim.z) * 0.5 * TILEWIDTH - Vector3.ONE * 0.01
	var gridMesh = hologram.get_node_or_null("GridShowMesh")
	if gridMesh != null:
		gridMesh.visible = true
		gridMesh.scale = Vector3(dim.x, dim.y, dim.z) * TILEWIDTH - Vector3.ONE * 0.005


# Returns what tiles the given orientation would occupy.
func tiles4(targetPosition: Vector3, targetRotation: Vector2, targetDimensions: Vector3):
	var occupation: Array = []
	# rotating dimensions if needed
	if targetRotation.y == 0:
		targetDimensions = Vector3(targetDimensions.z, targetDimensions.y, targetDimensions.x)
	# finding the coordinates for the top leftmost partition
	targetPosition -= (targetDimensions * 0.5).floor() * TILEWIDTH
	var offset = Vector3(1 - fmod(targetDimensions.x, 2), 0, 1 - fmod(targetDimensions.z, 2)) * TILEWIDTH * 0.5
	targetPosition += offset
	# finding the top leftmost partition
	var partition: Vector3 = (targetPosition / TILEWIDTH).floor()
	# offsetting and appending as many tiles as dimensions
	for x in range(targetDimensions.x):
		for z in range(targetDimensions.z):
			#occupation.append(partition + Vector3(x, 0, z))
			occupation.append(Vector2(partition.x, partition.z) + Vector2(x, z))
			#var tempValue: Vector2 = Vector2(targetPosition.x, targetPosition.z) + Vector2(x, z) * TILEWIDTH
			#tempValue = Vector2(stepify(tempValue.x, 0.1), stepify(tempValue.y, 0.1))
			#occupation.append(tempValue)
	return occupation


# Updates the shopping line for the open shopping screen.
func updateLine(item: Button):
	if open == null:
		return
	var mall: Dictionary = Economy.malls[open]
	var goods: Dictionary = mall["goods"]
	var itemName = item.get_node("Name").text
	if !goods.has(itemName):
		item.queue_free()
		selected = null
		return
	if filter != null && Economy.getType(itemName) != filter:
		item.queue_free()
		selected = null
		return
	var amount = Economy.getAmount(itemName, open)
	if amount <= 0:
		item.queue_free()
		selected = null
		return
	elif amount == INF:
		amount = "INF"
	else:
		amount = "x" + str(amount)
	item.get_node("Amount").text = amount
	var price = Economy.getPrice(itemName, open)
	item.get_node("Price").text = str(price) + CURRENCY
	if price > Economy.money:
		item.disabled = true
		if item == selected:
			deselect()
	else:
		item.disabled = false


# Updates the shopping list for the open shopping screen.
func updateList():
	if open == null:
		return
	var mall: Dictionary = Economy.malls[open]
	var goods: Dictionary = mall["goods"]
	var items: Dictionary = {}
	for item in list.get_children():
		var itemName = item.get_node("Name").text
		items[itemName] = null
		if !goods.has(itemName):
			item.queue_free()
			selected = null
			continue
		if filter != null && Economy.getType(itemName) != filter:
			item.queue_free()
			selected = null
			continue
		var amount = Economy.getAmount(itemName, open)
		if amount <= 0:
			item.queue_free()
			selected = null
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(itemName, open)
		item.get_node("Price").text = str(price) + CURRENCY
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false
	for good in goods.keys():
		if filter != null && Economy.getType(good) != filter:
			continue
		if items.has(good):
			continue
		var amount = Economy.getAmount(good, open)
		if amount <= 0:
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		var item = ITEM.instance()
		list.add_child(item)
		item.get_node("Name").text = good
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(good, open)
		item.get_node("Price").text = str(price) + CURRENCY
		item.get_node("Icon").texture = load(Economy.getIcon(good))
		item.connect("pressed", self, "pressed", [item])
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false


# Opens the given shop.
func openShop(shop: String):
	var selectedDeckNumber = GlobalObjectReferencer.cursor.selectedDeckNumber
	if selectedDeckNumber == -1:
		selectedDeckNumber = 0
		var theButton: TextureButton = get_parent().get_node("Decks").get_child(0).get_node("TextureButton")
		theButton.pressed = true
		GlobalObjectReferencer.playerShip.selectDeck(0)
		target = get_tree().get_nodes_in_group("PlayerDeck")[selectedDeckNumber]
	if open != null:
		closeShop()
	var mall: Dictionary = Economy.malls[shop]
	var index = 0
	for white in mall["white"]:
		var type = TYPE.instance()
		tabs.add_child(type)
		type.get_node("Name").text = white
		type.connect("pressed", self, "pressed", [type])
		if index == 0:
			type.pressed = true
			filter = type.get_node("Name").text
		index += 1
	var goods: Dictionary = mall["goods"]
	for good in goods.keys():
		if filter != null && Economy.getType(good) != filter:
			continue
		var amount = Economy.getAmount(good, shop)
		if amount <= 0:
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		var item = ITEM.instance()
		list.add_child(item)
		item.get_node("Name").text = good
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(good, shop)
		item.get_node("Price").text = str(price) + CURRENCY
		item.get_node("Icon").texture = load(Economy.getIcon(good))
		item.connect("pressed", self, "pressed", [item])
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false
	get_node("Shop").visible = true
	get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport/GameCamera").selectDeck(selectedDeckNumber)
	open = shop
	indicator.visible = true
	indicator.mouse_filter = Control.MOUSE_FILTER_STOP


# Closes any open shop.
func closeShop():
	GlobalObjectReferencer.cursor.selectedDeckNumber = -1
	var theButton: TextureButton = get_parent().get_node("Decks").get_child(0).get_node("TextureButton")
	theButton.pressed = false
	GlobalObjectReferencer.playerShip.selectDeck(-1)
	target = null
	if is_instance_valid(hologram) && is_instance_valid(parent):
		placeOrDestroyHologram()
	get_node("Shop").visible = false
	for item in list.get_children():
		item.queue_free()
		selected = null
	for type in tabs.get_children():
		type.queue_free()
	open = null
	deselect()
	return


# Called when an item is pressed on the shop.
func pressed(thing):
	if thing.get_node_or_null("Price") != null:
		if selected != null:
			destroyHologram()
		selected = thing
	else:
		for tab in tabs.get_children():
			if tab != thing:
				tab.pressed = false
			else:
				tab.pressed = true
		if filter == null || filter != thing.get_node("Name").text:
			filter = thing.get_node("Name").text
			if selected != null:
				destroyHologram()
			updateList()


# Deselects items.
func deselect():
	selected = null
	if resource != null:
		destroyHologram()


# Removes selected item from the open shop, and handles payment.
func purchase(node: Node):
	if open == null || selected == null:
		return
	var itemName = selected.get_node("Name").text
	node.name = itemName
	var itemPrice = float(selected.get_node("Price").text.rstrip(CURRENCY))
	Economy.money -= itemPrice
	var mall: Dictionary = Economy.malls[open]
	mall["goods"][itemName] -= 1
	mall["money"] += itemPrice
	updateList()


# Sells selected item to the open shop.
func sell():
	if hologram != null:
		if resource == null:
			var itemName: String = hologram.databaseName
			var mall: Dictionary = Economy.malls[open]
			var itemPrice = Economy.getPrice(itemName, open)
			if itemPrice <= mall["money"] && !mall["black"].has(itemName) && mall["white"].has(Economy.goods[itemName]["type"]):
				mall["money"] -= itemPrice
				mall["goods"][itemName] += 1
				Economy.money += itemPrice
				destroyHologram()
				updateList()

func _on_indicator():
	closeShop()
	indicator.visible = false
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
