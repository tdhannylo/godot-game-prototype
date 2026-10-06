extends CharacterBody2D

@export var patrol_speed: float = 55.0
@export var patrol_distance: float = 140.0

@export var fly_height: float = 15.0
@export var fly_speed: float = 3.0

var direction := 1.0
var start_x := 0.0
var start_y := 0.0
var fly_time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x
	start_y = global_position.y
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	fly_time += delta
	
	_patrol()
	_fly()
	_update_facing()


func _patrol() -> void:
	velocity.x = direction * patrol_speed
	global_position.x += velocity.x * get_physics_process_delta_time()

	var reached_patrol_edge := (
		(direction < 0.0 and global_position.x <= start_x - patrol_distance)
		or (direction > 0.0 and global_position.x >= start_x + patrol_distance)
	)

	if reached_patrol_edge:
		direction *= -1.0


func _fly() -> void:
	global_position.y = start_y + sin(fly_time * fly_speed) * fly_height


func _update_facing() -> void:
	sprite.flip_h = direction < 0.0


func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
