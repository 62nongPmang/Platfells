extends ColorRect

@export var target: Node2D
@export var start_height: float = 0.0
@export var end_height: float = -3000.0

# [변경] 단순 밝기 대신, 색상표(그라디언트)를 사용합니다.
@export var sky_gradient: Gradient

func _process(_delta):
	if target == null or sky_gradient == null:
		return
	
	var current_y = target.global_position.y
	
	# 1. 현재 높이를 0.0(시작점) ~ 1.0(끝점) 사이의 비율로 변환합니다.
	var ratio = remap(current_y, start_height, end_height, 0.0, 1.0)
	
	# 2. 비율이 0~1을 벗어나지 않도록 자릅니다.
	ratio = clamp(ratio, 0.0, 1.0)
	
	# 3. [핵심] 그라디언트 색상표에서 해당 비율 위치의 색을 뽑아옵니다.
	self.modulate = sky_gradient.sample(ratio)
