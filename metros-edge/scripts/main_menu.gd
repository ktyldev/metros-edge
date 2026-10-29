extends Control


func _ready():
	for button:Button in [%Start, %Options]:
		button.connect("mouse_entered", _on_button_mouse_entered.bind(button))
		button.connect("mouse_exited", _on_button_mouse_exited.bind(button))
		button.connect("focus_entered", _on_button_focus_entered.bind(button))
		button.connect("focus_exited", _on_button_focus_exited.bind(button))


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
	elif button.name == "Options":
		%StartText.visible = false
		%StartSpinny.visible = false
		%OptionsText.visible = true
		%OptionSpinny.visible = true
		%AnimationPlayer.play("OptionsMarquee")


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
	elif button.name == "Options":
		%OptionsText.visible = false
		%OptionSpinny.visible = false
