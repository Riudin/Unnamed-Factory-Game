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


func _init() -> void:
	setup_output_ports() # must be in init() because we need the output ports to apply rotation in super class before this node is ready


func _ready():
	super._ready()
	tree_exiting.connect(_on_tree_exiting)
	TickManager.tick.connect(_on_tick)

	setup_input_ports()
	set_visuals()

'''
	for port in input_ports:
		print("Input Ports: " + str(port.local_dir))
	for port in output_ports:
		print("Output Ports: " + str(port.local_dir))
'''

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


# # TODO: input_direction is deprecated, so remove this after full refactor
# func get_orientation():
# 	# Determine input direction(s) based on actual input ports
# 	var input_dirs: Array[Vector2i] = []
# 	for port in input_ports:
# 		input_dirs.append(port.local_dir)
	
# 	if input_dirs.is_empty():
# 		# No inputs, default input direction opposite to output
# 		input_direction = - output_ports[0].local_dir
# 		print("ERROR: on Conveyor Belt " + str(self) + ": no input direction found!")
# 	elif input_dirs.size() == 1:
# 		input_direction = input_dirs[0]
# 	else:
# 		# Multiple inputs - for now, use the first one (we can improve this later)
# 		input_direction = input_dirs[0]
	
# 	set_visuals() # CONTINUE HERE, get correct visuals for multiple outputs


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
	var output_dir = output_ports[0].local_dir
	var target_pos: Vector2i = global_position + output_dir * TILE_SIZE
	
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
	var input_dir = Vector2i.LEFT
	if not input_ports.is_empty():
		input_dir = input_ports[0].local_dir
	
	var output_dir = output_ports[0].local_dir
	var start: Vector2 = global_position + input_dir * TILE_SIZE
	var end: Vector2 = Vector2i(global_position) + output_dir
	return (start.lerp(end, progress) as Vector2i)


func _on_tree_exiting() -> void:
	for item in items:
		item.queue_free()
