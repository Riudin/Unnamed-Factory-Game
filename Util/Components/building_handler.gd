class_name building_handler
extends Node2D

@export var tilemap_ground_layer: TileMapLayer

@onready var conveyor_belt: PackedScene = preload("res://Objects/Scenes/Buildings/conveyor_belt.tscn")
@onready var giver: PackedScene = preload("res://Objects/Scenes/Buildings/giver.tscn")
@onready var trash: PackedScene = preload("res://Objects/Scenes/Buildings/trash.tscn")

const TILE_SIZE: float = 16.0

var current_building: PackedScene
var preview_active: bool = false
var preview_building: Node2D = null
var build_mode: bool = false
var is_building: bool = false
var is_removing: bool = false

var output_direction: Vector2i = Vector2i.RIGHT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("one"):
		if not build_mode or current_building != conveyor_belt:
			current_building = conveyor_belt
			build_mode = true
			clear_preview()
		else:
			current_building = null
			build_mode = false

	elif event.is_action_pressed("two"):
		if not build_mode or current_building != giver:
			current_building = giver
			build_mode = true
			clear_preview()
		else:
			current_building = null
			build_mode = false
	
	elif event.is_action_pressed("three"):
		if not build_mode or current_building != trash:
			current_building = trash
			build_mode = true
			clear_preview()
		else:
			current_building = null
			build_mode = false


	if event is InputEventMouseButton:
		# left mouse button to place buildings
		if build_mode and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_building = true
			
		if build_mode and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_building = false
			
		# Right mouse button to remove buildings
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false

	if event is InputEventKey:
		if event.is_action_pressed("rotate_left"):
			output_direction = Vector2i(output_direction.y, -output_direction.x)
			clear_preview()
		elif event.is_action_pressed("rotate_right"):
			output_direction = Vector2i(-output_direction.y, output_direction.x)
			clear_preview()


func _process(_delta):
	if build_mode and current_building != null and preview_active == false:
		preview_active = true
	elif (not build_mode or current_building == null) and preview_active == true:
		preview_active = false

		# Clear preview when preview_active gets turned off
		clear_preview()
	
	if preview_active:
		var mouse_tile: Vector2i = get_mouse_tile()
		show_preview(mouse_tile)
	
	# not sure if we need this, since we already clear previews when toggling preview_active.
	# elif get_tree().get_nodes_in_group("preview").size() > 0:
	# 	var preview_buildings = get_tree().get_nodes_in_group("preview")
	# 	for building in preview_buildings:
	# 		building.queue_free()

	if is_building: # that means we are currently holding left mouse button and are building. TODO: make unambiguous
		var mouse_tile: Vector2i = get_mouse_tile()
		if not GridRegistry.is_occupied(mouse_tile, true):
			place_building(
			mouse_tile,
			)
	elif is_removing:
		remove_building(tilemap_ground_layer.local_to_map(get_global_mouse_position()))


func show_preview(tile: Vector2i):
	# Clear previous preview   --->>> moved to toggle of preview_active in process
	# var preview_buildings = get_tree().get_nodes_in_group("preview")
	# for building in preview_buildings:
	# 	building.queue_free()
	# if we habe a preview building, we want to move it instead of creating a new one
	if preview_building != null:
		var snapped_world_position: Vector2i = tilemap_ground_layer.to_global(tilemap_ground_layer.map_to_local(tile))
		preview_building.global_position = snapped_world_position # TODO: maybe manage pos only in tile_coordinates
		preview_building.tile_coordinates = tile
		preview_building.get_orientation()
		preview_building.set_visuals()
	else:
		# Place new preview building
		place_building(
			tile,
			Color(1, 1, 1, 0.5), # semi-transparent
			true # is_preview
		)


func place_building(tile: Vector2i, color: Color = Color.WHITE, is_preview: bool = false): # maybe we don't need is_preview anymore?
	# just to be sure check if we have a building to place
	if current_building == null:
		return
	
	if preview_building != null and is_preview:
		preview_building.queue_free()

	# if not is_preview and GridRegistry.is_occupied(tile):
	# 	return
	# elif GridRegistry.is_occupied(tile, true):
	# 	color = Color.RED
	
	var snapped_world_position: Vector2i = tilemap_ground_layer.to_global(tilemap_ground_layer.map_to_local(tile))
	
	var new_building = current_building.instantiate()
	new_building.global_position = snapped_world_position
	new_building.tile_coordinates = tile
	new_building.output_direction = output_direction
	new_building.modulate = color
	if is_preview:
		new_building.add_to_group("preview")
		preview_building = new_building
	else:
		new_building.register()
		clear_preview()
	
	get_tree().current_scene.add_child(new_building)


func remove_building(tile: Vector2i):
	var building = GridRegistry.get_building(tile)
	if building:
		building.unregister()
		building.queue_free()


func get_mouse_tile() -> Vector2i:
	return tilemap_ground_layer.local_to_map(get_global_mouse_position())


func clear_preview():
	var preview_buildings = get_tree().get_nodes_in_group("preview")
	for building in preview_buildings:
		building.queue_free()
	preview_building = null