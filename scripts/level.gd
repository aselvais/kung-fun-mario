extends Node2D
# Super Mario Bros World 1-1 tribute

const TILE := 16
const W := 212
const SKY := Color(0.361, 0.580, 0.988)

var player: CharacterBody2D


func _ready() -> void:
	add_to_group("level")
	RenderingServer.set_default_clear_color(SKY)
	GameState.inst.play_bgm("game")
	_parallax()
	_decor()
	_ground()
	_pipes()
	_hard_blocks()
	_blocks()
	_enemies()
	_flag_and_castle()
	_spawn_player()
	_hud()


func spawn_item(kind: String, pos: Vector2) -> void:
	var n := _make_item(kind)
	add_child(n)
	n.global_position = pos


func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D


func _sprite(path: String, pos: Vector2, centered := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(path)
	s.centered = centered
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	add_child(s)
	return s


func _parallax() -> void:
	# All mountain strips share one baseline (ground top = 208, strip = 120).
	var mountain_y := 88.0
	_px_strip("FarMountains", 0.10, -24, "res://assets/sprites/mountain_far.png", mountain_y)
	_px_clouds()
	_px_strip("MidMountains", 0.28, -18, "res://assets/sprites/mountain_mid.png", mountain_y)
	_px_strip("NearMountains", 0.52, -12, "res://assets/sprites/mountain_near.png", mountain_y)


func _px_strip(layer_name: String, scale_x: float, z: int, tex_path: String, y: float) -> void:
	var layer := Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = Vector2(scale_x, 0.0)
	layer.repeat_size = Vector2(512.0, 0.0)
	layer.repeat_times = 8
	layer.z_index = z
	var s := Sprite2D.new()
	s.texture = _tex(tex_path)
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = Vector2(0, y)
	layer.add_child(s)
	add_child(layer)


func _px_clouds() -> void:
	var layer := Parallax2D.new()
	layer.name = "Clouds"
	layer.scroll_scale = Vector2(0.18, 0.0)
	layer.repeat_size = Vector2(512.0, 0.0)
	layer.repeat_times = 8
	layer.autoscroll = Vector2(-10.0, 0.0)
	layer.z_index = -20
	for spec in [
		["cloud3.png", Vector2(20, 16)],
		["cloud1.png", Vector2(120, 36)],
		["cloud2.png", Vector2(210, 22)],
		["cloud1.png", Vector2(320, 40)],
		["cloud3.png", Vector2(400, 14)],
	]:
		var s := Sprite2D.new()
		s.texture = _tex("res://assets/sprites/%s" % spec[0])
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = spec[1]
		layer.add_child(s)
	add_child(layer)


func _tile_pos(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE, ty * TILE)


func _static_rect(pos: Vector2, size: Vector2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = size * 0.5
	b.add_child(cs)
	add_child(b)
	return b


func _stamp_tile(path: String, tx: int, ty: int) -> void:
	_sprite(path, _tile_pos(tx, ty))


func _decor() -> void:
	for p in [[0, 10], [48, 10], [96, 10], [144, 10], [192, 10]]:
		var h := _sprite("res://assets/sprites/hill_large.png", _tile_pos(p[0], p[1]))
		h.z_index = -6
	for p in [[16, 11], [64, 11], [112, 11], [160, 11], [208, 11]]:
		var h := _sprite("res://assets/sprites/hill_small.png", _tile_pos(p[0], p[1]))
		h.z_index = -6
	for p in [[23, 12], [71, 12], [119, 12], [167, 12]]:
		var b := _sprite("res://assets/sprites/bush1.png", _tile_pos(p[0], p[1]))
		b.z_index = -5
	for p in [[41, 12], [89, 12], [137, 12]]:
		var b := _sprite("res://assets/sprites/bush2.png", _tile_pos(p[0], p[1]))
		b.z_index = -5
	for p in [[11, 12], [59, 12], [107, 12], [159, 12], [207, 12]]:
		var b := _sprite("res://assets/sprites/bush3.png", _tile_pos(p[0], p[1]))
		b.z_index = -5


func _fill_ground(x0: int, width: int) -> void:
	for x in range(x0, x0 + width):
		_stamp_tile("res://assets/tiles/ground_top.png", x, 13)
		_stamp_tile("res://assets/tiles/ground_fill.png", x, 14)
	_static_rect(_tile_pos(x0, 13), Vector2(width * TILE, 2 * TILE))


func _ground() -> void:
	_fill_ground(0, 69)
	_fill_ground(71, 15)
	_fill_ground(89, 64)
	_fill_ground(155, 57)


func _pipe(tx: int, top_y: int) -> void:
	var h := 13 - top_y
	_stamp_tile("res://assets/tiles/pipe_top_l.png", tx, top_y)
	_stamp_tile("res://assets/tiles/pipe_top_r.png", tx + 1, top_y)
	for y in range(top_y + 1, 13):
		_stamp_tile("res://assets/tiles/pipe_body_l.png", tx, y)
		_stamp_tile("res://assets/tiles/pipe_body_r.png", tx + 1, y)
	_static_rect(_tile_pos(tx, top_y), Vector2(2 * TILE, h * TILE))


func _pipes() -> void:
	_pipe(28, 11)
	_pipe(38, 10)
	_pipe(46, 9)
	_pipe(57, 9)
	_pipe(163, 11)
	_pipe(179, 11)


func _hard(tx: int, ty: int) -> void:
	_stamp_tile("res://assets/tiles/hard.png", tx, ty)
	_static_rect(_tile_pos(tx, ty), Vector2(TILE, TILE))


func _stairs_up(x0: int, steps: int) -> void:
	for i in steps:
		for j in range(i + 1):
			_hard(x0 + i, 12 - j)


func _stairs_down(x0: int, steps: int) -> void:
	for i in steps:
		for j in range(steps - i):
			_hard(x0 + i, 12 - j)


func _hard_blocks() -> void:
	_stairs_up(134, 4)
	_stairs_down(140, 4)
	_stairs_up(148, 4)
	for y in range(9, 13):
		_hard(152, y)
	_stairs_down(155, 4)
	_stairs_up(181, 8)
	for y in range(5, 13):
		_hard(189, y)


func _make_block(tx: int, ty: int, brick: bool, contents: String, is_secret := false) -> void:
	var b := StaticBody2D.new()
	b.set_script(load("res://scripts/block.gd"))
	b.position = _tile_pos(tx, ty)
	b.brick = brick
	b.contents = contents
	b.is_secret = is_secret
	b.collision_layer = 1
	b.collision_mask = 0
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_secret:
		spr.texture = _tex("res://assets/tiles/question_used.png")
	elif brick:
		spr.texture = _tex("res://assets/tiles/brick.png")
	else:
		spr.texture = _tex("res://assets/tiles/question.png")
	b.add_child(spr)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var sh := RectangleShape2D.new()
	sh.size = Vector2(TILE, TILE)
	cs.shape = sh
	cs.position = Vector2(TILE, TILE) * 0.5
	b.add_child(cs)
	add_child(b)


func _blocks() -> void:
	# Question blocks (classic 1-1 contents)
	_make_block(16, 9, false, "coin")
	_make_block(21, 9, false, "mushroom")
	_make_block(22, 5, false, "coin")
	_make_block(23, 9, false, "shuriken")
	_make_block(78, 9, false, "coin")
	_make_block(94, 5, false, "mushroom")
	_make_block(106, 9, false, "shuriken")
	_make_block(109, 5, false, "mushroom")
	_make_block(109, 9, false, "coin")
	_make_block(112, 9, false, "coin")
	_make_block(129, 5, false, "coin")
	_make_block(130, 5, false, "coin")
	_make_block(170, 9, false, "shuriken")
	# Hidden 1-up
	_make_block(64, 8, false, "hidden_1up", true)
	# Bricks (skip cells that are question blocks)
	var q := {
		Vector2i(21, 9): true, Vector2i(23, 9): true, Vector2i(78, 9): true,
		Vector2i(94, 5): true, Vector2i(129, 5): true, Vector2i(130, 5): true,
		Vector2i(170, 9): true,
	}
	var bricks := [
		[20, 5, 9], [77, 3, 9], [80, 8, 5], [91, 4, 5], [94, 1, 9],
		[100, 2, 9], [118, 1, 9], [121, 3, 5], [128, 4, 5], [129, 2, 9], [168, 4, 9],
	]
	var specials := {Vector2i(94, 9): "multi", Vector2i(100, 9): "star"}
	for spec in bricks:
		var x0: int = spec[0]
		var w: int = spec[1]
		var y: int = spec[2]
		for x in range(x0, x0 + w):
			if q.has(Vector2i(x, y)):
				continue
			var c := "empty"
			if specials.has(Vector2i(x, y)):
				c = specials[Vector2i(x, y)]
			_make_block(x, y, true, c)


func _make_enemy(kind: String, px: float, py: float) -> void:
	var e := CharacterBody2D.new()
	var script_path := "res://scripts/fighter.gd" if kind == "ninja" or kind == "sumo" else "res://scripts/enemy.gd"
	e.set_script(load(script_path))
	e.kind = kind
	e.position = Vector2(px, py)
	e.collision_layer = 4
	e.collision_mask = 1
	e.floor_stop_on_slope = true
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	e.add_child(spr)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var sh := RectangleShape2D.new()
	match kind:
		"sumo":
			sh.size = Vector2(18, 24)
		"ninja":
			sh.size = Vector2(12, 20)
		"goomba":
			sh.size = Vector2(12, 14)
		_:
			sh.size = Vector2(12, 20)
	cs.shape = sh
	e.add_child(cs)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(22, 26) if kind == "sumo" else Vector2(14, 16)
	acs.shape = ash
	area.add_child(acs)
	e.add_child(area)
	area.body_entered.connect(func (body: Node) -> void:
		if body.is_in_group("player") and e.has_method("on_player_hit"):
			e.on_player_hit(body)
	)
	add_child(e)


func _enemies() -> void:
	# JSON map uses top-left pixel coords for 16px sprites.
	var goombas: Array[Vector2] = [
		Vector2(352, 192), Vector2(640, 192), Vector2(816, 192), Vector2(840, 192),
		Vector2(1280, 64), Vector2(1312, 64), Vector2(1552, 192), Vector2(1576, 192),
		Vector2(1824, 192), Vector2(1848, 192), Vector2(1984, 192), Vector2(2008, 192),
		Vector2(2048, 192), Vector2(2072, 192), Vector2(2784, 192), Vector2(2808, 192),
	]
	for p in goombas:
		_make_enemy("goomba", p.x + 8.0, p.y + 8.0)
	_make_enemy("koopa", 1712.0 + 8.0, 185.0 + 12.0)
	# Bruce Lee (1984) fighters — ninja flying kick, green Yamo punch.
	_make_enemy("ninja", 520.0, 198.0)
	_make_enemy("sumo", 1008.0, 196.0)
	_make_enemy("ninja", 1880.0, 198.0)
	_make_enemy("sumo", 2260.0, 196.0)


func _flag_and_castle() -> void:
	_sprite("res://assets/sprites/castle.png", _tile_pos(202, 8))
	var pole := Area2D.new()
	pole.set_script(load("res://scripts/flagpole.gd"))
	pole.position = _tile_pos(198, 2)
	pole.collision_layer = 0
	pole.collision_mask = 2
	var pole_spr := Sprite2D.new()
	pole_spr.texture = _tex("res://assets/sprites/pole.png")
	pole_spr.centered = false
	pole_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pole.add_child(pole_spr)
	var flag := Sprite2D.new()
	flag.name = "Flag"
	flag.texture = _tex("res://assets/sprites/flag.png")
	flag.centered = false
	flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag.position = Vector2(-22, 8)
	pole.add_child(flag)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(8, 14 * TILE)
	cs.shape = sh
	cs.position = Vector2(2, 7 * TILE)
	pole.add_child(cs)
	add_child(pole)
	_hard(198, 12)


func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/player.gd"))
	player.position = Vector2(40, 13 * TILE - 10)
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_stop_on_slope = true
	player.safe_margin = 0.1
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	var race := "white"
	if GameState.inst:
		race = GameState.inst.race
	spr.texture = _tex("res://assets/sprites/%s/player_small_idle.png" % race)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(spr)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10, 14)
	cs.shape = sh
	cs.position = Vector2(0, 1)
	player.add_child(cs)
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = false
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * TILE
	cam.limit_bottom = 15 * TILE
	cam.drag_horizontal_enabled = true
	player.add_child(cam)
	add_child(player)
	cam.enabled = true
	cam.make_current()


func _make_item(kind: String) -> CharacterBody2D:
	var it := CharacterBody2D.new()
	it.set_script(load("res://scripts/item.gd"))
	it.kind = kind
	it.collision_layer = 8
	it.collision_mask = 1
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	it.add_child(spr)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var sh := RectangleShape2D.new()
	sh.size = Vector2(12, 12)
	cs.shape = sh
	it.add_child(cs)
	var area := Area2D.new()
	area.name = "Pickup"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = false
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(22, 22)
	acs.shape = ash
	area.add_child(acs)
	it.add_child(area)
	return it


func _hud() -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/hud.gd"))
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)
	var font_color := Color(1, 1, 1)
	var shadow := Color(0, 0, 0)
	var score := _label("Score", Vector2(4, 4), "MARIO\n000000")
	var coins := _label("Coins", Vector2(64, 4), "COINS\nx00")
	var lives := _label("Lives", Vector2(112, 4), "LIVES\n  3")
	var world := _label("World", Vector2(160, 4), "WORLD\n 1-1")
	var time := _label("Time", Vector2(208, 4), "TIME\n 400")
	var stars := _label("Stars", Vector2(4, 28), "")
	var banner := _label("Banner", Vector2(40, 96), "")
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.size = Vector2(176, 40)
	for l in [score, coins, lives, world, time, stars, banner]:
		l.add_theme_color_override("font_color", font_color)
		l.add_theme_color_override("font_shadow_color", shadow)
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
		root.add_child(l)
	add_child(hud)


func _label(n: String, pos: Vector2, text: String) -> Label:
	var l := Label.new()
	l.name = n
	l.position = pos
	l.text = text
	return l
