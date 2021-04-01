extends Control


var time: int = 0
var frac: float = 0.0
var updatePeriodForEconomy: float = 60.0
var placementHandler: Control


# Called when the node enters the scene tree for the first time.
func _ready():
	placementHandler = get_tree().get_root().get_node("Terminal/Interface/Shopping")
	# TODO: some code to initiate stuff for testing purposes, can be removed later on
	placementHandler.target = get_tree().get_root().get_node("Terminal/ViewportContainer/Viewport/Spatial/Ship")
	placementHandler.openShop("bananaTown")


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
