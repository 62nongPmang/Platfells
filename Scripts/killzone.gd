extends Area2D

@onready var timer: Timer = $Timer
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

func _on_body_entered(body: Node2D) -> void:
	print("You died!")
	
	# [수정] 여기서 바로 리로드하면 안 됩니다! 
	# 여기서는 '죽는 연출'만 시작합니다.
	
	if body.is_in_group("player"): # 플레이어인지 확인하는 게 안전함
		# 1. 물리 충돌 끄기 (또 죽는 것 방지)
		# body.get_node("CollisionShape2D").queue_free() 대신 이게 더 안전합니다.
		body.get_node("CollisionShape2D").set_deferred("disabled", true)
		
		# 2. 슬로우 모션 및 사운드
		Engine.time_scale = 0.5
		hurt_sound.play()
		
		# 3. 타이머 시작 (이 시간이 지나야 _on_timer_timeout이 실행됨)
		timer.start()


func _on_timer_timeout():
	# 타이머가 끝났을 때 (이제 진짜 재시작)
	
	# 1. 시간 속도 원상복구 (중요! 안 하면 다음 게임도 느림)
	Engine.time_scale = 1.0
	
	# 2. [핵심] 데이터 롤백 (저장된 상태로 되돌리기)
	GameManager.load_checkpoint()
	
	# 3. 씬 재시작
	get_tree().reload_current_scene()
