extends Control

var open = null
var count: Label
var counter = 0
var tavern: Label
var balance: Label
var difference: Label
var credits: Label
var handshake: Button


# Called when the node enters the scene tree for the first time.
func _ready():
	tavern = $Left/Content/Lower/TavernValue
	handshake = $Left/Content/Lower/Handshake
	count = $Left/Content/Upper/Crew/Label
	balance = $Left/Content/Lower/CostValue
	difference = $Left/Content/Lower/TotalValue
	credits = $Left/Content/Lower/CreditsValue
	$Left/Content/Upper/Hire/One.connect("pressed", self, "_on_press_swap", [1])
	$Left/Content/Upper/Hire/More.connect("pressed", self, "_on_press_swap", [10])
	#$Left/Content/Upper/Hire/All.connect("pressed", self, "_on_press_swap", [INF])
	$Left/Content/Upper/Fire/One.connect("pressed", self, "_on_press_swap", [-1])
	$Left/Content/Upper/Fire/More.connect("pressed", self, "_on_press_swap", [-10])
	#$Left/Content/Upper/Fire/All.connect("pressed", self, "_on_press_swap", [-INF])
	handshake.connect("pressed", self, "_on_press_handshake")
	GlobalObjectReferencer.tavern = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# Opens the given shop.
func openShop(name: String):
	GlobalObjectReferencer.navGUI.visible = false
	closeShop()
	if Economy.taverns.has(name):
		counter = GlobalObjectReferencer.crewManager.getCrewCount()
		open = name
		visible = true
		mouse_filter = MOUSE_FILTER_STOP
		refreshTemporary()


# Closes the opened shop.
func closeShop():
	if open != null:
		GlobalObjectReferencer.navGUI.visible = true
		open = null
		visible = false
		mouse_filter = MOUSE_FILTER_IGNORE
		# refreshTemporary()


func _on_press_swap(pressed):
	var amount = counter - GlobalObjectReferencer.crewManager.getCrewCount()
	amount = clamp(amount + pressed, -INF, Economy.taverns[open]["crew"]) - amount
	counter = clamp(counter + amount, 0, 100) # remove this later, and activate what's below instead, this one is for testing
	#counter = clamp(counter + pressed, 0, GlobalObjectReferencer.crewManager.getCapacity(Economy.getGG(item)))
	refreshTemporary()


func _on_press_handshake():
	var amount = counter - GlobalObjectReferencer.crewManager.getCrewCount()
	if amount != 0:
		var diff = (counter - GlobalObjectReferencer.crewManager.getCrewCount()) * 100;
		diff = clamp(diff, 0, INF);
		Economy.money -= diff
		if amount < 0:
			GlobalObjectReferencer.crewManager.fire(amount)
		else:
			GlobalObjectReferencer.crewManager.hire(amount)
		Economy.taverns[open]["crew"] -= amount
		counter = GlobalObjectReferencer.crewManager.getCrewCount()
		refreshTemporary()


func refreshTemporary():
	credits.text = str(Economy.money)
	count.text = str(counter) + " / " + "100" #str(GlobalObjectReferencer.crewManager.getCapacity(info.GG))
	var diff = (counter - GlobalObjectReferencer.crewManager.getCrewCount())
	tavern.text = str(Economy.taverns[open]["crew"] - diff)
	difference.text = str(int(diff))
	diff = clamp(diff, 0, INF)
	diff *= 100
	balance.text = str(int(diff * -1))
	if difference.text == "0":
		handshake.disabled = true
		balance.add_color_override("font_color", Color(1,1,1,1))
	elif Economy.money < diff:
		handshake.disabled = true
		balance.add_color_override("font_color", Color(1,0,0,1))
	else:
		handshake.disabled = false
		balance.add_color_override("font_color", Color(1,1,1,1))


func _on_Exit_pressed():
	closeShop()
