class_name  BuildingHandler
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

var last_previewed_tiles: Array = []
var last_end_tile: Vector2i


func _ready() -> void:
	current_building = conveyor_belt

func _process(_delta):
	if preview_active:
		show_building_preview()
	elif get_tree().get_nodes_in_group("preview").size() > 0:
		for node in get_tree().get_nodes_in_group("preview"):
			place_building(node.tile_coordinates, node.to_direction)
	
	if is_removing:
		remove_building(tilemap_ground_layer.local_to_map(get_global_mouse_position()))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
			preview_active = true
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			#end_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
			
			preview_active = false
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false

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

func direction_from_to(a: Vector2i, b: Vector2i):
	var direction := b - a
	return direction

func show_building_preview():
	end_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
	if end_tile == last_end_tile:
		return
	
	clear_preview()
	last_previewed_tiles.clear()
	
	var path: Array[Vector2i] = build_belt_path(start_tile, end_tile)
	if path.size() == 0:
		return
	
	var last_dir: Vector2i = Vector2i.ZERO
	
	for i in range(path.size()):
		var tile := path[i]
		var dir: Vector2i
		
		if i < path.size() - 1:
			dir = direction_from_to(tile, path[i + 1])
			last_dir = dir
		else:
			dir = last_dir
		
		if dir == Vector2i.ZERO:
			dir = Vector2i.RIGHT       # if its just one Tile, default to right
		
		place_building(tile, dir, Color.AQUA, true)
		last_previewed_tiles.append(tile)
	
	last_end_tile = end_tile

func clear_preview():
	for node in get_tree().get_nodes_in_group("preview"):
		node.queue_free()

func place_building(tile: Vector2i, to_direction: Vector2i, color: Color = Color.WHITE, is_preview: bool = false):
	if current_building == null:
		return
	
	if not is_preview and GridRegistry.is_occupied(tile):
		return
	
	var snapped_world_position: Vector2i = tilemap_ground_layer.to_global(
		tilemap_ground_layer.map_to_local(tile)
		)
	
	var building = current_building.instantiate()
	building.global_position = snapped_world_position
	building.tile_coordinates = tile
	building.to_direction = to_direction
	building.modulate = color
	if is_preview:
		building.add_to_group("preview")
	else:
		building.register()
	
	get_tree().current_scene.add_child(building)

func remove_building(tile: Vector2i):
	var building = GridRegistry.get_building(tile)
	if building:
		building.queue_free()
