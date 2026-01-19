class_name Building
extends Node2D


var tile_coordinates: Vector2i
var from_direction: Vector2i = Vector2i.LEFT
var to_direction: Vector2i = Vector2i.RIGHT

func register(preview: bool = false):
	if preview:
		GridRegistry.register_preview_building(tile_coordinates, self)
	else:
		GridRegistry.register_building(tile_coordinates, self)

func unregister(preview: bool = false):
	if preview:
		GridRegistry.unregister_preview_building(tile_coordinates)
	else:
		GridRegistry.unregister_building(tile_coordinates)

# func _exit_tree() -> void:
# 	unregister()
