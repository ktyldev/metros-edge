extends Label

func _process(delta):
	text = "%05.2f" % Global.level_timer.time_left
