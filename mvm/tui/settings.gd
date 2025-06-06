extends Control

func _on_ready() -> void:
	get_tree().paused = false
	print(get_tree().paused)

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)
