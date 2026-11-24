extends Area3D


func _on_body_entered(body):
	Global.change_scene_to("res://scenes/main.tscn")
