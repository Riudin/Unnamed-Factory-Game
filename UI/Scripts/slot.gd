extends PanelContainer

@export var building_texture: TextureRect
@export var selection_highlight: NinePatchRect

var stored_building_key: String = "" # "conveyor_belt", "giver", "trash", etc


func _ready() -> void:
    pass


func _process(_delta: float) -> void:
    # Update highlight based on current building in building_handler
    if stored_building_key and stored_building_key == get_building_key_from_path(BuildingHandler.current_building_path):
        selection_highlight.visible = true
    else:
        selection_highlight.visible = false


func set_building(building_key: String) -> void:
    # Set which building this slot stores and update the display
    if building_key not in BuildingHandler.buildings and building_key != "":
        push_error("Building key '%s' not found in BuildingHandler" % building_key)
        return
    
    stored_building_key = building_key
    update_display()


func update_display() -> void:
    # Update the displayed icon based on stored_building_key
    if stored_building_key == "":
        building_texture.texture = null
        return
    
    var icon = BuildingHandler.get_building_icon(stored_building_key)
    if icon:
        building_texture.texture = icon
    else:
        push_warning("No icon found for building: %s" % stored_building_key)


func get_building_key_from_path(path: String) -> String:
    # Convert a scene path back to building key.
    for key in BuildingHandler.buildings:
        if BuildingHandler.buildings[key] == path:
            return key
    return ""