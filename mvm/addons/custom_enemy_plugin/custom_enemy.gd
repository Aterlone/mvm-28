@tool
extends CharacterBody2D

var MAIN = null
var LEVEL = null
var ENEMY_CONTAINER = null
var PLAYER = null

# nodes added in new class scene
var SPRITE = null
var PLAYER_DETECTOR = null
var FLOOR_FINDER = null
var HITBOX = null
var HURTBOX = null
var ALERT_BOX = null

var money_min = 0;	var money_max = 10

var timer_nodes = {
	"Flash" : null,
	"Follow" : null,
	"AttackDuration" : null,
	"AttackWindUp" : null,
	"AttackDelay" : null,
	"Hurt" : null,
	"Walk" : null,
	"Turn" : null
}

var state_attack = false
var state_hurt = false
var state_dead = false

var ACTIVE = true
var boss = false  # boss overides some enemy functions (walking, enemy_container deletion)

var GRAVITY = 500
var TERMINAL_VELOCITY = 400

var movement_velocity = Vector2.ZERO  # this is the force of the enemy in any direction

var follow_time = 5
var hurt_time = 0.1
var attack_delay_time = 1.0
var attack_windup_time = 0.6
var attack_duration_time = 1.5

var default_health = 3
var health = default_health

var x_direction = 1

var last_line_of_sight = []  # records all objects detected by PLAYER_DETECTOR 

var is_walking_enemy = true  # determines if the enemy actually walks at all
var walking = false
var walk_speed = 40
var follow_speed = 65


var knockback_vector = Vector2.ZERO
var knockback_friction = 0.8  # how much knockback decreases to per frame
var knockback_mass = 1  # determines how much oomf knockback deals

enum animation_states {
	IDLE,
	IDLEWALK,
	FOLLOW,
	WINDUP,
	ATTACK,
	HURT,
	FALL,
	DIE
}

var animation_state = animation_states.IDLE

func animate():
	if state_dead:
		animation_state = animation_states.DIE
		return
	
	if state_attack:
		if timer_nodes["AttackWindUp"].time_left > 0:
			animation_state = animation_states.WINDUP
		elif timer_nodes["AttackDuration"].time_left > 0:
			animation_state = animation_states.ATTACK
		return
	
	if !is_on_floor():
		animation_state = animation_states.FALL
		return
	
	if timer_nodes["Hurt"].time_left > 0:
		animation_state = animation_states.HURT
		return
	
	if timer_nodes["Follow"].time_left <= 0:
		animation_state = animation_states.IDLEWALK
	else:
		animation_state = animation_states.FOLLOW
	
	if is_zero_approx(velocity.x):
		animation_state = animation_states.IDLE
		return


func _enter_tree() -> void:
	pass


func setup() -> void:
	set_collision_mask_value(16, true)
	add_to_group("Enemies")
	MAIN = get_tree().get_root().get_child(0)
	LEVEL = MAIN.get_node("RoomContainer").get_child(0)
	PLAYER = MAIN.get_node("Player")
	
	ENEMY_CONTAINER = get_parent()
	if ENEMY_CONTAINER.name != "EnemyContainer" and !boss:
		print(str(name) + " in level " + str(LEVEL) + "not in enemy container")
		queue_free()
	
	SPRITE = get_node("Sprite2D")
	
	PLAYER_DETECTOR = get_node("PlayerDetector")
	FLOOR_FINDER = get_node("FloorFinder")
	HITBOX = get_node("HitBox")
	HURTBOX = get_node("HurtBox")
	
	# create nodes
	for node in timer_nodes.keys():
		add_child(Timer.new())
		timer_nodes[node] = get_last_child()
		timer_nodes[node].name = str(node) + "T"
		timer_nodes[node].one_shot = true
		if "Attack" in node or "Walk" in node or "Hurt" in node:
			timer_nodes[node].connect("timeout", Callable(self, "on_" + str(node) + "T_end"))
	
	# setup nodes
		# these timers don't really change
	timer_nodes["Flash"].wait_time = 0.2
	timer_nodes["Turn"].wait_time = 0.1
		# these ones do hence assigned variables
	timer_nodes["Hurt"].wait_time = hurt_time
	timer_nodes["Follow"].wait_time = follow_time
	timer_nodes["AttackDelay"].wait_time = attack_delay_time
	timer_nodes["AttackWindUp"].wait_time = attack_windup_time
	timer_nodes["AttackDuration"].wait_time = attack_duration_time
	
	
	if is_walking_enemy:
		setup_walk()
	# testing
	add_child(Label.new())
	get_last_child().name = "Label"
	get_last_child().position.y -= 32


func get_last_child():
	return get_child(get_child_count() - 1)

""" BASE ATTACK SCRIPTS 
func on_AttackDelayT_end():  # length of pause between attacks
	pass


func on_AttackDurationT_end():  # length of attack anim.
	state_attack = false
	timer_nodes["AttackDelay"].wait_time = randf_range(1.6,2.3)
	timer_nodes["AttackDelay"].start()


func on_AttackWindUpT_end():  # length of attack wind up / telegraph
	# movement of attack goes here:
	pass
"""


func environmental_death():
	if $HurtBox.get_overlapping_areas().size() > 0:
		for area in $HurtBox.get_overlapping_areas():
			if area.is_in_group("EnvironmentalDanger"):
				die()


func run_physics():
	velocity.y += GRAVITY * get_physics_process_delta_time()
	velocity.x += knockback_vector.x
	if is_on_floor():
		knockback_vector.x *= knockback_friction
	
	set_velocity(velocity)
	set_up_direction(Vector2.UP)
	move_and_slide()
	velocity = velocity


func hurt_player():
	if HITBOX.get_overlapping_areas().size() > 0:
		for area in HITBOX.get_overlapping_areas():
			if area.get_parent().name == "Player":
				area.get_parent().hurt(self, 1)


func non_player_hurt(damage, node):
	"""Called by non player objects that have dealt damage i.e cinderbombs"""
	if node.name != "FireBomb":
		return
	var knockback_coef = 256 #replace with node.knockback_coef
	
	state_hurt = true
	state_attack = false
	timer_nodes["Flash"].start()
	timer_nodes["Hurt"].start()
	
	knockback_vector.x = sign(node.velocity.x)
	knockback_vector.y = sign(node.velocity.y)
	knockback_vector.normalized()
	
	var knockback_force = knockback_coef * (6 - int(knockback_mass)) / 6 + 100
	
	knockback_vector.x *= knockback_force * get_physics_process_delta_time() * 60 
	knockback_vector.y *= knockback_force * get_physics_process_delta_time() * 60
	
	velocity.y += -125 * get_physics_process_delta_time() * 60
	
	# knockback = -direction * knockback * knockback_coef * delta
	health -= damage  # subject to change for player damage upgrades.
	
	if health <= 0:
		die()


func hurt(damage):
	"""This is when the enemy is hurt by the player."""
	add_spark_particles()
	# hurt anim / sound / part.
	state_hurt = true
	timer_nodes["Flash"].start()
	timer_nodes["Hurt"].start()
	
	#if PLAYER.joy_y == 1:
		#knockback_vector.x = PLAYER.joy_x
	#else:
		#knockback_vector.x = PLAYER.x_direction
	#knockback_vector.y = -PLAYER.joy_y
	#knockback_vector.normalized()
	#
	#var knockback_force = PLAYER.knockback_coef * (6 - int(knockback_mass)) / 6 + 100
	#
	#knockback_vector.x *= knockback_force * get_physics_process_delta_time() * 60 
	#knockback_vector.y *= knockback_force * get_physics_process_delta_time() * 60
	
	#velocity.y += knockback_vector.y 
	
	# knockback = -direction * knockback * knockback_coef * delta
	health -= damage  # subject to change for player damage upgrades.
	
	if health <= 0 and !boss:
		die()


func on_HurtT_end():
	state_hurt = false


func get_jump_velocity_to_target(target_position, speed_y):
	velocity.x = (target_position.x - global_position.x)
	x_direction = sign(velocity.x)
	var y_speed = abs(speed_y)
	y_speed *= clamp((target_position.y / global_position.y), 0.8, 1.1)
	velocity.y = -y_speed
	var airtime = 2 * (y_speed / GRAVITY) * get_physics_process_delta_time() * 60
	velocity.x /= airtime


func flash_sprite():
	if SPRITE == null or timer_nodes["Flash"] == null:
		return
	if timer_nodes["Flash"].time_left > 0:
		SPRITE.material.set_shader_parameter("flashState", timer_nodes["Flash"].time_left * 10)
	else:
		SPRITE.material.set_shader_parameter("flashState", 0)


func spawn_explosion(spawn_position):
	pass
	#ENEMY_CONTAINER.add_child(explosion_file.instantiate())
	#ENEMY_CONTAINER.get_child(ENEMY_CONTAINER.get_child_count() - 1).global_position = spawn_position


func add_spark_particles():
	pass
	#ENEMY_CONTAINER.add_child(particles_spark.instantiate())
	#var particle = ENEMY_CONTAINER.get_child(ENEMY_CONTAINER.get_child_count() - 1)
	#particle.global_position = global_position
	#particle.look_at(PLAYER.global_position)
	#particle.rotation -= PI


func die():
	#spawn_explosion(global_position)
	queue_free()


func detect_player():
	pass
	# area2d finds player given PLAYER_DETECTOR region
	
	#PLAYER_DETECTOR.scale.x = x_direction
	#if PLAYER_DETECTOR.get_overlapping_areas().size() > 0:
		#timer_nodes["Follow"].start()
		#x_direction = sign(PLAYER.global_position.x - PLAYER_DETECTOR.global_position.x)


func setup_walk():
	timer_nodes["Walk"].start()
	walking = true
	velocity.x = walk_speed * x_direction


func idle_walk():
	FLOOR_FINDER.scale.x = x_direction
	if walking:
		velocity.x = walk_speed * x_direction
	else:
		velocity.x = 0
	if FLOOR_FINDER.get_overlapping_bodies().size() <= 0:
		if timer_nodes["Turn"].time_left <= 0:
			x_direction *= -1
			velocity.x = walk_speed * x_direction
			timer_nodes["Turn"].start()


func on_WalkT_end():
	timer_nodes["Walk"].wait_time = randf_range(1,3)
	timer_nodes["Walk"].start()
	if timer_nodes["Follow"].time_left != 0:
		return
	walking = !walking
	if walking:
		if randf_range(0.0,1.0) < 0.5:
			x_direction = -1
		else:
			x_direction = 1
		velocity.x = 65 * x_direction
	else:
		velocity.x = 0


""" BASE PROCESS SCRIPT 
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

func _process(delta: float) -> void:
	
	if state_dead or !ACTIVE:
		return
	
	# -------------------------- ANIMATION
	
	animate()
	var anim_name = anim_state_to_name[str(animation_states.keys()[animation_state])]
	if anim_name != null:
		$AnimationPlayer.play(anim_name)
	
	flash_sprite()
	SPRITE.scale.x = x_direction
	HITBOX.scale.x = x_direction
	
	# -------------------------- MOVE AND ATTACK
	
	hurt_player()
	
	if state_attack:
		run_attack()
		return
	
	detect_player()
	
	
	if !state_hurt:
		if timer_nodes["Follow"].time_left == 0: 
			# enemy is idle when player cannot be found
			idle()
		else: 
			# enemy follows and attacks when player is found
			follow()
			if timer_nodes["AttackDelay"].is_stopped():  # only attack after delay
				init_attack()
				return
	else:
		velocity.x = 0
	
	# -------------------------- PHYSICS
	
	# gravity , terminal velocity clamp, move_and_slide, animate
	var current_velocity = velocity
	
	run_physics()
	
	# -- WALK ADDEN.
	
	if current_velocity.x != 0 and velocity.x == 0 and walking:
		x_direction *= -1
		velocity.x = current_velocity.x * -1
"""

""" BASE IDLE
func idle():
	idle_walk()
"""

""" BASE FOLLOW
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
"""

"""
func init_attack():
	velocity = Vector2.ZERO
	state_attack = true
	
	timer_nodes["AttackWindUp"].start()
	timer_nodes["AttackDuration"].start()
"""

"""
func run_attack():
	if !timer_nodes["AttackWindUp"].is_stopped():
		# winding up
	else:
		# attacking
"""
