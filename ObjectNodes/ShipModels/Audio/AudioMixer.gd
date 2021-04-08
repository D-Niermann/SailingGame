extends Spatial


var players 
var _timer
export var prob_thresh = 1.0 # 0.7 = 70% probability of playing a sound per frame
export var update_frequ_sec = 1.0
export var pitch_min = 0.8
export var pitch_max = 1.0
func _ready():
	players = get_children()
	_timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(update_frequ_sec)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()


# only run this every update_frequ_sec seconds
func _on_Timer_timeout():
	for i in range(players.size()):
		if !players[i].playing and rand_range(0,1)<prob_thresh:
			players[i].set_pitch_scale(rand_range(pitch_min, pitch_max))
			players[i].playing = true
