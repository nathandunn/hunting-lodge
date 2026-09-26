extends Node3D
## Hunting Lodge Lighting — Scene-specific presets
## Handles WorldEnvironment, DirectionalLight3D, and point lights per scene

class_name HuntingLodgeLighting

# Scene enum
enum Scene {
	ARRIVAL = 1,
	GREAT_ROOM = 2,
	DINING_ROOM = 3,
	GUN_ROOM = 4,
	MOORLAND = 5,
	DUSK = 6
}

# Lights
var world_env: WorldEnvironment
var dir_light: DirectionalLight3D
var point_lights: Array[PointLight3D] = []

# Lighting data per scene
var lighting_presets: Dictionary = {
	Scene.ARRIVAL: {
		"sky_color": Color(0.87, 0.9, 0.95),
		"ambient_light_color": Color(0.9, 0.85, 0.7),
		"ambient_light_energy": 0.6,
		"dir_light_color": Color(1.0, 0.9, 0.7),
		"dir_light_energy": 1.2,
		"dir_light_angle": Vector3(45, -45, 0),  # angle, elevation, roll
		"shadow_blur": 2.0,
		"fog_enabled": false,
	},
	Scene.GREAT_ROOM: {
		"sky_color": Color(0.6, 0.55, 0.5),  # Darker interior
		"ambient_light_color": Color(0.85, 0.7, 0.45),  # Warm amber
		"ambient_light_energy": 0.4,
		"dir_light_color": Color(1.0, 0.8, 0.4),  # Fireplace glow
		"dir_light_energy": 0.7,
		"dir_light_angle": Vector3(60, -30, 0),
		"shadow_blur": 3.0,
		"fog_enabled": false,
		"point_lights": [
			{"pos": Vector3(-8, 8, 6), "energy": 0.5, "color": Color(1.0, 0.9, 0.5)},
			{"pos": Vector3(8, 8, 6), "energy": 0.5, "color": Color(1.0, 0.9, 0.5)},
			{"pos": Vector3(0, 2, 12), "energy": 0.6, "color": Color(1.0, 0.7, 0.3)},  # Fireplace
		],
	},
	Scene.DINING_ROOM: {
		"sky_color": Color(0.4, 0.35, 0.3),  # Very dark
		"ambient_light_color": Color(0.8, 0.65, 0.35),  # Candlelight
		"ambient_light_energy": 0.3,
		"dir_light_color": Color(1.0, 0.75, 0.3),
		"dir_light_energy": 0.4,
		"dir_light_angle": Vector3(70, -20, 0),
		"shadow_blur": 4.0,
		"fog_enabled": false,
		"point_lights": [
			{"pos": Vector3(1, 1.5, -0.5), "energy": 0.8, "color": Color(1.0, 0.9, 0.4)},  # Candelabra
			{"pos": Vector3(-1, 1.5, 0), "energy": 0.6, "color": Color(1.0, 0.85, 0.35)},  # Fill
		],
	},
	Scene.GUN_ROOM: {
		"sky_color": Color(0.7, 0.75, 0.8),  # Bright daytime
		"ambient_light_color": Color(1.0, 0.95, 0.85),  # Clinical white
		"ambient_light_energy": 0.8,
		"dir_light_color": Color(1.0, 0.98, 0.9),
		"dir_light_energy": 1.5,
		"dir_light_angle": Vector3(45, -60, 0),  # Overhead, clinical
		"shadow_blur": 1.0,  # Sharp shadows
		"fog_enabled": false,
		"point_lights": [
			{"pos": Vector3(-4, 4, 1), "energy": 0.7, "color": Color(1.0, 0.95, 0.85)},
			{"pos": Vector3(4, 4, 1), "energy": 0.7, "color": Color(1.0, 0.95, 0.85)},
		],
	},
	Scene.MOORLAND: {
		"sky_color": Color(1.0, 0.9, 0.65),  # Golden sky
		"ambient_light_color": Color(1.0, 0.9, 0.6),  # Warm ambient
		"ambient_light_energy": 0.7,
		"dir_light_color": Color(1.0, 0.95, 0.7),  # Low sun
		"dir_light_energy": 1.8,  # Strong dramatic light
		"dir_light_angle": Vector3(15, -75, 0),  # Low angle, side-lit
		"shadow_blur": 1.5,  # Sharp drama
		"fog_enabled": true,
		"fog_color": Color(0.9, 0.85, 0.7),
		"fog_density": 0.01,
	},
	Scene.DUSK: {
		"sky_color": Color(0.5, 0.4, 0.5),  # Purple-blue dusk
		"ambient_light_color": Color(0.6, 0.5, 0.7),  # Cool blue tint
		"ambient_light_energy": 0.4,
		"dir_light_color": Color(1.0, 0.7, 0.3),  # Dying warm light
		"dir_light_energy": 0.5,
		"dir_light_angle": Vector3(30, -80, 0),  # Very low, warm but fading
		"shadow_blur": 2.5,
		"fog_enabled": true,
		"fog_color": Color(0.4, 0.3, 0.5),
		"fog_density": 0.02,
	},
}

func _ready() -> void:
	_setup_lights()

func _setup_lights() -> void:
	"""Create and initialize all light nodes."""
	
	# WorldEnvironment for sky and ambient
	world_env = WorldEnvironment.new()
	var env = Environment.new()
	world_env.environment = env
	add_child(world_env)
	
	# DirectionalLight3D for sun/moon
	dir_light = DirectionalLight3D.new()
	dir_light.shadow_enabled = true
	dir_light.shadow_bias = 0.1
	add_child(dir_light)

func set_scene_lighting(scene: int) -> void:
	"""Apply lighting preset for a given scene."""
	if not lighting_presets.has(scene):
		push_error("Unknown scene: ", scene)
		return
	
	var preset = lighting_presets[scene]
	
	# Sky and ambient
	var env = world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = preset["sky_color"]
	env.ambient_light_source = Environment.AMBIENT_LIGHT_DISABLED
	env.ambient_light_energy = preset["ambient_light_energy"]
	env.ambient_light_energy_source = Environment.AMBIENT_LIGHT_ENERGY_WATT
	env.ambient_light = preset["ambient_light_color"]
	
	# Fog
	if preset.get("fog_enabled", false):
		env.fog_enabled = true
		env.fog_aerial_perspective = 0.1
		env.fog_density = preset.get("fog_density", 0.01)
		env.fog_light_color = preset.get("fog_color", Color.WHITE)
	else:
		env.fog_enabled = false
	
	# Directional light
	dir_light.light_color = preset["dir_light_color"]
	dir_light.light_energy = preset["dir_light_energy"]
	dir_light.shadow_blur = preset["shadow_blur"]
	
	# Rotation (angle, elevation, roll)
	var angle = preset["dir_light_angle"]
	dir_light.rotation.y = deg_to_rad(angle.y)
	dir_light.rotation.x = deg_to_rad(-angle.x)
	dir_light.rotation.z = deg_to_rad(angle.z)
	
	# Clear old point lights
	for light in point_lights:
		light.queue_free()
	point_lights.clear()
	
	# Add scene-specific point lights
	if preset.has("point_lights"):
		for light_data in preset["point_lights"]:
			var point_light = PointLight3D.new()
			point_light.light_color = light_data["color"]
			point_light.light_energy = light_data["energy"]
			point_light.omni_range = 5.0  # Adjust per scene if needed
			point_light.position = light_data["pos"]
			point_light.shadow_enabled = true
			add_child(point_light)
			point_lights.append(point_light)

func transition_scene_lighting(from_scene: int, to_scene: int, duration: float = 2.0) -> void:
	"""Smooth transition between two scene lightings."""
	var from_preset = lighting_presets.get(from_scene)
	var to_preset = lighting_presets.get(to_scene)
	
	if not from_preset or not to_preset:
		push_error("Invalid scene transition: ", from_scene, " -> ", to_scene)
		return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Interpolate ambient light color
	tween.tween_method(
		func(t: float):
			var env = world_env.environment
			env.background_color = from_preset["sky_color"].lerp(to_preset["sky_color"], t)
			env.ambient_light = from_preset["ambient_light_color"].lerp(to_preset["ambient_light_color"], t)
			env.ambient_light_energy = lerp(from_preset["ambient_light_energy"], to_preset["ambient_light_energy"], t)
			
			dir_light.light_color = from_preset["dir_light_color"].lerp(to_preset["dir_light_color"], t)
			dir_light.light_energy = lerp(from_preset["dir_light_energy"], to_preset["dir_light_energy"], t)
		,
		0.0,
		1.0,
		duration
	)
	
	# At end of transition, set full preset (catches point lights, fog, etc.)
	await tween.finished
	set_scene_lighting(to_scene)

# Utility: quick getters for color/energy values
func get_preset_color(scene: int, key: String) -> Color:
	if lighting_presets.has(scene) and lighting_presets[scene].has(key):
		return lighting_presets[scene][key]
	return Color.WHITE

func get_preset_energy(scene: int, key: String) -> float:
	if lighting_presets.has(scene) and lighting_presets[scene].has(key):
		return lighting_presets[scene][key]
	return 1.0
