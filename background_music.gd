# Background music player with looping support.
extends AudioStreamPlayer

func _ready() -> void:
	# Connect to finished signal to loop the music
	if finished.is_connected(Callable(self, "_on_music_finished")):
		finished.disconnect(Callable(self, "_on_music_finished"))
	finished.connect(Callable(self, "_on_music_finished"))


func _on_music_finished() -> void:
	play()
