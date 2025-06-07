extends CanvasLayer

func _ready() -> void:
	$Control/Start.connect("pressed", on_Start_pressed)
	get_tree().paused = true


func on_Start_pressed():
	get_tree().paused = false
	queue_free()
