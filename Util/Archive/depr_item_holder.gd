class_name ItemHolder
extends Node2D

@export_category("Settings")
@export var speed: float = 50.0

signal item_held

var moving_item: bool = false


func _physics_process(delta: float) -> void:
	if not moving_item or get_child_count() == 0:
		return
	
	var item := get_child(0)
	if item is Node2D:
		item.global_position = item.global_position.move_toward(get_parent().global_position, speed * delta)
		if item.global_position == get_parent().global_position:
			hold_item()

func hold_item() -> void:
	moving_item = false
	emit_signal("item_held")

func receive_item(item: Node2D) -> void:
	item.reparent(self, true)
	moving_item = true

func offload_item() -> Node2D:
	var item: Node2D = get_child(0)
	return item
