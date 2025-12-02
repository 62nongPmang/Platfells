# GameManager.gd
extends Node

# 1. 점수 관리
var score = 0

# 2. NPC 대화 횟수 관리 (추가된 부분)
# NPC의 ID를 키(Key)로, 만난 횟수를 값(Value)으로 저장하는 사전입니다.
# 예: { "npc_bigmac": 3, "npc_girl": 1 }
var npc_interaction_counts: Dictionary = {}

# 종료 타이머 변수
var quit_timer: float = 0.0
const QUIT_DURATION: float = 3.0 # 3초

# 마지막 세이브 위치 (Vector2)
var last_checkpoint_pos: Vector2 = Vector2.ZERO

# 세이브 포인트가 한 번이라도 찍혔는지 확인
var has_checkpoint: bool = false


func _process(delta: float) -> void:
	# ESC 키(ui_cancel)를 누르고 있는지 확인
	# (Godot 기본 설정에서 ui_cancel은 ESC에 매핑되어 있습니다)
	if Input.is_action_pressed("ui_cancel"):
		quit_timer += delta
		
		# 로그로 진행 상황 확인 (1초 단위로 출력)
		if int(quit_timer) > int(quit_timer - delta):
			print("게임 종료까지... " + str(int(QUIT_DURATION - quit_timer) + 1))
		
		# 3초가 지났다면 게임 종료
		if quit_timer >= QUIT_DURATION:
			print("게임 종료!")
			get_tree().quit()
			
	else:
		# 키를 떼면 타이머 초기화
		quit_timer = 0.0


# 점수 증가 함수
func add_point():
	score += 1
	print("현재 점수: " + str(score))


# 특정 NPC와의 만남 횟수를 1 증가시키는 함수
func increase_interaction(npc_id: String):
	# 만약 장부에 이미 이 NPC가 있다면? -> 횟수 + 1
	if npc_interaction_counts.has(npc_id):
		npc_interaction_counts[npc_id] += 1
	# 장부에 없는 처음 보는 NPC라면? -> 1로 등록
	else:
		npc_interaction_counts[npc_id] = 1
	
	# (디버그용) 잘 기록되는지 확인하고 싶으면 주석을 푸세요
	# print("NPC [" + npc_id + "] 와의 만남 횟수: " + str(npc_interaction_counts[npc_id]))


# [추가] 특정 NPC와 몇 번 만났는지 확인해서 숫자를 주는 함수
func get_interaction_count(npc_id: String) -> int:
	# 장부(get)에서 npc_id를 찾아서 값을 줍니다. 
	# 만약 장부에 없다면(한 번도 안 만났다면) 기본값 0을 줍니다.
	return npc_interaction_counts.get(npc_id, 0)
