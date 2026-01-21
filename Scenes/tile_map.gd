extends Node2D


@export var tilemap_ground_layer: TileMapLayer


func _ready() -> void:
	BuildingHandler.tilemap_ground_layer = tilemap_ground_layer