#class_name BuildingHandler
extends Node2D


@export var tilemap_ground_layer: TileMapLayer

@onready var conveyor_belt: PackedScene = preload("res://Objects/Scenes/Buildings/conveyor_belt.tscn")
@onready var giver: PackedScene = preload("res://Objects/Scenes/Buildings/giver.tscn")
@onready var trash: PackedScene = preload("res://Objects/Scenes/Buildings/trash.tscn")

const TILE_SIZE: float = 16.0

var current_building: PackedScene
var preview_active: bool = false
var is_removing: bool = false

var start_tile: Vector2i
var end_tile: Vector2i

#var last_previewed_tiles: Array = []
var last_end_tile: Vector2i

# TODO: implement UI to switch between building types
func _ready() -> void:
	current_building = conveyor_belt

func _process(_delta):
	if preview_active:
		generate_building_preview()
	elif get_tree().get_nodes_in_group("preview").size() > 0:
		finalize_preview_buildings()
	
	if is_removing:
		remove_building(tilemap_ground_layer.local_to_map(get_global_mouse_position()))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("one"):
		current_building = conveyor_belt
	elif event.is_action_pressed("two"):
		current_building = giver
	elif event.is_action_pressed("three"):
		current_building = trash
	# elif event is Input.is_action_pressed("four"):
	# 	current_building = refinery


	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
			preview_active = true
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			preview_active = false
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false
			print(GridRegistry.buildings)

func generate_building_preview():
	# Every frame get the current end tile and only proceed if it changed
	end_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
	if end_tile == last_end_tile:
		return
	
	# Clear previous preview
	clear_preview()
	#last_previewed_tiles.clear()
	
	# Build new path for preview
	var path: Array[Vector2i] = build_belt_path(start_tile, end_tile)
	# if path.size() == 0: # just in case
	# 	return
	
	# Reset last direction
	var last_to_dir: Vector2i = Vector2i.ZERO
	
	# Set the output_direction and input_direction for each tile in the path
	for i in range(path.size()):
		var tile := path[i]
		var output_direction: Vector2i
		
		if i < path.size() - 1: # all but last tile
			output_direction = path[i + 1] - tile
			last_to_dir = output_direction
		else:
			output_direction = last_to_dir
		
		if output_direction == Vector2i.ZERO:
			output_direction = Vector2i.RIGHT # if its just one Tile, default to right
		
		var input_direction: Vector2i = calculate_input_direction(tile, output_direction, true)

		# maybe check if already registered?
		place_building(tile, input_direction, output_direction, Color.AQUA, true)
		#last_previewed_tiles.append(tile)
	
	last_end_tile = end_tile

func finalize_preview_buildings():
	for node in get_tree().get_nodes_in_group("preview"):
		node.remove_from_group("preview")
		node.unregister(true)
		node.register()
		node.modulate = Color.WHITE

func place_building(
	tile: Vector2i,
	input_direction: Vector2i,
	output_direction: Vector2i,
	color: Color = Color.WHITE,
	is_preview: bool = false):
	if current_building == null:
		return
	
	if not is_preview and GridRegistry.is_occupied(tile):
		return
	elif GridRegistry.is_occupied(tile, true):
		color = Color.RED
	
	var snapped_world_position: Vector2i = tilemap_ground_layer.to_global(
		tilemap_ground_layer.map_to_local(tile)
		)
	
	var building = current_building.instantiate()
	building.global_position = snapped_world_position
	building.tile_coordinates = tile
	building.input_direction = input_direction
	building.output_direction = output_direction
	building.modulate = color
	if is_preview:
		building.add_to_group("preview")
		building.register(true)
	else:
		building.register()
	
	get_tree().current_scene.add_child(building)

func remove_building(tile: Vector2i):
	var building = GridRegistry.get_building(tile)
	if building:
		building.queue_free()

func build_belt_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	
	var dx := end.x - start.x
	var dy := end.y - start.y
	
	if abs(dx) >= abs(dy):
		for x in range(start.x, end.x, sign(dx)):
			path.append(Vector2i(x, start.y))
		for y in range(start.y, end.y, sign(dy)):
			path.append(Vector2i(end.x, y))
	else:
		for y in range(start.y, end.y, sign(dy)):
			path.append(Vector2i(start.x, y))
		for x in range(start.x, end.x, sign(dx)):
			path.append(Vector2i(x, end.y))
	
	path.append(end)
	return path

func calculate_input_direction(tile: Vector2i, tile_output_direction: Vector2i = Vector2i.RIGHT, preview: bool = false) -> Vector2i:
	for neighbor in get_neighbors(tile, preview):
		if neighbor is Building and neighbor.tile_coordinates + neighbor.output_direction == tile:
			return neighbor.tile_coordinates - tile
			# return here because we want to only look at the first neighbor for now
			# TODO: handle multiple neighbors looking at us
			# TODO: what if no neighbor is found? (first placed building)


	return -tile_output_direction # default if no neighbor is found

func get_neighbors(tile: Vector2i, preview: bool = false):
	var neighbor_left := GridRegistry.get_building(tile + Vector2i.LEFT)
	if neighbor_left == null and preview:
		neighbor_left = GridRegistry.get_preview_building(tile + Vector2i.LEFT)
	var neighbor_right := GridRegistry.get_building(tile + Vector2i.RIGHT)
	if neighbor_right == null and preview:
		neighbor_right = GridRegistry.get_preview_building(tile + Vector2i.RIGHT)
	var neighbor_up := GridRegistry.get_building(tile + Vector2i.UP)
	if neighbor_up == null and preview:
		neighbor_up = GridRegistry.get_preview_building(tile + Vector2i.UP)
	var neighbor_down := GridRegistry.get_building(tile + Vector2i.DOWN)
	if neighbor_down == null and preview:
		neighbor_down = GridRegistry.get_preview_building(tile + Vector2i.DOWN)
	var neighbors: Array = [neighbor_left, neighbor_right, neighbor_up, neighbor_down]
	
	return neighbors

func clear_preview():
	for node in get_tree().get_nodes_in_group("preview"):
		node.unregister(true)
		node.queue_free()
