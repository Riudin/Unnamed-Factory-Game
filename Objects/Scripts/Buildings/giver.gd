class_name Giver
extends Building

@export var output_per_second: float = 1.0
@export var produced_item: ItemData

@onready var item_instance_scene = preload(Constants.OTHER_SCENE_PATH["item_instance"])

var output_inventory: Inventory = Inventory.new(): get = get_output_inventory

var tick_counter: int = 0


func _init() -> void:
	setup_output_ports() # must be in init() because we need the output ports to apply rotation in super class before this node is ready


func setup_output_ports() -> void:
	# Giver always has one output port to the right by default
	var output_port = Port.new()
	output_port.port_type = Port.PortType.OUTPUT
	output_port.local_dir = Vector2i.RIGHT
	output_ports.append(output_port)


func _ready():
	super._ready()
	TickManager.tick.connect(_on_tick)


func _on_tick():
	if self.is_preview:
		return

	tick_counter += 1
	
	if tick_counter >= TickManager.tick_rate / output_per_second:
		tick_counter = 0
		if output_ports[0].connected_port != null: # TODO: this is a dirty workaround to avoid the giver to produce anything when its not connected to a belt.
													# this and the stacksize of 1 makes having an inventory obsolete right now.
			produce_item()


func produce_item():
	if produced_item == null:
		printerr("Giver has no produced_item assigned")
		return

	output_inventory.add(produced_item.id, 1)


## For other buildings and conveyor belts to get access to this inventory
func get_output_inventory():
	return output_inventory


## For other buildings and conveyor belts to get access of the item data of the item that is produced
func get_item_data(item_id: String) -> ItemData:
	# Return the item data if it matches what this giver produces
	if produced_item and produced_item.id == item_id:
		return produced_item
	return null
