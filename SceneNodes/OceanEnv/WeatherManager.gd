extends Spatial

#Vars
#Constants
const dayTime = 60 * 5 #time per day(+ night) in seconds
const daysPerSeason = 10 #days per season
 
#Day/Time/Seasons
var time : float
var day : int
var season = {
	0 : "summer",
	1 : "spring",
	2 : "autumn",
	3 : "winter" 
}
var currentSeason : String
var seasonId : int

#Sun/Sunlight/Wind
var lightDirection : Vector2
var windDirection : Vector2
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
var stormTime


func _process(delta):
	time_and_day(delta)
	lightDirection = sun_position()

func _is_storm_day():
	stormRng.randf()
	if stormRng > 0.8:
		return true
	else:
		return false

func _storm_time():
	var start_time = stormRng.randf_range(0, dayTime)
# warning-ignore:integer_division
# warning-ignore:integer_division
	var end_time = start_time + stormRng.randf_range(dayTime/10, dayTime/5)
	return [start_time, end_time]

func time_and_day(delta):
	time += delta
	if day != int(time / dayTime) and _is_storm_day():
		stormRng.randomize()
		stormTime = _storm_time()
	day = int(time / dayTime)
# warning-ignore:integer_division
	seasonId = (day / daysPerSeason) % 4
	currentSeason = season[seasonId]

func sun_position(): #light orientation due to time of day
	var currentTime = time - (day*dayTime)
# warning-ignore:integer_division
	var sunX = -80.0 * sin(PI*dayTime*currentTime)
	var sunY = -45 - 90 * (currentTime/(dayTime/4)) * (seasonId-2)/abs(seasonId-2)
	return Vector2(sunX, sunY)

func night_shadow_intensity(sunAngle): # for indirect light and shadows
	var sunImpact = 1.0-(abs(90.0-sunAngle)/90.0)
	shadowIntensity = sunImpact
	return shadowIntensity
