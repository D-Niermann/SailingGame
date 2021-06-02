extends Node

#Vars
#Constants and nodes
const dayTime = 60 * 5 #time per day(+ night) in seconds
const daysPerSeason = 10 #days per season
onready var sun = get_node("../SunLight")
 
#Day/Time/Seasons
var time = 0 #Time since game start
var day = 0
var sunX : float
var sunY : float
var season = {
	0 : "summer",
	1 : "spring",
	2 : "autumn",
	3 : "winter" 
}
var currentSeason : String
var seasonId : int

#Sun/Sunlight/Wind
var lightDirection : Vector3
var windDirection : Vector2 # NOT YET IMPLEMENTED
var shadowIntensity : float

#Storms NOT YET IMPLEMENTED
enum storm {
	Clear,
	Starting,
	Ongoing,
	Dissipating
}
var stormState : String
var stormRng = RandomNumberGenerator.new()
var startTime : float
var endTime : float


#Functions
func _process(delta):
	time_and_day(delta)
	light_orientation()
	night_shadow_intensity(PI/2-sunX)

func _is_storm_day():
	stormRng.randf()
	if stormRng > 0.8:
		return true
	else:
		return false

func _storm_time():
	startTime = stormRng.randf_range(0, dayTime)
# warning-ignore:integer_division
# warning-ignore:integer_division
	endTime = startTime + stormRng.randf_range(dayTime/10, dayTime/2)
	return [startTime, endTime]

func time_and_day(delta):
	time += delta
#	if day != int(time / dayTime) and _is_storm_day():
#		stormRng.randomize()
#		_storm_time() #Implementing/To be implemented
	day = int(time / dayTime)
	seasonId = (day / daysPerSeason) % 4
	currentSeason = season[seasonId]

func light_orientation(): #light orientation (angle)
	sunX = -80 * sin(2*PI/dayTime*time)
	sunY = 100 * cos(2*PI/dayTime*time) - 140 # 90*...-135 for correct model, this looks better I think
	sun.set_rotation(Vector3(deg2rad(sunX), deg2rad(sunY), 0))

func night_shadow_intensity(sunAngle): # for indirect light and shadows as the day ends
	shadowIntensity = 1.0-(abs(90.0-sunAngle)/90.0)
	sun.light_energy = shadowIntensity
