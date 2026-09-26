## Main — the director. Turns pages.
##
## Owns the sets, the cast (one Figure each, moved from set to set), the
## camera, the light and the lettering. A page from Story.pages() says where
## everything goes; turning to it is: place, light, frame, letter. Every page
## is a still, like a panel in a printed book — nothing moves once it's up.
##
## Controls: click, tap, Space, Enter or → for the next page; ← or Backspace
## for the previous; Home to start again.
##
## Headless check: `godot4 --path project -- --shots=<dir>` renders every page
## to <dir>/page_NN.png and quits (run it under Xvfb; --headless draws nothing).
extends Node3D

var lighting: Lighting
var world: Node3D
## Only the sets actually needed right now — at most current + previous, so
## the six sets (a thousand-odd mesh instances between them) are never all
## resident in GPU memory at once. See _ensure_set / _prune_sets.
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
var _turning: bool = false
var _visited: int = 0
var _prev_set: String = ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Ink.PAPER)
	lighting = Lighting.new()
	add_child(lighting)
	world = Node3D.new()
	world.name = "Sets"
	add_child(world)

	_fit_render_scale()
	get_viewport().size_changed.connect(_fit_render_scale)
	# Stills: when the window changes shape, reframe and re-letter the page.
	get_viewport().size_changed.connect(func() -> void:
		if index >= 0:
			_show(index))

	var skins := Ink.SKINS
	var i := 0
	for id in Story.CAST:
		var c: Dictionary = Story.CAST[id]
		var f := Figure.create(c["face"], c["costume"], c["tint"], skins[c["skin"]], c["h"], i * 0.37)
		f.name = id
		f.visible = false
		add_child(f)
		# Every page is a still: no breathing, no gesturing, no easing between poses.
		f.set_process(false)
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
	if _has_flag("--pagecheck"):
		_pagecheck()
		return
	if _has_flag("--memcheck"):
		_memcheck()
		return
	_show(0, true)


## The 3D picture is rendered at no more than RENDER_BUDGET pixels and scaled
## up; the lettering is 2D and stays at full resolution, so type is always
## crisp. On a Retina laptop the window is 6-7 megapixels, and every 3D render
## buffer (colour, depth, multisample, shadows' resolve) grows with it — that,
## not our scene, is what used up the browser's GPU budget and cost it the
## WebGL context a few pages in. Ink-and-paper art loses nothing at this size.
const RENDER_BUDGET := 2_000_000.0


func _fit_render_scale() -> void:
	var px := Vector2(DisplayServer.window_get_size())
	var scale := clampf(sqrt(RENDER_BUDGET / maxf(px.x * px.y, 1.0)), 0.4, 1.0)
	get_viewport().scaling_3d_scale = scale


## Returns the built root for [param name], building it on first use.
func _ensure_set(name: String) -> Node3D:
	if sets.has(name):
		return sets[name]
	var root := Sets.build_one(name, world)
	sets[name] = root
	return root


## Keeps at most the current set and the one shown just before it — enough for
## an instant back-page — and frees the rest, so GPU memory never holds more
## than two sets' worth of geometry at a time.
func _prune_sets(current: String) -> void:
	var keep := {current: true}
	if _prev_set != "":
		keep[_prev_set] = true
	for s in sets.keys():
		if not keep.has(s):
			var n: Node3D = sets[s]
			sets.erase(s)
			n.queue_free()
	_prev_set = current


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
	# A page turn is a cut, like a page of a book: no wipe, no easing.
	_show(to, true)
	_turning = false


func _show(i: int, _instant: bool = true) -> void:
	index = i
	_visited = maxi(_visited, i)
	var pg: Dictionary = pages[i]
	var set_name: String = pg["set"]
	var origin := Sets.origin(set_name)
	var root := _ensure_set(set_name)
	for s in sets:
		sets[s].visible = s == set_name
	_prune_sets(set_name)
	var windows: Array = root.get_meta("windows", []) if set_name == "exterior" else []
	lighting.apply(pg.get("light", "golden"), origin, windows, true)

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
		f.set_pose(c.get("pose", "stand"), true)
		f.talking = speaking.has(id)

	var cam: Array = pg["cam"]
	_cam_from = origin + cam[0]
	_cam_look = origin + cam[1]
	# The camera stands where the page puts it and stays there.
	_cam_to = _cam_from
	_cam_t = 0.0
	camera.fov = pg.get("fov", 42.0)
	_place_camera(0.0)
	letters.page = pg
	_make_headroom(pg)

	letters.folio = "%d / %d" % [i + 1, pages.size()]
	letters.show_hint = i == 0
	# Heads first, then lettering: the page is laid out once, on its first
	# frame, around wherever the faces are now.
	_update_anchors()


## Comics leave room at the top of a panel for the words. With the lettering
## this big, a shot framed with the speakers' heads near the top has nowhere
## to put a balloon but over someone's face or below the heads, out of reading
## order. So on a page with dialogue the camera rises — straight up, same
## angle — until the highest speaking head sits a little below mid-panel.
const HEADROOM := 0.46
const MAX_RISE := 1.4


func _make_headroom(pg: Dictionary) -> void:
	var said: Array = pg.get("say", [])
	if said.is_empty():
		return
	var panel := letters.panel_rect()
	# More lines of dialogue, more sky above the heads.
	var room := minf(HEADROOM + 0.08 * maxf(said.size() - 2, 0), 0.62)
	var want := panel.position.y + panel.size.y * room
	var risen := 0.0
	for _iter in 6:
		var top := INF
		var depth := 0.0
		for line in said:
			var f: Figure = cast.get(line[0])
			if f == null or not f.visible:
				continue
			var h := f.head_top()
			if camera.is_position_behind(h):
				continue
			var y := camera.unproject_position(h).y
			if y < top:
				top = y
				depth = -(camera.global_transform.affine_inverse() * h).z
		if top == INF or top >= want - 2.0 or risen >= MAX_RISE:
			return
		# World units per screen pixel at the speaker's depth (fov is vertical).
		var per_px := 2.0 * depth * tan(deg_to_rad(camera.fov) * 0.5) / get_viewport().get_visible_rect().size.y
		var rise := minf((want - top) * per_px, MAX_RISE - risen)
		risen += rise
		_cam_from.y += rise
		_cam_look.y += rise
		_cam_to = _cam_from
		_place_camera(0.0)


func _place_camera(t: float) -> void:
	var k := smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))
	var pos := _cam_from.lerp(_cam_to, k)
	camera.position = pos
	if not pos.is_equal_approx(_cam_look):
		camera.look_at(_cam_look, Vector3.UP)




func _update_anchors() -> void:
	var a := {}
	var faces := {}
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
		# Where the face card lands on screen, however near or far the camera.
		var fr := Rect2()
		var first := true
		for q in f.face_corners():
			if camera.is_position_behind(q):
				continue
			var sq := camera.unproject_position(q)
			if first:
				fr = Rect2(sq, Vector2.ZERO)
				first = false
			else:
				fr = fr.expand(sq)
		if not first and fr.intersects(vp):
			faces[id] = fr.grow(8)
	letters.faces = faces
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


func _has_flag(key: String) -> bool:
	return OS.get_cmdline_user_args().has(key)


## The pre-commit gate: walks every page under plain --headless (no Xvfb, no
## GPU needed) so a script error, a bad page dictionary or a set that fails to
## build shows up as SCRIPT ERROR / Parse Error in the log, the same way
## flipbook-field's drive6.gd gate catches breakage before it ships.
func _pagecheck() -> void:
	print("pagecheck: %d pages" % pages.size())
	for i in pages.size():
		_show(i, true)
		await get_tree().process_frame
		await get_tree().process_frame
		print("pagecheck: page %d ok (set=%s)" % [i + 1, pages[i]["set"]])
	print("PAGECHECK COMPLETE %d/%d" % [pages.size(), pages.size()])
	get_tree().quit()


## Reads the book forward, back and forward again, printing video and texture
## memory after each page. Run it under Xvfb with the opengl3 driver (the
## renderer a browser gets) — a number that climbs with every page turn is the
## leak that eventually costs a browser its WebGL context.
func _memcheck() -> void:
	var order: Array = []
	for i in pages.size():
		order.append(i)
	for i in range(pages.size() - 2, -1, -1):
		order.append(i)
	for i in pages.size():
		order.append(i)
	var limit := int(_arg("--memsteps")) if _arg("--memsteps") != "" else order.size()
	var step := 0
	for i in order.slice(0, limit):
		_show(i, true)
		for _f in 20:
			await get_tree().process_frame
		step += 1
		print("MEM %dx%d s3d %.2f step %03d page %02d video %7.1f MB  texture %7.1f MB  objects %d" % [
			DisplayServer.window_get_size().x, DisplayServer.window_get_size().y, get_viewport().scaling_3d_scale, step, i + 1,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.OBJECT_COUNT)])
	get_tree().quit()


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
		for problem in letters.audit():
			print("LAYOUT page %d: %s" % [i + 1, problem])
	get_tree().quit()
