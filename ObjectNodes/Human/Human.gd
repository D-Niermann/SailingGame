extends KinematicBody
class_name Human
"""
base Script on each human. maybe other special humans like officers can inherit from this.
gets controlled by crew manager, only feature is that he gets a target position and walks there, maybe later adding stamina and so on, but that can be done in crew manager too
"""

export var InfoPanel: PackedScene # scene object of cannons info ui panel

## stati
const S_TIRED = "S_TIRED"  # too tired to work
const S_DRUNK = "S_DRUNK" # too drunk to work
const S_HUNGRY = "S_HUNGRY" # too hungry
const S_THIRSTY = "S_THIRSTY" # too thirsty
const S_WOUNDED = "S_WOUNDED"  # too wounded - needs to go to doctor

var itemID = null # ref to the curernt item the human is working
var jobID = null # ref to the curernt item the human is working
var stati = [] #keeps track of all stati (stati = [S_Hungry, S_THIRSTY, ...]) 
var targetPos = Vector3.ZERO
var currentDeck = 0
var bodyHeight = 0.05
# var currentTaskGroup = null
var isHuman = true # flag for shopping script to see if this kin body is human
var infoPanel
# var isAssigned = false
var id
var currentTask


func _ready():
	targetPos.x += rand_range(-0.3,0.3)
	targetPos.z += rand_range(-0.3,0.3)
	id = IDGenerator.getID()

func assignDeck(deckRef):
	get_parent().remove_child(self)
	deckRef.add_child(self)

func giveGoToTask(task):
	"""
	gives a task
	"""
	currentTask = task
	targetPos = task.position
	self.itemID = task.itemID
	self.jobID = task.jobID
	# currentTaskGroup = TG

func removeTarget():
	# targetPos = (target_position)
	self.itemID = null
	currentTask = null
	self.jobID = null
	targetPos = Vector3.ZERO
	targetPos.x += rand_range(-0.3,0.3)
	targetPos.z += rand_range(-0.3,0.3)
	
func walkTowards(targetPos : Vector3):
	""" for now some simple function, later will use navmesh """
	self.translation += (targetPos-self.translation)*0.01
	self.translation.y = bodyHeight

func _process(delta):
	walkTowards(targetPos)



func createInfo(placeholder):
	"""
	Overwrites in inherited item classes.
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
	Overwrites in inherited item classes.
	removes info panel again
	"""
	if infoPanel!=null:
		infoPanel.queue_free()
