extends Area2D

export(String, FILE, "*.tscn") var level

func _on_LevelComplete_body_entered(body: Node) -> void:
	print("triggered2")
	if(body.name == "Player"):
		get_tree().change_scene(level)
