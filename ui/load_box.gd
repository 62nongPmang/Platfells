extends MarginContainer

# [사전 설정] 2단계에서 만든 SaveSlotUI 씬 경로를 정확히 적어주세요!
const SLOT_SCENE = preload("res://ui/save_slot_ui.tscn")

@onready var slot_container: HBoxContainer = $Podding/SlotContainer


var available_slots: Array = [] # 파일이 존재하는 슬롯 번호 모음
var current_index: int = 0      # 현재 선택된 커서 위치

func _ready():
	# 1. 1번~7번 슬롯을 검사해서 파일이 있으면 추가
	for i in range(1, 8):
		if GameManager.has_save_file(i):
			_add_slot_ui(i)
			available_slots.append(i)
	
	# 2. 파일이 하나도 없을 때 처리
	if available_slots.is_empty():
		var label = Label.new()
		label.text = "저장된 파일 없음"
		slot_container.add_child(label)
	else:
		# 파일이 있다면 첫 번째 슬롯을 선택 상태로 만듦
		_update_selection()
	
	# 3. 말풍선 위치 조정 (크기가 결정된 후 실행하기 위해 1프레임 대기)
	await get_tree().process_frame
	_adjust_position()

# 슬롯 UI 하나를 생성해서 컨테이너에 넣는 함수
func _add_slot_ui(slot_num: int):
	var slot = SLOT_SCENE.instantiate()
	slot_container.add_child(slot)
	slot.setup(slot_num) # SaveSlotUI.gd의 setup 함수 호출

# 말풍선을 캐릭터 머리 위 중앙으로 정렬하는 함수
func _adjust_position():
	# 피벗(기준점)을 중앙 하단으로 설정하면 캐릭터 머리 위에 예쁘게 뜹니다.
	# (말풍선 꼬리가 아래쪽에 있다고 가정)
	pivot_offset = Vector2(size.x / 2, size.y) 
	
	# 캐릭터(부모)의 (0,0) 위치에서 위쪽(Y 음수 방향)으로 띄움
	position = Vector2(-size.x / 2, -size.y - 40) 

func _process(_delta):
	# 저장된 파일이 없으면 '취소'만 가능
	if available_slots.is_empty():
		if Input.is_action_just_pressed("cancel_load"): # C키
			close()
		return

	# --- [키 입력 처리] ---
	
	# 1. 좌우 이동 (방향키)
	if Input.is_action_just_pressed("ui_right"):
		if current_index < available_slots.size() - 1:
			current_index += 1
			_update_selection()
			
	elif Input.is_action_just_pressed("ui_left"):
		if current_index > 0:
			current_index -= 1
			_update_selection()
			
	# 2. 불러오기 확정 (X키)
	elif Input.is_action_just_pressed("ui_accept"):
		var target_slot = available_slots[current_index]
		print("슬롯 %d번 불러오기 시도..." % target_slot)
		GameManager.load_game_from_slot(target_slot)
		# 로드에 성공하면 씬이 바뀌므로 close() 안 해도 자동으로 사라짐
		
	# 3. 취소/닫기 (C키)
	elif Input.is_action_just_pressed("ui_cancel"):
		close()

# 선택된 슬롯만 강조(밝게)하고 나머지는 어둡게 처리
func _update_selection():
	for i in range(slot_container.get_child_count()):
		var slot = slot_container.get_child(i)
		# SaveSlotUI.gd에 있는 set_focus 함수 활용
		if i == current_index:
			slot.set_focus(true)
		else:
			slot.set_focus(false)

# 말풍선 닫기
func close():
	# 닫히면서 플레이어에게 "나 닫혔어"라고 알려줄 수도 있음 (TreeExiting 신호 활용)
	queue_free()
