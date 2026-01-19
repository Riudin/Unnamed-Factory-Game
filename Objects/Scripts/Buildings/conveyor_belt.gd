class_name ConveyorBelt
extends Building


@export var debug: bool = false

@export_group("References")
@export var animation_player: AnimationPlayer
@export var output_direction_arrow: RayCast2D
@export var input_direction_arrow: RayCast2D

@export_group("Setup")
#enum {Left, Right, Up, Down}
#@export var input_direction: Vector2i = Vector2i.LEFT
#@export var output_direction: Vector2i = Vector2i.DOWN
@export var speed: float = 2.0 # tiles per second
@export var min_spacing: float = 16.0 # distance between items on belt # doesn't work yet

var grid_pos: Vector2i
var items: Array = []
var next_belt: ConveyorBelt = null

const TILE_SIZE: float = 16.0


func _ready():
	tree_exiting.connect(_on_tree_exiting)
	TickManager.tick.connect(_on_tick)
	get_orientation()
	set_visuals()


func _process(_delta: float) -> void:
	if debug:
		output_direction_arrow.visible = true
		input_direction_arrow.visible = true
	else:
		output_direction_arrow.visible = false
		input_direction_arrow.visible = false


func get_orientation():
	for neighbor in get_neighbors():
		if neighbor is Building and neighbor.tile_coordinates + neighbor.output_direction == self.tile_coordinates:
			input_direction = neighbor.output_direction
			break

	input_direction = - output_direction


func get_neighbors():
	var neighbor_left := GridRegistry.get_building(tile_coordinates + Vector2i.LEFT)
	var neighbor_right := GridRegistry.get_building(tile_coordinates + Vector2i.RIGHT)
	var neighbor_up := GridRegistry.get_building(tile_coordinates + Vector2i.UP)
	var neighbor_down := GridRegistry.get_building(tile_coordinates + Vector2i.DOWN)
	var neighbors: Array = [neighbor_left, neighbor_right, neighbor_up, neighbor_down]
	
	return neighbors


func set_visuals():
	var from: String
	var to: String
	if input_direction == Vector2i.LEFT:
		from = "left"
		input_direction_arrow.position = Vector2i.LEFT * TILE_SIZE
		input_direction_arrow.target_position = - Vector2i.LEFT * TILE_SIZE
	if input_direction == Vector2i.RIGHT:
		from = "right"
		input_direction_arrow.position = Vector2i.RIGHT * TILE_SIZE
		input_direction_arrow.target_position = - Vector2i.RIGHT * TILE_SIZE
	if input_direction == Vector2i.UP:
		from = "up"
		input_direction_arrow.position = Vector2i.UP * TILE_SIZE
		input_direction_arrow.target_position = - Vector2i.UP * TILE_SIZE
	if input_direction == Vector2i.DOWN:
		from = "down"
		input_direction_arrow.position = Vector2i.DOWN * TILE_SIZE
		input_direction_arrow.target_position = - Vector2i.DOWN * TILE_SIZE
	if output_direction == Vector2i.LEFT:
		to = "left"
		output_direction_arrow.target_position = Vector2i.LEFT * TILE_SIZE
	if output_direction == Vector2i.RIGHT:
		to = "right"
		output_direction_arrow.target_position = Vector2i.RIGHT * TILE_SIZE
	if output_direction == Vector2i.UP:
		to = "up"
		output_direction_arrow.target_position = Vector2i.UP * TILE_SIZE
	if output_direction == Vector2i.DOWN:
		to = "down"
		output_direction_arrow.target_position = Vector2i.DOWN * TILE_SIZE
	
	if animation_player.has_animation(from + "_" + to):
		animation_player.play(from + "_" + to)
	else:
		modulate = Color.PURPLE # purple tint to show error
		animation_player.play("left_right")


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
