extends MarginContainer

const WIN_TEXT := "Run complete"
const WIN_BLURB := "You made your train"
const LOSS_TEXT := "Run failed"
const LOSS_BLURB := "You missed your train..."

func win():
	%TimeShadow.visible = true
	%TimeLabel.visible = true
	%TimeShadow.text = "%05.2f" % Global.level_timer.time_left
	%TimeLabel.text = "%05.2f" % Global.level_timer.time_left
	%RunShadow.text = WIN_TEXT
	%RunLabel.text = WIN_TEXT
	%BlurbShadow.text = WIN_BLURB
	%BlurbLabel.text = WIN_BLURB
	$AnimationPlayer.play("enter")


func lose():
	%TimeShadow.text = "00.00"
	%TimeLabel.text = "00.00"
	%TimeShadow.visible = false
	%TimeLabel.visible = false
	%RunShadow.text = LOSS_TEXT
	%RunLabel.text = LOSS_TEXT
	%BlurbShadow.text = LOSS_BLURB
	%BlurbLabel.text = LOSS_BLURB
	$AnimationPlayer.play("enter")


#func _input(event: InputEvent) -> void:
	#if Input.is_action_just_pressed("ui_cancel"):
		#win()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "enter":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.change_scene_to("res://scenes/main_menu.tscn")
		await Global.trans_entered
		$AnimationPlayer.play("RESET")
