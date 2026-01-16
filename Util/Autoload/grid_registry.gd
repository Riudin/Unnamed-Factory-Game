extends Node

# key: tile coordinates, value: building node
var buildings: Dictionary = {}


func is_occupied(tile: Vector2i) -> bool:
	return buildings.has(tile)

func register_building(tile: Vector2i, building: Node2D) -> void:
	buildings[tile] = building

func unregister_building(tile: Vector2i) -> void:
	buildings.erase(tile)

func get_building(tile: Vector2i) -> Node2D:
	return buildings.get(tile)
