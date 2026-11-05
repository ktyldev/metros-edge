extends Node

var pauseable := false
var paused := false
var loading_scene : String
@onready var timer : Timer = Timer.new()

signal trans_entered

func _ready():
	timer.one_shot = true
	add_child(timer)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(enter_scene)


func _process(delta):
	if ResourceLoader.load_threaded_get_status(loading_scene) == ResourceLoader.THREAD_LOAD_LOADED and timer.is_stopped():
		var scene = ResourceLoader.load_threaded_get(loading_scene)
		get_tree().change_scene_to_packed(scene)


func transition(transition:String = "enter"):
	%AnimationPlayer.play(transition)

func change_scene_to(scene:String):
	loading_scene = scene
	get_tree().paused = true
	UILayer.get_node("AnimationPlayer").play("enter")
	await UILayer.get_node("AnimationPlayer").animation_finished
	trans_entered.emit()
	timer.start(1.0)
	ResourceLoader.load_threaded_request(scene)

func enter_scene():
	UILayer.get_node("AnimationPlayer").play("exit")
	await UILayer.get_node("AnimationPlayer").animation_finished
	get_tree().paused = false
	Global.pauseable = loading_scene != "res://scenes/main_menu.tscn"
