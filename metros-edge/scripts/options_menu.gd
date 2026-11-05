extends MarginContainer

signal options_exited(String)

var source := ""
var entered := false

func _ready():
	for node:Control in [%MusicSlider, %SFXSlider, %FOVSlider, %CheckBox, %BackButton]:
		node.connect("focus_entered", _on_node_focused.bind(node))
		node.connect("focus_exited", _on_node_unfocused)
		node.connect("mouse_entered", _on_mouse_entered.bind(node))
		node.focus_mode = Control.FOCUS_NONE
		node.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED


func _on_node_focused(node:Control) -> void:
	#%AnimationPlayer.stop()
	match node.name:
		"MusicSlider":
			%MusicSelection.visible = true
			%MusicLabel.modulate = Color(0.765, 0.941, 1.0)
			%AnimationPlayer.play("music_marquee")
		"SFXSlider":
			%SFXSelection.visible = true
			%SFXLabel.modulate = Color(0.765, 0.941, 1.0)
			%AnimationPlayer.play("sfx_marquee")
		"FOVSlider":
			%FOVSelection.visible = true
			%FOVLabel.modulate = Color(0.765, 0.941, 1.0)
			%AnimationPlayer.play("fov_marquee")
		"CheckBox":
			%FullscreenSelection.visible = true
			%FullscreenLabel.modulate = Color(0.765, 0.941, 1.0)
			%AnimationPlayer.play("fullscreen_marquee")
		"BackButton":
			%BackSelection.visible = true
			%AnimationPlayer.stop()
	%MusicMarq.visible = false
	%SFXMarq.visible = false
	%FOVMarq.visible = false
	%FullscreenMarq.visible = false


func _on_node_unfocused() -> void:
	%MusicSelection.visible = false
	%SFXSelection.visible = false
	%FOVSelection.visible = false
	%FullscreenSelection.visible = false
	%BackSelection.visible = false
	%MusicLabel.modulate = Color.WHITE
	%SFXLabel.modulate = Color.WHITE
	%FOVLabel.modulate = Color.WHITE 
	%FullscreenLabel.modulate = Color.WHITE


func _on_mouse_entered(node:Control) -> void:
	node.grab_focus()


func enter(from_source:String) -> void:
	$AnimationPlayer.play("options_enter")
	source = from_source
	await $AnimationPlayer.animation_finished
	entered = true
	for node:Control in [%MusicSlider, %SFXSlider, %FOVSlider, %CheckBox, %BackButton]:
		node.focus_mode = Control.FOCUS_ALL
		node.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED


func _on_back_button_pressed() -> void:
	for node:Control in [%MusicSlider, %SFXSlider, %FOVSlider, %CheckBox, %BackButton]:
		node.focus_mode = Control.FOCUS_NONE
		node.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	$AnimationPlayer.play("options_exit")
	await $AnimationPlayer.animation_finished
	entered = false
	options_exited.emit(source)
	source = ""


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
