extends Control

func _ready() -> void:
	get_tree().paused = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	queue_free()


func _on_settings_pressed() -> void:
	var room_container = get_parent()
	var scene = load("res://tui/settings.tscn").instantiate()
	room_container.add_child(scene)
	get_tree().paused = false
	queue_free()


func _on_exit_pressed() -> void:
	pass # Code to restart game.
