extends "res://addons/custom_enemy_plugin/custom_enemy.gd"



func _ready() -> void:
	velocity = Vector2(200,0)
	health = 2
	is_walking_enemy = false
	setup()
	is_walking_enemy = false


func _process(delta: float) -> void:
	
	if state_dead or !ACTIVE:
		return
	
	# -------------------------- ANIMATION
	
	flash_sprite()
	SPRITE.scale.x = x_direction
	HITBOX.scale.x = x_direction
	
	# -------------------------- MOVE AND ATTACK
	
	hurt_player()
	
	move_and_slide()
	
	if is_on_floor() or is_on_ceiling() or is_on_wall():
		queue_free()



func on_AttackDelayT_end():  # length of pause between attacks
	pass


func on_AttackDurationT_end():  # length of attack anim.
	state_attack = false
	timer_nodes["AttackDelay"].wait_time = randf_range(1.6,2.3)
	timer_nodes["AttackDelay"].start()


func on_AttackWindUpT_end():  # length of attack wind up / telegraph
	# movement of attack goes here:
	print("yo")
	ENEMY_CONTAINER.add_child(load("res://Enemies/acorn.tscn").instantiate())
	var acorn = ENEMY_CONTAINER.get_child(ENEMY_CONTAINER.get_child_count() - 1)
	acorn.global_position = global_position
	acorn.velocity.x *= sign(scale.x)
	
	pass
