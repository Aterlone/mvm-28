extends CharacterBody3D


@onready var MAIN = get_tree().get_root().get_child(0)

var cam_locked = false # if true camera doesn't move

# controls
var joy_x = 0 # -1 = left, 1 = right
var joy_y = 0 # -1 = down, 1 = up
# button vars count up from 0 every frame once a key is pressed
var button_jump = 0

var jumping = false # is player jumping?
var jump_position = Vector3.ZERO # records position player jumped from - used in cam script
var jumps = 0 # number of times jumped

var impulse = Vector2.ZERO # used to apply a force alongside velocity such as wall jump

var GRAVITY = 80
var jump_height = 1800 
var twirl_height = jump_height / 3
var gravity_jump_quotient = 0.75 # how much gravity is lessened by when jumping

var run_speed_max = 750
var run_accel = 75
var crouch_friction = 0.3  # rate of slow down when crouched and moving in x

var wall_jump_speed_x = run_speed_max * 2
var wall_jump_speed_y = jump_height * 0.75
var wall_jump_friction = 0.4

var terminal_speed_x = 1800
var terminal_speed_y = 2880

var flag_pole = false # in flag pole mode
var flag_pole_node = null

var current_animation = ""


func _ready() -> void:
	# time of which player can still fully jump after falling off of a ledge
	$CoyoteT.connect("timeout", on_CoyoteT_timeout)
	$FallDeathT.connect("timeout", on_FallDeathT_timeout)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"): MAIN.end_level(); return
	
	if flag_pole: run_flag_pole(); return
	
	get_controls()
	movement()
	
	animate()
	
	if $EntityCollider.get_overlapping_areas().size() > 0:
		# death
		fall_to_death()
		return


func animate():
	if (joy_x != 0):
		$Sprite3D.scale.x = sign(joy_x)
	current_animation = ""
	if is_on_floor():
		if is_zero_approx(velocity.x):
			current_animation = "idle"
		else:
			current_animation = "walk"
	else:
		if $WallCollider.get_overlapping_bodies().size() > 0:
			current_animation = "wall slide"
			return
		if !$TwirlDurationT.is_stopped():
			current_animation = "twirl"
			return
		if velocity.y > 0:
			current_animation = "jump"
		else:
			current_animation = "fall"
	
	if $AnimationPlayer.has_animation(current_animation.capitalize()):
		$AnimationPlayer.play(current_animation.capitalize())


func get_controls():
	joy_y = sign(Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down"))
	joy_x = sign(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))
	
	if Input.get_action_strength("ui_up") > 0:
		button_jump += 1
	else:
		button_jump = 0


func movement_x():
	"""Handles running and crouching, impulse x"""
	var delta = get_physics_process_delta_time()
	# storing the movement x values in vars to modify when crouched and add delta
	var delta_run_speed_max = joy_x * run_speed_max * delta
	var delta_run_accel = run_accel * delta
	var delta_terminal_speed_x = terminal_speed_x * delta
	
	if joy_y == -1:
		# SMB3 style crouch - can't speed up but slide forward more
		delta_run_speed_max = 0
		delta_run_accel *= crouch_friction
	
	velocity.x = move_toward(
		velocity.x,
		delta_run_speed_max,
		delta_run_accel
		)
	
	if impulse.x != 0:
		velocity.x = impulse.x
	
	# prevent extreme speed with a speed cap
	velocity.x = clamp(velocity.x, -delta_terminal_speed_x, delta_terminal_speed_x)


func setup_movement_y():
	if is_on_floor():
		jump_position = global_position
		jumping = false
		jumps = 0
	else:
		if jumps == 0 and $CoyoteT.is_stopped():
			$CoyoteT.start()


func on_CoyoteT_timeout():
	"""Prevents player from jumping long after falling off of a ledge"""
	if jumps == 0:
		jumps = 1


func movement_y():
	"""Handles jump scripts and gravity"""
	
	# this function could be collapsed into smaller funcitons
	# however, because the script are so closely related and use the same variables
	# it seems to be clearer to just have them all together in one place, unified.
	
	var delta = get_physics_process_delta_time()
	
	# wall jump setup
	var touching_wall = ($WallCollider.get_overlapping_bodies().size() > 0)
	var wall_jump_dir = $WallCollider.scale.x
	# wall jump collider is set AFTER touching_wall to prevent frame perfect wall jump bugs.
	if joy_x != 0: $WallCollider.scale.x = joy_x
	
	setup_movement_y()
	
	# jump setup
	var can_jump = !jumping or touching_wall
	
	# jump clause
	if button_jump == 1 and can_jump:
		$JumpDurationT.start()
		if touching_wall and !is_on_floor():
			impulse.x = wall_jump_speed_x * delta * -wall_jump_dir
			velocity.y = wall_jump_speed_y * delta
			$WallCollider.scale.x *= -1
			$Sprite3D.scale.x *= -1
		else:
			jumps += 1
			if jumps == 1:
				velocity.y = jump_height * delta
			elif jumps > 1 and $TwirlDurationT.is_stopped():
				$TwirlDurationT.start()
				velocity.y = twirl_height * delta
	
	# jump follow-through
	var gravity_coef = 1
	if !$JumpDurationT.is_stopped() and button_jump > 0 and velocity.y > 0:
		if impulse.x == 0:
			# this allows the player to jump higher if the button is held down.
			# only active during regular jump and NOT wall jump
			gravity_coef = gravity_jump_quotient
	else:
		impulse.x = 0
	
	# gravity
	velocity.y -= GRAVITY * delta * gravity_coef
	
	# speed cap y
	var delta_terminal_speed_y = terminal_speed_y * delta
	if touching_wall and velocity.y < 0:
		delta_terminal_speed_y *= wall_jump_friction
	
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)


func movement():
	
	movement_x()
	movement_y()
	
	# keeps player from falling off
	global_position.z = 0.0
	# prevents getting stuck on gridmap collision shapes
	max_slides = 200
	
	move_and_slide()


func die():
	MAIN.LIVES -= 1
	if MAIN.LIVES < 0:
		MAIN.end_level()
		MAIN.LIVES = MAIN.BASE_LIVES
	else:
		MAIN.restart_level()


func on_flag_pole(new_flag_pole_node):
	"""Called by flag_pole when player is overlapping the pole collider"""
	if !flag_pole:
		flag_pole = true
		flag_pole_node = new_flag_pole_node
		global_position.x = flag_pole_node.global_position.x
		global_position.z = flag_pole_node.global_position.z
		$FlagPoleDelayT.start()


func run_flag_pole():
	"""Execute simple flag pole animation for exiting levels"""
	var slide_speed = 0.1
	var walk_speed = run_speed_max * 0.01
	if !$FlagPoleDelayT.is_stopped(): return # pause for dramatic delay
	
	
	if abs(global_position.y - flag_pole_node.global_position.y) < slide_speed * 2:
		# at bottom of pole so lock y to pole base y
		global_position.y = flag_pole_node.global_position.y
	else:
		# slide down pole
		global_position.y -= slide_speed
		return
	
	# walk off screen
	global_position.x += walk_speed * get_physics_process_delta_time()
	cam_locked = true
	
	if (global_position.x - flag_pole_node.global_position.x) > 20:
		# 20 units is off screen so close level
		MAIN.end_level()


func fall_to_death():
	# starts death timer and locks cam
	cam_locked = true
	if $FallDeathT.is_stopped():
		$FallDeathT.start()


func on_FallDeathT_timeout():
	die()

var bounce_height = 3000
func on_spring():
	"""Called by Spring when player is overlapping the bounce collider"""
	var delta = get_physics_process_delta_time()
	jumps+=1
	velocity.y = bounce_height * delta
