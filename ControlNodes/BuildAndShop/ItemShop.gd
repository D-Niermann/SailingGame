extends Control


const ITEM: PackedScene = preload("res://ControlNodes/BuildAndShop/Item.tscn")

var open = null
var type = "food"
var item = null
var types: Control
var items: HBoxContainer
var count: Label
var counter = 0
var balance: Label
var difference: Label
var credits: Label
var trade: Button
var barF: TextureProgress
var barM: TextureProgress
var barW: TextureProgress
var barG: TextureProgress


# Called when the node enters the scene tree for the first time.
func _ready():
	trade = $Info/Middle/Content/Lower/Trade
	types = $Menu/Types
	items = $Menu/Items/Scroller/Container
	count = $Info/Middle/Content/Upper/Cargo/Label
	balance = $Info/Middle/Content/Lower/BalanceValue
	difference = $Info/Middle/Content/Lower/AmountValue
	credits = $Info/Left/Content/Credits/Label
	barF = $Info/Left/Content/Sliders/BarF
	barM = $Info/Left/Content/Sliders/BarM
	barW = $Info/Left/Content/Sliders/BarW
	barG = $Info/Left/Content/Sliders/BarG
	$Menu/Types/Food.connect("pressed", self, "_on_press_type", [Economy.IG_FOOD])
	$Menu/Types/Materials.connect("pressed", self, "_on_press_type", [Economy.IG_UTILITY])
	$Menu/Types/Weapons.connect("pressed", self, "_on_press_type", [Economy.IG_AMMO])
	$Info/Middle/Content/Upper/Buy/One.connect("pressed", self, "_on_press_swap", [1])
	$Info/Middle/Content/Upper/Buy/More.connect("pressed", self, "_on_press_swap", [10])
	$Info/Middle/Content/Upper/Buy/All.connect("pressed", self, "_on_press_swap", [INF])
	$Info/Middle/Content/Upper/Sell/One.connect("pressed", self, "_on_press_swap", [-1])
	$Info/Middle/Content/Upper/Sell/More.connect("pressed", self, "_on_press_swap", [-10])
	$Info/Middle/Content/Upper/Sell/All.connect("pressed", self, "_on_press_swap", [-INF])
	$Info/Middle/Content/Lower/Trade.connect("pressed", self, "_on_press_trade")
	GlobalObjectReferencer.itemShop = self
	#openShop("bananaConsumables") # remove this line later on, this is for testing purposes only


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# Opens the given shop.
func openShop(name: String):
	GlobalObjectReferencer.navGUI.visible = false
	closeShop()
	if Economy.cmalls.has(name):
		open = name
		visible = true
		mouse_filter = MOUSE_FILTER_STOP
		refreshInventory()
		refreshTemporary()


# Lists inventory of the open shop for the selected type of items.
func refreshInventory():
	for item in items.get_children():
		item.queue_free()
	if open == null:
		return
	var goods: Array = Economy.cmalls[open].goods
	for good in goods:
		var info = Economy.consumables[good]
		if info.GG != type && (info.GG != Economy.IG_GUNPOWDER || type != "igAmmo"):
			continue
		var newItem: Button = ITEM.instance()
		items.add_child(newItem)
		newItem.get_node("Name").text = good
		newItem.get_node("Amount").text = str(GlobalObjectReferencer.crewManager.getAmount(good)) + " / " + str(GlobalObjectReferencer.crewManager.getCapacity(info.GG))
		if info.icon != null:
			newItem.get_node("Icon").texture = load(info.icon)
		newItem.connect("pressed", self, "_on_press_item", [good])


# Closes the opened shop.
func closeShop():
	if open != null:
		GlobalObjectReferencer.navGUI.visible = true
		open = null
		visible = false
		mouse_filter = MOUSE_FILTER_IGNORE
		refreshInventory()
		refreshTemporary()


func _on_press_type(pressed: String):
	if type != pressed:
		type = pressed
		item = null
		refreshInventory()
		refreshTemporary()


func _on_press_item(pressed: String):
	if item != pressed:
		item = pressed
		counter = GlobalObjectReferencer.crewManager.getAmount(item)
		refreshTemporary()


func _on_press_swap(pressed):
	if item != null:
		# counter = clamp(counter + pressed, 0, 10) # remove this later, and activate what's below instead, this one is for testing
		counter = clamp(counter + pressed, 0, GlobalObjectReferencer.crewManager.getCapacity(Economy.getGG(item)))
		refreshTemporary()


func _on_press_trade():
	if item != null:
		var amount = counter - GlobalObjectReferencer.crewManager.getAmount(item)
		if amount != 0:
			var diff = (counter - GlobalObjectReferencer.crewManager.getAmount(item)) * Economy.consumables[item].price
			Economy.money -= diff
			GlobalObjectReferencer.crewManager.tradeGood(amount, item)
			counter = GlobalObjectReferencer.crewManager.getAmount(item)
			refreshTemporary()
			refreshInventory()


func refreshTemporary():
	credits.text = str(Economy.money)
	if item != null:
		var info = Economy.consumables[item]
		count.text = str(counter) + " / " + str(GlobalObjectReferencer.crewManager.getCapacity(info.GG))
		var diff = (counter - GlobalObjectReferencer.crewManager.getAmount(item))
		difference.text = str(int(diff))
		diff *= Economy.consumables[item].price
		balance.text = str(int(diff * -1))
		if difference.text == "0":
			trade.disabled = true
			balance.add_color_override("font_color", Color(1,1,1,1))
		elif Economy.money < diff:
			trade.disabled = true
			balance.add_color_override("font_color", Color(1,0,0,1))
		else:
			trade.disabled = false
			balance.add_color_override("font_color", Color(1,1,1,1))
	else:
		count.text = ""
		balance.text = "0"
		trade.disabled = true
		balance.add_color_override("font_color", Color(1,1,1,1))
	# Setting sliders here
	barF.max_value = GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD)
	barF.value = GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_FOOD)
	if GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD) == 0:
		barF.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		barF.modulate = Color(1, 1, 1, 1)
	barM.max_value = GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_UTILITY)
	barM.value = GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_UTILITY)
	if GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD) == 0:
		barM.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		barM.modulate = Color(1, 1, 1, 1)
	barW.max_value = GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_AMMO)
	barW.value = GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_AMMO)
	if GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD) == 0:
		barW.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		barW.modulate = Color(1, 1, 1, 1)
	barG.max_value = GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_GUNPOWDER)
	barG.value = GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_GUNPOWDER)
	if GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD) == 0:
		barG.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		barG.modulate = Color(1, 1, 1, 1)


func _on_Exit_pressed():
	closeShop()
