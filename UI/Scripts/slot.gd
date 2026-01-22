extends PanelContainer


@export var building_texture: TextureRect
@export var selection_highlight: NinePatchRect

@export var stored_building: PackedScene


func _process(_delta: float) -> void:
	if stored_building and str(stored_building) == BuildingHandler.current_building_path:
		selection_highlight.visible = true
	else:
		selection_highlight.visible = false
