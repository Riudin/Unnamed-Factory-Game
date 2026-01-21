extends Node


var show_advanced_building_info: bool = false: set = set_show_advanced_building_info

signal show_advanced_building_info_toggled

func set_show_advanced_building_info(toggle: bool):
	show_advanced_building_info = toggle
	emit_signal("show_advanced_building_info_toggled")