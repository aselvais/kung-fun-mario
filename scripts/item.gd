extends CharacterBody2D
# mushroom / star / coin

const GRAVITY := 800.0
const WALK := 50.0

@export var kind := "mushroom" # mushroom, star, coin

@onready var sprite: Sprite2D = $Sprite
@onready var pickup: Area2D = $Pickup
@onready var collision: CollisionShape2D = $CollisionShape2D

var dir := 1
var _anim := 0.0
var spawned := false
var _collected := false


func _ready() -> void:
	add_to_group("items")
	pickup.body_entered.connect(_on_body)
	pickup.monitoring = false
	pickup.monitorable = false
	if kind == "coin":
		collision_layer = 0
		collision_mask = 0
		spawned = true
		pickup.monitoring = true
		_update_tex()
		return
	_update_tex()
	collision.disabled = true
	var start_y := position.y
	var tw := create_tween()
	tw.tween_property(self, "position:y", start_y - 16.0, 0.28)
	tw.tween_callback(_finish_spawn)


func _finish_spawn() -> void:
	spawned = true
	collision.set_deferred("disabled", false)
	# Let it finish popping out before it can be grabbed.
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(func ():
		if is_instance_valid(pickup):
			pickup.monitoring = true
		_try_collect()
	)


func _physics_process(delta: float) -> void:
	_anim += delta
	_update_tex()
	if kind == "coin":
		return
	if not spawned:
		return
	velocity.y += GRAVITY * delta
	if kind == "star":
		if is_on_floor():
			velocity.y = -220.0
		velocity.x = WALK * 1.4 * dir
	else:
		velocity.x = WALK * dir
	move_and_slide()
	if is_on_wall():
		dir *= -1
	if global_position.y > 16 * 16:
		queue_free()
		return
	if pickup.monitoring:
		_try_collect()


func _on_body(body: Node) -> void:
	_collect(body)


func _try_collect() -> void:
	if _collected or not spawned or pickup == null or not pickup.monitoring:
		return
	for body in pickup.get_overlapping_bodies():
		if body != null and body.is_in_group("player"):
			_collect(body)
			return


func _collect(body: Node) -> void:
	if _collected:
		return
	if body == null or not body.is_in_group("player"):
		return
	_collected = true
	match kind:
		"mushroom":
			if body.has_method("grow"):
				body.grow()
		"star":
			GameState.inst.add_score(1000)
			body.set("invincible", 6.0)
			GameState.inst.play_sfx("star")
		"shuriken":
			if body.has_method("give_shurikens"):
				body.give_shurikens()
		"coin":
			GameState.inst.add_coin()
	queue_free()


func _update_tex() -> void:
	match kind:
		"mushroom":
			sprite.texture = load("res://assets/sprites/mushroom.png")
		"star":
			sprite.texture = load("res://assets/sprites/star.png")
			sprite.modulate = Color(1, 1, 1, 1) if fmod(_anim, 0.12) < 0.06 else Color(1, 1, 0.6)
		"shuriken":
			sprite.texture = load("res://assets/sprites/shuriken.png")
			sprite.rotation = _anim * 10.0
		"coin":
			var f := int(fmod(_anim * 10.0, 4.0))
			sprite.texture = load("res://assets/sprites/coin%d.png" % f)
