class_name  BuildingHandler
extends Node2D


@export var tilemap_ground_layer: TileMapLayer

@onready var conveyor_belt: PackedScene = preload("res://Objects/Scenes/Buildings/conveyor_belt.tscn")
@onready var giver: PackedScene = preload("res://Objects/Scenes/Buildings/giver.tscn")
@onready var trash: PackedScene = preload("res://Objects/Scenes/Buildings/trash.tscn")

const TILE_SIZE: float = 16.0

var current_building: PackedScene
var is_building: bool = false
var is_removing: bool = false


func _ready() -> void:
	current_building = conveyor_belt

func _process(_delta):
	if is_building:
		place_building()
	
	if is_removing:
		remove_building()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_building = true
			#print(tilemap_ground_layer.local_to_map(get_global_mouse_position()))
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_building = false
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false

func place_building():
	if current_building == null:
		return
	
	var mouse_position: Vector2 = get_global_mouse_position()
	var tile: Vector2 = tilemap_ground_layer.local_to_map(
		tilemap_ground_layer.to_local(mouse_position)
		)
	
	if GridRegistry.is_occupied(tile):
		return
	
	var snapped_world_position: Vector2 = tilemap_ground_layer.to_global(
		tilemap_ground_layer.map_to_local(tile)
		)
	
	var building = current_building.instantiate()
	building.global_position = snapped_world_position
	building.tile_coordinates = tile
	building.register()
	get_tree().current_scene.add_child(building)

func remove_building():
	var mouse_position: Vector2 = get_global_mouse_position()
	var tile := tilemap_ground_layer.local_to_map(
		tilemap_ground_layer.to_local(mouse_position)
	)
	
	var building = GridRegistry.get_building(tile)
	if building:
		building.queue_free()
