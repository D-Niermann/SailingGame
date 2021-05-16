extends Spatial

#Vars
#Constants
const dayTime = 60 * 5 #time per day(+ night) in seconds
const daysPerSeason = 10 #days per season
 
#Day/Time/Seasons
var time : float
var day : int
enum season{
	summer=0,
	spring=1,
	autumn=2,
	winter=3 
}
var currentSeason : String

#Sun/Sunlight/Wind
var lightDirection = Vector2(0, 0)
var windDirection = Vector2(0, 0)
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
	sun_position()

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
	var i = (day / daysPerSeason) % 4
	currentSeason = season[i]

func _seasonal_sun_position(): #light orientation due to season NOT COMPLETE
	var sunMaxHeight
	var sunYRotation
	return Vector2(sunMaxHeight, sunYRotation)

func _time_sun_position(): #light orientation due to time of day
	var currentTime = time - (day*dayTime)
# warning-ignore:integer_division
	var sunPath = 360/dayTime
	var seasonalSunPosition = _seasonal_sun_position()
	var sunX = fmod(sunPath * currentTime, seasonalSunPosition.x)
	var sunY = seasonalSunPosition.y
	return Vector2(sunX, sunY)

func sun_position():
	pass

func night_shadow_intensity(sunAngle): # for indirect light and shadows
	var sunImpact = 1.0-(abs(90.0-sunAngle)/90.0)
	shadowIntensity = sunImpact
	return shadowIntensity
