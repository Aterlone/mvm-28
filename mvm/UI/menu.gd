extends CanvasLayer


@onready var MAIN = get_tree().get_root().get_child(0)

var ACTIVE = false


func _ready() -> void:
	set_visibility("Buttons")
	$Control/Buttons/Resume.connect("pressed", on_Resume_pressed)
	$Control/Buttons/Settings.connect("pressed", on_Settings_pressed)
	$Control/Buttons/Exit.connect("pressed", on_Exit_pressed)
	
	$Control/Settings/Return.connect("pressed", on_Return_pressed)
	$Control/Settings/Fullscreen.connect("pressed", on_Fullscreen_pressed)


func _process(delta: float) -> void:
	if MAIN.has_node("Title"):
		visible = false
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		ACTIVE = !ACTIVE
		if ACTIVE:
			set_visibility("Buttons")
	
	get_tree().paused = ACTIVE
	visible = ACTIVE


func on_Return_pressed():
	set_visibility("Buttons")


func on_Fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_window().move_to_center()


func on_Resume_pressed():
	ACTIVE = false


func on_Settings_pressed():
	set_visibility("Settings")


func on_Exit_pressed():
	get_tree().quit()


func set_visibility(tab):
	$Control/Buttons.visible = (tab == "Buttons")
	$Control/Settings.visible = (tab == "Settings")


func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		clamp(linear_to_db(value), -1000, 1000)
	)
	$Control/Settings/Music.text = "MUSIC: " + str(round(value * 100))


func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		clamp(linear_to_db(value), -1000, 1000)
	)
	$Control/Settings/SFX.text = "SFX: " + str(round(value * 100))
