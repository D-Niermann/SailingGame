extends Spatial

"""
Script on a spatial the moves environment audio sources with the camera, but keeps their height (water should be quite in the sky), and manages 
audio sources.
"""

var camera
var waterAudio # audio source player water
var windAudio # audio source player wind

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_viewport().get_camera()
	waterAudio = $WaterAudio
	windAudio = $WindAudio


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	## set the water audio source under the camera but at constant water height
	waterAudio.translation.x = camera.translation.x
	waterAudio.translation.y = 5
	waterAudio.translation.z = camera.translation.z

	## set the wind audio source under the camera but at constant wind height
	windAudio.translation.x = camera.translation.x
	windAudio.translation.y = 250
	windAudio.translation.z = camera.translation.z
	
