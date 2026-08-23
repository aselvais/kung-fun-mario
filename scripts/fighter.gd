extends CharacterBody2D
# Bruce Lee (C64, 1984) inspired: ninja flying-kick + green Yamo punch

const GRAVITY := 900.0
const MAX_FALL := 340.0

@export var kind := "ninja" # ninja, sumo

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var dir := -1
var hp := 2
var dead := false
var stunned := 0.0
var attack_cd := 0.25
var attacking := false
var attack_time := 0.0
var attack_dur := 0.40
var _anim := 0.0
var _hitbox: Area2D
var _hitbox_cs: CollisionShape2D
var _hitbox_shape: RectangleShape2D
var _hurt_ids: Dictionary = {}


func _ready() -> void:
	add_to_group("enemies")
	if kind == "sumo":
		hp = 3
		attack_dur = 0.38
	_make_hitbox()
	_update_sprite()


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return
	if stunned > 0.0:
		stunned -= delta
		sprite.modulate = Color(1, 1, 1, 1) if fmod(stunned, 0.1) < 0.05 else Color(1, 0.6, 0.6)
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y += GRAVITY * delta
		move_and_slide()
		_update_sprite()
		return
	sprite.modulate = Color.WHITE

	if attack_cd > 0.0:
		attack_cd -= delta

	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	var player := _player()

	if attacking:
		_update_attack(delta)
	else:
		_patrol_or_chase(player, delta)
		if is_on_floor():
			_try_attack(player)

	move_and_slide()
	if is_on_wall() and not attacking:
		dir *= -1
	if is_on_floor() and not attacking and _ledge_ahead():
		dir *= -1
	if global_position.y > 16 * 16:
		queue_free()
		return
	_anim += delta
	_update_sprite()
	if attacking:
		_strike_overlaps()


func _player() -> CharacterBody2D:
	var n := get_tree().get_first_node_in_group("player")
	return n as CharacterBody2D


func _patrol_or_chase(player: CharacterBody2D, _delta: float) -> void:
	var speed := 44.0 if kind == "ninja" else 22.0
	var detect := 170.0 if kind == "ninja" else 150.0
	var strike_range := 52.0 if kind == "ninja" else 24.0
	if player != null and not bool(player.get("dead")):
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) < detect and absf(player.global_position.y - global_position.y) < 48.0:
			if absf(dx) > 4.0:
				dir = 1 if dx > 0.0 else -1
			if absf(dx) < strike_range:
				velocity.x = 0.0
				return
	velocity.x = speed * dir


func _try_attack(player: CharacterBody2D) -> void:
	if player == null or bool(player.get("dead")) or attack_cd > 0.0:
		return
	var dx: float = player.global_position.x - global_position.x
	var dy: float = player.global_position.y - global_position.y
	if absf(dy) > 22.0:
		return
	if absf(dx) > 4.0:
		dir = 1 if dx > 0.0 else -1
	if kind == "ninja":
		if absf(dx) < 56.0:
			_start_jump_kick()
	else:
		if absf(dx) < 28.0:
			_start_punch()


func _start_jump_kick() -> void:
	attacking = true
	attack_time = 0.0
	velocity = Vector2(dir * 118.0, -248.0)
	attack_cd = 1.15
	_hurt_ids.clear()
	GameState.inst.play_sfx("kick")


func _start_punch() -> void:
	attacking = true
	attack_time = 0.0
	velocity.x = 0.0
	attack_cd = 0.95
	_hurt_ids.clear()
	GameState.inst.play_sfx("punch")


func _update_attack(delta: float) -> void:
	attack_time += delta
	if kind == "sumo":
		velocity.x = 0.0
	var active: bool
	if kind == "ninja":
		active = attack_time >= 0.05 and not is_on_floor()
		_hitbox_shape.size = Vector2(18, 10)
		_hitbox_cs.position = Vector2(dir * 14.0, 2.0)
	else:
		active = attack_time >= 0.08 and attack_time < attack_dur * 0.85
		_hitbox_shape.size = Vector2(16, 12)
		_hitbox_cs.position = Vector2(dir * 16.0, 0.0)
	_hitbox.monitoring = active
	var done := attack_time >= attack_dur
	if kind == "ninja":
		done = is_on_floor() and attack_time >= 0.18
	if done:
		attacking = false
		_hitbox.monitoring = false


func _strike_overlaps() -> void:
	if _hitbox == null or not _hitbox.monitoring:
		return
	for body in _hitbox.get_overlapping_bodies():
		_hit_player(body)


func _hit_player(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var id := body.get_instance_id()
	if _hurt_ids.has(id):
		return
	if bool(body.get("attacking")):
		take_hit(body, str(body.get("attack_kind")))
		_hurt_ids[id] = true
		return
	if body.has_method("hurt"):
		body.hurt(true, self)
		_hurt_ids[id] = true


func on_player_hit(player: Node) -> void:
	if dead:
		return
	var p := player as CharacterBody2D
	if p == null:
		return
	var from_above: bool = p.global_position.y < global_position.y - 2.0 and p.velocity.y > 0.0
	if from_above:
		take_hit(p, "stomp")
		if p.has_method("stomp_bounce"):
			p.stomp_bounce()
	elif bool(p.get("attacking")):
		take_hit(p, str(p.get("attack_kind")))
	elif player.has_method("hurt"):
		player.hurt(true, self)


func take_hit(player: Node, _kind: String) -> void:
	if dead or stunned > 0.0:
		return
	hp -= 1
	GameState.inst.play_sfx("hit")
	var away := 1
	if player is Node2D:
		away = 1 if global_position.x >= (player as Node2D).global_position.x else -1
	dir = -away
	if hp <= 0:
		_die(away)
		return
	stunned = 0.28
	attacking = false
	if _hitbox:
		_hitbox.monitoring = false
	velocity = Vector2(away * 90.0, -90.0)
	GameState.inst.add_score(200)


func _die(away: int) -> void:
	dead = true
	attacking = false
	GameState.inst.add_score(400 if kind == "sumo" else 300)
	collision.set_deferred("disabled", true)
	if _hitbox:
		_hitbox.monitoring = false
	velocity = Vector2(away * 120.0, -180.0)
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_callback(queue_free)


func _ledge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 10.0, 2.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 18))
	q.collision_mask = 1
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()


func _make_hitbox() -> void:
	_hitbox = Area2D.new()
	_hitbox.name = "FighterHitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox_cs = CollisionShape2D.new()
	_hitbox_shape = RectangleShape2D.new()
	_hitbox_shape.size = Vector2(14, 10)
	_hitbox_cs.shape = _hitbox_shape
	_hitbox.add_child(_hitbox_cs)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_hit_player)


func _update_sprite() -> void:
	sprite.flip_h = dir < 0
	var tex: Texture2D
	if kind == "sumo":
		if attacking:
			tex = load("res://assets/sprites/sumo_punch.png")
		else:
			var f := "1" if fmod(_anim, 0.36) < 0.18 else "2"
			tex = load("res://assets/sprites/sumo_walk%s.png" % f)
		sprite.offset = Vector2(0, -2)
	else:
		if attacking:
			tex = load("res://assets/sprites/ninja_kick.png")
		else:
			var f := "1" if fmod(_anim, 0.22) < 0.11 else "2"
			tex = load("res://assets/sprites/ninja_walk%s.png" % f)
		sprite.offset = Vector2(0, -1)
	sprite.texture = tex
	if dead:
		sprite.modulate = Color(1, 1, 1, 0.7)
		sprite.rotation = 1.2 * dir
