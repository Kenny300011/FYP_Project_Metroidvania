extends Control

var progress = []
var scene
var scene_load_status = 0

func _ready():
	scene = "res://Scenes/stage.tscn"
	ResourceLoader.load_threaded_request(scene)
	
func _process(delta: float) -> void:
	scene_load_status = ResourceLoader.load_threaded_get_status(scene,progress)
	$Label.text = str(floor(progress[0]*100)) + "%"
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(scene)
		get_tree().change_scene_to_packed(new_scene)
