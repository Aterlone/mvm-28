extends Area2D

func _ready() -> void:
	if $WaterCollider.shape != null:
		$WaterSprite.size = $WaterCollider.shape.size
		$WaterSprite.global_position = $WaterCollider.global_position - $WaterCollider.shape.size / 2
