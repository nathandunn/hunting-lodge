## Main — the director. Turns pages.
##
## Owns the sets, the cast (one Figure each, moved from set to set), the
## camera, the light and the lettering. A page from Story.pages() says where
## everything goes; turning to it is: wipe to paper, place, light, frame,
## letter, wipe back.
##
## Controls: click, tap, Space, Enter or → for the next page; ← or Backspace
## for the previous; Home to start again.
##
## Headless check: `godot4 --path project -- --shots=<dir>` renders every page
## to <dir>/page_NN.png and quits (run it under Xvfb; --headless draws nothing).
extends Node3D

var lighting: Lighting
var sets: Dictionary = {}
var cast: Dictionary = {}
var camera: Camera3D
var letters: Lettering
var pages: Array = []
var index: int = -1

var _cam_from: Vector3
var _cam_to: Vector3
var _cam_look: Vector3
var _cam_t: float = 0.0
var _drift: float = 0.03
var _turning: bool = false
var _birds: Node3D
var _visited: int = 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Ink.PAPER)
	lighting = Lighting.new()
	add_child(lighting)
	var world := Node3D.new()
	world.name = "Sets"
	add_child(world)
	sets = Sets.build_all(world)
	_birds = sets["moor"].get_meta("birds")

	var skins := Ink.SKINS
	var i := 0
	for id in Story.CAST:
		var c: Dictionary = Story.CAST[id]
		var f := Figure.create(c["face"], c["costume"], c["tint"], skins[c["skin"]], c["h"], i * 0.37)
		f.name = id
		f.visible = false
		add_child(f)
		cast[id] = f
		i += 1

	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	letters = Lettering.new()
	layer.add_child(letters)

	pages = Story.pages()
	var shots := _arg("--shots")
	if shots != "":
		_render_all(shots)
		return
	_show(0, true)


# --- Pages ------------------------------------------------------------------------

func next_page() -> void:
	if index < pages.size() - 1:
		_turn(index + 1)


func prev_page() -> void:
	if index > 0:
		_turn(index - 1)


func _turn(to: int) -> void:
	if _turning:
		return
	_turning = true
	var tw := create_tween()
	tw.tween_property(letters, "wipe", 1.0, 0.12)
	await tw.finished
	_show(to, false)
	var back := create_tween()
	back.tween_property(letters, "wipe", 0.0, 0.2)
	await back.finished
	_turning = false


func _show(i: int, instant: bool) -> void:
	index = i
	_visited = maxi(_visited, i)
	var pg: Dictionary = pages[i]
	var set_name: String = pg["set"]
	var origin := Sets.origin(set_name)
	for s in sets:
		sets[s].visible = s == set_name
	var windows: Array = sets["exterior"].get_meta("windows", []) if set_name == "exterior" else []
	lighting.apply(pg.get("light", "golden"), origin, windows, instant)

	var who: Dictionary = pg.get("cast", {})
	var speaking := {}
	for line in pg.get("say", []):
		speaking[line[0]] = true
	for id in cast:
		var f: Figure = cast[id]
		if not who.has(id):
			f.visible = false
			continue
		var c: Dictionary = who[id]
		var d: Dictionary = Story.CAST[id]
		f.visible = true
		f.position = origin + c.get("at", Vector3.ZERO)
		f.rotation.y = deg_to_rad(c.get("yaw", 0.0))
		f.set_costume(c.get("costume", d["costume"]), c.get("tint", d["tint"]))
		f.set_seated(c.get("seated", false))
		f.give_gun(c.get("gun", false))
		f.give_hat(c.get("hat", false), c.get("holed", false))
		f.set_pose(c.get("pose", "stand"), instant)
		f.talking = speaking.has(id)

	var cam: Array = pg["cam"]
	_cam_from = origin + cam[0]
	_cam_look = origin + cam[1]
	_drift = pg.get("drift", 0.03)
	_cam_to = _cam_from.lerp(_cam_look, _drift)
	_cam_t = 0.0
	camera.fov = pg.get("fov", 42.0)
	_place_camera(0.0)

	letters.page = pg
	letters.folio = "%d / %d" % [i + 1, pages.size()]
	letters.show_hint = i == 0


func _place_camera(t: float) -> void:
	var k := smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))
	var pos := _cam_from.lerp(_cam_to, k)
	camera.position = pos
	if not pos.is_equal_approx(_cam_look):
		camera.look_at(_cam_look, Vector3.UP)


func _process(delta: float) -> void:
	if index < 0:
		return
	_cam_t += delta / 9.0
	_place_camera(_cam_t)
	if _birds and _birds.is_visible_in_tree():
		_birds.position.x = 4.0 + fmod(Time.get_ticks_msec() / 1000.0 * 0.6, 12.0) - 6.0
	_update_anchors()


func _update_anchors() -> void:
	var a := {}
	var vp := get_viewport().get_visible_rect()
	for id in cast:
		var f: Figure = cast[id]
		if not f.visible:
			continue
		var p := f.head_top()
		if camera.is_position_behind(p):
			continue
		var s := camera.unproject_position(p)
		if vp.grow(-8).has_point(s):
			a[id] = s
	letters.anchors = a


# --- Input ------------------------------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			# Left fifth of the page goes back, like turning a real one.
			if e.position.x < get_viewport().get_visible_rect().size.x * 0.2 and index > 0:
				prev_page()
			else:
				next_page()
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			prev_page()
	elif e is InputEventScreenTouch and e.pressed:
		if e.position.x < get_viewport().get_visible_rect().size.x * 0.2 and index > 0:
			prev_page()
		else:
			next_page()
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT, KEY_D, KEY_PAGEDOWN:
				next_page()
			KEY_LEFT, KEY_A, KEY_BACKSPACE, KEY_PAGEUP:
				prev_page()
			KEY_HOME, KEY_R:
				if index != 0:
					_turn(0)


# --- Headless proofs ----------------------------------------------------------------

func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


func _render_all(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var only := _arg("--page")
	for i in pages.size():
		if only != "" and int(only) != i + 1:
			continue
		_show(i, true)
		for _f in 24:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/page_%02d.png" % [dir, i + 1])
		print("shot page %d" % (i + 1))
	get_tree().quit()
