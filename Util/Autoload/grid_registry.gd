extends Node

# key: tile coordinates, value: building node
var buildings: Dictionary = {}


func is_occupied(tile: Vector2) -> bool:
	return buildings.has(tile)

func register_building(tile: Vector2, building: Node2D) -> void:
	buildings[tile] = building

func unregister_building(tile: Vector2) -> void:
	buildings.erase(tile)

func get_building(tile: Vector2) -> Node2D:
	return buildings.get(tile)
