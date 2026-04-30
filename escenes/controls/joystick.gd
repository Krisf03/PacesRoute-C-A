extends Area2D

class_name Joystick

#Variables para calcular distancia y dirección del toque más adelante

var distance:float
var direction:Vector2

var index = -1 #Variable para definir cuantos dedos pueden usar el joystick

#Variables @onready para acceder a los nodos hijos y sus propiedade

@onready var var_range = $Range
@onready var button = $Button
@onready var radius = $CollisionShape2D.shape.radius

func _ready() -> void: 
	pass
	
#Funcion para manejar los inputs del teclado con el touch

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch: #Verifica si se presiona o se suelta el touch
		if event.is_pressed() and index == -1: #Verifica que el input del touch sea cuando se presiona
			distance = global_position.distance_to(event.position)
			if distance <= radius: #Si el toque fue dentro de la zona del joystick
				index = event.index
				button.global_position = event.position #Tepea el centro del joystick al lugar del toque
				direction = global_position.direction_to(button.global_position) * distance / radius #calcula qué tan lejos está el touch del centro y en qué dirección 
			elif event.index == index: #si se acaba de soltar
				index = -1
				button.position = Vector2.ZERO
				direction = Vector2.ZERO
				
		else: #Se ejecuta si el input es al soltar el touch
			button.position = Vector2.ZERO
			direction = Vector2.ZERO
			
	if event is InputEventScreenDrag: #Verifica si se arrastra el touch
		if index == event.index:
			distance = global_position.distance_to(event.position)
			if distance <= radius:
				button.global_position = event.position
				direction = global_position.direction_to(button.global_position) * distance / radius #calcula qué tan lejos está el touch del centro y en qué dirección 
			else:
				direction = global_position.direction_to(event.position)
				button.position = direction * radius
