extends CharacterBody2D
# walker / koopa

const GRAVITY := 900.0
const WALK := 28.0
const SHELL := 180.0

@export var kind := "goomba" # goomba, koopa

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var dir := -1
var squashed := false
var shell := false
var shell_moving := false
var _anim := 0.0


func _ready() -> void:
	add_to_group("enemies")
	_update_sprite()


func _physics_process(delta: float) -> void:
	if squashed:
		return
	velocity.y += GRAVITY * delta
	if kind == "koopa" and shell:
		velocity.x = SHELL * dir if shell_moving else 0.0
	else:
		velocity.x = WALK * dir
	move_and_slide()

	if is_on_wall():
		dir *= -1
		if shell_moving:
			GameState.inst.add_score(100)

	if global_position.y > 16 * 16:
		queue_free()

	_anim += delta
	_update_sprite()


func on_player_hit(player: Node) -> void:
	if squashed:
		return
	var p := player as CharacterBody2D
	if p == null:
		return
	var from_above: bool = p.global_position.y < global_position.y - 2.0 and p.velocity.y > 0.0
	if from_above:
		if kind == "koopa":
			_stomp_koopa(player)
		else:
			_squash(player)
	elif bool(p.get("attacking")):
		take_hit(p, str(p.get("attack_kind")))
	elif shell and not shell_moving:
		shell_moving = true
		dir = 1 if player.global_position.x < global_position.x else -1
		GameState.inst.add_score(400)
	elif player.has_method("hurt"):
		player.hurt(true, self)


func take_hit(player: Node, _kind: String) -> void:
	if squashed:
		return
	dir = 1 if player.global_position.x < global_position.x else -1
	GameState.inst.play_sfx("hit")
	if kind == "koopa":
		if not shell:
			shell = true
			shell_moving = true
			GameState.inst.add_score(200)
			_shape_shell()
		else:
			shell_moving = true
			GameState.inst.add_score(400)
	else:
		_squash(player, false)


func _squash(player: Node, bounce := true) -> void:
	squashed = true
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	sprite.texture = load("res://assets/sprites/goomba_flat.png")
	sprite.offset = Vector2.ZERO
	if bounce and player.has_method("stomp_bounce"):
		player.stomp_bounce()
	GameState.inst.add_score(100)
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(queue_free)


func _stomp_koopa(player: Node) -> void:
	if player.has_method("stomp_bounce"):
		player.stomp_bounce()
	if not shell:
		shell = true
		shell_moving = false
		GameState.inst.add_score(100)
		_shape_shell()
	elif shell_moving:
		shell_moving = false
		GameState.inst.add_score(100)
	else:
		shell_moving = true
		dir = 1 if player.global_position.x < global_position.x else -1
		GameState.inst.add_score(400)


func _shape_shell() -> void:
	var sh := collision.shape as RectangleShape2D
	sh.size = Vector2(12, 12)
	collision.position = Vector2(0, 4)


func _update_sprite() -> void:
	sprite.flip_h = dir > 0
	if kind == "koopa":
		if shell:
			sprite.texture = load("res://assets/sprites/koopa_shell.png")
			sprite.offset = Vector2(0, 0)
		else:
			var f := "1" if fmod(_anim, 0.3) < 0.15 else "2"
			sprite.texture = load("res://assets/sprites/koopa%s.png" % f)
			sprite.offset = Vector2(0, -4)
	else:
		var f := "1" if fmod(_anim, 0.25) < 0.12 else "2"
		sprite.texture = load("res://assets/sprites/goomba%s.png" % f)
