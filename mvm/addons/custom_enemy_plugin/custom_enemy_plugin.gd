@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("Enemy Class", "CharacterBody2D", preload("res://addons/custom_enemy_plugin/custom_enemy.gd"), preload("res://addons/custom_enemy_plugin/enemysymbol.png"))


func _exit_tree() -> void:
	remove_custom_type("Enemy Class")
