extends CharacterBody2D

const PPM = 32
const SPRITE_SCALE = 1

var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE
var left_limit := 30
var right_limit := 450

@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	direction = Vector2(1, 0)
	
func _physics_process(delta: float) -> void:
	if position.x < left_limit:
		direction = Vector2(1, 0)
	if position.x > right_limit:
		direction = Vector2(-1, 0)
	velocity = direction * speed
	move_and_slide()
	_calculate_flip_h()
	_animation_run()

func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0
		
func _animation_run():
	if velocity != Vector2.ZERO:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
