extends PanelContainer

@export var current_building: buildings : get = get_current_building

enum buildings {DRILL, BELT, CONTAINER, FORGE}


func get_current_building():
	return current_building
