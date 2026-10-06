extends Area2D

@export var next_level = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		call_deferred("load_next_scene")


func load_next_scene():
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
