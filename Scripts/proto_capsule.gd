extends CharacterBody3D

@onready var label: Label = $"../Label"

# =====================
# Movement tuning
# =====================
@export var move_speed := 30.0
@export var ground_accel := 120.0
@export var ground_deaccel := 90.0

@export var air_accel := 30.0
@export var air_deaccel := 10.0

@export var jump_velocity := 20.0

@export var gravity_strength := 40.0
@export var fall_multiplier := 3.5

# =====================
# Dash tuning
# =====================
@export var dash_speed := 80.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.8

@export var max_jumps := 2
@export var max_dashes := 2

@export var dash_preserve_vertical := true
@export var dash_keep_best_speed := true

# =====================
# Wall run tuning (Titanfall/BO3-ish)
# =====================
@export var wall_run_speed := 65.0
@export var wall_run_duration := 1.0
@export var wall_run_cooldown := 0.2

@export var wall_detect_distance := 1.0
@export var wall_ray_height := 1.0

@export var wall_stick_force := 25.0
@export var wall_run_gravity_scale := 0.35
@export var wall_run_max_fall_speed := 12.0

@export var wall_jump_up := 18.0
@export var wall_jump_push := 22.0
@export var wall_jump_forward_boost := 8.0

@export var wall_collision_mask := 1

# =====================
# Debug label tuning
# =====================
@export var show_debug_label := true
@export var show_speed_in_label := true

var debug_override_text := ""
var debug_override_timer := 0.0

# =====================
# State
# =====================
var jumps_left := 0
var dashes_left := 0

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var dash_saved_y := 0.0

var was_on_floor := false

var is_wall_running := false
var wall_run_timer := 0.0
var wall_run_cooldown_timer := 0.0
var wall_normal := Vector3.ZERO

@onready var cam_pivot: Node3D = $SprintArmPivot
var look_x := 0.0
@export var mouse_sensitivity := 0.002

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	jumps_left = max_jumps
	dashes_left = max_dashes
	_update_label("READY")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal rotation
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Vertical rotation
		look_x -= event.relative.y * mouse_sensitivity
		look_x = clamp(look_x, -1.2, 1.2) # clamp vertical look
		cam_pivot.rotation.x = look_x

func _physics_process(delta: float) -> void:
	# =====================
	# Label override timer (for short messages like WALL JUMP)
	# =====================
	if debug_override_timer > 0.0:
		debug_override_timer -= delta
		if debug_override_timer <= 0.0:
			debug_override_timer = 0.0
			debug_override_text = ""

	var on_floor_now := is_on_floor()

	# --- Landing reset ---
	if on_floor_now and not was_on_floor:
		jumps_left = max_jumps
		dashes_left = max_dashes

	was_on_floor = on_floor_now

	# --- Cooldowns ---
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0.0:
			dash_cooldown_timer = 0.0

	if wall_run_cooldown_timer > 0.0:
		wall_run_cooldown_timer -= delta
		if wall_run_cooldown_timer < 0.0:
			wall_run_cooldown_timer = 0.0

	# --- Camera-relative input ---
	var input_vec := Input.get_vector("left", "right", "forward", "back")

	var move_dir := cam_pivot.global_transform.basis * Vector3(input_vec.x, 0, input_vec.y)
	move_dir.y = 0.0
	if move_dir.length() > 0.1:
		move_dir = move_dir.normalized()
	else:
		move_dir = Vector3.ZERO

	var cam_forward := -cam_pivot.global_transform.basis.z
	cam_forward.y = 0.0
	if cam_forward.length() > 0.001:
		cam_forward = cam_forward.normalized()

	var cam_right := cam_pivot.global_transform.basis.x
	cam_right.y = 0.0
	if cam_right.length() > 0.001:
		cam_right = cam_right.normalized()

	var wants_forward := input_vec.y < -0.2

	# =====================
	# Dash active
	# =====================
	if is_dashing:
		_update_label("DASH", on_floor_now)
		dash_timer -= delta

		var target_dash_speed := dash_speed
		if dash_keep_best_speed:
			var current_h := Vector3(velocity.x, 0, velocity.z).length()
			if current_h > target_dash_speed:
				target_dash_speed = current_h

		velocity.x = dash_direction.x * target_dash_speed
		velocity.z = dash_direction.z * target_dash_speed

		if dash_preserve_vertical:
			velocity.y = dash_saved_y
		else:
			velocity.y = 0.0

		if dash_timer <= 0.0:
			is_dashing = false

	else:
		# =====================
		# Wall run update / start
		# =====================
		if is_wall_running:
			_update_label("WALL RUN", on_floor_now)
			update_wall_run(delta, cam_forward, wants_forward)
		else:
			if (not on_floor_now) and wants_forward and wall_run_cooldown_timer <= 0.0:
				var found_wall := try_start_wall_run(cam_right)
				if found_wall:
					_update_label("WALL RUN", on_floor_now)
					move_and_slide()
					return

		# =====================
		# Gravity (normal)
		# =====================
		if not is_wall_running:
			if velocity.y < 0.0:
				velocity.y -= gravity_strength * fall_multiplier * delta
			else:
				velocity.y -= gravity_strength * delta

		# =====================
		# Jump (normal + wall jump)
		# =====================
		if Input.is_action_just_pressed("jump"):
			if is_wall_running:
				do_wall_jump(cam_forward)
				# do_wall_jump sets a short label override
			else:
				if jumps_left > 0:
					velocity.y = jump_velocity
					jumps_left -= 1

		# =====================
		# Horizontal movement
		# =====================
		if not is_wall_running:
			var accel := air_accel
			var deaccel := air_deaccel
			if on_floor_now:
				accel = ground_accel
				deaccel = ground_deaccel

			if move_dir != Vector3.ZERO:
				velocity.x = move_toward(velocity.x, move_dir.x * move_speed, accel * delta)
				velocity.z = move_toward(velocity.z, move_dir.z * move_speed, accel * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, deaccel * delta)
				velocity.z = move_toward(velocity.z, 0.0, deaccel * delta)

		# =====================
		# Dash start (blocked during wall run)
		# =====================
		if (not is_wall_running) and Input.is_action_just_pressed("dash") and dashes_left > 0 and dash_cooldown_timer <= 0.0:
			start_dash(move_dir)
			_update_label("DASH", on_floor_now)

		# =====================
		# Default label when not dashing/wall-running
		# =====================
		if not is_wall_running:
			if on_floor_now:
				_update_label("GROUND", on_floor_now)
			else:
				_update_label("AIR", on_floor_now)

	move_and_slide()

# =====================
# Label helper
# =====================
func _update_label(state_text: String, on_floor_now: bool = false) -> void:
	if not show_debug_label:
		return
	if label == null:
		return

	var text := state_text

	# temporary override (e.g., WALL JUMP)
	if debug_override_text != "" and debug_override_timer > 0.0:
		text = debug_override_text

	if show_speed_in_label:
		var hspeed := Vector3(velocity.x, 0, velocity.z).length()
		text += " | h: " + str(snappedf(hspeed, 0.01))
		text += " | J: " + str(jumps_left) + "/" + str(max_jumps)
		text += " | D: " + str(dashes_left) + "/" + str(max_dashes)

	label.text = text

# =====================
# Dash helper
# =====================
func start_dash(direction: Vector3) -> void:
	var dir := direction
	if dir == Vector3.ZERO:
		dir = -cam_pivot.global_transform.basis.z

	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dashes_left -= 1

	dash_direction = dir.normalized()
	dash_saved_y = velocity.y

# =====================
# Wall run helpers
# =====================
func try_start_wall_run(cam_right: Vector3) -> bool:
	var origin := global_transform.origin + Vector3.UP * wall_ray_height

	var left_hit := raycast_wall(origin, -cam_right)
	var right_hit := raycast_wall(origin, cam_right)

	if left_hit.has("normal") and not right_hit.has("normal"):
		begin_wall_run(left_hit["normal"] as Vector3)
		return true

	if right_hit.has("normal") and not left_hit.has("normal"):
		begin_wall_run(right_hit["normal"] as Vector3)
		return true

	if left_hit.has("normal") and right_hit.has("normal"):
		var vel_h := Vector3(velocity.x, 0, velocity.z)
		if vel_h.length() < 0.1:
			begin_wall_run(right_hit["normal"] as Vector3)
			return true

		var left_normal: Vector3 = left_hit["normal"] as Vector3
		var right_normal: Vector3 = right_hit["normal"] as Vector3

		var left_score: float = abs(vel_h.normalized().dot(left_normal))
		var right_score: float = abs(vel_h.normalized().dot(right_normal))

		if left_score > right_score:
			begin_wall_run(left_normal)
		else:
			begin_wall_run(right_normal)
		return true

	return false

func begin_wall_run(hit_normal: Vector3) -> void:
	is_wall_running = true
	wall_run_timer = wall_run_duration
	wall_normal = hit_normal.normalized()

	if velocity.y < -wall_run_max_fall_speed:
		velocity.y = -wall_run_max_fall_speed

func update_wall_run(delta: float, cam_forward: Vector3, wants_forward: bool) -> void:
	wall_run_timer -= delta

	if is_on_floor():
		end_wall_run()
		return

	if wall_run_timer <= 0.0:
		end_wall_run()
		return

	if not wants_forward:
		end_wall_run()
		return

	var cam_right := cam_pivot.global_transform.basis.x
	cam_right.y = 0.0
	if cam_right.length() > 0.001:
		cam_right = cam_right.normalized()

	var origin := global_transform.origin + Vector3.UP * wall_ray_height

	var left_hit := raycast_wall(origin, -cam_right)
	var right_hit := raycast_wall(origin, cam_right)

	var still_on_wall := false
	if left_hit.has("normal"):
		wall_normal = (left_hit["normal"] as Vector3).normalized()
		still_on_wall = true
	if right_hit.has("normal"):
		wall_normal = (right_hit["normal"] as Vector3).normalized()
		still_on_wall = true

	if not still_on_wall:
		end_wall_run()
		return

	var along := cam_forward - wall_normal * cam_forward.dot(wall_normal)
	if along.length() < 0.001:
		end_wall_run()
		return
	along = along.normalized()

	velocity.x = along.x * wall_run_speed
	velocity.z = along.z * wall_run_speed

	var wall_grav := gravity_strength * wall_run_gravity_scale
	velocity.y -= wall_grav * delta

	if velocity.y < -wall_run_max_fall_speed:
		velocity.y = -wall_run_max_fall_speed

	velocity += -wall_normal * wall_stick_force * delta

func do_wall_jump(cam_forward: Vector3) -> void:
	end_wall_run()

	var push := wall_normal * wall_jump_push
	var up := Vector3.UP * wall_jump_up
	var forward := cam_forward * wall_jump_forward_boost

	velocity = push + up + forward

	dashes_left = max_dashes
	jumps_left = max_jumps

	# Label flash
	debug_override_text = "WALL JUMP"
	debug_override_timer = 0.25
	_update_label("WALL JUMP")

func end_wall_run() -> void:
	if is_wall_running:
		is_wall_running = false
		wall_run_timer = 0.0
		wall_run_cooldown_timer = wall_run_cooldown

func raycast_wall(origin: Vector3, dir: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = origin + dir.normalized() * wall_detect_distance
	query.collision_mask = wall_collision_mask
	query.exclude = [self]

	return space.intersect_ray(query)
