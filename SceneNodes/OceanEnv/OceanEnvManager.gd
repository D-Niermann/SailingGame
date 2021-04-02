extends Spatial

export(float) var wind_strength = 0.5 setget set_wind_strength

var time = 0.0
var wind_modified = 1.0

var visual_material
var physical_material

var gerstner_height
var gerstner_normal
var gerstner_stretch
var gerstner_2_height
var gerstner_2_normal
var gerstner_2_stretch
var bubble_amount
var foam_amount
var bubble_gerstner
var foam_gerstner
var detail_normal_intensity

var shift_vector
var curl_strength


var image
var data
var imgToWorld = 4 # if gerstner tiling = 1, the height map has size 4x4 units in global world coords
var gerstner_tiling1
var gerstner_tiling2
var imSize = 1024.0 # size in px of the height map
var gerstner_speed1 = Vector2(0.01, 0.014)
var gerstner_speed2 = Vector2(0.007,0.01)
func _ready():
	## load the image
	## Warning: the shader and the get_pixel() functions have different origin definitions (top-left vs bottom left) the this image needs to be flipped!
	image = load("res://SceneNodes/OceanEnv/Textures/gerstner_height_get_height.jpg")
	data = image.get_data()
	data.lock()

	visual_material = $waterplane.material_override
	physical_material = $render_targets/vector_map_buffer/image.material
	
	gerstner_height = visual_material.get_shader_param("gerstner_height")
	gerstner_normal = visual_material.get_shader_param("gerstner_normal")
	gerstner_stretch = visual_material.get_shader_param("gerstner_stretch")
	gerstner_2_height = visual_material.get_shader_param("gerstner_2_height")
	gerstner_2_normal = visual_material.get_shader_param("gerstner_2_normal")
	gerstner_2_stretch = visual_material.get_shader_param("gerstner_2_stretch")
	bubble_amount = visual_material.get_shader_param("bubble_amount")
	foam_amount = visual_material.get_shader_param("foam_amount")
	detail_normal_intensity = visual_material.get_shader_param("detail_normal_intensity")
	bubble_gerstner = visual_material.get_shader_param("bubble_gerstner")
	foam_gerstner = visual_material.get_shader_param("foam_gerstner")
	

	gerstner_tiling1 = visual_material.get_shader_param("gerstner_tiling")
	gerstner_tiling2 = visual_material.get_shader_param("gerstner_2_tiling")


	shift_vector = physical_material.get_shader_param("shift_vector")
	curl_strength = physical_material.get_shader_param("curl_strength")




func update_water(wind):
	visual_material.set_shader_param("gerstner_height", gerstner_height * wind)
	visual_material.set_shader_param("gerstner_normal", gerstner_normal * wind)
	# visual_material.set_shader_param("gerstner_stretch", gerstner_stretch * wind)
	visual_material.set_shader_param("gerstner_2_height", gerstner_2_height * wind)
	visual_material.set_shader_param("gerstner_2_normal", gerstner_2_normal * wind)
	# visual_material.set_shader_param("gerstner_2_stretch", gerstner_2_stretch * wind)
	visual_material.set_shader_param("bubble_amount", bubble_amount * wind)
	visual_material.set_shader_param("foam_amount", foam_amount * wind)
	visual_material.set_shader_param("detail_normal_intensity", detail_normal_intensity * wind)
	visual_material.set_shader_param("bubble_gerstner", bubble_gerstner * wind)
	visual_material.set_shader_param("foam_gerstner", foam_gerstner * wind)
	
	physical_material.set_shader_param("shift_vector", shift_vector * wind)
	physical_material.set_shader_param("curl_strength", curl_strength * clamp(wind, 1.0, 1.2))

func set_wind_strength(value):
	wind_strength = value

func get_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	return files

func set_water_style(value):
	var style_path = "res://textures/water/gradients"
	var style_list = get_files_in_directory(style_path)
	var gradient = GradientTexture.new()
	
	gradient.gradient = load(style_path + "/" + style_list[value])
	visual_material.set_shader_param("water_color", gradient)
	
func set_subsurface_scattering(value):
	visual_material.set_shader_param("sss_strength", value);

func _physics_process(delta):
	
	## ocean movement
	visual_material.set_shader_param("time", time)
	visual_material.set_shader_param("gerstner_speed", gerstner_speed1) 
	visual_material.set_shader_param("gerstner_2_speed", gerstner_speed2)
	time += delta
	wind_modified = wind_modified + ((wind_strength + sin(time) * 0.2) - wind_modified) * delta * 0.5
	
	# DEBUG WIND VAR
	# print(wind_modified)
	
	update_water(wind_modified)

func getWaterHeight(position : Vector3):
	## i think for negative values the pos needs to be flipped somehow
	var pos2d : Vector2 = Vector2(position.x, position.z)
	var pxPos1 : Vector2 = imSize * pos2d/imgToWorld*gerstner_tiling1 # pixel postion on the height map (ony use x and z!)
	var pxPos2 : Vector2 = imSize * pos2d/imgToWorld*gerstner_tiling2
	# print(pxPos1)
	## pixel gerstenr 1
	var px_x1 = int(fmod(pxPos1.x + gerstner_speed1.x*time*imSize, imSize))#,imSize)
	var px_y1 = int(fmod(-(pxPos1.y + gerstner_speed1.y*time*imSize) , imSize))#,imSize)
	## mirror for negative values
	if px_x1<0:
		px_x1 = abs(abs(px_x1)-imSize)
	if px_y1<0:
		px_y1 = abs(abs(px_y1)-imSize)

	## pixel gerstner 2
	var px_x2 = int(fmod(pxPos2.x + gerstner_speed2.x*time*imSize, imSize))#,imSize)
	var px_y2 = int(fmod(-(pxPos2.y + gerstner_speed2.y*time*imSize), imSize))#,imSize)
	## mirror for negative values
	if px_x2<0:
		px_x2 = abs(abs(px_x2)-imSize)
	if px_y2<0:
		px_y2 = abs(abs(px_y2)-imSize)
		
	var h1 = gerstner_height * wind_modified * pow(data.get_pixel(px_x1, px_y1)[0],1) ## TODO add gerstern height
	var h2 = gerstner_2_height * wind_modified * pow(data.get_pixel(px_x2, px_y2)[0],0.5)
	# print("px: ", px_x1,",",px_y1)
	var h_target = h1 + h2 ## TODO measure the actual height
	return h_target


func _notification(what): 
	if what == NOTIFICATION_PREDELETE: 
		data.unlock()
		pass
