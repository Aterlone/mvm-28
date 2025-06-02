extends "res://addons/custom_enemy_plugin/custom_enemy.gd"


var anim_state_to_name = {
	"IDLE" : "Idle",
	"IDLEWALK" : "Run",
	"FOLLOW" : "Run",
	"WINDUP" : "Attack",
	"ATTACK" : null,
	"HURT" : "Hurt",
	"FALL" : null,
	"DIE" : "Hurt"
}


func _ready() -> void:
	health = 2
	is_walking_enemy = false
	setup()


func _process(delta: float) -> void:
	
	if state_dead or !ACTIVE:
		return
	
	# -------------------------- ANIMATION
	
	#animate()
	#var anim_name = anim_state_to_name[str(animation_states.keys()[animation_state])]
	#if anim_name != null:
		#$AnimationPlayer.play(anim_name)
	
	flash_sprite()
	SPRITE.scale.x = x_direction
	HITBOX.scale.x = x_direction
	
	# -------------------------- MOVE AND ATTACK
	
	hurt_player()
	
	if state_attack:
		#run_attack()
		return
	
	detect_player()
	
	if timer_nodes["AttackDelay"].is_stopped():  # only attack after delay
		init_attack()
		#return
	
	
	#if !state_hurt:
		#if timer_nodes["Follow"].time_left == 0: 
			## enemy is idle when player cannot be found
			#idle()
		#else: 
			## enemy follows and attacks when player is found
			#follow()
			#
	#else:
		#velocity.x = 0
	
	# -------------------------- PHYSICS
	
	# gravity , terminal velocity clamp, move_and_slide, animate
	var current_velocity = velocity
	
	run_physics()
	
	# -- WALK ADDEN.
	
	if current_velocity.x != 0 and velocity.x == 0 and walking:
		x_direction *= -1
		velocity.x = current_velocity.x * -1


func idle():
	idle_walk()


func follow():
	# trail player & position for attacks
	x_direction = sign(PLAYER.global_position.x - PLAYER_DETECTOR.global_position.x)
	velocity.x = follow_speed * x_direction 
	if PLAYER.velocity.x != 0:
		velocity.x *= 1 - clamp(
			abs((global_position.y - PLAYER.global_position.y) / 64),
			0,
			0.5
			)


func init_attack():
	velocity = Vector2.ZERO
	state_attack = true
	
	timer_nodes["AttackWindUp"].start()
	timer_nodes["AttackDuration"].start()


#func run_attack():
	#if !timer_nodes["AttackWindUp"].is_stopped():
		## winding up
	#else:
		## attacking


func on_AttackDelayT_end():  # length of pause between attacks
	pass


func on_AttackDurationT_end():  # length of attack anim.
	state_attack = false
	timer_nodes["AttackDelay"].wait_time = randf_range(1.6,2.3)
	timer_nodes["AttackDelay"].start()


func on_AttackWindUpT_end():  # length of attack wind up / telegraph
	# movement of attack goes here:
	ENEMY_CONTAINER.add_child(load("res://Enemies/acorn.tscn").instantiate())
	var acorn = ENEMY_CONTAINER.get_child(ENEMY_CONTAINER.get_child_count() - 1)
	acorn.global_position = global_position
	acorn.velocity.x *= sign(scale.x)
	
	pass
