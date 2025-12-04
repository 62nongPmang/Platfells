# GameManager.gd
extends Node

# --- 게임 데이터 변수들 ---
var score: int = 0
var npc_interaction_counts: Dictionary = {}
var collected_coins: Array = []

# --- [복구됨] 임시 세이브/롤백용 변수 (오류 해결 핵심) ---
var last_checkpoint_pos: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var checkpoint_data: Dictionary = {}

# --- 세이브 시스템 변수 ---
var current_slot_id: int = -1 
const SAVE_PATH_TEMPLATE = "user://save_%d.dat"


# --- [기능 1] 파일에 영구 저장 (슬롯) ---
func save_game_to_slot(slot_id: int, pos: Vector2):
	current_slot_id = slot_id
	
	# 임시 변수들도 업데이트 (죽었을 때 바로 부활하기 위해)
	save_checkpoint(pos)
	
	var save_data = {
		"score": score,
		"interaction": npc_interaction_counts,
		"coins": collected_coins,
		"player_pos_x": pos.x,
		"player_pos_y": pos.y,
		"scene_path": get_tree().current_scene.scene_file_path
	}
	
	var path = SAVE_PATH_TEMPLATE % slot_id
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("슬롯 %d번 파일 저장 완료!" % slot_id)
	else:
		print("오류: 파일 저장 실패")


# --- [기능 2] 파일에서 불러오기 (슬롯) ---
func load_game_from_slot(slot_id: int):
	var path = SAVE_PATH_TEMPLATE % slot_id
	
	if not FileAccess.file_exists(path):
		print("오류: %d번 세이브 파일이 없습니다." % slot_id)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		
		# 데이터 복구
		score = loaded_data.get("score", 0)
		npc_interaction_counts = loaded_data.get("interaction", {})
		collected_coins = loaded_data.get("coins", [])
		current_slot_id = slot_id
		
		# 임시 변수 업데이트 (Player _ready에서 사용됨)
		last_checkpoint_pos = Vector2(loaded_data["player_pos_x"], loaded_data["player_pos_y"])
		has_checkpoint = true
		
		# [중요] 로드한 직후에 '임시 체크포인트' 데이터도 갱신해줘야 죽었을 때 롤백 가능
		checkpoint_data = {
			"score": score,
			"interaction": npc_interaction_counts.duplicate(),
			"coins": collected_coins.duplicate()
		}
		
		get_tree().change_scene_to_file(loaded_data["scene_path"])
		print("슬롯 %d번 로드 완료!" % slot_id)


# --- [기능 3] 메모리에 임시 저장 (죽었을 때 롤백용) ---
func save_checkpoint(pos: Vector2):
	last_checkpoint_pos = pos
	has_checkpoint = true
	
	checkpoint_data = {
		"score": score,
		"interaction": npc_interaction_counts.duplicate(), 
		"coins": collected_coins.duplicate()               
	}
	print("임시 체크포인트 갱신됨")


# --- [기능 4] 메모리에서 복구 (죽었을 때) ---
func load_checkpoint():
	if not has_checkpoint:
		return
	
	score = checkpoint_data["score"]
	npc_interaction_counts = checkpoint_data["interaction"].duplicate()
	collected_coins = checkpoint_data["coins"].duplicate()
	
	print("임시 체크포인트로 롤백 완료!")


# --- 기타 유틸리티 함수 ---
func has_save_file(slot_id: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH_TEMPLATE % slot_id)
	
func add_point():
	score += 1
	print("현재 점수: " + str(score))

func increase_interaction(npc_id: String):
	if npc_interaction_counts.has(npc_id):
		npc_interaction_counts[npc_id] += 1
	else:
		npc_interaction_counts[npc_id] = 1

func get_interaction_count(npc_id: String) -> int:
	return npc_interaction_counts.get(npc_id, 0)

func register_coin(coin_name: String):
	if not collected_coins.has(coin_name):
		collected_coins.append(coin_name)

func is_coin_collected(coin_name: String) -> bool:
	return collected_coins.has(coin_name)

# 파일 내용 전체를 로드하지 않고 정보만 살짝 리턴하는 함수
func get_save_info(slot_id: int) -> Dictionary:
	var path = SAVE_PATH_TEMPLATE % slot_id
	if not FileAccess.file_exists(path):
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()
	return data
