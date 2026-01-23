class_name Building
extends Node2D


@export var selection_highlight: SelectionHighlight

var tile_coordinates: Vector2i
var input_ports: Array[Port] = []
var output_ports: Array[Port] = []
var inventory: Array[ItemResource]


func _ready() -> void:
	setup_output_marker()


func rotate_output_ports(clockwise: bool = true) -> void:
	# Rotate all output ports (called before placement when building is rotated)
	for port in output_ports:
		if clockwise:
			port.local_dir = Vector2i(-port.local_dir.y, port.local_dir.x)
		else:
			port.local_dir = Vector2i(port.local_dir.y, -port.local_dir.x)


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
		# Use first output port direction TODO: instantiate multiple markers
		var output_dir = Vector2i.RIGHT
		if output_ports.size() > 0:
			output_dir = output_ports[0].local_dir
		selection_highlight.output_marker.look_at(Vector2i(global_position) + output_dir)
	

# Maybe need this later?
# func _exit_tree() -> void:
# 	unregister()
