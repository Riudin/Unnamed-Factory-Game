extends GridContainer

@export var slot1: PanelContainer
@export var slot2: PanelContainer
@export var slot3: PanelContainer
@export var slot4: PanelContainer
@export var slot5: PanelContainer
@export var slot6: PanelContainer
@export var slot7: PanelContainer
@export var slot8: PanelContainer

func _ready() -> void:
	slot1.set_building("conveyor_belt")
	slot2.set_building("giver")
	slot3.set_building("trash")
	slot4.set_building("splitter")


''' OLD
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
'''