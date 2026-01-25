class_name ItemInstance
extends Node2D


var item_data: ItemData

@export_group("References")
@export var sprite: Sprite2D

var progress: float = 0.0
var current_belt: ConveyorBelt = null


func _ready() -> void:
	if item_data:
		sprite.texture = item_data.icon
	else:
		printerr("No item_resource on ItemInstance")
