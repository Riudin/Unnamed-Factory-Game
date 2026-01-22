extends Resource
class_name Port

enum PortType {
	INPUT,
	OUTPUT
}

@export var port_type: PortType
@export var local_dir: Vector2i
var connected_port: Port = null