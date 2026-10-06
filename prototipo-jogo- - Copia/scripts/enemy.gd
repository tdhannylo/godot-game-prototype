extends CharacterBody2D

@export var patrol_speed: float = 55.0
@export var patrol_distance: float = 140.0

var direction := -1.0
var start_x := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	velocity.y += get_gravity().y * delta
	velocity.x = direction * patrol_speed
	move_and_slide()

	var reached_patrol_edge := (
		(direction < 0.0 and global_position.x <= start_x - patrol_distance)
		or (direction > 0.0 and global_position.x >= start_x + patrol_distance)
	)
	if is_on_wall() or reached_patrol_edge:
		direction *= -1.0
	_update_facing()

func _update_facing() -> void:
	sprite.flip_h = direction > 0.0

func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
