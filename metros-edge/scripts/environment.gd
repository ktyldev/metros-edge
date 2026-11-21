extends Node3D


func _ready() -> void:
	_disable_static_lights(self)

func _disable_static_lights(node: Node3D) -> void:
	for child in node.get_children():
		if child is Light3D and child.light_bake_mode == Light3D.BAKE_STATIC:
			child.visible = false

		if child is Node3D:
			_disable_static_lights(child)
