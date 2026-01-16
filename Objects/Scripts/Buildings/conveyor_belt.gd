class_name ConveyorBelt
extends Building


@export var debug: bool = false

@export_group("References")
@export var animation_player: AnimationPlayer
@export var to_direction_arrow: RayCast2D
@export var from_direction_arrow: RayCast2D

@export_group("Setup")
#enum {Left, Right, Up, Down}
#@export var from_direction: Vector2i = Vector2i.LEFT
#@export var to_direction: Vector2i = Vector2i.DOWN
@export var speed: float = 2.0              # tiles per second
@export var min_spacing: float = 16.0       # distance between items on belt # doesn't work yet

var grid_pos: Vector2i
var items: Array = []
var next_belt: ConveyorBelt = null

const TILE_SIZE: float = 16.0


func _ready():
	TickManager.tick.connect(_on_tick)
	self.add_to_group("belts")
	self.add_to_group("buildings")
	get_neighbors()
	get_orientation()
	set_visuals()
	#print("to: " + str(to_direction))
	#print("-----")

func _process(_delta: float) -> void:
	if debug:
		to_direction_arrow.visible = true
		from_direction_arrow.visible = true
	else:
		to_direction_arrow.visible = false
		from_direction_arrow.visible = false

func get_orientation():
	var searching_directions: Array = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	
	for direction in searching_directions:
		if direction == to_direction:
			continue
		
		var target_pos: Vector2i = global_position + direction * TILE_SIZE
		
		for belt in get_tree().get_nodes_in_group("belts"):
			if belt == self:
				continue
			if belt.global_position.distance_to(target_pos) < TILE_SIZE / 2:
				from_direction = direction
				return

func get_neighbors():
	var neighbor_left := GridRegistry.get_building(tile_coordinates + Vector2i.LEFT)
	var neighbor_right := GridRegistry.get_building(tile_coordinates + Vector2i.RIGHT)
	var neighbor_up := GridRegistry.get_building(tile_coordinates + Vector2i.UP)
	var neighbor_down := GridRegistry.get_building(tile_coordinates + Vector2i.DOWN)
	var neighbors: Array = [neighbor_left, neighbor_right, neighbor_up, neighbor_down]
	
	for n in neighbors:
		# if neighbor output is looking at us
		if n is Building and n.tile_coordinates + n.to_direction == self.tile_coordinates:
			from_direction = n.tile_coordinates - self.tile_coordinates
			#print("from: " + str(from_direction))
			
			# break because we want to only look at the first neighbor
			# TODO: handle multiple neighbors looking at us
			break


func set_visuals():
	var from: String
	var to: String
	if from_direction == Vector2i.LEFT: 
		from = "left"
		from_direction_arrow.position = Vector2i.LEFT * TILE_SIZE
		from_direction_arrow.target_position = -Vector2i.LEFT * TILE_SIZE
	if from_direction == Vector2i.RIGHT: 
		from = "right"
		from_direction_arrow.position = Vector2i.RIGHT * TILE_SIZE
		from_direction_arrow.target_position = -Vector2i.RIGHT * TILE_SIZE
	if from_direction == Vector2i.UP: 
		from = "up"
		from_direction_arrow.position = Vector2i.UP * TILE_SIZE
		from_direction_arrow.target_position = -Vector2i.UP * TILE_SIZE
	if from_direction == Vector2i.DOWN: 
		from = "down"
		from_direction_arrow.position = Vector2i.DOWN * TILE_SIZE
		from_direction_arrow.target_position = -Vector2i.DOWN * TILE_SIZE
	if to_direction == Vector2i.LEFT: 
		to = "left"
		to_direction_arrow.target_position = Vector2i.LEFT * TILE_SIZE
	if to_direction == Vector2i.RIGHT: 
		to = "right"
		to_direction_arrow.target_position = Vector2i.RIGHT * TILE_SIZE
	if to_direction == Vector2i.UP: 
		to = "up"
		to_direction_arrow.target_position = Vector2i.UP * TILE_SIZE
	if to_direction == Vector2i.DOWN: 
		to = "down"
		to_direction_arrow.target_position = Vector2i.DOWN * TILE_SIZE
	
	animation_player.play(from + "_" + to)
	#print(str(self) + " direction is " + from + "_" + to)
	#print("to arrow target is: " + str(to_direction_arrow.target_position))

func _on_tick():
	_advance_items()

func _advance_items():
	if items.is_empty():
		return
	
	# iterate from back to front because ?
	for i in range(items.size() - 1, -1, -1):
		var item = items[i]
		var max_progress := 1.0
		
		# block by item ahead
		if i < items.size()-1:
			var item_ahead = items[i+1]
			max_progress = item_ahead.progress - min_spacing
		
		# move toward max progress
		item.progress = min(item.progress + speed / TickManager.tick_rate, max_progress)
		
		# reached end?
		if item.progress >= 1.0:
			_push_to_next_belt(item)
	
	_update_item_positions()

func _get_next_belt() -> ConveyorBelt:
	var target_pos: Vector2i = global_position + to_direction * TILE_SIZE
	
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
	var start := global_position + from_direction * TILE_SIZE
	var end := Vector2i(global_position) + to_direction
	return start.lerp(end, progress)
