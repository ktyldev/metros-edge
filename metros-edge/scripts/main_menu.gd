extends Control


var source_string := "main"


func _ready():
	for button:Button in [%Start, %Options]:
		button.connect("mouse_entered", _on_button_mouse_entered.bind(button))
		button.connect("mouse_exited", _on_button_mouse_exited.bind(button))
		button.connect("focus_entered", _on_button_focus_entered.bind(button))
		button.connect("focus_exited", _on_button_focus_exited.bind(button))
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	UILayer.get_node("Options").connect("options_exited", _on_options_closed)


func _on_button_mouse_entered(button:Button) -> void:
	button.grab_focus()


func _on_button_focus_entered(button:Button) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(button.get_parent(), "offset_transform_position", Vector2(12, 0), 0.3)
	if button.name == "Start":
		%StartText.visible = true
		%StartSpinny.visible = true
		%OptionsText.visible = false
		%OptionSpinny.visible = false
		%AnimationPlayer.play("StartMarquee")
		%StartGradient.visible = true
	elif button.name == "Options":
		%StartText.visible = false
		%StartSpinny.visible = false
		%OptionsText.visible = true
		%OptionSpinny.visible = true
		%AnimationPlayer.play("OptionsMarquee")
		%OptionGradient.visible = true


func _on_button_mouse_exited(button:Button) -> void:
	button.release_focus()


func _on_button_focus_exited(button:Button) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(button.get_parent(), "offset_transform_position", Vector2(0, 0), 0.3)
	if button.name == "Start":
		%StartText.visible = false
		%StartSpinny.visible = false
		%StartGradient.visible = false
	elif button.name == "Options":
		%OptionsText.visible = false
		%OptionSpinny.visible = false
		%OptionGradient.visible = false


func _on_options_pressed() -> void:
	for button:Button in [%Start, %Options]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	$AnimationPlayer.play("start_exit")
	await $AnimationPlayer.animation_finished
	UILayer.get_node("Options").enter(source_string)


func _on_options_closed(source:String) -> void:
	if source == source_string:
		$AnimationPlayer.play("start_enter")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "start_enter":
		for button:Button in [%Start, %Options]:
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED


func _on_start_pressed():
	Global.change_scene_to("res://scenes/main.tscn")
