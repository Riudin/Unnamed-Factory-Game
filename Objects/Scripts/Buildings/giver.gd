class_name Giver
extends Building

@export var output_per_second: int = 1
@export var item_resource: ItemResource
@export var item_node_scene: PackedScene

var tick_counter: int = 0

const TILE_SIZE: float = 16.0

func _ready():
	TickManager.tick.connect(_on_tick)
	self.add_to_group("buildings")
	setup_output_marker()

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
	item.item_resource = item_resource
	get_tree().current_scene.add_child(item) # später ort ändern
	belt.add_item(item, 0.0)


func get_output_belt():
	var target_pos = global_position + output_direction * TILE_SIZE
	
	for belt in get_tree().get_nodes_in_group("belts"):
		if belt.global_position.distance_to(target_pos) < TILE_SIZE / 2:
			return belt
	
	return null
