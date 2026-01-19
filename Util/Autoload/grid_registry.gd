extends Node

# key: tile coordinates, value: building node
var buildings: Dictionary = {}
var preview_buildings: Dictionary = {}


func is_occupied(tile: Vector2i, check_previews: bool = false) -> bool:
	var occupied: bool = false

	if buildings.has(tile):
		occupied = true
	if check_previews and preview_buildings.has(tile):
		occupied = true
		
	return occupied

func register_building(tile: Vector2i, building: Node2D, ) -> void:
	buildings[tile] = building

func register_preview_building(tile: Vector2i, building: Node2D) -> void:
	preview_buildings[tile] = building

func unregister_building(tile: Vector2i) -> void:
	buildings.erase(tile)

func unregister_preview_building(tile: Vector2i) -> void:
	preview_buildings.erase(tile)

func get_building(tile: Vector2i) -> Node2D:
	return buildings.get(tile)

func get_preview_building(tile: Vector2i) -> Node2D:
	return preview_buildings.get(tile)
