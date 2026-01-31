extends StaticBody3D

func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	if body.is_in_group("player"):
		Signalbus.emit_signal("checkpoint_reached",self)
		
