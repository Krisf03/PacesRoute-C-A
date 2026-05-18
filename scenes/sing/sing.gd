extends Node2D

var is_player_close := false

func _area_entered():
	is_player_close = true

func _area_exited():
	is_player_close = false
