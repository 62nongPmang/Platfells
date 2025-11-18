extends StaticBody2D

@export var npc_name: String = "NPC_name"
@export var can_interact: bool = true

# NPC가 가질 고유의 대사 (인스펙터 창에서 직접 입력)
@export_multiline var dialog_lines: Array[String] = [
	"첫마디.",
	"요소 추가 혹은 삭제로 마디 추가 가능.",
]
@onready var name_label: Label = $LabelScale/NameLabel
@onready var interaction_area: Area2D = $InteractionArea
@onready var press_e_bottn: AnimatedSprite2D = $PressE if has_node("PressE") else null

var player_in_range: bool = false

func _ready():
	assert(interaction_area != null, "'interaction_area' 변수가 null입니다! $InteractionArea 노드 이름을 확인하세요.")
	assert(name_label != null, "'name_label' 변수가 null입니다! $NameLabel 노드 이름을 확인하세요.")

	name_label.text = npc_name
	
	if not can_interact:
		interaction_area.monitoring = false
		if press_e_bottn: press_e_bottn.hide()
		return

	if press_e_bottn:
		press_e_bottn.hide() # 시작 시 무조건 숨김

	var err_entered = interaction_area.body_entered.connect(_on_body_entered)
	var err_exited = interaction_area.body_exited.connect(_on_body_exited)
	
	if err_entered != OK or err_exited != OK:
		push_error("NPC 시그널 연결 실패!")
		return
	
	interaction_area.monitoring = true


# _process를 사용하여 "Press E" 아이콘을 관리 (이 방식이 대화중일 때 아이콘을 숨기기에 가장 좋습니다.)
func _process(_delta):
	if not press_e_bottn: return # E 아이콘이 없으면 실행 안 함
	if not can_interact: return

	# "Press E" 아이콘은
	# 플레이어가 범위 안에 있고, 현재 대화 중이 아닐 때만 보여야 합니다.
	if player_in_range and not DialogueManager.is_dialog_active:
		press_e_bottn.show()
	else:
		press_e_bottn.hide()


# 상호작용 키 입력 처리
func _unhandled_input(event):
	# 1. 플레이어가 범위 안에 있고
	# 2. 'advance_dialog' 액션이 눌렸고 (E키 등)
	# 3. 현재 대화가 활성화 상태가 아닐 때만 대화를 '시작'합니다.
	if (
		player_in_range and
		event.is_action_pressed("advance_dialog") and
		not DialogueManager.is_dialog_active
	):
		# 이 입력을 '처리됨'으로 설정합니다.
		# 이렇게 하지 않으면, 이 키 입력이 DialogueManager의 _unhandled_input에도
		# 전달되어, 대화가 시작되자마자 첫 줄이 스킵되는 버그가 발생합니다.
		get_tree().root.set_input_as_handled()
		
		# Autoload로 등록한 DialogueManager를 호출합니다.
		# 위치: 이 NPC의 위치 (text_box.gd가 이 위치를 기준으로 오프셋을 계산함)
		# 대사: 이 NPC가 가진 dialog_lines
		DialogueManager.start_dialog(global_position, dialog_lines)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
