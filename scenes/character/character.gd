extends CharacterBody2D

#Constantes de velocidad según la escala del personaje
const PPM = 32
const SPRITE_SCALE = 2

#variables para el movimiento 
var joystick : Area2D
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE

#variable para la animación 
@export var animated_sprite : AnimatedSprite2D

#variable para detectar objetos interactuables con raycast
@export var interact : RayCast2D

func _ready() -> void:
	pass

#función para el movimiento del personaje 
func _physics_process(_delta: float) -> void:
	#diferencia entre dirección de joystick y dirección del teclado 
	var joystick_direction = Vector2.ZERO
	#calcula el input del teclado directamente en su variable
	var keyboard_direction = Input.get_vector(
			"ui_left",
			"ui_right",
			"ui_up",
			"ui_down"
		)

	#calcula la dirección del joystick y lo mete en su variable 
	if joystick != null and is_instance_valid(joystick):
		joystick_direction = joystick.direction

	#suma las variables, para que no decidir una u otra, y se normaliza para evitar velocidades exageradas
	direction = joystick_direction + keyboard_direction
	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	_calculate_flip_h()

	_animation_run()

#para que mire en la dirección correcta 
func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0
		
#para que la animación funcione en cada frame
func _animation_run():
	if velocity != Vector2.ZERO:
		animated_sprite.play("Walk")
		animated_sprite.position.y =+ 6.5
	else:
		animated_sprite.play("idle")
		animated_sprite.position.y =- 6.5

func receive_joystick(j: Area2D) -> void:
	joystick = j
