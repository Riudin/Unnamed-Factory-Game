extends GridContainer

signal building_selected(building)

func _on_slot_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var selected_building = $Slot1.get_current_building()
		building_selected.emit(selected_building)
	
	# get currently loaded building
	# mkae mouse build mode have that building


func _on_slot_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		print("slot 2 pressed!")
