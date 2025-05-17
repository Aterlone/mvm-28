extends CharacterBody2D


@onready var MAIN = get_tree().get_root().get_child(0)

var cam_locked = false # if true camera doesn't move

# controls
var joy_x = 0 # -1 = left, 1 = right
var joy_y = 0 # -1 = down, 1 = up
# button vars count up from 0 every frame once a key is pressed
var button_jump = 0

var jumping = false # is player jumping?
var jump_position = Vector2.ZERO # records position player jumped from - used in cam script
var jumps = 0 # number of times jumped

var impulse = Vector2.ZERO # used to apply a force alongside velocity such as wall jump

var GRAVITY = -750
var jump_height = -20000 
var gravity_jump_quotient = 0.75 # how much gravity is lessened by when jumping

var run_speed_max = 9000
var run_accel = 150000
var crouch_friction = 0.3  # rate of slow down when crouched and moving in x

var terminal_speed_x = 3600000
var terminal_speed_y = 5760000

var current_animation = ""


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"): MAIN.end_level(); return
		
	get_controls()
	movement()
	
	animate()


func animate():
	if (joy_x != 0):
		$Sprite2D.scale.x = sign(joy_x)
	current_animation = ""
	if is_on_floor():
		if is_zero_approx(velocity.x):
			current_animation = "idle"
		else:
			current_animation = "walk"
	else:
		if velocity.y > 0:
			current_animation = "jump"
		else:
			current_animation = "fall"
	
	#if $AnimationPlayer.has_animation(current_animation.capitalize()):
		#$AnimationPlayer.play(current_animation.capitalize())


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
	
	setup_movement_y()
	
	# jump setup
	var can_jump = !jumping
	
	# jump clause
	if button_jump == 1 and can_jump:
		#$JumpDurationT.start()
		jumps += 1
		if jumps == 1:
			velocity.y = jump_height * delta
	
	# jump follow-through
	var gravity_coef = 1

	
	# gravity
	velocity.y -= GRAVITY * delta * gravity_coef
	
	# speed cap y
	var delta_terminal_speed_y = terminal_speed_y * delta
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)


func movement():
	
	movement_x()
	movement_y()
	
	# keeps player from falling off
	# prevents getting stuck on gridmap collision shapes
	max_slides = 200
	
	move_and_slide()


func die():
	pass
