extends Node2D

var building_mode = false

func enter_building_mode(building):
	building_mode = true
	print("now building" + str(building))


func _on_tool_bar_building_selected(building: Variant) -> void:
	enter_building_mode(building)
