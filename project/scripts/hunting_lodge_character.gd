extends Node3D
## Hunting Lodge Character — FaceCard + body for the pacifist couple
## Handles face rotation, posture, and corruption progression

class_name HuntingLodgeCharacter

# Face indices (from flip book project)
enum Face { WOMAN = 0, MAN = 1 }

@export var face_index: int = Face.WOMAN
@export var character_name: String = "Character"

# Components
var face_card: Node3D  # Should be a MeshInstance3D with FaceCard material
var body: Node3D  # Simple capsule or block for body

# State
var current_rotation: float = 0.0  # Z-axis rotation in degrees
var current_posture: Vector3 = Vector3.ZERO  # Body position offset for slouch/tension

func _ready() -> void:
	_build_character()

func _build_character() -> void:
	"""Build character mesh with FaceCard and body."""
	
	# Body (simple capsule)
	var body_mesh = CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 2.0
	
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.9, 0.8, 0.7)  # Skin tone
	
	var body_instance = MeshInstance3D.new()
	body_instance.mesh = body_mesh
	body_instance.set_surface_override_material(0, body_material)
	body_instance.position.y = 1.0
	add_child(body_instance)
	body = body_instance
	
	# FaceCard (paper cutout head)
	# This references the face texture from the flip book project
	# Face dimensions: 160x160 px, rendered at 0.62 quad size
	var face_quad = QuadMesh.new()
	face_quad.size = Vector2(0.62, 0.62)
	
	# Material: unlit, alpha, double-sided (matching ink.gd from flipbook-field)
	var face_material = StandardMaterial3D.new()
	face_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Load face texture (assuming it's at res://faces/face_XX.png from your project)
	var texture_path = "res://faces/face_%02d.png" % face_index
	var face_texture = load(texture_path)
	if face_texture:
		face_material.albedo_texture = face_texture
	else:
		# Fallback: solid color if texture missing
		face_material.albedo_color = Color(1.0, 0.9, 0.8)
	
	var face_quad_instance = MeshInstance3D.new()
	face_quad_instance.mesh = face_quad
	face_quad_instance.set_surface_override_material(0, face_material)
	face_quad_instance.position.y = 1.8  # Head height
	add_child(face_quad_instance)
	face_card = face_quad_instance

func set_corruption_state(scene: int, animate: bool = true) -> void:
	"""Set rotation and posture based on corruption level (scene progression)."""
	var target_rotation: float = 0.0
	var target_posture: Vector3 = Vector3.ZERO
	
	match scene:
		1:  # ARRIVAL: Neutral, upright
			target_rotation = 0.0
			target_posture = Vector3(0, 0, 0)
		2:  # GREAT_ROOM: Slight unease, beginning angle
			target_rotation = 10.0
			target_posture = Vector3(0, -0.05, 0)  # Slight stiffening
		3:  # DINING_ROOM: Curious tilt, leaning in
			target_rotation = 18.0
			target_posture = Vector3(0, -0.1, 0)
		4:  # GUN_ROOM: Profile, assertive
			target_rotation = 40.0
			target_posture = Vector3(0, -0.15, 0)
		5:  # MOORLAND: Extreme profile, wild
			target_rotation = 75.0
			target_posture = Vector3(0, -0.2, 0)
		6:  # DUSK: Bowed, shame
			target_rotation = 0.0
			target_posture = Vector3(0, 0.3, 0)  # Head down
	
	if animate:
		_animate_rotation(target_rotation, 1.0)
		_animate_posture(target_posture, 1.0)
	else:
		current_rotation = target_rotation
		current_posture = target_posture
		_update_visual()

func _animate_rotation(target: float, duration: float) -> void:
	"""Smoothly rotate face card to target angle."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(val: float):
			current_rotation = val
			_update_visual(),
		current_rotation,
		target,
		duration
	)

func _animate_posture(target: Vector3, duration: float) -> void:
	"""Smoothly change posture."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(val: Vector3):
			current_posture = val
			_update_visual(),
		current_posture,
		target,
		duration
	)

func _update_visual() -> void:
	"""Apply current rotation and posture to face card and body."""
	if face_card:
		face_card.rotation.z = deg_to_rad(current_rotation)
		face_card.position.y = 1.8 + current_posture.y
	
	if body:
		body.position += current_posture * 0.1

func set_position_in_scene(scene: int) -> void:
	"""Position character in space based on scene and face index."""
	# Woman (wavy hair) is typically frame-left, man (spiky) frame-right
	var x_offset = -1.5 if face_index == Face.WOMAN else 1.5
	
	match scene:
		1:  # ARRIVAL: In front of lodge
			position = Vector3(x_offset, 0, -5)
		2:  # GREAT_ROOM: Standing in great room
			position = Vector3(x_offset + 2, 0.5, 3)
		3:  # DINING_ROOM: At the table, leaning
			position = Vector3(x_offset - 1, 0.5, 0)
		4:  # GUN_ROOM: Handling weapons
			position = Vector3(x_offset, 0.5, -1)
		5:  # MOORLAND: On the moor
			position = Vector3(x_offset + 3, 2, 5)
		6:  # DUSK: Descending steps
			position = Vector3(x_offset - 2, 0.5, -5)

func get_face_index() -> int:
	return face_index

func get_character_name() -> String:
	return character_name
