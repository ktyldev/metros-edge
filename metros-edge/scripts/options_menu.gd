extends MarginContainer

func _ready():
	for node:Control in [%MusicSlider, %SFXSlider, %FOVSlider, %CheckBox, %BackButton]:
		node.connect("focus_entered", _on_node_focused.bind(node))
		node.connect("mouse_entered", _on_mouse_enetered.bind(node))


func _on_node_focused(node:Control) -> void:
	%MusicSelection.visible = false
	%SFXSelection.visible = false
	%FOVSelection.visible = false
	%FullscreenSelection.visible = false
	%MusicLabel.modulate = Color.WHITE
	%SFXLabel.modulate = Color.WHITE
	%FOVLabel.modulate = Color.WHITE 
	%FullscreenLabel.modulate = Color.WHITE
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
		_:
			%AnimationPlayer.stop()
	%MusicMarq.visible = false
	%SFXMarq.visible = false
	%FOVMarq.visible = false
	%FullscreenMarq.visible = false


func _on_mouse_enetered(node:Control) -> void:
	node.grab_focus()
