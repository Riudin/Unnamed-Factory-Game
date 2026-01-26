extends Node2D

## Node References -> need to be set via script because this is a singleton
var tilemap_ground_layer: TileMapLayer # Set by TileMap

var current_building_path: String
var preview_building: Node2D = null

var last_preview_tile: Vector2i # defaults to (0,0), keep in mind to check if that causes problems (also never resets)
var building_origin_tile: Vector2i # defaults to (0,0), keep in mind to check if that causes problems (also never resets)
var last_building_tile: Vector2i # defaults to (0,0), keep in mind to check if that causes problems (also never resets)

var preview_active: bool = false
var build_mode: bool = false
var is_building: bool = false
var is_removing: bool = false

var rotation_count: int = 0 # Track number of rotations for output port direction


func _unhandled_input(event: InputEvent) -> void:
	# This whole input one, two, three... section is spaghetti. But eh.. it works TODO: unspaghetti
	if event.is_action_pressed("one"):
		if not build_mode or current_building_path != Constants.BUILDING_SCENE_PATH["conveyor_belt"]:
			current_building_path = Constants.BUILDING_SCENE_PATH["conveyor_belt"]
			rotation_count = 0
			build_mode = true
			update_preview()
		else:
			current_building_path = ""
			build_mode = false

	elif event.is_action_pressed("two"):
		if not build_mode or current_building_path != Constants.BUILDING_SCENE_PATH["giver"]:
			current_building_path = Constants.BUILDING_SCENE_PATH["giver"]
			rotation_count = 0
			build_mode = true
			update_preview()
		else:
			current_building_path = ""
			build_mode = false
	
	elif event.is_action_pressed("three"):
		if not build_mode or current_building_path != Constants.BUILDING_SCENE_PATH["trash"]:
			current_building_path = Constants.BUILDING_SCENE_PATH["trash"]
			rotation_count = 0
			build_mode = true
			update_preview()
	
	elif event.is_action_pressed("four"):
		if not build_mode or current_building_path != Constants.BUILDING_SCENE_PATH["splitter"]:
			current_building_path = Constants.BUILDING_SCENE_PATH["splitter"]
			rotation_count = 0
			build_mode = true
			update_preview()

		else:
			current_building_path = ""
			build_mode = false


	if event is InputEventMouseButton:
		# left mouse button to place buildings
		if build_mode and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			building_origin_tile = get_mouse_tile()
			last_building_tile = building_origin_tile
			is_building = true

			place_building(building_origin_tile)
			update_preview(building_origin_tile)

			if current_building_path != Constants.BUILDING_SCENE_PATH["conveyor_belt"]:
				is_building = false
			
		if build_mode and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_building = false
			
		# right mouse button to remove buildings
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_removing = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_removing = false

	if event is InputEventKey:
		if event.is_action_pressed("rotate_left") and current_building_path != "":
			rotation_count -= 1
			update_preview()
		elif event.is_action_pressed("rotate_right") and current_building_path != "":
			rotation_count += 1
			update_preview()
	
	if event is InputEventKey:
		if event.is_action_pressed("show_advanced_building_info"):
			GameSettings.set_show_advanced_building_info(not GameSettings.show_advanced_building_info)
	
	if event is InputEventKey:
		if event.is_action_pressed("cancel_building"):
			current_building_path = ""
			build_mode = false
			preview_active = false
			clear_preview()
			preview_building = null


func _process(_delta):
	# if we are in build mode and have a building selected, activate preview. if not, deactivate preview
	if build_mode and current_building_path != "" and preview_active == false:
		preview_active = true
	elif (not build_mode or current_building_path == "") and preview_active == true:
		preview_active = false
		clear_preview()
		preview_building = null
	
	# update preview when changing mouse tile while it's active and we're not actively building
	if not is_building and preview_active:
		var mouse_tile: Vector2i = get_mouse_tile()
		if mouse_tile != last_preview_tile:
			update_preview()

	if is_building: # that means we are currently holding left mouse button and are building. TODO: make code unambiguous
		var mouse_tile: Vector2i = get_mouse_tile()
		var building_tile: Vector2i = mouse_tile

		# Calculate building direction based on rotation_count
		var building_orientation = _get_orientation_from_rotation()

		if mouse_tile != building_origin_tile:
			if building_orientation == Vector2i.RIGHT or building_orientation == Vector2i.LEFT:
				building_tile = Vector2i(mouse_tile.x, building_origin_tile.y)
			else:
				building_tile = Vector2i(building_origin_tile.x, mouse_tile.y)

		# only place and update preview when the restricted tile actually changes
		if preview_active and building_tile != last_building_tile:
			place_building(building_tile)
			update_preview(building_tile)

			# casual euclidean distance calculation to check if we have to fill in missing tiles. 
			# (yes, I figured this shit out myself! this is what I have to put up with!)
			var distance = int(sqrt(pow((last_building_tile.x - building_tile.x), 2) + pow((last_building_tile.y - building_tile.y), 2)))
			# Note to self: always check documentation first to find stuff like Vector2.distance_to() in the future...

			# TODO: maybe replace this prototyping abomination with the path function from depr_building_handler when too much free time
			if distance > 1:
				for i in range(1, distance):
					if building_orientation == Vector2i.RIGHT: place_building(Vector2i(last_building_tile.x + i, last_building_tile.y))
					if building_orientation == Vector2i.LEFT: place_building(Vector2i(last_building_tile.x - i, last_building_tile.y))
					if building_orientation == Vector2i.UP: place_building(Vector2i(last_building_tile.x, last_building_tile.y - i))
					if building_orientation == Vector2i.DOWN: place_building(Vector2i(last_building_tile.x, last_building_tile.y + i))

			last_building_tile = building_tile
			
	elif is_removing:
		remove_building(tilemap_ground_layer.local_to_map(get_global_mouse_position()))

func show_preview(tile: Vector2i):
	var can_build: bool = true
	var preview_color: Color

	if GridRegistry.is_occupied(tile, true):
		if preview_building and preview_building is ConveyorBelt \
			and GridRegistry.get_building(tile) is ConveyorBelt \
			and GridRegistry.get_building(tile).output_ports[0].local_dir != preview_building.output_ports[0].local_dir:
			can_build = true
		else:
			can_build = false
	
	if can_build:
		preview_color = Color(0, 1, 0, 1) # green
	else:
		preview_color = Color(1, 0, 0, 1) # red

	place_building(
		tile,
		preview_color,
		true # is_preview
	)
	
	last_preview_tile = tile


func place_building(tile: Vector2i, color: Color = Color.WHITE, is_preview: bool = false):
	var can_build: bool = true

	if not is_preview and GridRegistry.is_occupied(tile):
		can_build = false

		# you can overwrite specifically conveyor belts if you want to place one with a different direction.
		# TODO: when rotation of already placed buildings is implemented, maybe just rotate instead
		if current_building_path != "" \
			and current_building_path == Constants.BUILDING_SCENE_PATH["conveyor_belt"] \
			and GridRegistry.get_building(tile) is ConveyorBelt \
			and GridRegistry.get_building(tile).output_ports[0].local_dir != _get_orientation_from_rotation():
			remove_building(tile)
			can_build = true

	if not can_build:
		return

	var scene = load(current_building_path)
	var snapped_world_position: Vector2i = tilemap_ground_layer.to_global(tilemap_ground_layer.map_to_local(tile))
	
	var new_building = scene.instantiate()
	new_building.global_position = snapped_world_position
	new_building.tile_coordinates = tile
	
	# Apply rotations to output ports
	for _i in range(rotation_count % 4):
		new_building.rotate_output_ports(true)
	
	new_building.modulate = color
	if is_preview:
		new_building.add_to_group("preview")
		new_building.top_level = true
		preview_building = new_building
	else:
		new_building.register()
		new_building.is_preview = false
		new_building.connect_to_neighbors() # ADD THIS LINE
	
	get_tree().current_scene.add_child(new_building)

	# Update all 4 neighbors input and output ports
	GridRegistry.update_neighbors_ports(tile)
	
	# Reconnect neighbors since their ports may have changed
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]: # ADD THIS SECTION
		var neighbor = GridRegistry.get_building(tile + direction)
		if neighbor and neighbor is Building:
			neighbor.connect_to_neighbors()

func remove_building(tile: Vector2i):
	var building = GridRegistry.get_building(tile)
	if building:
		# Disconnect all ports before removing
		for port in building.output_ports + building.input_ports:
			if port.connected_port:
				port.connected_port.connected_port = null
				port.connected_port = null
		
		building.unregister()
		building.queue_free()


func _get_orientation_from_rotation() -> Vector2i:
	var rotations = rotation_count % 4
	match rotations:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		3:
			return Vector2i.UP
	return Vector2i.RIGHT


func get_mouse_tile() -> Vector2i:
	return tilemap_ground_layer.local_to_map(get_global_mouse_position())


func get_building_icon(building_name: String) -> Texture2D:
	if building_name in Constants.BUILDING_ICON_PATH:
		return load(Constants.BUILDING_ICON_PATH[building_name])
	return null


func update_preview(tile: Vector2i = get_mouse_tile()):
	clear_preview()
	show_preview(tile)


func clear_preview():
	var preview_buildings = get_tree().get_nodes_in_group("preview")
	for building in preview_buildings:
		building.queue_free()
