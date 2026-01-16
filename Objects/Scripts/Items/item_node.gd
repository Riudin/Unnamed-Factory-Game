class_name ItemNode
extends Node2D

@export var item_resource: ItemResource

@export_group("References")
@export var sprite: Sprite2D

var display_name: String

var progress: float = 0.0
var current_belt: ConveyorBelt = null


func _ready() -> void:
	if item_resource:
		sprite.texture = item_resource.icon
		display_name = item_resource.display_name
