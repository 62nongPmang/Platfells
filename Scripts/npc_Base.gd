extends StaticBody2D

@export var npc_name: String = "NPC_name"
@export var can_interact: bool = true

# NPC가 가질 고유의 대사 (인스펙터 창에서 직접 입력)
@export_multiline var dialog_lines: Array[String] = [
	"",
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


# _process를 사용하여 "Press E" 아이콘을 관리
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
	if (
		player_in_range and
		event.is_action_pressed("advance_dialog") and
		not DialogueManager.is_dialog_active
	):
		get_tree().root.set_input_as_handled()
		
		var final_lines: Array[String] = dialog_lines.duplicate()
		
		# 2. 모든 대사 줄을 검사하여 "{score}" 라는 글자를 실제 점수로 바꿉니다.
		for i in range(final_lines.size()):
			if "{score}" in final_lines[i]:
				# "{score}" 부분을 GameManager.score 값으로 교체
				final_lines[i] = final_lines[i].replace("{score}", str(GameManager.score))
		
		# 3. 가공된 대사(final_lines)를 DialogueManager에게 넘깁니다.
		DialogueManager.start_dialog(global_position, final_lines)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
