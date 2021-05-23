extends Control


func _ready():
	pass

func _on_wind_speed_value_changed(value):
	GlobalObjectReferencer.ocean.set_wind_strength(value)

func _on_water_style_value_changed(value):
	GlobalObjectReferencer.ocean.set_water_style(value)

func _on_subsurface_scattering_value_changed(value):
	GlobalObjectReferencer.ocean.set_subsurface_scattering(value)

func _on_sun_glare_value_changed(value):
	GlobalObjectReferencer.ocean.sunLight.speedMod = value

func _on_CheckButton_toggled(state:bool):
	# var NPCships = get_tree().get_nodes_in_group("NPCShip")
	# for i in range(NPCships.size()):
	# 	NPCships[i].get_node("AIController").isActive = state
	pass

func _on_WeaponSlider_value_changed(val):
	GlobalObjectReferencer.crewManager.setCrewCount(Economy.TG_WEAPONS, val)

func _on_NavSlider_value_changed(val):
	GlobalObjectReferencer.crewManager.setCrewCount(Economy.TG_NAVIGATION, val)

func _on_UtilsSlider_value_changed(val):
	GlobalObjectReferencer.crewManager.setCrewCount(Economy.TG_UTILITY, val)
