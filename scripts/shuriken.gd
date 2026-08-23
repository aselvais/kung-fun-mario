extends Area2D
# thrown ninja star

const SPEED := 240.0
const LIFE := 1.35

var dir := 1
var shooter: Node
var _life := LIFE
var _hit := false


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	position.x += dir * SPEED * delta
	rotation += 18.0 * delta * dir
	_life -= delta
	if _life <= 0.0 or global_position.y > 16 * 16 or global_position.x < -32.0:
		queue_free()


func _on_body(body: Node) -> void:
	if _hit or body == shooter:
		return
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemies") and body.has_method("take_hit"):
		_hit = true
		var src: Node = shooter if shooter != null else self
		body.take_hit(src, "shuriken")
		queue_free()
		return
	_hit = true
	queue_free()
