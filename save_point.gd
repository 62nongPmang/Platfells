extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false # 이미 밟은 곳인지 확인

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 플레이어이고, 아직 활성화 안 된 곳이라면
	if body.is_in_group("player") and not is_activated:
		activate_checkpoint()

func activate_checkpoint():
	is_activated = true
	print("세이브 포인트 저장 완료!")
	
	# GameManager에게 내 위치를 기억시킴
	# global_position은 이 세이브 포인트의 월드 좌표입니다.
	GameManager.last_checkpoint_pos = global_position
	GameManager.has_checkpoint = true
	
	# [연출] 활성화되었다는 표시 (예: 색상을 초록색으로 변경)
	sprite.modulate = Color.GREEN
	sprite.play("savepoint_01")
