class_name Building
extends Node2D


@export var selection_highlight: SelectionHighlight

var tile_coordinates: Vector2i
var input_direction: Vector2i = Vector2i.LEFT
var output_direction: Vector2i = Vector2i.RIGHT


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


func setup_output_marker():
	if selection_highlight.output_marker:
		selection_highlight.output_marker.look_at(Vector2i(global_position) + output_direction)
	

# Maybe need this later?
# func _exit_tree() -> void:
# 	unregister()
