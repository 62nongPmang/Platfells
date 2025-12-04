extends VBoxContainer

@onready var label = $SlotLabel
# AnimatedSprite2D 대신 Sprite2D를 가져옵니다.
@onready var sprite = $IconHolder/Sprite2D 

var slot_num: int = 0

func setup(num: int):
	slot_num = num
	# 숫자를 2자리로 예쁘게 포맷팅 (1 -> "01")
	label.text = "%02d" % num
	
	# Sprite2D는 인스펙터에서 이미지를 넣었으면
	# 여기서 anim.frame = 0 같은 코드가 필요 없습니다.
	# (만약 상황에 따라 이미지를 바꾸고 싶다면 sprite.texture = load("경로") 를 쓰면 됩니다)

# 선택되었을 때 강조 효과
func set_focus(is_focused: bool):
	if is_focused:
		modulate = Color.WHITE # 원래 밝기
		scale = Vector2(1.2, 1.2) # 선택됨: 커짐
	else:
		modulate = Color(0.5, 0.5, 0.5) # 선택 안됨: 어둡게 (회색조)
		scale = Vector2(1.0, 1.0)
