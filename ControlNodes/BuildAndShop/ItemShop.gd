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
var credits: Label
var trade: Button


# Called when the node enters the scene tree for the first time.
func _ready():
	trade = $Info/Middle/Content/Lower/Trade
	types = $Menu/Types
	items = $Menu/Items/Scroller/Container
	count = $Info/Middle/Content/Upper/Amount/Label
	balance = $Info/Middle/Content/Lower/BalanceValue
	credits = $Info/Left/Content/Credits/Label
	$Menu/Types/Food.connect("pressed", self, "_on_press_type", ["food"])
	$Menu/Types/Materials.connect("pressed", self, "_on_press_type", ["material"])
	$Menu/Types/Weapons.connect("pressed", self, "_on_press_type", ["weapon"])
	$Info/Middle/Content/Upper/Buy/One.connect("pressed", self, "_on_press_swap", [1])
	$Info/Middle/Content/Upper/Buy/More.connect("pressed", self, "_on_press_swap", [10])
	$Info/Middle/Content/Upper/Buy/All.connect("pressed", self, "_on_press_swap", [INF])
	$Info/Middle/Content/Upper/Sell/One.connect("pressed", self, "_on_press_swap", [-1])
	$Info/Middle/Content/Upper/Sell/More.connect("pressed", self, "_on_press_swap", [-10])
	$Info/Middle/Content/Upper/Sell/All.connect("pressed", self, "_on_press_swap", [-INF])
	$Info/Middle/Content/Lower/Trade.connect("pressed", self, "_on_press_trade")
	openShop("bananaConsumables") # remove this line later on, this is for testing purposes only


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# Opens the given shop.
func openShop(name: String):
	closeShop()
	if Economy.cmalls.has(name):
		open = name
		visible = true
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
		if info.type != type:
			continue
		var newItem: Button = ITEM.instance()
		items.add_child(newItem)
		newItem.get_node("Name").text = good
		newItem.get_node("Amount").text = str(GlobalObjectReferencer.crewManager.getAmount(good)) + " / " + str(GlobalObjectReferencer.crewManager.getCapacity(good))
		if info.icon != null:
			newItem.get_node("Icon").texture = load(info.icon)
		newItem.connect("pressed", self, "_on_press_item", [good])


# Closes the opened shop.
func closeShop():
	if open != null:
		open = null
		visible = false
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
		#counter = clamp(counter + pressed, 0, 10) # remove this later, and activate what's below instead, this one is for testing
		counter = clamp(counter + pressed, 0, GlobalObjectReferencer.crewManager.getCapacity(item))
		refreshTemporary()


func _on_press_trade():
	if item != null:
		var amount = counter - GlobalObjectReferencer.crewManager.getAmount(item)
		if amount != 0:
			var difference = (counter - GlobalObjectReferencer.crewManager.getAmount(item)) * Economy.consumables[item].price
			Economy.money -= difference
			GlobalObjectReferencer.crewManager.tradeGood(amount, item)
			counter = GlobalObjectReferencer.crewManager.getAmount(item)
			refreshTemporary()
			refreshInventory()


func refreshTemporary():
	credits.text = str(Economy.money)
	if item != null:
		count.text = str(counter) + " / " + str(GlobalObjectReferencer.crewManager.getCapacity(item))
		var difference = (counter - GlobalObjectReferencer.crewManager.getAmount(item)) * Economy.consumables[item].price
		balance.text = str(int(difference * -1))
		if Economy.money < difference:
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
