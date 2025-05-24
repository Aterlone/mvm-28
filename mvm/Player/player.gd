extends CharacterBody2D


@onready var MAIN = get_tree().get_root().get_child(0)

var cam_locked = false # if true camera doesn't move

# controls
var joy_x = 0 # -1 = left, 1 = right
var joy_y = 0 # -1 = down, 1 = up
# button vars count up from 0 every frame once a key is pressed
var button_jump = 0
var button_attack = 0

var x_direction = 1

var jumping = false # is player jumping?
var jump_position = Vector2.ZERO # records position player jumped from - used in cam script
var jumps = 0 # number of times jumped

var GRAVITY = 750
@export var jump_height = -20000 
var gravity_jump_quotient = 0.75 # how much gravity is lessened by when jumping

var run_speed_max = 9000
@export var run_accel = 100

var crouch_friction = 0.3  # rate of slow down when crouched and moving in x

var terminal_speed_x = 3600000
var terminal_speed_y = 5760000

var current_animation = ""

var abilities = {
	"harden" : false,
	"bubble" : false,
	"swim" : false
}

var safe_position = null

func _ready() -> void:
	var size = Vector2i(640, 360) * 2
	get_window().size = size
	get_window().move_to_center()
	set_camera_border()
	pass


func set_camera_border():
	if get_parent().get_node("RoomContainer").get_children().size() <= 0:
		return
	var tiles = get_parent().get_node("RoomContainer").get_child(0).get_node("CollisionTiles")
	var tiles_rect = tiles.get_used_rect()  # format: pos x, pos y, end x, end y
	var tiles_cell_size = tiles.tile_set.tile_size
	$Camera2D.limit_top = tiles_rect.position.y * tiles_cell_size.y
	$Camera2D.limit_bottom = tiles_rect.end.y * tiles_cell_size.y
	$Camera2D.limit_left = tiles_rect.position.x * tiles_cell_size.x
	$Camera2D.limit_right = tiles_rect.end.x * tiles_cell_size.x


func _physics_process(delta: float) -> void:
		
	get_controls()
	movement()
	
	attack()
	
	animate()


func attack():
	if button_attack == 1:
		add_sibling(load("res://Player/spitdrop.tscn").instantiate())
		var spitdrop = get_parent().get_child(get_index() + 1)
		spitdrop.global_position = global_position
		spitdrop.velocity = Vector2(
			run_speed_max * x_direction * 2,
			jump_height * 0.6
		) * get_physics_process_delta_time()


func animate():
	if (joy_x != 0):
		$Sprite2D.scale.x = sign(joy_x)
	current_animation = ""
	if joy_y == -1:
		$Sprite2D.frame = 1
		if is_on_floor():
			$Sprite2D.rotation_degrees += velocity.x * 0.05
		else:
			$Sprite2D.rotation_degrees += velocity.x * 0.02
		return
	
	$Sprite2D.frame = 0
	$Sprite2D.rotation_degrees = 0
	
	if joy_y == 1 and velocity.y > 0:
		$Sprite2D.frame = 2
		return
	
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
	if joy_x != 0:
		x_direction = joy_x
	if Input.is_key_pressed(KEY_G):
		abilities["swim"] = true
	else:
		abilities["swim"] = false
		if Input.is_key_pressed(KEY_UP):
			abilities["bubble"] = true
		else:
			abilities["bubble"] = false

		if Input.is_key_pressed(KEY_DOWN):
			abilities["harden"] = true
		else:
			abilities["harden"] = false
	
	
	if Input.get_action_strength("jump") > 0:
		button_jump += 1
	else:
		button_jump = 0
	
	if Input.get_action_strength("attack") > 0:
		button_attack += 1
	else:
		button_attack = 0


func movement_x():
	"""Handles running and crouching, impulse x"""
	var delta = get_physics_process_delta_time()
	# storing the movement x values in vars to modify when crouched and add delta
	var delta_run_speed_max = joy_x * run_speed_max * delta
	var delta_run_accel = run_accel * delta
	var delta_terminal_speed_x = terminal_speed_x * delta
	
	velocity.x = move_toward(
		velocity.x,
		delta_run_speed_max,
		delta_run_accel
		)
	
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
		$JumpDurationT.start()
		jumps += 1
		if jumps == 1:
			velocity.y = jump_height * delta
	
	# jump follow-through
	var gravity_coef = 1
	if !$JumpDurationT.is_stopped() and button_jump > 0 and velocity.y < 0:
		# this allows the player to jump higher if the button is held down.
		# only active during regular jump and NOT wall jump
		gravity_coef = gravity_jump_quotient
	
	# gravity
	velocity.y += GRAVITY * delta * gravity_coef
	
	# speed cap y
	var delta_terminal_speed_y = terminal_speed_y * delta
	
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)


func hardened():
	var delta = get_physics_process_delta_time()
	
	var speed = run_speed_max * delta
	if abs(velocity.x) > speed:
		velocity.x = speed * sign(velocity.x)
	
	
	velocity.y += GRAVITY * delta
	
	# speed cap y
	var delta_terminal_speed_y = terminal_speed_y * delta
	
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)
	
	var prev_vel = velocity
	move_and_slide()
	
	if is_on_floor() or is_on_ceiling():
		velocity.y = prev_vel.y * -0.9
	if is_on_wall():
		velocity.x = prev_vel.x * -1


func bubble():
	var delta = get_physics_process_delta_time()
	
	movement_x()
	
	velocity.y += GRAVITY * delta * 0.3
	
	# speed cap y
	var delta_terminal_speed_y = terminal_speed_y * delta
	
	velocity.y = clamp(velocity.y, jump_height * delta * 0.2, -jump_height * delta * 0.1)
	
	move_and_slide()


func water(can_swim):
	jumps = 99
	var delta = get_physics_process_delta_time()
	# storing the movement x values in vars to modify when crouched and add delta
	var delta_run_speed_max = run_speed_max * delta
	var delta_run_accel = run_accel * delta
	
	var delta_terminal_speed_x = run_speed_max * delta * 0.85
	var delta_terminal_speed_y = run_speed_max * delta * 0.85
	
	var swim_speed = 0.3
	var slow_speed = 0.1
	
	if joy_x != 0:
		delta_run_accel *= swim_speed
	else:
		delta_run_accel *= slow_speed
	
	velocity.x = move_toward(
		velocity.x,
		joy_x * delta_run_speed_max,
		delta_run_accel
		)
	
	# prevent extreme speed with a speed cap
	velocity.x = clamp(velocity.x, -delta_terminal_speed_x, delta_terminal_speed_x)
	
	delta_run_accel = run_accel * delta
	if joy_x != 0:
		delta_run_accel *= swim_speed
	else:
		delta_run_accel *= slow_speed
		
		
	velocity.y = move_toward(
		velocity.y,
		-joy_y * delta_run_speed_max,
		delta_run_accel
		)
	
	
	
	# prevent extreme speed with a speed cap
	velocity.y = clamp(velocity.y, -delta_terminal_speed_y, delta_terminal_speed_y)
	
	
	move_and_slide()
	
	if button_jump != 0 or !can_swim:
		velocity.y -= GRAVITY * delta
		if button_jump != 0:
			if $ExitWaterDetector.get_overlapping_areas().size() == 0:
				velocity.y = jump_height * 0.85 * delta


func movement():
	print(abilities)
	if $WaterDetector.get_overlapping_areas().size() > 0:
		water(abilities["swim"])
		return
	
	if joy_y == -1 and abilities["harden"]:
		hardened()
	elif joy_y == 1 and velocity.y > 0 and abilities["bubble"]:
		bubble()
	else:
		movement_x()
		movement_y()
		move_and_slide()


func die():
	pass


func _on_warp_detector_area_entered(area: Area2D) -> void:
	if $WarpDelayT.is_stopped():
		MAIN.warp(area)


func _on_damage_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("DangerReturn"):
		safe_position = area.global_position + 0.5 * Vector2(0,area.get_child(0).shape.size.y - $MainCollider.shape.size.y)
	else:
		if safe_position != null:
			global_position = safe_position
	
