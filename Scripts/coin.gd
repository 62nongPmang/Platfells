extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(_body: Node2D) -> void:
	# 오토로드된 GameManager를 직접 호출
	GameManager.add_point()
	
	animation_player.play("pickup")
