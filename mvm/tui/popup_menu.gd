extends MarginContainer

@export var start_screen: VBoxContainer
@export var menu_screen: VBoxContainer
@export var settings_screen: VBoxContainer

func _ready() -> void:
	toggle_visibility(menu_screen)
	toggle_visibility(settings_screen)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("settings"):
		if !start_screen.visible && !settings_screen.visible:
			toggle_visibility(menu_screen)
		

func toggle_visibility(object):
	if object.visible:
		object.visible = false
	else:
		object.visible = true

# start menu settings
func _on_start_pressed() -> void:
	toggle_visibility(start_screen)

# base menu settings
func _on_resume_pressed() -> void:
	toggle_visibility(menu_screen)

func _on_settings_pressed() -> void:
	toggle_visibility(menu_screen)
	toggle_visibility(settings_screen)

func _on_exit_pressed() -> void:
	toggle_visibility(menu_screen)

# settings menu settings
func _on_back_pressed() -> void:
	toggle_visibility(menu_screen)
	toggle_visibility(settings_screen)
