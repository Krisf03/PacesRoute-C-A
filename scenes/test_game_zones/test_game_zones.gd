extends Node2D

@export_file("*.tscn") var next_scene : String
@export var is_in_ice_zone : bool
@export var is_in_fire_zone : bool
@export var is_in_earth_zone : bool
@export var is_in_water_zone : bool

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not PlayerManager.the_game_controls:
		if area.owner.is_in_group("player") and next_scene != "":
			PlayerManager.the_game_controls = true
			Transitioner.transition_to_scene(next_scene)

func _on_ice_area_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_ice_zone = true
		area.owner._animated_sprite.self_modulate = Color.AQUA

func _on_ice_area_area_exited(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_ice_zone = false
		area.owner._animated_sprite.self_modulate = Color.WHITE

func _on_fire_area_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_fire_zone = true
		area.owner._animated_sprite.self_modulate = Color.ORANGE_RED

func _on_fire_area_area_exited(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_fire_zone = false
		area.owner._animated_sprite.self_modulate = Color.WHITE

func _on_earth_area_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_earth_zone = true
		area.owner._animated_sprite.self_modulate = Color.SADDLE_BROWN

func _on_earth_area_area_exited(area: Area2D) -> void:
		is_in_earth_zone = false
		area.owner._animated_sprite.self_modulate = Color.WHITE

func _on_water_area_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		is_in_water_zone = true
		area.owner._animated_sprite.self_modulate = Color.BLUE

func _on_water_area_area_exited(area: Area2D) -> void:
		is_in_water_zone = false
		area.owner._animated_sprite.self_modulate = Color.WHITE
