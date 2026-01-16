extends Node2D

@export var stone: PackedScene
@export var belt_detector: BeltDetector
@export var timer: Timer
@export var item_holder: Node2D


func _on_belt_detector_belt_detected(destination: Node2D) -> void:
	var item: Node2D = stone.instantiate()
	item_holder.add_child(item)
	destination.receive_item(item)
	timer.start()

func _on_timer_timeout():
	belt_detector.detect()
