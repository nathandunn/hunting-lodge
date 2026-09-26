## Lettering — everything printed on top of the picture.
##
## The panel border and paper margin, the narrator's caption boxes, speech
## balloons with tails that find the speaker's head every frame, sound effects,
## title plates and the folio. Pure drawing: the director hands it a page and
## the screen positions of heads; it never touches the 3D scene.
class_name Lettering
extends Control

const BALLOON := Color("fbf8ef")
const CAPTION := Color("efdc9c")
const SFX_FILL := Color("c2412f")

var f_text: Font
var f_italic: Font
var f_bold: Font
var f_title: Font

var page: Dictionary = {}
## who -> Vector2 screen point just above the head, or absent when off-screen.
var anchors: Dictionary = {}
var folio: String = ""
var show_hint: bool = true
## 0..1 paper wipe between pages.
var wipe: float = 0.0

var _panel: Rect2
var _last: Rect2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	f_text = load("res://fonts/CrimsonPro-Regular.ttf")
	f_italic = load("res://fonts/CrimsonPro-Italic.ttf")
	f_bold = load("res://fonts/CrimsonPro-Bold.ttf")
	f_title = load("res://fonts/Gloock-Regular.ttf")


## The picture's rectangle in screen space — the director fits the camera to it.
func panel_rect() -> Rect2:
	var s := size
	var m := clampf(minf(s.x, s.y) * 0.03, 10.0, 28.0)
	var r := Rect2(m, m, s.x - m * 2.0, s.y - m * 2.0)
	if page.get("frame", "full") == "wide" and s.x > s.y:
		var bar := s.y * 0.08
		r = r.grow_individual(0, -bar, 0, -bar)
	return r


func _text_size() -> float:
	return clampf(minf(size.x * 0.022, size.y * 0.036), 15.0, 26.0)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if size.x < 160.0 or size.y < 120.0:
		return
	_panel = panel_rect()
	var ts := _text_size()
	var taken: Array[Rect2] = []
	_last = Rect2()

	if page.has("caption"):
		taken.append(_caption(page["caption"], true, ts))
	if page.has("caption2"):
		taken.append(_caption(page["caption2"], false, ts))
	if page.has("title"):
		taken.append(_title(page["title"]))

	var said: Array = page.get("say", [])
	for i in said.size():
		var line: Array = said[i]
		var kind: String = line[2] if line.size() > 2 else "speech"
		_last = _balloon(line[0], line[1], kind, ts, taken)
		taken.append(_last)

	for s in page.get("sfx", []):
		_sfx(s[0], s[1], s[2])

	_frame()
	_folio(ts)
	if wipe > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Ink.PAPER, wipe))


# --- Frame and folio ------------------------------------------------------------

func _frame() -> void:
	var s := size
	var p := _panel
	var paper := Ink.PAPER
	draw_rect(Rect2(0, 0, s.x, p.position.y), paper)
	draw_rect(Rect2(0, p.end.y, s.x, s.y - p.end.y), paper)
	draw_rect(Rect2(0, p.position.y, p.position.x, p.size.y), paper)
	draw_rect(Rect2(p.end.x, p.position.y, s.x - p.end.x, p.size.y), paper)
	draw_rect(p, Ink.INK, false, 4.0)


func _folio(ts: float) -> void:
	var fs := ts * 0.8
	var p := _panel
	var y := p.end.y + (size.y - p.end.y) * 0.5 + fs * 0.35
	if size.y - p.end.y < fs * 1.2:
		y = p.end.y - 10.0
	if folio != "":
		var w := f_italic.get_string_size(folio, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_plate_text(Vector2(p.end.x - w - 12.0, y), folio, f_italic, fs, size.y - p.end.y < fs * 1.2)
	if show_hint:
		var hint := "tap, click or space to turn the page  ·  ← back"
		_plate_text(Vector2(p.position.x + 12.0, y), hint, f_italic, fs, size.y - p.end.y < fs * 1.2)


func _plate_text(at: Vector2, t: String, f: Font, fs: float, plate: bool) -> void:
	if plate:
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_rect(Rect2(at + Vector2(-6, -fs), Vector2(w + 12, fs * 1.35)), Color(Ink.PAPER, 0.9))
	draw_string(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Ink.INK)


# --- Captions ------------------------------------------------------------------------

func _caption(t: String, top: bool, ts: float) -> Rect2:
	var p := _panel
	var maxw := minf(p.size.x * (0.44 if p.size.x > p.size.y else 0.86), 560.0)
	var pad := Vector2(14, 10)
	var fs := ts * 0.95
	var tsz := f_italic.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, maxw - pad.x * 2, fs)
	var box := Rect2(Vector2.ZERO, tsz + pad * 2)
	var inset := 14.0
	if top:
		box.position = p.position + Vector2(inset, inset)
	else:
		box.position = p.end - box.size - Vector2(inset, inset)
	draw_rect(box, CAPTION)
	draw_rect(box, Ink.INK, false, 2.5)
	draw_multiline_string(f_italic, box.position + pad + Vector2(0, f_italic.get_ascent(fs)), t,
		HORIZONTAL_ALIGNMENT_LEFT, maxw - pad.x * 2, fs, -1, Ink.INK)
	return box.grow(6)


func _title(t: Array) -> Rect2:
	var p := _panel
	var big := clampf(p.size.y * 0.13, 36.0, 110.0)
	var small := clampf(big * 0.28, 14.0, 26.0)
	var tw := f_title.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	var maxw := minf(p.size.x * 0.8, maxf(tw, 300.0) + 80.0)
	var sub_sz := f_italic.get_multiline_string_size(t[1], HORIZONTAL_ALIGNMENT_CENTER, maxw - 40.0, small)
	var h := big * 1.15 + sub_sz.y + 40.0
	var box := Rect2(Vector2(p.get_center().x - maxw * 0.5, p.position.y + p.size.y * 0.52 - h * 0.5), Vector2(maxw, h))
	draw_rect(box, Color(Ink.PAPER, 0.94))
	draw_rect(box, Ink.INK, false, 3.0)
	draw_rect(box.grow(-7), Ink.INK, false, 1.0)
	draw_string(f_title, Vector2(box.position.x, box.position.y + 18.0 + big * 0.95), t[0],
		HORIZONTAL_ALIGNMENT_CENTER, maxw, big, Ink.INK)
	draw_multiline_string(f_italic, Vector2(box.position.x + 20.0, box.position.y + 18.0 + big * 1.15 + small),
		t[1], HORIZONTAL_ALIGNMENT_CENTER, maxw - 40.0, small, -1, Ink.INK)
	return box.grow(6)


# --- Balloons ---------------------------------------------------------------------------

func _balloon(who: String, txt: String, kind: String, ts: float, taken: Array[Rect2]) -> Rect2:
	var t := txt
	var p := _panel
	var landscape := p.size.x > p.size.y
	var maxw := minf(p.size.x * (0.30 if landscape else 0.62), 400.0)
	var f := f_bold if kind == "shout" else f_text
	var fs := ts * (1.08 if kind == "shout" else 1.0)
	var tsz := f.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs)
	var pad := Vector2(26, 16) if kind != "shout" else Vector2(34, 24)
	var bs := tsz + pad * 2.0
	var has_anchor := anchors.has(who)
	var a: Vector2 = anchors.get(who, Vector2(p.get_center().x, p.position.y))

	# Heads are sacred: a balloon may not sit on anybody's face.
	var blocked: Array[Rect2] = taken.duplicate()
	for id in anchors:
		var h: Vector2 = anchors[id]
		blocked.append(Rect2(h + Vector2(-48, -10), Vector2(96, 110)))
	# Try above the head, then either side of it, and take the first spot that
	# is clear and on the page.
	var inner := p.grow(-10)
	var tries := [
		Vector2(a.x - bs.x * 0.5, a.y - bs.y - 46.0),
		Vector2(a.x - bs.x * 0.5, p.position.y + 10.0),
		Vector2(a.x + 70.0, a.y - bs.y * 0.6),
		Vector2(a.x - 70.0 - bs.x, a.y - bs.y * 0.6),
		Vector2(a.x + 70.0, p.position.y + 10.0),
		Vector2(a.x - 70.0 - bs.x, p.position.y + 10.0),
	]
	for spot in tries:
		var c := Rect2(spot, bs)
		c.position.x = clampf(c.position.x, inner.position.x, inner.end.x - bs.x)
		c.position.y = clampf(c.position.y, inner.position.y, inner.end.y - bs.y)
		var clear := true
		# Reading order: a later balloon may not sit up and to the left of the
		# one before it, or it gets read first.
		if _last.size.x > 0.0 and c.position.y < _last.position.y + 12.0 and c.get_center().x < _last.get_center().x:
			clear = false
		for o in blocked:
			if c.intersects(o):
				clear = false
				break
		if clear:
			return _draw_balloon(c, a, has_anchor, kind, "", f, fs, pad, txt)
	# Nothing clear: start above the speaker and slide down past what is on the
	# page. Balloons are read top to bottom, so the order holds.
	var r := Rect2(Vector2(a.x - bs.x * 0.5, a.y - bs.y - 46.0), bs)
	r.position.x = clampf(r.position.x, p.position.x + 10.0, p.end.x - bs.x - 10.0)
	r.position.y = maxf(r.position.y, p.position.y + 10.0)
	for _i in 8:
		var hit := false
		for o in taken:
			if r.intersects(o):
				r.position.y = o.end.y + 6.0
				hit = true
		if not hit:
			break
	if r.end.y > p.end.y - 10.0:
		# No room below: try beside the column of balloons instead.
		r.position.y = p.end.y - 10.0 - bs.y
		for o in taken:
			if r.intersects(o):
				r.position.x = o.end.x + 8.0 if o.get_center().x < p.get_center().x else o.position.x - bs.x - 8.0
				r.position.x = clampf(r.position.x, p.position.x + 10.0, p.end.x - bs.x - 10.0)

	return _draw_balloon(r, a, has_anchor, kind, "", f, fs, pad, t)


func _draw_balloon(r: Rect2, a: Vector2, has_anchor: bool, kind: String, _u: String,
		f: Font, fs: float, pad: Vector2, t: String) -> Rect2:
	var shape := _jagged(r) if kind == "shout" else _oval(r)
	var outline := shape
	if has_anchor and not r.grow(-4).has_point(a):
		var tail := _tail(r, a)
		var merged := Geometry2D.merge_polygons(shape, tail)
		if merged.size() > 0:
			outline = merged[0]
	draw_colored_polygon(outline, BALLOON)
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Ink.INK, 2.5, true)
	draw_multiline_string(f, r.position + Vector2(pad.x, pad.y + f.get_ascent(fs)), t,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x - pad.x * 2.0, fs, -1, Ink.INK)
	return r.grow(4)


## A lettered balloon: a superellipse, which is rounder than a rounded rect and
## squarer than an ellipse, like the ones drawn with a template.
func _oval(r: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := r.get_center()
	var hx := r.size.x * 0.5 + 6.0
	var hy := r.size.y * 0.5 + 4.0
	var n := 2.6
	for i in 64:
		var th := TAU * float(i) / 64.0
		var ct := cos(th)
		var st := sin(th)
		var x := pow(absf(ct), 2.0 / n) * signf(ct) * hx
		var y := pow(absf(st), 2.0 / n) * signf(st) * hy
		pts.append(c + Vector2(x, y))
	return pts


func _jagged(r: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := r.get_center()
	var hx := r.size.x * 0.5 + 4.0
	var hy := r.size.y * 0.5 + 2.0
	var spikes := 22
	for i in spikes * 2:
		var th := TAU * float(i) / float(spikes * 2)
		var k := 1.14 if i % 2 == 0 else 0.93
		pts.append(c + Vector2(cos(th) * hx * k, sin(th) * hy * k))
	return pts


## A tail from the balloon's edge toward [param a], stopping short of the head.
func _tail(r: Rect2, a: Vector2) -> PackedVector2Array:
	var c := r.get_center()
	var below := a.y > c.y
	var bx := clampf(a.x, r.position.x + r.size.x * 0.25, r.end.x - r.size.x * 0.25)
	var by := r.end.y - 6.0 if below else r.position.y + 6.0
	var tip := a
	var d := a - Vector2(bx, by)
	if d.length() > 30.0:
		tip = a - d.normalized() * 16.0
	var w := clampf(r.size.x * 0.07, 10.0, 18.0)
	return PackedVector2Array([Vector2(bx - w, by), tip, Vector2(bx + w, by)])


# --- Sound effects ---------------------------------------------------------------------

func _sfx(t: String, at: Vector2, deg: float) -> void:
	var p := _panel
	var fs := clampf(p.size.y * 0.1, 30.0, 96.0)
	var pos := p.position + p.size * at
	var w := f_title.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_set_transform(pos, deg_to_rad(deg), Vector2.ONE)
	draw_string_outline(f_title, Vector2(-w * 0.5, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Ink.INK)
	draw_string(f_title, Vector2(-w * 0.5, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SFX_FILL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
