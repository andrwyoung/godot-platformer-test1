extends Node

func _ready() -> void:
	var scene = load("res://Player.tscn")
	var player = scene.instance()
	add_child(player)
