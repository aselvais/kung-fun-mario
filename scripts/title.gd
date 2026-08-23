extends Control
# Title + race select + help

const SKY := Color(0.361, 0.580, 0.988)
const RACES := [
	{"id": "white", "label": "WHITE"},
	{"id": "black", "label": "BLACK"},
	{"id": "asian", "label": "ASIAN"},
]

var _race := "white"
var _world_bg: Node2D
var _scroll_layers: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(SKY)
	if GameState.inst:
		GameState.inst.play_bgm("menu")
	_ensure_bg()
	_build_title()


func _process(delta: float) -> void:
	for layer in _scroll_layers:
		var node: Node2D = layer["node"]
		var speed: float = layer["speed"]
		var wrap: float = layer["wrap"]
		node.position.x -= speed * delta
		if node.position.x <= -wrap:
			node.position.x += wrap


func _style_button() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.72, 0.08, 0.08, 0.92)
	s.border_color = Color(1, 1, 1)
	s.set_border_width_all(1)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _label(text: String, pos: Vector2, size: Vector2, font_size: int, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PixelUI.stamp(l, font_size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	add_child(l)
	return l


func _button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	PixelUI.stamp(b, 8)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style_button())
	var hover := _style_button()
	hover.bg_color = Color(0.90, 0.20, 0.12, 0.95)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	add_child(b)
	return b


func _sprite_tex(anim: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/sprites/%s/player_small_%s.png" % [_race, anim])
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = pos
	t.size = Vector2(24, 24)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _tex_sprite(parent: Node2D, path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	parent.add_child(s)
	return s


func _ensure_bg() -> void:
	if _world_bg != null and is_instance_valid(_world_bg):
		move_child(_world_bg, 0)
		return
	_world_bg = Node2D.new()
	_world_bg.name = "MenuBg"
	_world_bg.z_index = -20
	add_child(_world_bg)
	move_child(_world_bg, 0)
	_scroll_layers.clear()
	var wrap := 512.0
	var far := Node2D.new()
	_world_bg.add_child(far)
	for copy in [0.0, wrap]:
		_tex_sprite(far, "res://assets/sprites/mountain_far.png", Vector2(0.0 + copy, 88))
	_scroll_layers.append({"node": far, "speed": 4.0, "wrap": wrap})
	var clouds := Node2D.new()
	_world_bg.add_child(clouds)
	for copy in [0.0, wrap]:
		_tex_sprite(clouds, "res://assets/sprites/cloud3.png", Vector2(20 + copy, 18))
		_tex_sprite(clouds, "res://assets/sprites/cloud1.png", Vector2(120 + copy, 36))
		_tex_sprite(clouds, "res://assets/sprites/cloud2.png", Vector2(210 + copy, 22))
		_tex_sprite(clouds, "res://assets/sprites/cloud1.png", Vector2(320 + copy, 40))
		_tex_sprite(clouds, "res://assets/sprites/cloud3.png", Vector2(400 + copy, 16))
	_scroll_layers.append({"node": clouds, "speed": 8.0, "wrap": wrap})
	var mid := Node2D.new()
	_world_bg.add_child(mid)
	for copy in [0.0, wrap]:
		_tex_sprite(mid, "res://assets/sprites/mountain_mid.png", Vector2(0.0 + copy, 88))
	_scroll_layers.append({"node": mid, "speed": 11.0, "wrap": wrap})
	var near := Node2D.new()
	_world_bg.add_child(near)
	for copy in [0.0, wrap]:
		_tex_sprite(near, "res://assets/sprites/mountain_near.png", Vector2(0.0 + copy, 88))
	_scroll_layers.append({"node": near, "speed": 14.0, "wrap": wrap})
	var hills := Node2D.new()
	_world_bg.add_child(hills)
	for copy in [0.0, wrap]:
		_tex_sprite(hills, "res://assets/sprites/hill_large.png", Vector2(0 + copy, 144))
		_tex_sprite(hills, "res://assets/sprites/hill_small.png", Vector2(96 + copy, 160))
		_tex_sprite(hills, "res://assets/sprites/hill_large.png", Vector2(176 + copy, 144))
		_tex_sprite(hills, "res://assets/sprites/hill_small.png", Vector2(288 + copy, 160))
		_tex_sprite(hills, "res://assets/sprites/hill_large.png", Vector2(368 + copy, 144))
		_tex_sprite(hills, "res://assets/sprites/bush3.png", Vector2(48 + copy, 192))
		_tex_sprite(hills, "res://assets/sprites/bush1.png", Vector2(160 + copy, 192))
		_tex_sprite(hills, "res://assets/sprites/bush2.png", Vector2(250 + copy, 192))
		_tex_sprite(hills, "res://assets/sprites/bush3.png", Vector2(400 + copy, 192))
	_scroll_layers.append({"node": hills, "speed": 16.0, "wrap": wrap})
	var ground := Node2D.new()
	_world_bg.add_child(ground)
	for copy_i in 2:
		var ox := copy_i * wrap
		for x in range(0, int(wrap), 16):
			_tex_sprite(ground, "res://assets/tiles/ground_top.png", Vector2(x + ox, 208))
			_tex_sprite(ground, "res://assets/tiles/ground_fill.png", Vector2(x + ox, 224))
		_tex_sprite(ground, "res://assets/tiles/pipe_top_l.png", Vector2(80 + ox, 176))
		_tex_sprite(ground, "res://assets/tiles/pipe_top_r.png", Vector2(96 + ox, 176))
		_tex_sprite(ground, "res://assets/tiles/pipe_body_l.png", Vector2(80 + ox, 192))
		_tex_sprite(ground, "res://assets/tiles/pipe_body_r.png", Vector2(96 + ox, 192))
		_tex_sprite(ground, "res://assets/tiles/question.png", Vector2(160 + ox, 144))
		_tex_sprite(ground, "res://assets/tiles/brick.png", Vector2(176 + ox, 144))
		_tex_sprite(ground, "res://assets/tiles/question.png", Vector2(192 + ox, 144))
		_tex_sprite(ground, "res://assets/tiles/brick.png", Vector2(320 + ox, 160))
	_scroll_layers.append({"node": ground, "speed": 28.0, "wrap": wrap})


func _clear() -> void:
	for c in get_children():
		if c == _world_bg:
			continue
		c.queue_free()


func _build_title() -> void:
	_clear()
	_ensure_bg()
	_label("KUNG-FU MARIO", Vector2(0, 28), Vector2(256, 24), 16)
	_label("WORLD 1-1", Vector2(0, 52), Vector2(256, 12), 8)
	var ng := _button("NEW GAME", Vector2(72, 96), Vector2(112, 22))
	ng.pressed.connect(_build_race)
	var q := _button("QUIT", Vector2(72, 128), Vector2(112, 22))
	q.pressed.connect(func (): get_tree().quit())


func _build_race() -> void:
	_clear()
	_ensure_bg()
	if GameState.inst:
		GameState.inst.play_sfx("coin")
		GameState.inst.play_bgm("menu")
	_label("CHOOSE FIGHTER", Vector2(0, 16), Vector2(256, 16), 12)
	_label("SELECT A RACE", Vector2(0, 34), Vector2(256, 12), 8)
	var y := 58
	for r in RACES:
		_race_row(str(r["id"]), str(r["label"]), y)
		y += 40


func _race_row(race_id: String, label: String, y: int) -> void:
	var preview := TextureRect.new()
	preview.texture = load("res://assets/sprites/%s/player_small_idle.png" % race_id)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.position = Vector2(48, y)
	preview.size = Vector2(32, 32)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	var b := _button(label, Vector2(88, y + 6), Vector2(120, 22))
	b.pressed.connect(func (): _choose_race(race_id))


func _choose_race(race_id: String) -> void:
	_race = race_id
	if GameState.inst:
		GameState.inst.race = race_id
		GameState.inst.play_sfx("coin")
	_build_help()


func _build_help() -> void:
	_clear()
	_ensure_bg()
	if GameState.inst:
		GameState.inst.play_bgm("menu")
	_label("HELP", Vector2(0, 2), Vector2(256, 16), 12)
	_help_row(16, "idle", "WALK", "A / D")
	_help_row(40, "walk2", "RUN", "TAP A/D TWICE")
	_help_row(64, "jump", "JUMP", "SPACE / W")
	_help_row(88, "jump", "DOUBLE", "JUMP AGAIN IN AIR")
	_help_row(112, "punch", "PUNCH", "L")
	_help_row(136, "kick", "KICK", "K")
	_help_row(160, "idle", "MENU", "ESC")
	var start := _button("START", Vector2(72, 198), Vector2(112, 22))
	start.pressed.connect(_start_game)


func _help_row(y: int, anim: String, action: String, keys: String) -> void:
	_sprite_tex(anim, Vector2(8, y))
	_label(action, Vector2(36, y + 4), Vector2(54, 16), 8, HORIZONTAL_ALIGNMENT_LEFT)
	_label(keys, Vector2(94, y + 4), Vector2(154, 16), 8, HORIZONTAL_ALIGNMENT_LEFT)


func _start_game() -> void:
	if GameState.inst:
		GameState.inst.race = _race
		GameState.inst.reset_run()
		GameState.inst.play_sfx("powerup")
	get_tree().change_scene_to_file("res://scenes/world_1_1.tscn")
