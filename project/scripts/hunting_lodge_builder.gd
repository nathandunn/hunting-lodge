extends Node3D
## Hunting Lodge — Procedural 3D modeling
## Six scenes for the Wodehouse pacifist couple narrative

class_name HuntingLodge

# Materials
var mat_stone: StandardMaterial3D
var mat_wood_dark: StandardMaterial3D
var mat_wood_light: StandardMaterial3D
var mat_brass: StandardMaterial3D
var mat_leather: StandardMaterial3D
var mat_grass: StandardMaterial3D
var mat_sky: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	# Build scenes on demand; for now, build the lodge shell
	build_lodge_shell()

func _setup_materials() -> void:
	# Stone
	mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.65, 0.62, 0.58)
	mat_stone.roughness = 0.8
	
	# Dark wood (gun room, dining)
	mat_wood_dark = StandardMaterial3D.new()
	mat_wood_dark.albedo_color = Color(0.3, 0.25, 0.15)
	mat_wood_dark.roughness = 0.6
	
	# Light wood (doors, trim)
	mat_wood_light = StandardMaterial3D.new()
	mat_wood_light.albedo_color = Color(0.7, 0.6, 0.45)
	mat_wood_light.roughness = 0.7
	
	# Brass fixtures
	mat_brass = StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.9, 0.75, 0.3)
	mat_brass.metallic = 1.0
	mat_brass.roughness = 0.3
	
	# Leather
	mat_leather = StandardMaterial3D.new()
	mat_leather.albedo_color = Color(0.4, 0.3, 0.2)
	mat_leather.roughness = 0.8
	
	# Grass
	mat_grass = StandardMaterial3D.new()
	mat_grass.albedo_color = Color(0.3, 0.5, 0.2)
	mat_grass.roughness = 0.9
	
	# Sky
	mat_sky = StandardMaterial3D.new()
	mat_sky.albedo_color = Color(0.7, 0.8, 0.9)

func build_lodge_shell() -> void:
	"""Build the main lodge structure and interior shells."""
	
	# Ground
	var ground = CSGBox3D.new()
	ground.size = Vector3(100, 0.5, 100)
	ground.material = mat_grass
	add_child(ground)
	
	# Main lodge body: central rectangular block
	var lodge_body = CSGBox3D.new()
	lodge_body.size = Vector3(30, 15, 20)
	lodge_body.position = Vector3(0, 7.5, 0)
	lodge_body.material = mat_stone
	add_child(lodge_body)
	
	# Roof (simple pitched)
	var roof_left = CSGBox3D.new()
	roof_left.size = Vector3(30, 2, 10)
	roof_left.position = Vector3(-5, 15, 0)
	roof_left.rotation.z = deg_to_rad(20)
	roof_left.material = mat_wood_dark
	add_child(roof_left)
	
	var roof_right = CSGBox3D.new()
	roof_right.size = Vector3(30, 2, 10)
	roof_right.position = Vector3(5, 15, 0)
	roof_right.rotation.z = deg_to_rad(-20)
	roof_right.material = mat_wood_dark
	add_child(roof_right)
	
	# Front entrance (portico)
	_build_entrance()
	
	# Windows
	_build_windows()
	
	# Interior rooms (CSG negative volumes for open spaces)
	_build_interior_volumes()

func _build_entrance() -> void:
	"""Front entrance portico."""
	var columns_left = CSGCylinder3D.new()
	columns_left.radius = 0.8
	columns_left.height = 5
	columns_left.position = Vector3(-5, 2.5, -10)
	columns_left.material = mat_stone
	add_child(columns_left)
	
	var columns_right = CSGCylinder3D.new()
	columns_right.radius = 0.8
	columns_right.height = 5
	columns_right.position = Vector3(5, 2.5, -10)
	columns_right.material = mat_stone
	add_child(columns_right)
	
	# Portico roof
	var portico_roof = CSGBox3D.new()
	portico_roof.size = Vector3(12, 1, 3)
	portico_roof.position = Vector3(0, 5.5, -10)
	portico_roof.material = mat_wood_dark
	add_child(portico_roof)
	
	# Front door
	var door = CSGBox3D.new()
	door.size = Vector3(2, 4, 0.3)
	door.position = Vector3(0, 2, -10.1)
	door.material = mat_wood_light
	add_child(door)

func _build_windows() -> void:
	"""Windows on front and sides."""
	# Front windows (symmetrical)
	var front_win_left = CSGBox3D.new()
	front_win_left.size = Vector3(2, 2, 0.2)
	front_win_left.position = Vector3(-6, 8, -10.1)
	add_child(front_win_left)
	
	var front_win_right = CSGBox3D.new()
	front_win_right.size = Vector3(2, 2, 0.2)
	front_win_right.position = Vector3(6, 8, -10.1)
	add_child(front_win_right)
	
	# Side windows
	for i in range(3):
		var side_left = CSGBox3D.new()
		side_left.size = Vector3(0.2, 2, 2)
		side_left.position = Vector3(-15.1, 8 - (i * 2.5), -5 + (i * 4))
		add_child(side_left)
		
		var side_right = CSGBox3D.new()
		side_right.size = Vector3(0.2, 2, 2)
		side_right.position = Vector3(15.1, 8 - (i * 2.5), -5 + (i * 4))
		add_child(side_right)

func _build_interior_volumes() -> void:
	"""Interior room shells (will be detailed per scene)."""
	# Great room (high ceiling, central)
	var great_room = CSGBox3D.new()
	great_room.size = Vector3(20, 12, 12)
	great_room.position = Vector3(0, 6, 2)
	great_room.operation = CSGShape3D.OPERATION_SUBTRACT
	add_child(great_room)
	
	# Gun room (rear left)
	var gun_room = CSGBox3D.new()
	gun_room.size = Vector3(8, 8, 8)
	gun_room.position = Vector3(-8, 4, 8)
	gun_room.operation = CSGShape3D.OPERATION_SUBTRACT
	add_child(gun_room)
	
	# Dining room (rear right)
	var dining_room = CSGBox3D.new()
	dining_room.size = Vector3(8, 8, 8)
	dining_room.position = Vector3(8, 4, 8)
	dining_room.operation = CSGShape3D.OPERATION_SUBTRACT
	add_child(dining_room)

func build_scene_1_arrival() -> Node3D:
	"""Scene 1: Exterior arrival. Clean, inviting."""
	var scene = Node3D.new()
	
	# Lodge silhouette
	var lodge = build_lodge_shell()
	scene.add_child(lodge)
	
	# Driveway
	var driveway = CSGBox3D.new()
	driveway.size = Vector3(8, 0.2, 20)
	driveway.position = Vector3(0, 0.1, -20)
	driveway.material = mat_stone
	scene.add_child(driveway)
	
	# Landscaping: hedges
	var hedge_left = CSGBox3D.new()
	hedge_left.size = Vector3(2, 2, 30)
	hedge_left.position = Vector3(-15, 1, -15)
	hedge_left.material = mat_grass
	scene.add_child(hedge_left)
	
	# Lighting: soft golden (handled via WorldEnvironment)
	return scene

func build_scene_2_interior_great_room() -> Node3D:
	"""Scene 2: Great room with trophies and paintings."""
	var scene = Node3D.new()
	
	# Walls
	var back_wall = CSGBox3D.new()
	back_wall.size = Vector3(20, 12, 0.5)
	back_wall.position = Vector3(0, 6, 12)
	back_wall.material = mat_wood_dark
	scene.add_child(back_wall)
	
	var left_wall = CSGBox3D.new()
	left_wall.size = Vector3(0.5, 12, 12)
	left_wall.position = Vector3(-10, 6, 6)
	left_wall.material = mat_wood_dark
	scene.add_child(left_wall)
	
	var right_wall = CSGBox3D.new()
	right_wall.size = Vector3(0.5, 12, 12)
	right_wall.position = Vector3(10, 6, 6)
	right_wall.material = mat_wood_dark
	scene.add_child(right_wall)
	
	# Floor
	var floor = CSGBox3D.new()
	floor.size = Vector3(20, 0.5, 12)
	floor.position = Vector3(0, 0.25, 6)
	floor.material = mat_wood_light
	scene.add_child(floor)
	
	# Trophies (mounted heads — cylinders as placeholders)
	_build_trophy_mounts(scene, 4, Vector3(-8, 8, 6), 3)
	_build_trophy_mounts(scene, 4, Vector3(8, 8, 6), 3)
	
	# Fireplace
	var fireplace = CSGBox3D.new()
	fireplace.size = Vector3(3, 4, 1)
	fireplace.position = Vector3(0, 2, 12)
	fireplace.material = mat_stone
	scene.add_child(fireplace)
	
	# Painting frames (flat rects on walls)
	_build_paintings(scene, Vector3(-9, 7, 6.2), 2, 2)
	_build_paintings(scene, Vector3(9, 7, 6.2), 2, 2)
	
	return scene

func build_scene_3_dining_room() -> Node3D:
	"""Scene 3: Dining room with maps and rifle."""
	var scene = Node3D.new()
	
	# Walls
	var walls = _build_room_walls(8, 8, scene)
	
	# Long dining table
	var table_top = CSGBox3D.new()
	table_top.size = Vector3(6, 0.3, 3)
	table_top.position = Vector3(0, 1, 0)
	table_top.material = mat_wood_dark
	scene.add_child(table_top)
	
	# Table legs
	for dx in [-2.5, 2.5]:
		for dz in [-1, 1]:
			var leg = CSGBox3D.new()
			leg.size = Vector3(0.2, 1, 0.2)
			leg.position = Vector3(dx, 0.5, dz)
			leg.material = mat_wood_dark
			scene.add_child(leg)
	
	# Props on table: maps, ledgers (simple boxes)
	var map = CSGBox3D.new()
	map.size = Vector3(1.5, 0.05, 1)
	map.position = Vector3(-1, 1.2, 0)
	map.material = mat_wood_light
	scene.add_child(map)
	
	# Rifle propped on table
	var rifle = CSGBox3D.new()
	rifle.size = Vector3(0.1, 0.1, 2)
	rifle.position = Vector3(2, 1.3, 0)
	rifle.rotation.z = deg_to_rad(20)
	rifle.material = mat_leather
	scene.add_child(rifle)
	
	# Candelabra (simple cylinder cluster)
	var candle = CSGCylinder3D.new()
	candle.radius = 0.2
	candle.height = 0.8
	candle.position = Vector3(1, 1.3, -0.5)
	candle.material = mat_brass
	scene.add_child(candle)
	
	return scene

func build_scene_4_gun_room() -> Node3D:
	"""Scene 4: Gun room with racks, ammunition, hunting gear."""
	var scene = Node3D.new()
	
	var walls = _build_room_walls(8, 8, scene)
	
	# Weapon rack (wall-mounted)
	_build_weapon_rack(scene, Vector3(-3.5, 4, 0.2), 4)
	
	# Ammunition boxes (stacked)
	for i in range(3):
		for j in range(2):
			var ammo = CSGBox3D.new()
			ammo.size = Vector3(1, 0.8, 0.8)
			ammo.position = Vector3(-2 + (j * 1.2), 0.4 + (i * 0.9), 2)
			ammo.material = mat_leather
			scene.add_child(ammo)
	
	# Hunting jackets on pegs (thin boxes)
	var jacket = CSGBox3D.new()
	jacket.size = Vector3(1.5, 2, 0.3)
	jacket.position = Vector3(3, 2.5, 0.2)
	jacket.material = mat_leather
	scene.add_child(jacket)
	
	# Boots (simple pairs)
	for i in range(3):
		var boot = CSGBox3D.new()
		boot.size = Vector3(0.6, 0.5, 0.4)
		boot.position = Vector3(-2 + (i * 1.5), 0.25, -2)
		boot.material = mat_leather
		scene.add_child(boot)
	
	return scene

func build_scene_5_moorland() -> Node3D:
	"""Scene 5: The hunt — open moorland."""
	var scene = Node3D.new()
	
	# Rolling hills (CSG shapes)
	var hill_1 = CSGBox3D.new()
	hill_1.size = Vector3(50, 5, 40)
	hill_1.position = Vector3(0, 2.5, 10)
	hill_1.material = mat_grass
	scene.add_child(hill_1)
	
	var hill_2 = CSGBox3D.new()
	hill_2.size = Vector3(40, 3, 30)
	hill_2.position = Vector3(-10, 1.5, -5)
	hill_2.material = mat_grass
	scene.add_child(hill_2)
	
	# Distant copse (trees as tall thin cylinders)
	for i in range(5):
		var tree = CSGCylinder3D.new()
		tree.radius = 0.5
		tree.height = 8
		tree.position = Vector3(-15 + (i * 3), 4, 25)
		tree.material = mat_wood_dark
		scene.add_child(tree)
	
	return scene

func build_scene_6_dusk() -> Node3D:
	"""Scene 6: Lodge steps at dusk — denouement."""
	var scene = Node3D.new()
	
	# Lodge (distant, darker)
	var lodge = build_lodge_shell()
	lodge.position = Vector3(0, 0, 10)
	scene.add_child(lodge)
	
	# Stone steps
	for i in range(5):
		var step = CSGBox3D.new()
		step.size = Vector3(6, 0.4, 1)
		step.position = Vector3(0, 0.2 + (i * 0.4), -8 + (i * 1))
		step.material = mat_stone
		scene.add_child(step)
	
	# Ground
	var ground = CSGBox3D.new()
	ground.size = Vector3(60, 0.5, 40)
	ground.position = Vector3(0, 0, 0)
	ground.material = mat_grass
	scene.add_child(ground)
	
	return scene

# Utility functions

func _build_room_walls(width: float, depth: float, parent: Node3D) -> void:
	"""Generic room walls."""
	var back_wall = CSGBox3D.new()
	back_wall.size = Vector3(width, 8, 0.3)
	back_wall.position = Vector3(0, 4, depth / 2)
	back_wall.material = mat_wood_dark
	parent.add_child(back_wall)
	
	var left_wall = CSGBox3D.new()
	left_wall.size = Vector3(0.3, 8, depth)
	left_wall.position = Vector3(-width / 2, 4, 0)
	left_wall.material = mat_wood_dark
	parent.add_child(left_wall)
	
	var right_wall = CSGBox3D.new()
	right_wall.size = Vector3(0.3, 8, depth)
	right_wall.position = Vector3(width / 2, 4, 0)
	right_wall.material = mat_wood_dark
	parent.add_child(right_wall)
	
	var floor = CSGBox3D.new()
	floor.size = Vector3(width, 0.3, depth)
	floor.position = Vector3(0, 0.15, 0)
	floor.material = mat_wood_light
	parent.add_child(floor)

func _build_trophy_mounts(parent: Node3D, count: int, offset: Vector3, spacing: float) -> void:
	"""Build trophy mounts (as simple cylinders for heads)."""
	for i in range(count):
		var mount = CSGCylinder3D.new()
		mount.radius = 0.4
		mount.height = 0.6
		mount.position = offset + Vector3(0, -i * spacing, 0)
		mount.material = mat_brass
		parent.add_child(mount)

func _build_paintings(parent: Node3D, pos: Vector3, width: float, height: float) -> void:
	"""Build painting frames on walls."""
	var frame = CSGBox3D.new()
	frame.size = Vector3(width, height, 0.1)
	frame.position = pos
	frame.material = mat_wood_light
	parent.add_child(frame)

func _build_weapon_rack(parent: Node3D, pos: Vector3, count: int) -> void:
	"""Build a wall-mounted weapon rack."""
	var rack_base = CSGBox3D.new()
	rack_base.size = Vector3(2, 3, 0.3)
	rack_base.position = pos
	rack_base.material = mat_wood_dark
	parent.add_child(rack_base)
	
	# Rifles (thin boxes on rack)
	for i in range(count):
		var rifle = CSGBox3D.new()
		rifle.size = Vector3(0.1, 2, 0.8)
		rifle.position = pos + Vector3(-0.6 + (i * 0.4), 1, 0)
		rifle.material = mat_leather
		parent.add_child(rifle)
