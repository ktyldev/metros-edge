extends MarginContainer


var source_string := "pause"
var in_options := false


func _ready():
	for button:Button in [%Resume, %Options, %Quit]:
		button.connect("focus_entered", _on_button_focused.bind(button))
		button.connect("mouse_entered", _on_button_mouse_entered.bind(button))
		button.connect("mouse_exited", _on_button_mouse_exited.bind(button))
		button.connect("focus_exited", _on_button_focus_exited.bind(button))
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	get_parent().get_node("Options").connect("options_exited", _on_options_closed)


func _input(event):
	if event.is_action_pressed("pause") and Global.pauseable and !Global.paused:
		Global.paused = true
		get_tree().paused = true
		$AnimationPlayer.play("pause_enter")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("pause") and Global.paused:
		if UILayer.get_node("Options").entered:
			UILayer.get_node("Options")._on_back_button_pressed()
		elif !$AnimationPlayer.is_playing() and !UILayer.get_node("Options/AnimationPlayer").is_playing():
			for button:Button in [%Resume, %Options, %Quit]:
				button.focus_mode = Control.FOCUS_NONE
				button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
			$AnimationPlayer.play("pause_exit")


func _on_button_focused(button:Button) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(button.get_parent(), "offset_transform_position", Vector2(12, 0), 0.3)
	if button.name == "Resume":
		%ResumeGradient.visible = true
		%AnimationPlayer.play("resume_marquee")
	elif button.name == "Options":
		%OptionsGradient.visible = true
		%AnimationPlayer.play("options_marquee")
	elif button.name == "Quit":
		%QuitGradient.visible = true
		%AnimationPlayer.play("quit_marquee")


func _on_button_focus_exited(button:Button) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(button.get_parent(), "offset_transform_position", Vector2(0, 0), 0.3)
	%AnimationPlayer.stop()
	if button.name == "Resume":
		%ResumeGradient.visible = false
		%ResumeMarquee.visible = false
	elif button.name == "Options":
		%OptionsGradient.visible = false
		%OptionsMarquee.visible = false
	elif button.name == "Quit":
		%QuitGradient.visible = false
		%QuitMarquee.visible = false


func _on_button_mouse_entered(button:Button) -> void:
	button.grab_focus()


func _on_button_mouse_exited(button:Button) -> void:
	button.release_focus()


func _on_animation_player_animation_finished(anim_name) -> void:
	if "pause_enter" in anim_name:
		for button:Button in [%Resume, %Options, %Quit]:
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	elif anim_name == "pause_exit":
		get_tree().paused = false
		Global.paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif anim_name == "pause_exit_with_bg":
		UILayer.get_node("Options").enter(source_string)


func _on_options_pressed() -> void:
	for button:Button in [%Resume, %Options, %Quit]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	$AnimationPlayer.play("pause_exit_with_bg")


func _on_options_closed(source:String) -> void:
	if source == source_string:
		$AnimationPlayer.play("pause_enter_with_bg")


func _on_resume_pressed():
	for button:Button in [%Resume, %Options, %Quit]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	$AnimationPlayer.play("pause_exit")


func _on_quit_pressed():
	for button:Button in [%Resume, %Options, %Quit]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	Global.pauseable = false
	Global.paused = false
	Global.change_scene_to("res://scenes/main_menu.tscn")
	await Global.trans_entered
	$AnimationPlayer.play("set_exit")
