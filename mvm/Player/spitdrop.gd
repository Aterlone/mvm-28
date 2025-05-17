extends CharacterBody2D


var GRAVITY = 750

var terminal_speed_y = 5760000

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	var delta_terminal_speed_y = terminal_speed_y * delta
	
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)
	
	move_and_slide()
	if is_on_floor() or is_on_wall() or is_on_ceiling():
		queue_free()
