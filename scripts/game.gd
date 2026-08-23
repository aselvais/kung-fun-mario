extends Node
class_name GameState
# looping overworld BGM + sfx bus

static var inst: GameState

signal score_changed(value: int)
signal coins_changed(value: int)
signal lives_changed(value: int)
signal time_changed(value: int)
signal player_died
signal level_cleared

const TILE := 16
const LEVEL_WIDTH := 212
const LEVEL_HEIGHT := 15
const GROUND_TOP_TILE := 13
const BGM_GAME_DB := -8.0
const BGM_MENU_DB := -11.0

var score: int = 0
var coins: int = 0
var lives: int = 3
var time_left: int = 400
var paused: bool = false
var won: bool = false
var race := "white"

var _timer_acc := 0.0
var _sfx_cache: Dictionary = {}
var _bgm: AudioStreamPlayer
var _bgm_track := ""


func _enter_tree() -> void:
	inst = self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.scene_file_path
	if path.ends_with("world_1_1.tscn"):
		won = false
		paused = false
		get_tree().paused = false
		play_bgm("menu")
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		get_tree().root.set_input_as_handled()


func start_bgm() -> void:
	play_bgm("game")


func play_bgm(track: String) -> void:
	if _bgm_track == track and _bgm != null and _bgm.playing:
		return
	if _bgm == null:
		_bgm = AudioStreamPlayer.new()
		_bgm.name = "BGM"
		_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_bgm)
	var path := "res://assets/music/overworld.wav"
	var db := BGM_GAME_DB
	if track == "menu":
		path = "res://assets/music/menu.wav"
		db = BGM_MENU_DB
	if not ResourceLoader.exists(path):
		return
	_bgm_track = track
	_bgm.stream = load(path)
	_bgm.volume_db = db
	if not _bgm.finished.is_connected(_on_bgm_finished):
		_bgm.finished.connect(_on_bgm_finished)
	_bgm.play()


func _on_bgm_finished() -> void:
	if _bgm != null and not won:
		_bgm.play()


func _set_bgm_db(db: float) -> void:
	if _bgm != null:
		_bgm.volume_db = db


func play_sfx(sfx_name: String) -> void:
	var path := "res://assets/sfx/%s.wav" % sfx_name
	var stream: AudioStream = _sfx_cache.get(sfx_name)
	if stream == null:
		if not ResourceLoader.exists(path):
			return
		stream = load(path) as AudioStream
		if stream == null:
			return
		_sfx_cache[sfx_name] = stream
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	if sfx_name == "die":
		_set_bgm_db(-18.0)
	elif sfx_name == "win":
		_set_bgm_db(-14.0)


func _process(delta: float) -> void:
	if paused or won:
		return
	_timer_acc += delta
	if _timer_acc >= 0.5:
		_timer_acc = 0.0
		time_left = max(time_left - 1, 0)
		time_changed.emit(time_left)
		if time_left == 0:
			player_died.emit()


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func add_coin(amount: int = 1) -> void:
	coins += amount
	add_score(200 * amount)
	play_sfx("coin")
	if coins >= 100:
		coins -= 100
		lives += 1
		lives_changed.emit(lives)
		play_sfx("oneup")
	coins_changed.emit(coins)


func lose_life() -> void:
	lives = max(lives - 1, 0)
	lives_changed.emit(lives)


func reset_run() -> void:
	score = 0
	coins = 0
	lives = 3
	time_left = 400
	won = false
	paused = false
	_timer_acc = 0.0
	score_changed.emit(score)
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	time_changed.emit(time_left)


func restart_level() -> void:
	time_left = 400
	won = false
	paused = false
	_timer_acc = 0.0
	time_changed.emit(time_left)
	play_bgm("game")
	get_tree().reload_current_scene()
