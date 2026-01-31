extends Node3D

@export var platform_scenes: Array[PackedScene] = []
@export var min_section_length := 2
@export var max_section_length := 5

@export var platform_count := 30  # total number of platforms to generate

# Directional movement for platform placement
var direction := Vector3.FORWARD

var rng := RandomNumberGenerator.new()
var last_position := Vector3(0, 780, 0)

# Type-specific gaps and heights
var platform_settings := [
	{"min_gap": 150, "max_gap": 200, "min_height": 0, "max_height": 20, "size": Vector3(372,1,108)}, # Road
	{"min_gap": 0, "max_gap": 10, "min_height": 0, "max_height": 15, "size": Vector3(45,15,1)},   # Wall
	{"min_gap": 150, "max_gap": 200, "min_height": 0, "max_height": 20, "size": Vector3(372,60,151)} # Hazard
]

func _ready():
	# Setup RNG with seed
	if LevelOptions.use_random_seed:
		rng.randomize()
		LevelOptions.seed = rng.randi_range(0, 999_999_999)
	else:
		LevelOptions.seed = clamp(LevelOptions.seed, 0, 999_999_999)
	rng.seed = LevelOptions.seed
	LevelOptions.save_seed()
	$seed.text = "SEED: %d" % LevelOptions.seed

	# Starting platform
	var starting_platform = platform_scenes[0].instantiate()
	starting_platform.position = last_position
	add_child(starting_platform)
	generate_level()

func generate_level():
	var spawned := 1
	while spawned < platform_count:
		if spawned == 4:
			spawn_platform(platform_scenes[2], platform_settings[2])
			spawned += 1
		# Pick a section length
		var section_length := rng.randi_range(min_section_length, max_section_length)

		# Pick a platform type
		var settings = platform_settings[0]
		var scene = platform_scenes[0]

		# Spawn section
		for i in range(section_length):
			if spawned >= platform_count:
				break
			spawn_platform(scene, settings)
			spawned += 1

	print("Seed:", LevelOptions.seed)

func spawn_platform(scene: PackedScene, settings: Dictionary):
	var platform = scene.instantiate()

	# Random gap & height for this platform type
	var gap = rng.randf_range(settings.min_gap, settings.max_gap)
	var height = rng.randf_range(settings.min_height, settings.max_height)

	last_position += direction * gap
	last_position.y += height

	platform.position = last_position
	add_child(platform)
	print("Spawned %s at %s" % [platform.name, last_position])
