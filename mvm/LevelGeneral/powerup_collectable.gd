extends Area2D

@onready var PLAYER = get_tree().get_root().get_node("Main/Player")

@export_enum (
	"harden",
	"bubble",
	"swim",
	"key1",
	"key2",
	"key3"
) var powerup_type : String

var colors = {
	"harden" : Color.RED,
	"bubble" : Color.BLUE,
	"swim" : Color.GREEN,
	"key1" : Color.RED,
	"key2" : Color.BLUE,
	"key3" : Color.GREEN
}


func _physics_process(delta: float) -> void:
	if powerup_type == null:
		return
	$Gem.modulate = colors[powerup_type]
	$PowerupAnimation/Gem.modulate = colors[powerup_type]


func play_anim():
	$Gem.visible = false
	get_tree().paused = true
	
	PLAYER.global_position = global_position
	PLAYER.visible = false
	
	$PowerupAnimation/AnimationPlayer.play("PowerupHarden")
	await $PowerupAnimation/AnimationPlayer.animation_finished
	
	PLAYER.global_position = $PowerupAnimation.global_position
	PLAYER.visible = true
	
	get_tree().paused = false
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	
	
	if area.get_parent().name == "Player":
		area.get_parent().update_powerups(powerup_type)
	
	play_anim()
