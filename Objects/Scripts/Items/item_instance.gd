class_name ItemInstance
extends Node2D


var item_data: ItemData

@export_group("References")
@export var sprite: Sprite2D

var progress: float = 0.0
var current_belt: ConveyorBelt = null
var input_port_dir: Vector2i = Vector2i.LEFT # Direction of the input port this item entered from


func _ready() -> void:
	if item_data:
		sprite.texture = item_data.icon
	else:
		printerr("No item_resource on ItemInstance")
