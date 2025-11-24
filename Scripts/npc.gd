extends StaticBody2D

# [바리에이션용] 인스펙터에서 NPC 이름 및 상호작용 여부를 설정합니다.
@export var npc_name: String = "NPC"
@export var can_interact: bool = true
#바보
@onready var press_e: Label = $PressE
@onready var interaction_area: Area2D = $InteractionArea

# [바리에이션용] 'PressE' 라벨이 *있을 때만* 가져옵니다.
# 만약 'PressE' 노드가 없으면 null이 되어, 오류 없이 유연하게 처리됩니다.
@onready var press_e_label: Label = $PressE if has_node("PressE") else null

var player_in_range: bool = false #범위 내 플레이어 확인

func _ready():
	# 1. (NPC_IDEL) NPC 이름 설정
	press_e.text = npc_name
	
	# 2. 상호작용이 불가능한 NPC면, 감지 기능을 끕니다.
	if not can_interact:
		interaction_area.monitoring = false # 감지 자체를 비활성화
		if press_e_label:
			press_e_label.hide() # 혹시 켜져 있으면 숨김
		return # _ready() 함수 종료
	
	#3. 상호작용 가능 NPC 설정 (needs : collision mask 2)
	interaction_area.monitoring = true
	
	#4. 'PressE' 라벨이 존재한다면, 숨김을 기본으로 합니다.
	if press_e_label:
		press_e_label.hide()
	
# 5. [중요] 시그널을 코드로 직접 연결합니다. (실수 방지)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# 플레이어가 감지 영역에 들어왔을 때
func _on_body_entered(body: Node2D) -> void:
	# 들어온 body가 "player" 그룹에 속하는지 확인 (가장 안전한 방법)
	# (참고: Player 씬의 루트 노드를 "player" 그룹에 추가해야 합니다)
	if body.is_in_group("player"):
		player_in_range = true
		
		# 'PressE' 라벨이 있는 NPC(null이 아니면)일 때만 표시
		if press_e_label:
			press_e_label.show()

# 플레이어가 감지 영역에서 나갔을 때
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		
		# 'PressE' 라벨이 있는 NPC일 때만 숨김
		if press_e_label:
			press_e_label.hide()

# (추가) 실제 상호작용 로직
func _unhandled_input(event):
	# 범위 안에 있고(player_in_range), 'interact' 액션(예: E키)을 눌렀을 때
	if player_in_range and event.is_action_just_pressed("interact"):
		print("플레이어가 NPC [" + npc_name + "]와 상호작용!")
		# 여기에 대화창을 띄우는 코드를 넣습니다.
		# 예: DialogueManager.start_conversation(npc_name)
		get_tree().set_input_as_handled() # 다른 곳에서 입력 처리 방지
