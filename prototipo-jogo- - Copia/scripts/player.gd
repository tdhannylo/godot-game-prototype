extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	fall,
	dash,
	hurt
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed = 200
@export var acceleration = 500
@export var deceleration = 1000
@export var slide_deceleration = 67
const JUMP_VELOCITY = -400.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState
var dead := false

@export var dash_speed = 400.0
@export var dash_duration = 0.15

var is_dashing := false
var dash_time := 0.0

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if dead:
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.dash:
			dash_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
	
	move_and_slide()
	check_tile_hazard()

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_dash_state():
	status = PlayerState.dash
	is_dashing = true
	dash_time = 0.0
	
	if direction == 0:
		direction = -1 if anim.flip_h else 1
	
	velocity.x = direction * dash_speed
	velocity.y = 0

func go_to_hurt_state():
	if dead:
		return
	status = PlayerState.hurt
	dead = true
	anim.play("hurt")
	velocity = Vector2.ZERO
	set_physics_process(false)
	reload_timer.wait_time = 1.2
	reload_timer.start()

func die() -> void:
	if dead:
		return
	go_to_hurt_state()

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return

func jump_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()

func fall_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return

func dash_state(delta):
	dash_time += delta

	if dash_time >= dash_duration:
		dash_time = 0.0
		is_dashing = false
		go_to_fall_state()

func hurt_state(_delta):
	pass

func move(delta):
	update_direction()
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		

func update_direction():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false
		

func can_jump() -> bool:
	return jump_count < max_jump_count

func check_tile_hazard() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer and collider.is_in_group("hazards"):
			var tilemap = collider
			
			var collision_position = collision.get_position()
			var coordinates = tilemap.local_to_map(
				tilemap.to_local(collision_position)
			)
			
			var tile_data = tilemap.get_cell_tile_data(coordinates)
			
			if tile_data and tile_data.get_custom_data("danger"):
				die()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if dead:
		return
	if velocity.y > 0:
		#inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		if status != PlayerState.hurt:
			go_to_hurt_state()


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
