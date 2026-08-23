extends StaticBody2D
# bumpable brick / question block

@export var brick := false
@export var contents := "empty" # empty, coin, mushroom, star, multi, hidden_1up
@export var is_secret := false

@onready var sprite: Sprite2D = $Sprite

var used := false
var coins_left := 10
var _busy := false
var _rest: Vector2


func _ready() -> void:
	_rest = position
	add_to_group("blocks")
	if is_secret:
		sprite.visible = false
		sprite.modulate.a = 0.0


func bump(player: Node) -> void:
	if _busy:
		return
	if used and contents != "multi":
		return
	var p := player as CharacterBody2D
	if is_secret and p != null and p.velocity.y >= 0.0:
		return
	if brick and not used and contents == "empty":
		if player.get("is_big"):
			_break_apart()
			return
		_bounce()
		GameState.inst.play_sfx("bump")
		return
	_busy = true
	_bounce()
	_dispense(player)
	if contents == "multi":
		coins_left -= 1
		if coins_left <= 0:
			_set_used()
		_busy = false
	else:
		_set_used()
		_busy = false


func _dispense(player: Node) -> void:
	match contents:
		"coin", "multi":
			GameState.inst.add_coin()
			_pop_sprite("res://assets/sprites/coin0.png", 80)
		"mushroom":
			_spawn_item("mushroom")
			GameState.inst.play_sfx("powerup")
		"star":
			_spawn_item("star")
			GameState.inst.play_sfx("powerup")
		"shuriken":
			_spawn_item("shuriken")
			GameState.inst.play_sfx("powerup")
		"hidden_1up":
			GameState.inst.lives += 1
			GameState.inst.lives_changed.emit(GameState.inst.lives)
			GameState.inst.add_score(1000)
			GameState.inst.play_sfx("oneup")
			_pop_sprite("res://assets/sprites/mushroom.png", 40)
		_:
			if brick:
				pass
			else:
				GameState.inst.add_coin()
				_pop_sprite("res://assets/sprites/coin0.png", 80)


func _spawn_item(kind: String) -> void:
	var level: Node = get_tree().get_first_node_in_group("level")
	if level == null:
		level = get_parent()
	if level != null and level.has_method("spawn_item"):
		# Center of the tile so the power-up pops out of the block, not its corner.
		level.spawn_item(kind, global_position + Vector2(8, 8))


func _set_used() -> void:
	used = true
	is_secret = false
	sprite.visible = true
	sprite.modulate.a = 1.0
	if brick and contents != "empty":
		sprite.texture = load("res://assets/tiles/question_used.png")
	else:
		sprite.texture = load("res://assets/tiles/question_used.png")


func _bounce() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", _rest.y - 6.0, 0.08)
	tw.tween_property(self, "position:y", _rest.y, 0.08)


func _break_apart() -> void:
	GameState.inst.add_score(50)
	GameState.inst.play_sfx("break")
	queue_free()


func _pop_sprite(path: String, rise: float) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.global_position = global_position + Vector2(0, -12)
	get_parent().add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "position:y", s.position.y - rise, 0.35)
	tw.tween_property(s, "modulate:a", 0.0, 0.15)
	tw.tween_callback(s.queue_free)
