extends Node

var pauseable := false
var paused := false
var loading_scene : String
@onready var load_timer : Timer = Timer.new()
@onready var level_timer : Timer = Timer.new()

signal trans_entered

# FMOD Stuff
var banks := Array()
var test_event: FmodEvent = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(enter_scene)
	
	load_fmod_banks()
	load_timer.one_shot = true
	add_child(load_timer)
	level_timer.one_shot = true
	add_child(level_timer)
	level_timer.connect("timeout", level_timer_timeout)


func start_level_timer():
	level_timer.start(20)


func level_timer_timeout():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(Engine, "time_scale", 0, 0.5)
	await tween.finished
	Engine.time_scale = 1.0
	get_tree().paused = true
	UILayer.get_node("LevelEndUI").lose()


func _process(delta):
	if ResourceLoader.load_threaded_get_status(loading_scene) == ResourceLoader.THREAD_LOAD_LOADED and load_timer.is_stopped():
		var scene = ResourceLoader.load_threaded_get(loading_scene)
		get_tree().change_scene_to_packed(scene)

func load_fmod_banks():
	banks.append(FmodServer.load_bank("res://assets/FMODBanks/Desktop/Master.strings.bank", FmodBank.ConnectFlags.CONNECT_REFERENCE_COUNTED))
	banks.append(FmodServer.load_bank("res://assets/FMODBanks/Desktop/Master.bank", FmodBank.ConnectFlags.CONNECT_REFERENCE_COUNTED))
	
	test_event = FmodServer.create_event_instance("event:/MUS_Menu")
	test_event.start()


func transition(transition:String = "enter"):
	%AnimationPlayer.play(transition)

func change_scene_to(scene:String):
	loading_scene = scene
	get_tree().paused = true
	UILayer.get_node("AnimationPlayer").play("enter")
	await UILayer.get_node("AnimationPlayer").animation_finished
	trans_entered.emit()
	load_timer.start(1.0)
	ResourceLoader.load_threaded_request(scene)

func enter_scene():
	UILayer.get_node("AnimationPlayer").play("exit")
	await UILayer.get_node("AnimationPlayer").animation_finished
	get_tree().paused = false
	Global.pauseable = loading_scene != "res://scenes/main_menu.tscn"
	if loading_scene != "res://scenes/main_menu.tscn":
		start_level_timer()
