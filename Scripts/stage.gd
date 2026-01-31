extends Node3D
var final_checkpoint = false

func _ready():
	Signalbus.checkpoint_reached.connect(_on_checkpoint_reached)
	$Stage_OST.play()
	resume()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		pause_menu()
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		resume()
	if final_checkpoint:
		$Stage_OST.stop()
		$Final_Checkpoint.play()
		
func pause_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	$CanvasLayer.show()
	$CanvasLayer/Resume.disabled = false
	$CanvasLayer/Quit.disabled = false
	$Stage_OST.volume_db = -10
	
func resume():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	$CanvasLayer.hide()
	$CanvasLayer/Resume.disabled = true
	$CanvasLayer/Quit.disabled = true
	$Stage_OST.volume_db = 0
	

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_checkpoint_reached():
	final_checkpoint = true
	print("checkpoint")
