extends StaticBody2D

var health = 2
var is_dead = false

const  IA_FIRST_MET_DIALOGUE = preload("res://dialogues/ia_first_met.dialogue")

func _take_damage(amount: int, _source_position: Vector2):
	#print("recibí daño: ", amount)
	health -= amount
	#print("Vida actual: ", health)
	if health <= 0:
		_die()

func  _die():
	is_dead = true
	#print("ME MORÍ")
	await  get_tree().create_timer(1).timeout
	if not is_inside_tree():
		return
	queue_free()

func _input(event: InputEvent) -> void:
	if GameManager.is_near_manikin:
		if event.is_action_pressed("interact"):
			DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "manikin")

func _on_interact_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		GameManager.is_near_manikin = true


func _on_interact_area_2d_area_exited(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		GameManager.is_near_manikin = false
