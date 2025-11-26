extends Resource
class_name DialogueBranch

# 코인 횟수 조
@export_group("Score Condition")
@export var min_score: int = -1
@export var max_score: int = 9999

# 상호작용 횟수 조건
@export_group("Interaction Condition")
@export var min_interactions: int = -1   # 몇 번째 만남부터?
@export var max_interactions: int = 9999 # 몇 번째 만남까지?

# 조건이 맞으면 출력할 대사건
@export_multiline var lines: Array[String] = []
