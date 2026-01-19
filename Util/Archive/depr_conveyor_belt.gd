#class_name ConveyorBelt
extends Area2D


@export_group("References")
@export var sprite: Sprite2D
@export var belt_detector: BeltDetector
@export var item_holder: ItemHolder

@export_category("Setup")
enum Direction {Left, Right, Up, Down}
@export var input_direction: Direction = Direction.Right
@export var output_direction: Direction = Direction.Left


func _ready() -> void:
	set_direction()

func set_direction() -> void:
	match output_direction:
		Direction.Left:
			belt_detector.position = Vector2.LEFT * 16
			match input_direction:
				Direction.Right:
					sprite.frame = 1
				Direction.Up:
					sprite.frame = 9
				Direction.Down:
					sprite.frame = 2
		Direction.Right:
			belt_detector.position = Vector2.RIGHT * 16
			match input_direction:
				Direction.Left:
					sprite.frame = 11
				Direction.Up:
					sprite.frame = 10
				Direction.Down:
					sprite.frame = 3
		Direction.Up:
			belt_detector.position = Vector2.UP * 16
			match input_direction:
				Direction.Left:
					sprite.frame = 12
				Direction.Right:
					sprite.frame = 8
				Direction.Down:
					sprite.frame = 7
		Direction.Down:
			belt_detector.position = Vector2.DOWN * 16
			match input_direction:
				Direction.Left:
					sprite.frame = 4
				Direction.Right:
					sprite.frame = 0
				Direction.Up:
					sprite.frame = 5

func can_receive_item() -> bool:
	return item_holder.get_child_count() == 0

func receive_item(item: Node2D) -> void:
	item_holder.receive_item(item)

func _on_belt_detector_belt_detected(area: Area2D) -> void:
	var item: Node2D = item_holder.offload_item()
	area.receive_item(item)

func _on_item_holder_item_held():
	belt_detector.detect()
