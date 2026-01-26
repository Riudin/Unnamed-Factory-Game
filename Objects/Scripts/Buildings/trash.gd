class_name Trash
extends Building


var current_input_index: int = 0 # for round-robin input prioritization
var output_inventory: Inventory = Inventory.new(): get = get_output_inventory
var max_stacksize: int = 999


func _ready():
	super._ready()
	TickManager.tick.connect(_on_tick)

	output_inventory.max_stacksize = max_stacksize
	setup_input_ports()


func setup_input_ports() -> void:
	input_ports.clear()
	
	# Check all 4 neighbors and create input ports for those pointing at us
	var neighbor_dirs = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	
	for direction in neighbor_dirs:
		var neighbor = GridRegistry.get_building(tile_coordinates + direction)
		if neighbor and neighbor is Building:
			# Check if neighbor has an output port pointing at us
			for output_port in neighbor.output_ports:
				if neighbor.tile_coordinates + output_port.local_dir == tile_coordinates:
					# Create input port from neighbor output direction
					var input_port = Port.new()
					input_port.port_type = Port.PortType.INPUT
					input_port.local_dir = direction # input_port direction should be == direction we found the neighbor in
					input_ports.append(input_port)
					break # because one output port pointing at us is enough. we don't need to know about any other ports from that neighbor


func update_ports() -> void:
	setup_input_ports()


func _on_tick():
	if self.is_preview:
		return

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
				var item = output_inv.items.keys()[0]

				# add item to own inventory
				output_inventory.add(item, 1)
				
				# remove from other building's inventory
				output_inv.remove(item, 1)

		elif building is ConveyorBelt:
			if building.item_inventory.is_empty():
				continue
			elif building.item_inventory[0].progress < 1.0:
				continue
			else:
				var item: ItemInstance = building.item_inventory[0]

				# add item to own inventory
				output_inventory.add(item.item_data.id, 1)

				item.queue_free()

				# remove item from inventory of the other belt
				building.item_inventory.remove_at(0)


func can_accept_item() -> bool:
	return true


## For other buildings and conveyor belts to get access to this inventory
func get_output_inventory():
	return output_inventory
