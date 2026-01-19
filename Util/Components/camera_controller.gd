extends Node2D


@export var camera: Camera2D

var camera_speed: float = 400.0

func _process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	if Input.is_action_pressed("camera_right"):
		input_vector.x += 1
	if Input.is_action_pressed("camera_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("camera_down"):
		input_vector.y += 1
	if Input.is_action_pressed("camera_up"):
		input_vector.y -= 1
	
	input_vector = input_vector.normalized()
	
	camera.position += input_vector * camera_speed * delta

	if Input.is_action_just_pressed("camera_zoom_in"):
		camera.zoom *= 0.8
	if Input.is_action_just_pressed("camera_zoom_out"):
		camera.zoom *= 1.2
	
	camera.force_update_scroll()