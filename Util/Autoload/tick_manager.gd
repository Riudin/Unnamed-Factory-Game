extends Node

signal tick

var tick_rate: float = 60.0 # TODO: having the tickrate too low causes jittering (not just stuttering) movement of items on belts or even completely false positions
var accumulator: float = 0.0

func _process(delta: float) -> void:
	accumulator += delta
	while accumulator >= 1.0 / tick_rate:
		accumulator -= 1.0 / tick_rate
		tick.emit()
