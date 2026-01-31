extends Camera3D

@export var spring_arm: Node3D
@export var lerp_power: float = 1.0

#if want to switch to 1st person perspective
@export var normal_fov := 70.0
@export var dash_fov := 88.0
@export var fov_speed := 10.0

var target_fov := 70.0


func set_dash_fov(active: bool):
	if active:
		target_fov = dash_fov
	else:
		target_fov = normal_fov


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(position, spring_arm.position, delta * lerp_power)
	
	#if want to switch to 1st person perspective
	#fov = lerp(fov, target_fov, delta * fov_speed)
