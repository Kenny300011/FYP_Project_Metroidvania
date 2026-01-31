extends Node3D

func _ready() -> void:
	main_menu()
	$Main_Menu.play()
	$Options.play()
	$Options.volume_db = -40
	
func _physics_process(delta: float) -> void:
	$Camera3D.rotate_y(0.002)


func _on_option_pressed() -> void:
	if $Random_Seed.button_pressed:
		LevelOptions.use_random_seed = true
		LevelOptions.seed = 0
		var loadingscreen = load("res://Scenes/loading_screen.tscn")
		get_tree().change_scene_to_packed(loadingscreen)
	elif $Seed.button_pressed:
		LevelOptions.use_random_seed = false
		LevelOptions.seed = int($Seed_Input.text)
		if LevelOptions.load_seed():
			var loadingscreen = load("res://Scenes/loading_screen.tscn")
			get_tree().change_scene_to_packed(loadingscreen)
		else:
			print("No saved seed found")

func _on_play_pressed() -> void:
	dynamic_music($Options)
	switch_options()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func dynamic_music(music):
	var tween := get_tree().create_tween()
	if music == $Main_Menu:
		tween.set_parallel(true)
		tween.tween_property($Options,"volume_db",-40,0.5)
		tween.tween_property(music,"volume_db",0,1.0)
	elif music == $Options:
		tween.set_parallel(true)
		tween.tween_property($Main_Menu,"volume_db",-40,0.5)
		tween.tween_property(music,"volume_db",0,1.0)
	
func music_fade_in(music):
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(music,"volume_db",0,0.5)
	
func switch_options():
	$Play.disabled = true
	$Quit.disabled = true
	$Play.hide()
	$Quit.hide()
	$Start.disabled = false
	$back.disabled = false
	$Start.show()
	$back.show()
	$Random_Seed.disabled = false
	$Seed.disabled = false
	$Seed_Input.show()
	$Random_Seed.show()
	$Seed.show()
	
func main_menu():
	$Play.disabled = false
	$Quit.disabled = false
	$Play.show()
	$Quit.show()
	$Start.disabled = true
	$back.disabled = true
	$Start.hide()
	$back.hide()
	$Random_Seed.disabled = true
	$Seed.disabled = true
	$Seed_Input.editable = false
	$Seed_Input.hide()
	$Random_Seed.hide()
	$Seed.hide()
	
func _on_button_pressed() -> void:
	main_menu()
	dynamic_music($Main_Menu)


func _on_random_seed_toggled(pressed) -> void:
	$Seed_Input.editable = false


func _on_seed_toggled(pressed) -> void:
	$Seed_Input.editable = true
