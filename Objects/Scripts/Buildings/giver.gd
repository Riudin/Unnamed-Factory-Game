class_name Giver
extends Building

@export var output_per_second: int = 1
@export var produced_item: ItemResource
@export var item_node_scene: PackedScene

var tick_counter: int = 0

#const TILE_SIZE: float = 16.0


func _init() -> void:
	setup_output_ports() # must be in init() because we need the output ports to apply rotation in super class before this node is ready


func setup_output_ports() -> void:
	# Giver always has one output port to the right by default
	var output_port = Port.new()
	output_port.port_type = Port.PortType.OUTPUT
	output_port.local_dir = Vector2i.RIGHT
	output_ports.append(output_port)


func _ready():
	super._ready()
	TickManager.tick.connect(_on_tick)


func _on_tick():
	tick_counter += 1
	
	if tick_counter >= TickManager.tick_rate / output_per_second:
		tick_counter = 0
		produce_item()


func produce_item():
	var belt: Node2D = get_output_belt()
	
	if belt == null or not belt.can_accept_item():
		return
	
	var item = item_node_scene.instantiate()
	item.item_resource = produced_item
	get_tree().current_scene.add_child(item) # später ort ändern
	belt.add_item(item, 0.0)


func get_output_belt():
	var output_dir = output_ports[0].local_dir if output_ports.size() > 0 else Vector2i.RIGHT
	var target_pos = global_position + output_dir * Constants.TILE_SIZE
	
	for belt in get_tree().get_nodes_in_group("belts"):
		if belt.global_position.distance_to(target_pos) < Constants.TILE_SIZE / 2:
			return belt
	
	return null
