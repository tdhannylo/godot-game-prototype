extends TileMapLayer

@export var rise_speed: float = 75.0

func _process(delta: float) -> void:
	position.y -= rise_speed * delta

func _on_hazard_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
