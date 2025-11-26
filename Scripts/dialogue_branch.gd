@tool
extends Resource
class_name DialogueBranch

# ==========================================
# 1. 점수 조건 (Score)
# ==========================================
@export var use_score_condition: bool = false:
	set(value):
		use_score_condition = value
		# [핵심] 값이 바뀌면 에디터에게 "목록 새로고침해!"라고 알림
		notify_property_list_changed() 

@export var min_score: int = 0
@export var max_score: int = 10


# ==========================================
# 2. 상호작용 횟수 조건 (Interaction)
# ==========================================
@export var use_interaction_condition: bool = false:
	set(value):
		use_interaction_condition = value
		notify_property_list_changed()

@export var min_interactions: int = -1
@export var max_interactions: int = 10


# ==========================================
# 3. 대사 내용
# ==========================================
@export_multiline var lines: Array[String] = []


# ==========================================
# [마법의 함수] 체크가 꺼져있으면 변수를 숨깁니다.
# ==========================================
func _validate_property(property: Dictionary):
	# 점수 사용 안 함(false) -> 점수 관련 변수 숨김
	if not use_score_condition and property.name in ["min_score", "max_score"]:
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 횟수 사용 안 함(false) -> 횟수 관련 변수 숨김
	if not use_interaction_condition and property.name in ["min_interactions", "max_interactions"]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
