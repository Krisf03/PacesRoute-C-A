extends Area2D

#Variables para acceder a los nodos hijos y sus propiedades

@onready var var_range = $Range
@onready var button = $Button
@onready var radius = $CollisionShape2D.shape.radius

func _ready() -> void: 
	pass 
	
	
#Funcion para manejar los inputs del teclado con el touch

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch: #Verifica si se presiona o se suelta el touch
		if event.is_pressed(): #Verifica que el input del touch sea cuando se presiona
			if global_position.distance_to(event.position) < radius: #Si el toque fue dentro de la zona del joystick
				button.global_position = event.position #Tepea el centro del joystick al lugar del toque
			
		else: #Se ejecuta si el input es al soltar el touch
			pass
	if event is InputEventScreenDrag: #Verifica si se arrastra el touch
		pass
		
	
