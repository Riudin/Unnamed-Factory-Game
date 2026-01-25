class_name Building
extends Node2D


@export var selection_highlight: SelectionHighlight

var tile_coordinates: Vector2i
var input_ports: Array[Port] = []
var output_ports: Array[Port] = []

var is_preview: bool = true


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
	

func connect_to_neighbors() -> void:
	var neighbor_dirs = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	for direction in neighbor_dirs:
		var neighbor_tile = tile_coordinates + direction
		var neighbor = GridRegistry.get_building(neighbor_tile)
			
		if not neighbor or not neighbor is Building:
			continue
        
		# Try to connect our output ports to neighbor's input ports
		for our_output in output_ports:
			if our_output.local_dir == direction: # Our port points at neighbor
				for neighbor_input in neighbor.input_ports:
					if neighbor_input.local_dir == -direction: # Neighbor port points back at us
						# Make bidirectional connection
						our_output.connected_port = neighbor_input
						neighbor_input.connected_port = our_output

		# Try to connect our input ports to neighbor's output ports
		for our_input in input_ports:
			if our_input.local_dir == direction: # Our port faces neighbor
				for neighbor_output in neighbor.output_ports:
					if neighbor_output.local_dir == -direction: # Neighbor output points at us
						our_input.connected_port = neighbor_output
						neighbor_output.connected_port = our_input


func get_item_data(_item_id: String) -> ItemData:
	# Override in subclasses that produce items
	return null