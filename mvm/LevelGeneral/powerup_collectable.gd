extends Area2D

@export_enum (
	"harden",
	"bubble",
	"swim"
) var powerup_type : String


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().name == "Player":
		area.get_parent().update_powerups(powerup_type)
		queue_free()
