class_name Splitter
extends Building


var output_inventory: Inventory = Inventory.new(): get = get_output_inventory


func _init() -> void:
	setup_output_ports() # must be in init() because we need the output ports to apply rotation in super class before this node is ready


func _ready():
	super._ready()
	TickManager.tick.connect(_on_tick)

	setup_input_ports()


func setup_input_ports() -> void:
	input_ports.clear()

	# Splitter always has one input port that defaults to left
	var input_port = Port.new()
	input_port.port_type = Port.PortType.INPUT
	input_port.local_dir = Vector2.LEFT
	input_ports.append(input_port)


func update_ports() -> void:
	setup_input_ports()


func setup_output_ports() -> void:
	# Splitter always has 3 output ports that default to up right and down
	var output_directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	for dir in output_directions:
		var output_port = Port.new()
		output_port.port_type = Port.PortType.OUTPUT
		output_port.local_dir = dir
		output_ports.append(output_port)


func _on_tick():
	if self.is_preview:
		return

	fetch_inputs()


func fetch_inputs():
	if not can_accept_item():
		return
	
	var building: Node2D = GridRegistry.get_building(tile_coordinates + input_ports[0].local_dir)
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
			return
		elif building.item_inventory[0].progress < 1.0:
			return
		else:
			var item: ItemInstance = building.item_inventory[0]

			# add item to own inventory
			output_inventory.add(item.item_data.id, 1)

			# remove item from inventory of the other belt
			building.item_inventory.remove_at(0)


func can_accept_item() -> bool:
	if output_inventory.items.size() == 1: # TODO: check why this works and if its the correct way
		return false
	
	return true


## For other buildings and conveyor belts to get access to this inventory
func get_output_inventory():
	return output_inventory


## For other buildings and conveyor belts to get access of the item data of the item that is produced
# func get_item_data(item_id: String) -> ItemData:
# 	# Return the item data if it matches what this giver produces
# 	if produced_item and produced_item.id == item_id:
# 		return produced_item
# 	return null
