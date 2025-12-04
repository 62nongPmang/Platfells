# SavePoint.gd
extends Area2D

# [추가] 이 세이브 포인트가 담당하는 슬롯 번호 (1 ~ 7)
@export_range(1, 7) var slot_id: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var is_activated: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_activated:
		activate_checkpoint()

func activate_checkpoint():
	is_activated = true # (선택) 한 번만 저장되게 하려면 true 유지, 여러 번 가능하면 false로 리셋
	sprite.modulate = Color.GREEN 
	
	print("세이브 슬롯 %d번에 저장 시도..." % slot_id)
	
	# [수정] GameManager에게 슬롯 번호와 함께 저장 요청
	GameManager.save_game_to_slot(slot_id, global_position)
