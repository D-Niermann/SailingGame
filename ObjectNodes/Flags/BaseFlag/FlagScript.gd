extends Spatial

var rand_time_offset = 0.0

func _ready():
	rand_time_offset = rand_range(0,99) # if max rand number is around PI, the difference in the shaders is not that big, set to inf and diff is also maximum possible
	$Flag.material_override.set_shader_param("time_offset", rand_time_offset)
