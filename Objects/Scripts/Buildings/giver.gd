class_name Giver
extends Building

@export var output_per_second: int = 1
@export var produced_item: ItemData

@onready var item_instance_scene = preload(Constants.OTHER_SCENE_PATH["item_instance"])

var inventory: Inventory = Inventory.new()

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
	tick_counter += 1
	
	if tick_counter >= TickManager.tick_rate / output_per_second:
		tick_counter = 0
		produce_item()


func produce_item():
	if is_preview:
		return

	if produced_item == null:
		printerr("Giver has no produced_item assigned")
		return

	inventory.add(produced_item.id, 1)

	# Create visual representation and place on output belt
	if output_ports[0].connected_port == null: # TODO: checks only first port. In the future we need to check more
		return

	
	var item_instance = item_instance_scene.instantiate() as ItemInstance
	item_instance.item_resource = produced_item

	# var output_belt = get_output_belt()
	# if output_belt != null:
	# 	get_tree().current_scene.add_child(item_instance)
	# 	output_belt.add_item(item_instance, 0.0)
	# else:
	# 	# Item produced but no belt connected - queue for deletion or store visually
	# 	item_instance.queue_free()


func get_output_belt():
	pass
	# old code
	'''
	var output_dir = output_ports[0].local_dir if output_ports.size() > 0 else Vector2i.RIGHT
	var target_pos = global_position + output_dir * Constants.TILE_SIZE
	
	for belt in get_tree().get_nodes_in_group("belts"):
		if belt.global_position.distance_to(target_pos) < Constants.TILE_SIZE / 2:
			return belt
	
	return null
	'''
