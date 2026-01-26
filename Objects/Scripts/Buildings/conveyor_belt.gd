class_name ConveyorBelt
extends Building


#@export var debug: bool = false

@export_group("References")
@export var animation_player: AnimationPlayer

@export_group("Setup")
@export var speed: float = 2.0 # items per second
@export var min_spacing: float = 0.33 # distance between items on belt

#var grid_pos: Vector2i
var item_inventory: Array = []
#var next_belt: ConveyorBelt = null

var current_input_index: int = 0 # for round-robin input prioritization


#################################
# Setup Orientation and Visuals #
#################################


func _init() -> void:
	setup_output_ports() # must be in init() because we need the output ports to apply rotation in super class before this node is ready


func _ready():
	super._ready()
	tree_exiting.connect(_on_tree_exiting)
	TickManager.tick.connect(_on_tick)

	setup_input_ports()
	set_visuals()


func setup_output_ports() -> void:
	if output_ports.size() > 0:
		return # already set up
		
	# ConveyorBelt always has one output port that defaults to right
	var output_port = Port.new()
	output_port.port_type = Port.PortType.OUTPUT
	output_port.local_dir = Vector2i.RIGHT
	output_ports.append(output_port)


func setup_input_ports() -> void:
	input_ports.clear()
	
	# Check all 4 neighbors and create input ports for those pointing at us
	var neighbor_dirs = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	
	for direction in neighbor_dirs:
		var neighbor = GridRegistry.get_building(tile_coordinates + direction)
		if neighbor and neighbor is Building:
			# Check if neighbor has an output port pointing at us
			for output_port in neighbor.output_ports:
				if neighbor.tile_coordinates + output_port.local_dir == tile_coordinates \
				and direction != output_ports[0].local_dir:
					# Create input port from neighbor output direction
					var input_port = Port.new()
					input_port.port_type = Port.PortType.INPUT
					input_port.local_dir = direction # input_port direction should be == direction we found the neighbor in
					input_ports.append(input_port)
					break # because one output port pointing at us is enough. we don't need to know about any other ports from that neighbor

	# If we don't have neighbors, default to one input opposite of output
	if input_ports.size() <= 0:
		var input_port = Port.new()
		input_port.port_type = Port.PortType.INPUT
		input_port.local_dir = - output_ports[0].local_dir # input_port direction is opposite of our first output_port direction
		input_ports.append(input_port)


func set_visuals():
	var input_dirs: Dictionary = {
		"left": false,
		"right": false,
		"up": false,
		"down": false,
	}

	# get directions as strings from input_ports.local_dir
	for port in input_ports:
		match port.local_dir:
			Vector2i.LEFT:
				input_dirs["left"] = true
			Vector2i.RIGHT:
				input_dirs["right"] = true
			Vector2i.UP:
				input_dirs["up"] = true
			Vector2i.DOWN:
				input_dirs["down"] = true
	
	var from: Array[String] = []
	for key in input_dirs:
		if input_dirs[key] == true:
			from.append(key)

	# Gets output direction from output ports. For conveyor belts only 1 output supported
	var to: String
	var output_dir = output_ports[0].local_dir
	if output_dir == Vector2i.LEFT:
		to = "left"
	elif output_dir == Vector2i.RIGHT:
		to = "right"
	elif output_dir == Vector2i.UP:
		to = "up"
	elif output_dir == Vector2i.DOWN:
		to = "down"
	
	# Build string for animation player
	var anim_to_play: String = ""
	for dir in from:
		anim_to_play += dir + "_"
	anim_to_play += to

	if animation_player.has_animation(anim_to_play):
		animation_player.play(anim_to_play)
	else:
		modulate = Color.PURPLE # purple to show error
		animation_player.play("left_right") # default animation
		print("Animation " + str(anim_to_play) + " not found.")


func update_ports() -> void:
	setup_input_ports()
	set_visuals()

###################
## Item Handling ##
###################

func _on_tick():
	if self.is_preview:
		return

	advance_items()
	fetch_inputs()


func fetch_inputs():
	if not can_accept_item():
		return
	
	# Try inputs in round-robin fashion
	var num_inputs = input_ports.size()
	for i in range(num_inputs):
		var input_index = (current_input_index + i) % num_inputs
		var port = input_ports[input_index]
		
		var building: Node2D = GridRegistry.get_building(tile_coordinates + port.local_dir)
		if building is Building and building.has_method("get_output_inventory"):
			var output_inv = building.get_output_inventory()
			if output_inv.items.size() > 0:
				# Get first item (FIFO)
				var item_id = output_inv.items.keys()[0]
				print(item_id)
				
				# Get ItemData from the building
				var item_data: ItemData = null
				if building.has_method("get_item_data"):
					item_data = building.get_item_data(item_id)
				
				if item_data != null:
					# Create and add item instance to belt
					var item_instance_scene = preload(Constants.OTHER_SCENE_PATH["item_instance"])
					var item_instance = item_instance_scene.instantiate() as ItemInstance
					item_instance.item_data = item_data
					
					add_item(item_instance, 0.0, port.local_dir)
					
					get_tree().current_scene.add_child(item_instance)
					item_instance.global_position = _point_from_progress(0.0, port.local_dir)
					
					# Remove from source building's output inventory
					output_inv.remove(item_id, 1)
					
					# Move to next input for next time
					current_input_index = (input_index + 1) % num_inputs
					
					# Only accept one item per tick
					return
				else:
					print("Could not get ItemData for item_id: ", item_id)
		elif building is ConveyorBelt:
			if building.item_inventory.is_empty():
				continue
			elif building.item_inventory[0].progress < 1.0:
				continue
			else:
				var item: ItemInstance = building.item_inventory[0]

				# add item to own inventory
				add_item(item, 0.0, port.local_dir) # Initial progress set to 0.1 because 0.0 would be the same as 1.0 at the belt in front
				item.progress = item.progress + speed / TickManager.tick_rate

				# remove item from inventory of the other belt
				building.item_inventory.remove_at(0)


func advance_items():
	if item_inventory.size() < 1:
		return
	
	for i in range(item_inventory.size()):
		var item = item_inventory[i]
		var max_progress := 1.0
		
		# block by item ahead
		if i > 0: # don't update oldest items max_progress
			var item_ahead = item_inventory[i - 1]
			max_progress = item_ahead.progress - min_spacing
		
		# prevent items from getting negative max_progress
		max_progress = max(max_progress, 0.0)
		
		# move toward max progress
		item.progress = min(item.progress + speed / TickManager.tick_rate, max_progress)
			
	_update_item_positions()


func can_accept_item() -> bool:
	# Can accept if inventory is empty
	if item_inventory.is_empty():
		return true

	# return true if progress from last item in array (which is the newest one on the belt) is greater than min_spacing
	return item_inventory[-1].progress > min_spacing


func add_item(item, start_progress := 0.0, from_input_dir: Vector2i = Vector2i.LEFT):
	item.current_belt = self
	item.progress = start_progress
	item.input_port_dir = from_input_dir
	item_inventory.append(item)


func _update_item_positions():
	for i in range(item_inventory.size()):
		var item = item_inventory[i]
		item.global_position = _point_from_progress(item.progress, item.input_port_dir)


func _point_from_progress(progress: float, input_dir: Vector2i = input_ports[0].local_dir) -> Vector2:
	var half_tile = Constants.TILE_SIZE / 2.0
	
	var output_dir = output_ports[0].local_dir
	
	# Item position: input edge -> center -> output edge
	# This ensures items always cross the center and handle turns properly
	var input_edge = Vector2(global_position) + Vector2(input_dir) * half_tile
	var center = Vector2(global_position)
	var output_edge = Vector2(global_position) + Vector2(output_dir) * half_tile
	
	if progress < 0.5:
		# First half: input edge to center
		return input_edge.lerp(center, progress * 2.0)
	else:
		# Second half: center to output edge
		return center.lerp(output_edge, (progress - 0.5) * 2.0)


func _on_tree_exiting() -> void:
	for item in item_inventory:
		item.queue_free()
