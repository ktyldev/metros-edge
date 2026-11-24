extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player.global_transform = $Environment/Greybox/StartingPlatform/PlayerStart.global_transform
	connect("tree_exiting", reset_timer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func reset_timer():
	Global.level_timer.stop()
	print("stopping timer!")
