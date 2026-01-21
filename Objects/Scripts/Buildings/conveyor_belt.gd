class_name ConveyorBelt
extends Building


@export var debug: bool = false

@export_group("References")
@export var animation_player: AnimationPlayer

@export_group("Setup")
@export var speed: float = 2.0 # tiles per second
@export var min_spacing: float = 16.0 # distance between items on belt # doesn't work yet

var grid_pos: Vector2i
var items: Array = []
var next_belt: ConveyorBelt = null

const TILE_SIZE: float = 16.0


#################################
# Setup Orientation and Visuals #
#################################


func _ready():
	tree_exiting.connect(_on_tree_exiting)
	TickManager.tick.connect(_on_tick)

	get_orientation()
	setup_output_marker()


func get_orientation():
	input_direction = - output_direction

	var input_connections: Array = get_input_connections()
	if input_connections.size() > 1:
		input_direction = - output_direction
		# TODO: handle edge case of 2 inputs adjacent to each other
		# expected outcome: input fom left and down -> output dir left = input from down and vice versa
	elif input_connections.size() > 0:
		var input_building = input_connections[0]
		input_direction = - input_building.output_direction
	
	if input_direction == output_direction:
		input_direction = - output_direction

	set_visuals()
	

func get_input_connections():
	var neighbor_left := GridRegistry.get_building(tile_coordinates + Vector2i.LEFT)
	var neighbor_right := GridRegistry.get_building(tile_coordinates + Vector2i.RIGHT)
	var neighbor_up := GridRegistry.get_building(tile_coordinates + Vector2i.UP)
	var neighbor_down := GridRegistry.get_building(tile_coordinates + Vector2i.DOWN)

	var neighbors: Array = [neighbor_left, neighbor_right, neighbor_up, neighbor_down]
	var input_connections: Array = []

	for neighbor in neighbors:
		if neighbor is Building and neighbor.tile_coordinates + neighbor.output_direction == self.tile_coordinates:
			input_connections.append(neighbor)

	return input_connections


func set_visuals():
	var from: String
	var to: String
	if input_direction == Vector2i.LEFT:
		from = "left"
	if input_direction == Vector2i.RIGHT:
		from = "right"
	if input_direction == Vector2i.UP:
		from = "up"
	if input_direction == Vector2i.DOWN:
		from = "down"
	if output_direction == Vector2i.LEFT:
		to = "left"
	if output_direction == Vector2i.RIGHT:
		to = "right"
	if output_direction == Vector2i.UP:
		to = "up"
	if output_direction == Vector2i.DOWN:
		to = "down"
	if animation_player.has_animation(from + "_" + to):
		animation_player.play(from + "_" + to)
	else:
		modulate = Color.PURPLE # purple to show error
		animation_player.play("left_right")

###################
## Item Handling ##
###################

func _on_tick():
	_advance_items()


func _advance_items():
	if items.is_empty():
		return
	
	# iterate backwards to handle removal while iterating
	for i in range(items.size() - 1, -1, -1):
		var item = items[i]
		var max_progress := 1.0
		
		# block by item ahead
		if i < items.size() - 1:
			var item_ahead = items[i + 1]
			max_progress = item_ahead.progress - min_spacing
		
		# move toward max progress
		item.progress = min(item.progress + speed / TickManager.tick_rate, max_progress)
		
		# reached end?
		if item.progress >= 1.0:
			_push_to_next_belt(item)
	
	_update_item_positions()


func _get_next_belt() -> ConveyorBelt:
	var target_pos: Vector2i = global_position + output_direction * TILE_SIZE
	
	for belt in get_tree().get_nodes_in_group("belts"):
		if belt == self:
			continue
		if belt.global_position.distance_to(target_pos) < TILE_SIZE / 2:
			return belt
	
	return null


func _push_to_next_belt(item):
	next_belt = _get_next_belt()
	
	if next_belt == null:
		return
	
	if next_belt.can_accept_item():
		items.erase(item)
		next_belt.add_item(item, 0.0)


func can_accept_item() -> bool:
	if items.is_empty():
		return true
	
	return items[0].progress > min_spacing


func add_item(item, start_progress := 0.0):
	item.current_belt = self
	item.progress = start_progress
	items.append(item)


func _update_item_positions():
	for item in items:
		item.global_position = _point_from_progress(item.progress)


func _point_from_progress(progress: float) -> Vector2i:
	var start := global_position + input_direction * TILE_SIZE
	var end := Vector2i(global_position) + output_direction
	return start.lerp(end, progress)


func _on_tree_exiting() -> void:
	for item in items:
		item.queue_free()
