extends Resource
class_name Port

enum PortType {
	INPUT,
	OUTPUT
}

var port_type: PortType
var local_dir: Vector2i
var connected_port: Port = null