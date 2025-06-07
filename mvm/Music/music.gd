extends Node


var music_on = false

var blacklist = [
	"central_10"
]


func fade_music(fade_time):
	$FadeT.wait_time = fade_time
	$FadeT.start()
	if !$MusicPlayer.playing:
		$MusicPlayer.play()


func update(new_area, new_room):
	var file_name = (new_area + new_room).to_snake_case()
	if !(file_name in blacklist):
		if !music_on:
			music_on = true
			fade_music(10.0)
	else:
		if music_on:
			music_on = false
			fade_music(-10.0)


func kill():
	$MusicPlayer.stop()


func lerp_fade(min, max):
	$MusicPlayer.volume_db = lerp(
			min,
			max,
			$FadeT.time_left / $FadeT.wait_time
			)


func _physics_process(delta: float) -> void:
	if $FadeT.is_stopped() or $FadeT.wait_time == 0:
		$MusicPlayer.volume_db = 0.0
	else:
		if music_on:
			lerp_fade(0.0, -80.0)
		else:
			lerp_fade(-80.0, 0.0)
		
