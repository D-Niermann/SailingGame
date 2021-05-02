extends Node

var danger := 0.0


func _on_menu_pressed():
	if $MixingDeskMusic.current_song_num == 1:
		$MixingDeskMusic.queue_bar_transition('menu')

func _on_ingame_pressed():
	if $MixingDeskMusic.current_song_num == 0:
		$MixingDeskMusic.queue_bar_transition('main')


func _on_HSlider_value_changed(value):
	danger = value
