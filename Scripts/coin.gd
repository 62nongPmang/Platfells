# Coin.gd
extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# [추가] 씬이 로딩될 때, 내가 이미 수집된 목록에 있는지 확인
	# (주의: 씬 안에서 코인들의 이름이 서로 달라야 합니다. Coin, Coin2, Coin3...)
	if GameManager.is_coin_collected(self.name):
		queue_free() # 이미 먹었으면 삭제

func _on_body_entered(_body: Node2D):
	# 1. 점수 추가
	GameManager.add_point()
	
	# 2. [추가] "나 먹혔어!"라고 이름 등록
	GameManager.register_coin(self.name)
	
	# 3. 애니메이션 재생 (끝나면 queue_free)
	animation_player.play("pickup")
