extends CharacterBody2D

const PPM = 32
const SPRITE_SCALE = 7

var joystick : Area2D
var direction : Vector2
var speed = 2.0 * PPM * SPRITE_SCALE

func _ready() -> void:
	pass

func _input(_event: InputEvent) -> void:
	pass
		
func _physics_process(_delta: float) -> void:
	if joystick != null and is_instance_valid(joystick):
		direction = joystick.direction
	else:
		direction = Vector2.ZERO
	velocity = direction * speed
	move_and_slide()

func receive_joystick(j : Area2D):
	joystick = j
