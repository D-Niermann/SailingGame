extends Spatial

"""
base Script on each human. maybe other special humans like officers can inherit from this.
"""
## stati
var S_TIRED =  false # too tired to work
var S_DRUNK =  false# too drunk to work
var S_HUNGRY = false # too hungry
var S_THIRSTY = false # too thirsty
var S_WOUNDED =  false # too wounded - needs to go to doctor

var status 
func _ready():
	pass


	