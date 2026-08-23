extends CharacterBody2D
# World 1-1 tribute player — Kung-Fu Master (1984) look

const TILE := 16.0
const WALK_SPEED := 92.0
const RUN_SPEED := 152.0
const ACCEL := 520.0
const DECEL := 640.0
const AIR_ACCEL := 380.0
const JUMP_VELOCITY := -268.0
const JUMP_CUT := 0.42
const GRAVITY := 780.0
const FALL_GRAVITY := 1180.0
const MAX_FALL := 340.0
const STOMP_BOUNCE := -180.0
const INVINCIBLE_TIME := 1.6
const MAX_JUMPS := 2
const DOUBLE_JUMP_VELOCITY := -250.0
const PUNCH_TIME := 0.22
const KICK_TIME := 0.32
const PUNCH_ACTIVE := 0.05
const KICK_ACTIVE := 0.08
const TAP_WINDOW := 0.28
const SHURIKEN_TIME := 180.0

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D

var is_big := false
var dead := false
var clearing := false
var facing := 1
var invincible := 0.0
var walk_timer := 0.0
var spawn_pos := Vector2.ZERO
var jumps_left := MAX_JUMPS
var _shape: RectangleShape2D
var attacking := false
var attack_kind := ""
var attack_time := 0.0
var _hitbox: Area2D
var _hitbox_shape: RectangleShape2D
var _hitbox_cs: CollisionShape2D
var _tap_dir := 0
var _tap_time := -1.0
var _dashing := false
var _growing := false
var shuriken_left := 0.0
var _bubble: Control
var _bubble_label: Label
var _bubble_tw: Tween
const SHOUTS := [
	"Holy crap!",
	"Son of a biscuit!",
	"What the heck!",
	"Dagnabbit!",
	"Oh sugar!",
	"Dickweed!",
	"Shitshow!",
	"Clusterfuck!",
	"Fuckery!",
	"Bollocks!",
	"Assclown!",
	"Fucktrumpet!",
	"Knobhead!"
]


func _ready() -> void:
	spawn_pos = global_position
	_shape = collision.shape as RectangleShape2D
	floor_snap_length = 4.0
	_apply_size()
	add_to_group("player")
	_make_hitbox()
	_make_bubble()


func _physics_process(delta: float) -> void:
	if dead or clearing:
		return
	if invincible > 0.0:
		invincible -= delta
		sprite.visible = fmod(invincible, 0.12) < 0.06
	else:
		sprite.visible = true

	if shuriken_left > 0.0:
		shuriken_left = max(0.0, shuriken_left - delta)
		_hud_shuriken()
	_try_attack()
	_update_attack(delta)

	_update_dash_tap()
	var input_x := Input.get_axis("move_left", "move_right")
	var holding_dash := (_dashing and ((_tap_dir < 0 and Input.is_action_pressed("move_left")) or (_tap_dir > 0 and Input.is_action_pressed("move_right"))))
	if not holding_dash:
		_dashing = false
	var running := Input.is_action_pressed("run") or _dashing
	var max_speed := RUN_SPEED if running else WALK_SPEED
	if attacking:
		max_speed *= 0.35
	var accel := ACCEL if is_on_floor() else AIR_ACCEL

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * max_speed, accel * delta)
		if not attacking:
			facing = 1 if input_x > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
		_dashing = false

	if is_on_floor():
		jumps_left = MAX_JUMPS
	if Input.is_action_just_pressed("jump") and not attacking and jumps_left > 0:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			GameState.inst.play_sfx("jump")
		else:
			velocity.y = DOUBLE_JUMP_VELOCITY
			GameState.inst.play_sfx("double_jump")
		jumps_left -= 1
	elif not is_on_floor() and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	var g := GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y = min(velocity.y + g * delta, MAX_FALL)

	move_and_slide()

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var n := col.get_normal()
		var other := col.get_collider()
		if other == null:
			continue
		if n.y > 0.5 and other.has_method("bump"):
			other.bump(self)
		if other.is_in_group("enemies") and other.has_method("on_player_hit"):
			other.on_player_hit(self)

	if global_position.y > TILE * 16.0:
		die()

	global_position.x = max(global_position.x, TILE)
	_animate(delta)


func _update_dash_tap() -> void:
	var dir := 0
	if Input.is_action_just_pressed("move_left"):
		dir = -1
	elif Input.is_action_just_pressed("move_right"):
		dir = 1
	else:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if dir == _tap_dir and (now - _tap_time) <= TAP_WINDOW:
		_dashing = true
	_tap_dir = dir
	_tap_time = now


func _try_attack() -> void:
	if attacking or dead:
		return
	if Input.is_action_just_pressed("punch"):
		_start_attack("punch")
	elif Input.is_action_just_pressed("kick"):
		_start_attack("kick")


func _start_attack(kind: String) -> void:
	attacking = true
	attack_kind = kind
	attack_time = 0.0
	GameState.inst.play_sfx(kind)
	if kind == "punch" and shuriken_left > 0.0:
		_throw_shuriken()
	var scale_hit := 1.6 if is_big else 1.0
	if kind == "kick":
		_hitbox_shape.size = Vector2(18, 12) * scale_hit
	else:
		_hitbox_shape.size = Vector2(12, 10) * scale_hit


func _update_attack(delta: float) -> void:
	if not attacking:
		_hitbox.monitoring = false
		return
	attack_time += delta
	var dur := KICK_TIME if attack_kind == "kick" else PUNCH_TIME
	var active_at := KICK_ACTIVE if attack_kind == "kick" else PUNCH_ACTIVE
	var reach := 16.0 if attack_kind == "kick" else 11.0
	if is_big:
		reach *= 1.6
	_hitbox_cs.position = Vector2(facing * reach, -10.0 if is_big else 0.0)
	var active := attack_time >= active_at and attack_time < dur * 0.85
	_hitbox.monitoring = active
	if active:
		for body in _hitbox.get_overlapping_bodies():
			_strike(body)
	if attack_time >= dur:
		attacking = false
		attack_kind = ""
		_hitbox.monitoring = false


func _strike(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_hit"):
		body.take_hit(self, attack_kind)


func _on_hitbox_body(body: Node) -> void:
	if attacking:
		_strike(body)


func _make_hitbox() -> void:
	_hitbox = Area2D.new()
	_hitbox.name = "AttackHitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 4
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox_cs = CollisionShape2D.new()
	_hitbox_shape = RectangleShape2D.new()
	_hitbox_shape.size = Vector2(12, 10)
	_hitbox_cs.shape = _hitbox_shape
	_hitbox.add_child(_hitbox_cs)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_on_hitbox_body)


func give_shurikens(secs: float = SHURIKEN_TIME) -> void:
	shuriken_left = secs
	GameState.inst.add_score(1000)
	GameState.inst.play_sfx("powerup")
	_hud_shuriken()


func _hud_shuriken() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("set_shuriken"):
		hud.set_shuriken(shuriken_left)


func _throw_shuriken() -> void:
	var star := Area2D.new()
	star.set_script(load("res://scripts/shuriken.gd"))
	star.dir = facing
	star.shooter = self
	star.collision_layer = 0
	star.collision_mask = 5
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = load("res://assets/sprites/shuriken.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	star.add_child(spr)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10, 10)
	cs.shape = sh
	star.add_child(cs)
	get_parent().add_child(star)
	star.global_position = global_position + Vector2(facing * 14.0, -6.0 if is_big else 0.0)


func stomp_bounce() -> void:
	velocity.y = STOMP_BOUNCE
	GameState.inst.play_sfx("stomp")


func grow() -> void:
	if is_big:
		GameState.inst.add_score(1000)
		GameState.inst.play_sfx("grow")
		return
	if _growing or dead:
		return
	_growing = true
	GameState.inst.add_score(1000)
	GameState.inst.play_sfx("grow")
	# Wait to drop away from the ? block so the 2x body does not jam inside it.
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_callback(_finish_grow)


func _finish_grow() -> void:
	_growing = false
	if dead or is_big:
		return
	is_big = true
	_apply_size()


func shrink() -> void:
	if not is_big:
		hurt()
		return
	is_big = false
	invincible = INVINCIBLE_TIME
	_apply_size()


func hurt(from_enemy := false, source: Node = null) -> void:
	if invincible > 0.0 or dead or attacking:
		return
	if from_enemy:
		_shout()
		_knockback(source)
	if is_big:
		shrink()
	else:
		die(from_enemy)


func _knockback(source: Node) -> void:
	var dir := -float(facing)
	if source is Node2D:
		var dx: float = global_position.x - (source as Node2D).global_position.x
		if absf(dx) > 0.5:
			dir = signf(dx)
	velocity.x = dir * 190.0
	velocity.y = -170.0


func _shout() -> void:
	GameState.inst.play_sfx("ouch")
	if _bubble == null or _bubble_label == null:
		return
	_bubble_label.text = SHOUTS[randi() % SHOUTS.size()]
	_bubble.visible = true
	_bubble.modulate.a = 1.0
	_bubble.reset_size()
	if _bubble_tw:
		_bubble_tw.kill()
	_bubble_tw = create_tween()
	_bubble_tw.tween_interval(0.95)
	_bubble_tw.tween_property(_bubble, "modulate:a", 0.0, 0.18)
	_bubble_tw.tween_callback(func ():
		if _bubble:
			_bubble.visible = false
	)


func _make_bubble() -> void:
	_bubble = Control.new()
	_bubble.name = "OuchBubble"
	_bubble.z_index = 30
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.position = Vector2(6, -28)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.set_border_width_all(1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	_bubble_label = Label.new()
	PixelUI.stamp(_bubble_label, 8)
	_bubble_label.add_theme_color_override("font_color", Color.BLACK)
	_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_bubble_label)
	_bubble.add_child(panel)
	_bubble.visible = false
	add_child(_bubble)


func die(keep_knockback := false) -> void:
	if dead:
		return
	dead = true
	attacking = false
	shuriken_left = 0.0
	_hud_shuriken()
	if keep_knockback:
		velocity.y = min(velocity.y, -140.0)
	else:
		velocity = Vector2(0, JUMP_VELOCITY * 0.7)
	GameState.inst.play_sfx("die")
	collision.set_deferred("disabled", true)
	GameState.inst.lose_life()
	GameState.inst.player_died.emit()
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(self, "velocity:y", 280.0, 0.6)
	tw.tween_interval(0.6)
	tw.finished.connect(func ():
		if GameState.inst.lives <= 0:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null and hud.has_method("show_game_over_menu"):
				hud.show_game_over_menu()
			return
		GameState.inst.restart_level()
	)


func start_clear() -> void:
	clearing = true
	velocity = Vector2.ZERO


func foot_bottom() -> float:
	if _shape == null:
		return 10.0
	return _shape.size.y * 0.5 + collision.position.y


func walk_to_castle(target_x: float) -> void:
	clearing = true
	global_position.y = 13.0 * TILE - foot_bottom()
	var tw := create_tween()
	tw.tween_property(self, "global_position:x", target_x, 1.2)
	tw.finished.connect(func ():
		visible = false
		GameState.inst.won = true
		GameState.inst.play_sfx("win")
		GameState.inst.level_cleared.emit()
	)


func _apply_size() -> void:
	if is_big:
		sprite.scale = Vector2(2, 2)
		# Twice the small body; grow upward so feet stay planted.
		_shape.size = Vector2(16, 36)
		collision.position = Vector2(0, -8)
		if _bubble:
			_bubble.position = Vector2(10, -44)
	else:
		sprite.scale = Vector2(1, 1)
		_shape.size = Vector2(10, 20)
		collision.position = Vector2(0, 0)
		if _bubble:
			_bubble.position = Vector2(8, -22)


func _animate(delta: float) -> void:
	sprite.flip_h = facing < 0
	var prefix := "player_small_"
	var anim := "idle"
	if attacking:
		anim = attack_kind
	elif not is_on_floor():
		anim = "jump"
	elif abs(velocity.x) > 12.0:
		walk_timer += delta
		anim = "walk1" if fmod(walk_timer, 0.16) < 0.08 else "walk2"
	else:
		walk_timer = 0.0
	var race := "white"
	if GameState.inst:
		race = GameState.inst.race
	sprite.texture = load("res://assets/sprites/%s/%s%s.png" % [race, prefix, anim]) as Texture2D
	# Plant sprite feet on the collider bottom (not in the dirt).
	sprite.offset = Vector2(0, -7) if is_big else Vector2(0, -2)
