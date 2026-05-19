extends Node2D

var is_player_close := false

func _area_entered(_area):
	is_player_close = true

func _area_exited(_area):
	is_player_close = false
