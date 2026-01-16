class_name BeltDetector
extends Area2D


signal belt_detected

var detecting: bool = false


func _physics_process(_delta: float) -> void:
	if not detecting:
		return
	
	var areas: Array = get_overlapping_areas()
	for area in areas:
		if area.can_receive_item():
			emit_signal("belt_detected", area)
			detecting = false
			break

func detect() -> void:
	detecting = true
