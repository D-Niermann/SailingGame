extends "res://ObjectNodes/Items/BaseItem.gd"

export var InfoPanel: PackedScene # scene object of cannons info ui panel
var isLeaking = false 
var leakHealth = 5 #threshold under which leaking starts

var infoPanel

func _ready():
	maxHealth = 10
	currentHealth = maxHealth


func _physics_process(delta):
	if isLeaking:
		myShip.fillWater(0.01*delta)

# overwrite base function for extra stuff
func giveDmg(damage : float):
	.giveDmg(damage) # call parent function
	## extras
	if currentHealth<leakHealth:
		isLeaking = true
		if myShip.isPlayer: # only make particle effects if ship is player
			if $WaterLeakParticles!=null:
				$WaterLeakParticles.emitting = true
			if $WaterLeakParticles2!=null:
				$WaterLeakParticles2.emitting = true
			if $WaterLeakParticles3!=null:
				$WaterLeakParticles3.emitting = true
	

func createInfo(placeholder):
	"""
	Instances the correponding item info panel and moves it to placeholder.rect_position.
	The instanced info box connects to this item and communicates user input and item stati.
	"""
	if InfoPanel!=null:
		## instance panel
		infoPanel = InfoPanel.instance()
		infoPanel.visible = false
		infoPanel.positionRef = placeholder
		self.add_child(infoPanel)
		infoPanel.rect_position = placeholder.rect_position

		## link self to panel, enables info access
		infoPanel.link(self)

		## make panel visible
		infoPanel.visible = true

func removeInfo():
	"""
	removes info panel again
	"""
	if infoPanel!=null:
		infoPanel.queue_free()

