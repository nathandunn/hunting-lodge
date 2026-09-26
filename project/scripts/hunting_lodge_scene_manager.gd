extends Node3D
## Hunting Lodge Scene Manager — Orchestrates scenes, lighting, camera, and dialogue
## Ties together HuntingLodgeBuilder, HuntingLodgeLighting, and FaceCard integration

class_name HuntingLodgeSceneManager

# Scene references
var lodge_builder: HuntingLodge
var lighting_controller: HuntingLodgeLighting
var current_scene_node: Node3D
var current_scene: int = 0

# Characters
var woman: HuntingLodgeCharacter
var man: HuntingLodgeCharacter

# Camera
var camera: Camera3D

# Dialogue
var dialogue_layer: CanvasLayer
var dialogue_label: Label

# State
var is_transitioning: bool = false

# Scene data: camera positions and dialogue per scene
var scene_data: Dictionary = {
	HuntingLodgeLighting.Scene.ARRIVAL: {
		"name": "Arrival",
		"camera_pos": Vector3(0, 3, -15),
		"camera_look_at": Vector3(0, 5, 0),
		"dialogue": ["My dear, how pleasant to escape the city and its vulgar blood sports.", "This lodge shall be a haven of civilised restraint."],
		"dialogue_timing": [0.5, 3.0],
	},
	HuntingLodgeLighting.Scene.GREAT_ROOM: {
		"name": "Great Room",
		"camera_pos": Vector3(0, 3, -5),
		"camera_look_at": Vector3(0, 6, 2),
		"dialogue": ["Dreadfully ugly, these trophies.", "All the more reason we shan't participate. We are above it."],
		"dialogue_timing": [0.5, 3.5],
	},
	HuntingLodgeLighting.Scene.DINING_ROOM: {
		"name": "Dining Room",
		"camera_pos": Vector3(-2, 1.5, -1),
		"camera_look_at": Vector3(0, 1.2, 0),
		"dialogue": ["These accounts are quite detailed.", "One supposes the technique requires... study.", "Mmm. Yes. Purely from an academic standpoint, you understand."],
		"dialogue_timing": [0.5, 2.5, 4.5],
	},
	HuntingLodgeLighting.Scene.GUN_ROOM: {
		"name": "Gun Room",
		"camera_pos": Vector3(0, 2.5, -3),
		"camera_look_at": Vector3(0, 2, 0),
		"dialogue": ["One really must understand the sport to critique it effectively.", "Precisely. We are merely... field researchers."],
		"dialogue_timing": [0.5, 3.0],
	},
	HuntingLodgeLighting.Scene.MOORLAND: {
		"name": "Moorland — The Hunt",
		"camera_pos": Vector3(-5, 3, 15),
		"camera_look_at": Vector3(5, 3, 5),
		"dialogue": ["Did you see—? Oh, magnificent!"],
		"dialogue_timing": [1.0],
	},
	HuntingLodgeLighting.Scene.DUSK: {
		"name": "Dusk — Reckoning",
		"camera_pos": Vector3(-8, 2, -10),
		"camera_look_at": Vector3(0, 1.5, 0),
		"dialogue": ["We came here to escape... and instead...", "Yes. We did rather become what we despised, didn't we?", "The lodge has that effect on people, I suspect."],
		"dialogue_timing": [0.5, 3.0, 5.5],
	},
}

func _ready() -> void:
	# Setup builders
	lodge_builder = HuntingLodge.new()
	add_child(lodge_builder)
	
	lighting_controller = HuntingLodgeLighting.new()
	add_child(lighting_controller)
	
	# Setup characters
	woman = HuntingLodgeCharacter.new()
	woman.face_index = HuntingLodgeCharacter.Face.WOMAN
	woman.character_name = "Woman"
	add_child(woman)
	
	man = HuntingLodgeCharacter.new()
	man.face_index = HuntingLodgeCharacter.Face.MAN
	man.character_name = "Man"
	add_child(man)
	
	# Setup camera
	camera = Camera3D.new()
	add_child(camera)
	get_viewport().set_camera_3d(camera)
	
	# Setup dialogue layer
	dialogue_layer = CanvasLayer.new()
	add_child(dialogue_layer)
	
	dialogue_label = Label.new()
	dialogue_label.anchor_left = 0.5
	dialogue_label.anchor_top = 1.0
	dialogue_label.offset_left = -300
	dialogue_label.offset_top = -80
	dialogue_label.size = Vector2(600, 60)
	dialogue_label.text = ""
	dialogue_label.alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_font_size_override("font_size", 24)
	dialogue_label.add_theme_color_override("font_color", Color.BLACK)
	dialogue_layer.add_child(dialogue_label)
	
	# Start first scene
	show_scene(HuntingLodgeLighting.Scene.ARRIVAL)

func show_scene(scene: int) -> void:
	"""Load and display a scene with lighting and dialogue."""
	if is_transitioning:
		return
	
	if scene == current_scene and current_scene_node:
		return
	
	is_transitioning = true
	
	var old_scene = current_scene
	current_scene = scene
	
	# Transition lighting
	if old_scene > 0:
		await lighting_controller.transition_scene_lighting(old_scene, scene, 1.5)
	else:
		lighting_controller.set_scene_lighting(scene)
	
	# Clear old scene
	if current_scene_node:
		current_scene_node.queue_free()
	
	# Build new scene
	match scene:
		HuntingLodgeLighting.Scene.ARRIVAL:
			current_scene_node = lodge_builder.build_scene_1_arrival()
		HuntingLodgeLighting.Scene.GREAT_ROOM:
			current_scene_node = lodge_builder.build_scene_2_interior_great_room()
		HuntingLodgeLighting.Scene.DINING_ROOM:
			current_scene_node = lodge_builder.build_scene_3_dining_room()
		HuntingLodgeLighting.Scene.GUN_ROOM:
			current_scene_node = lodge_builder.build_scene_4_gun_room()
		HuntingLodgeLighting.Scene.MOORLAND:
			current_scene_node = lodge_builder.build_scene_5_moorland()
		HuntingLodgeLighting.Scene.DUSK:
			current_scene_node = lodge_builder.build_scene_6_dusk()
	
	add_child(current_scene_node)
	current_scene_node.position = Vector3.ZERO
	
	# Position and corrupt characters
	woman.set_position_in_scene(scene)
	man.set_position_in_scene(scene)
	woman.set_corruption_state(scene, animate=true)
	man.set_corruption_state(scene, animate=true)
	
	# Position camera
	var data = scene_data[scene]
	camera.global_position = data["camera_pos"]
	camera.look_at(data["camera_look_at"], Vector3.UP)
	
	# Play dialogue
	_play_dialogue(data.get("dialogue", []), data.get("dialogue_timing", []))
	
	is_transitioning = false

func _play_dialogue(lines: Array, timings: Array) -> void:
	"""Display dialogue lines with timing."""
	dialogue_label.text = ""
	
	for i in range(lines.size()):
		var delay = timings[i] if i < timings.size() else 1.0
		await get_tree().create_timer(delay).timeout
		dialogue_label.text = lines[i]
	
	# Clear after final line
	var final_delay = timings[-1] + 2.5 if timings.size() > 0 else 3.5
	await get_tree().create_timer(final_delay).timeout
	dialogue_label.text = ""

func next_scene() -> void:
	"""Advance to next scene."""
	var next = current_scene + 1
	if next <= HuntingLodgeLighting.Scene.DUSK:
		show_scene(next)

func prev_scene() -> void:
	"""Go back to previous scene."""
	var prev = current_scene - 1
	if prev >= HuntingLodgeLighting.Scene.ARRIVAL:
		show_scene(prev)

func _input(event: InputEvent) -> void:
	"""Keyboard controls for testing."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_D:
				next_scene()
			KEY_LEFT, KEY_A:
				prev_scene()
			KEY_R:
				show_scene(current_scene)  # Reload current
			KEY_ESCAPE:
				get_tree().quit()
