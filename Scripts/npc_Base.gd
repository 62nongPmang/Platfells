extends StaticBody2D

@export var npc_id: String = ""

@export var npc_name: String = "NPC_name"
@export var can_interact: bool = true

# [핵심 변경] 단순 대사 배열 대신, '분기(Branch) 목록'을 가집니다.
# 인스펙터에서 여러 개의 조건을 추가할 수 있습니다.
@export var dialogue_branches: Array[DialogueBranch] = []

# [기본 대사] 아무 조건도 맞지 않을 때 나올 대사 (안전장치)
@export_multiline var default_lines: Array[String] = [""]

@onready var name_label: Label = $LabelScale/NameLabel
@onready var interaction_area: Area2D = $InteractionArea
@onready var press_e_button: AnimatedSprite2D = $PressE if has_node("PressE") else null

var player_in_range: bool = false

func _ready():
	assert(interaction_area != null, "'interaction_area' 변수가 null입니다! $InteractionArea 노드 이름을 확인하세요.")
	assert(name_label != null, "'name_label' 변수가 null입니다! $NameLabel 노드 이름을 확인하세요.")

	name_label.text = npc_name
	
	if not can_interact:
		interaction_area.monitoring = false
		if press_e_button: press_e_button.hide()
		return

	if press_e_button:
		press_e_button.hide() # 시작 시 무조건 숨김

	var err_entered = interaction_area.body_entered.connect(_on_body_entered)
	var err_exited = interaction_area.body_exited.connect(_on_body_exited)
	
	if err_entered != OK or err_exited != OK:
		push_error("NPC 시그널 연결 실패!")
		return
	
	interaction_area.monitoring = true


# _process를 사용하여 "Press E" 아이콘을 관리
func _process(_delta):
	if not press_e_button: return # E 아이콘이 없으면 실행 안 함
	if not can_interact: return

	# "Press E" 아이콘은
	# 플레이어가 범위 안에 있고, 현재 대화 중이 아닐 때만 보여야 합니다.
	if player_in_range and not DialogueManager.is_dialog_active:
		press_e_button.show()
	else:
		press_e_button.hide()


# 상호작용 키 입력 처리
func _unhandled_input(event):
	if (
		player_in_range and
		event.is_action_pressed("interaction") and
		not DialogueManager.is_dialog_active
	):
		get_tree().root.set_input_as_handled()
		
		# [1] 만남 횟수 기록 (ID가 있을 때만)
		if npc_id != "":
			GameManager.increase_interaction(npc_id)
		
		# [2] 현재 상태 변수 준비 (이 부분이 빠져서 에러가 났었습니다!)
		var current_score = GameManager.score
		# GameManager에게 "나 얘랑 몇 번 만났어?" 하고 물어봅니다.
		var current_count = GameManager.get_interaction_count(npc_id)
		
		var target_lines: Array[String] = default_lines
		# 3. 모든 분기 검사
		for branch in dialogue_branches:
			
			# 만약 인스펙터에 빈 칸(null)이 있다면 무시하고 다음으로 넘어갑니다.
			if branch == null:
				continue
			
			# --- A. 점수 조건 검사 ---
			var score_pass = true 
			if branch.use_score_condition:
				if current_score < branch.min_score or current_score > branch.max_score:
					score_pass = false # 범위 벗어남 -> 탈락!
			
			
			# --- B. 횟수 조건 검사 ---
			var interaction_pass = true
			
			# 체크박스를 켰을 때만, 횟수를 검사합니다.
			if branch.use_interaction_condition:
				if current_count < branch.min_interactions or current_count > branch.max_interactions:
					interaction_pass = false # 범위 벗어남 -> 탈락!
			
			
			# 두 조건 모두(혹은 켜진 것들) 통과했다면 채택!
			if score_pass and interaction_pass:
				target_lines = branch.lines
				break
		
		# [2. 텍스트 치환 로직 ({score} -> 점수)]
		var final_lines: Array[String] = target_lines.duplicate()
		
		for i in range(final_lines.size()):
			if "{score}" in final_lines[i]:
				final_lines[i] = final_lines[i].replace("{score}", str(GameManager.score))
		
		# [3. 대화 시작]
		DialogueManager.start_dialog(global_position, final_lines)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
