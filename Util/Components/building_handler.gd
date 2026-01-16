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

var start_tile: Vector2
var end_tile: Vector2

var last_previewed_tiles: Array = []


func _ready() -> void:
	current_building = conveyor_belt

func _process(_delta):
	if preview_active:
		show_building_preview()
	
	if is_removing:
		remove_building(tilemap_ground_layer.local_to_map(get_global_mouse_position()))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
			preview_active = true
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			end_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
			
			preview_active = false
			
			#var path := build_belt_path(start_tile, end_tile)
			#for i in path.size() - 1:
				#var dir = direction_from_to(path[i], path[i + 1])
				#place_building(path[i], dir)
			#place_building(path[-1], direction_from_to(path[-2], path[-1]))
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false

func build_belt_path(start: Vector2, end: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = []
	
	var dx := end.x - start.x
	var dy := end.y - start.y
	
	if abs(dx) >= abs(dy):
		for x in range(start.x, end.x, sign(dx)):
			path.append(Vector2(x, start.y))
		for y in range(start.y, end.y, sign(dy)):
			path.append(Vector2(end.x, y))
	else:
		for y in range(start.y, end.y, sign(dy)):
			path.append(Vector2(start.x, y))
		for x in range(start.x, end.x, sign(dx)):
			path.append(Vector2(x, end.y))
	
	path.append(end)
	return path

func direction_from_to(a: Vector2, b: Vector2):
	var direction := b - a
	return direction

func show_building_preview():
	if last_previewed_tiles.size() > 0:
		for i in last_previewed_tiles.size():
			remove_building(last_previewed_tiles[i])
		last_previewed_tiles.clear()
	
	end_tile = tilemap_ground_layer.local_to_map(get_global_mouse_position())
	
	var path := build_belt_path(start_tile, end_tile)
	for i in path.size() - 1:
		var dir = direction_from_to(path[i], path[i + 1])
		place_building(path[i], dir, Color.AQUA)
		last_previewed_tiles.append(path[i])
	place_building(path[-1], Vector2.RIGHT, Color.AQUA)
	last_previewed_tiles.append(path[-1])

func place_building(tile: Vector2, to_direction: Vector2, color: Color = Color.WHITE):
	if current_building == null:
		return
	
	if GridRegistry.is_occupied(tile):
		return
	
	var snapped_world_position: Vector2 = tilemap_ground_layer.to_global(
		tilemap_ground_layer.map_to_local(tile)
		)
	
	var building = current_building.instantiate()
	building.global_position = snapped_world_position
	building.tile_coordinates = tile
	building.to_direction = to_direction
	building.modulate = color
	building.register()
	get_tree().current_scene.add_child(building)

func remove_building(tile: Vector2):
	var building = GridRegistry.get_building(tile)
	if building:
		building.queue_free()
