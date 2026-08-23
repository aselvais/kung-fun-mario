extends CanvasLayer
# 1-1 HUD + game over

@onready var score_l: Label = $Root/Score
@onready var coins_l: Label = $Root/Coins
@onready var lives_l: Label = $Root/Lives
@onready var world_l: Label = $Root/World
@onready var time_l: Label = $Root/Time
@onready var stars_l: Label = $Root/Stars
@onready var banner: Label = $Root/Banner

var _menu_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	for n in [$Root/Score, $Root/Coins, $Root/Lives, $Root/World, $Root/Time, $Root/Stars, $Root/Banner]:
		PixelUI.stamp(n, 8)
	GameState.inst.score_changed.connect(_on_score)
	GameState.inst.coins_changed.connect(_on_coins)
	GameState.inst.lives_changed.connect(_on_lives)
	GameState.inst.time_changed.connect(_on_time)
	GameState.inst.level_cleared.connect(_on_win)
	GameState.inst.player_died.connect(_on_die)
	_on_score(GameState.inst.score)
	_on_coins(GameState.inst.coins)
	_on_lives(GameState.inst.lives)
	_on_time(GameState.inst.time_left)
	world_l.text = "WORLD\n 1-1"
	banner.text = ""


func _on_score(v: int) -> void:
	score_l.text = "MARIO\n%06d" % v


func _on_coins(v: int) -> void:
	coins_l.text = "COINS\nx%02d" % v


func _on_lives(v: int) -> void:
	lives_l.text = "LIVES\n  %d" % v


func _on_time(v: int) -> void:
	time_l.text = "TIME\n %03d" % v


func set_shuriken(seconds: float) -> void:
	if stars_l == null:
		return
	if seconds <= 0.0:
		stars_l.text = ""
		return
	var t := int(ceil(seconds))
	stars_l.text = "STAR %d:%02d" % [int(t / 60), t % 60]


func _on_win() -> void:
	banner.text = "COURSE\nCLEAR"


func _on_die() -> void:
	if GameState.inst.lives <= 0:
		banner.text = "GAME OVER"
	else:
		banner.text = "TRY AGAIN"


func show_game_over_menu() -> void:
	GameState.inst.paused = true
	get_tree().paused = true
	banner.text = "GAME OVER"
	PixelUI.stamp(banner, 16)
	if _menu_btn != null and is_instance_valid(_menu_btn):
		_menu_btn.visible = true
		return
	_menu_btn = Button.new()
	_menu_btn.name = "MenuButton"
	_menu_btn.text = "MAIN MENU"
	_menu_btn.position = Vector2(64, 148)
	_menu_btn.size = Vector2(128, 22)
	_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	PixelUI.stamp(_menu_btn, 8)
	_menu_btn.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.08, 0.08, 0.92)
	style.border_color = Color.WHITE
	style.set_border_width_all(1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_menu_btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.90, 0.20, 0.12, 0.95)
	_menu_btn.add_theme_stylebox_override("hover", hover)
	_menu_btn.add_theme_stylebox_override("pressed", hover)
	_menu_btn.pressed.connect(_on_menu)
	$Root.add_child(_menu_btn)


func _on_menu() -> void:
	get_tree().paused = false
	GameState.inst.paused = false
	GameState.inst.won = false
	GameState.inst.play_bgm("menu")
	get_tree().change_scene_to_file("res://scenes/title.tscn")
