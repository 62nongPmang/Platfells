extends Area2D

@onready var timer: Timer = $Timer
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

func _on_body_entered(body: Node2D) -> void:
	print("You died!")
	Engine.time_scale = 0.5
	body.get_node("CollisionShape2D").queue_free()
	timer.start()
	hurt_sound.play()



func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
