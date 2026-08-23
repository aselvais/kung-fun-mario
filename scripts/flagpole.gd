extends Area2D
# goal pole

@onready var flag: Sprite2D = $Flag

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	GameState.inst.add_score(2000)
	GameState.inst.play_sfx("flag")
	if body.has_method("start_clear"):
		body.start_clear()
	# Slide down onto the grass (tile row 13), not past it underground.
	var feet := 10.0
	if body.has_method("foot_bottom"):
		feet = body.foot_bottom()
	var stand_y := 13.0 * 16.0 - feet
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(flag, "position:y", 13 * 16 - 24, 0.9)
	tw.tween_property(body, "global_position:y", stand_y, 0.9)
	tw.chain().tween_callback(func ():
		if body.has_method("walk_to_castle"):
			body.walk_to_castle(global_position.x + 16 * 5)
	)
