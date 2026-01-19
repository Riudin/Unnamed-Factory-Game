class_name Trash
extends Building


@export var intake_per_second: int = 1
@export var input_direction: Vector2i = Vector2i.LEFT

signal item_taken(item)

var tick_counter: int = 0

const TILE_SIZE: float = 16.0

func _ready():
	TickManager.tick.connect(_on_tick)
	self.add_to_group("buildings")

func _on_tick():
	tick_counter += 1
	
	if tick_counter >= TickManager.tick_rate / intake_per_second:
		tick_counter = 0
		take_in_item()

func take_in_item():
	var belt: Node2D = get_input_belt()
	if belt == null or belt.items.size() < 1:
		return
	
	var intake_item: Node2D = belt.items[0]
	emit_signal("item_taken", intake_item)
	print("Taken Item in: " + str(intake_item.display_name))
	belt.items.erase(intake_item) # maybe later on move deletion of the item to belt. but it's fine for now
	intake_item.queue_free()
	
	
func get_input_belt():
	var target_pos = global_position + input_direction * TILE_SIZE
	
	for belt in get_tree().get_nodes_in_group("belts"):
		if belt.global_position.distance_to(target_pos) < TILE_SIZE / 2:
			return belt
	
	return null
