extends Node2D

# [설정 1] 이동할 목적지 좌표 (깃발)
@export var destination_marker: Marker2D
# [설정 2] 도착했을 때 애니메이션을 재생할 '반대편 문' (Door 씬 노드)
@export var linked_door: Node2D 

@onready var interaction_area: Area2D = $InteractionArea
@onready var anim: AnimatedSprite2D = $OldDoor


var player_ref: CharacterBody2D = null 
var is_teleporting: bool = false 

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	anim.play("close")

# [편의 기능] 외부에서 이 문의 애니메이션을 실행하기 위한 함수
func play_door_open():
	anim.play("open")
	await anim.animation_finished # 애니메이션이 끝날 때까지 기다림

func play_door_close():
	anim.play("close")
	await anim.animation_finished

func _unhandled_input(event):
	if player_ref != null and event.is_action_pressed("advance_dialog") and not is_teleporting:
		
		# 안전장치: 목적지와 반대편 문이 모두 연결되어 있어야 함
		if destination_marker == null or linked_door == null:
			print("오류: Destination Marker 또는 Linked Door가 인스펙터에 연결되지 않았습니다.")
			return
			
		is_teleporting = true
		var target_player = player_ref # 플레이어 백업
		
		# 1. 플레이어 조작 정지
		if "can_move" in target_player:
			target_player.can_move = false
		
		# --- [시퀀스 시작] ---
		
		# 2. 출발점 문 열림 (기다림)
		await play_door_open()
		
		# 문이 활짝 열린 상태에서 "잠깐 대기"
		await get_tree().create_timer(0.5).timeout
		
		# 3. 출발점 문 닫힘 + 동시에 캐릭터 사라짐
		anim.play("close") # 기다리지 않고(await 없음) 바로 다음 줄 실행
		target_player.visible = false
		
		# 4. 이동 중 대기 (문이 완전히 닫히고 이동하는 느낌을 위해 약간의 딜레이)
		await get_tree().create_timer(1.0).timeout
		
		# 5. 위치 이동 (안 보이는 상태)
		target_player.global_position = destination_marker.global_position
		
		# 6. 도착점 문 열림 + 동시에 캐릭터 나타남
		# (반대편 문의 함수를 호출합니다)
		linked_door.anim.play("open") 
		target_player.visible = true
		
		# 도착점 문이 다 열릴 때까지 기다림
		await linked_door.anim.animation_finished
		
		# 도착해서도 문이 잠깐 열려있다가 닫힘 (0.3초)
		await get_tree().create_timer(0.5).timeout
		
		# 7. 도착점 문 닫힘
		# (반대편 문 닫기)
		linked_door.play_door_close()
		
		# -------------------
		
		# 8. 조작 재개
		if "can_move" in target_player:
			target_player.can_move = true
			
		is_teleporting = false

# ... (아래 _on_body_entered, _on_body_exited 함수는 기존과 동일) ...
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
