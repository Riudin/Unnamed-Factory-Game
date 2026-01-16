class_name Building
extends Node2D


var tile_coordinates: Vector2
var from_direction: Vector2 = Vector2.LEFT
var to_direction: Vector2 = Vector2.RIGHT

func register():
	GridRegistry.register_building(tile_coordinates, self)

func unregister():
	GridRegistry.unregister_building(tile_coordinates)

func _exit_tree() -> void:
	unregister() 
