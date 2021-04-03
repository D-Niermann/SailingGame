extends Control

var ocean = null

func _ready():
	if get_tree().get_nodes_in_group("Ocean").size()>0:
		ocean = get_tree().get_nodes_in_group("Ocean")[0]

func _on_wind_speed_value_changed(value):
	ocean.set_wind_strength(value)

func _on_water_style_value_changed(value):
	ocean.set_water_style(value)

func _on_subsurface_scattering_value_changed(value):
	ocean.set_subsurface_scattering(value)

func _on_sun_glare_value_changed(value):
	pass
	#get_tree().get_nodes_in_group("Light")[0].time = value