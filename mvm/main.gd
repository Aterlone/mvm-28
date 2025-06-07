extends Node2D

@onready var PLAYER = get_node("Player")

func warp(warp_node):
	var next_room = str(warp_node.room_number)
	var next_area = warp_node.room_name
	var direction = warp_node.direction
	var room_char = warp_node.room_char
	
	for child in $RoomContainer.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var new_level_file = "res://Levels/" + next_area.capitalize() + "/" + (next_area + next_room).to_snake_case() + ".tscn" 
	
	
	var new_level = load(new_level_file)
	
	$RoomContainer.add_child(new_level.instantiate())
	
	var new_warp = $RoomContainer.get_child(1).get_node("WarpZones").get_node("Warp" + room_char.capitalize())
	
	PLAYER.global_position = new_warp.global_position
	PLAYER.get_node("Camera2D").reset_smoothing()
	PLAYER.get_node("WarpDelayT").start()
	PLAYER.set_camera_border()
	
	PLAYER.safe_position = null
	
	if direction == "up":
		PLAYER.velocity.y = PLAYER.jump_height * get_physics_process_delta_time()
