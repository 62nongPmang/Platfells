extends StaticBody2D

var is_open: bool = false
var player_in_range: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_col: CollisionShape2D = $WallCol
@onready var interaction_area: Area2D = $InteractionArea
@onready var press_e: Node2D = $PressE if has_node("PressE") else null

func _ready():
	# 시그널 연결
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	anim.play("close")
	if press_e: press_e.hide()

func _unhandled_input(event):
	# 키를 눌렀을 때 로그를 찍어봅니다.
	if event.is_action_pressed("interaction"):
		print("--- [DEBUG] 키 입력 감지됨 (interaction) ---")
		print("1. 범위 내 플레이어 있음?: ", player_in_range)
		print("2. 문이 이미 열렸나?: ", is_open)
		
		if player_in_range and not is_open:
			print(">> 조건 만족! 문을 엽니다.")
			open_door()
		else:
			print(">> 조건 불만족. 무시함.")

func open_door():
	is_open = true
	anim.play("open")
	wall_col.set_deferred("disabled", true)
	if press_e: press_e.hide()

func _on_body_entered(body):
	# 범위에 들어온 물체의 정체를 밝힙니다.
	print("[DEBUG] InteractionArea 감지됨: ", body.name)
	
	if body.is_in_group("player"):
		print(">> 플레이어 확인됨! (그룹 일치)")
		player_in_range = true
		if not is_open and press_e: press_e.show()
	else:
		print(">> 플레이어 그룹이 아님. (현재 그룹: ", body.get_groups(), ")")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if press_e: press_e.hide()
