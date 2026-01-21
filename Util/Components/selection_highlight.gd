class_name SelectionHighlight
extends Node2D


@export var highlight_sprite: Sprite2D
@export var output_marker: Marker2D
@export var mouse_detector: Area2D


func _ready() -> void:
	GameSettings.connect("show_advanced_building_info_toggled", on_show_advanced_building_info_toggled)

	highlight_sprite.visible = false
	if output_marker:
		if not (GameSettings.show_advanced_building_info or BuildingHandler.build_mode):
			output_marker.visible = false


func _on_mouse_detector_mouse_entered() -> void:
	if not BuildingHandler.build_mode:
		highlight_sprite.visible = true
	if output_marker:
		output_marker.visible = true

func _on_mouse_detector_mouse_exited() -> void:
	highlight_sprite.visible = false
	if output_marker:
		if not GameSettings.show_advanced_building_info:
			output_marker.visible = false


func on_show_advanced_building_info_toggled():
	if output_marker:
		if GameSettings.show_advanced_building_info:
			output_marker.visible = true
		else:
			output_marker.visible = false