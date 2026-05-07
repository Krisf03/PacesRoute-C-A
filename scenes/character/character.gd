extends CharacterBody2D

const PPM = 32
const SPRITE_SCALE = 7

var joystick : Area2D
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE
var keyboard_side = Input.get_axis("ui_left", "ui_right")
var keyboard_front = Input.get_axis("ui_up", "ui_down")

@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	pass

func _input(_event: InputEvent) -> void:
	pass
		
func _physics_process(_delta: float) -> void:
	if keyboard_front != null:
		direction.y = keyboard_front
	elif  keyboard_side != null:
		direction.x = keyboard_side
	
	if joystick != null and is_instance_valid(joystick):
		direction = joystick.direction
	else:
		direction = Vector2.ZERO
	
	
	velocity = direction * speed
	move_and_slide()
	
	_calculate_flip_h()
	
	_animation_run()
		
func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0
		
func _animation_run():
	if velocity != Vector2.ZERO:
		animated_sprite.play("Walk")
		animated_sprite.position.y =+ 32
	else:
		animated_sprite.play("idle")
		animated_sprite.position.y =- 32

func receive_joystick(j : Area2D):
	joystick = j
