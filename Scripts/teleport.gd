class_name UniversalTP
extends Node2D

# [설정 1] 타입 선택
enum TpType { DOOR, CAVE, HOLE, EMPTY }
@export_category("Type Settings")
@export var tp_type: TpType = TpType.DOOR

@export_category("Connection")
@export var destination: Marker2D
@export var linked_tp: UniversalTP

@export_category("Teleport Timing")
@export var travel_time: float = 1.0   
@export var arrival_delay: float = 0.3 

@export_category("Path Movement")
@export var camera_path: Path2D        
@export var is_reverse_path: bool = false 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var player_ref: CharacterBody2D = null
var is_teleporting: bool = false
var is_open: bool = false 

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	update_visual()

func update_visual():
	if tp_type == TpType.EMPTY:
		anim.visible = false
		return
	
	anim.visible = true
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

# --- 키 입력 감지 ---
func _unhandled_input(event):
	if destination == null:
		return

	if player_ref != null and not is_teleporting and event.is_action_pressed("interaction"):
		
		var current_player = player_ref
		
		if tp_type == TpType.DOOR:
			if not is_open:
				start_sequence(current_player)
		else:
			perform_teleport(current_player)

# --- 출발 시퀀스 ---
func start_sequence(target_player):
	is_open = true
	if anim.sprite_frames.has_animation("open"):
		anim.play("open")
		await anim.animation_finished
	
	perform_teleport(target_player)
	
	close_sequence()

func close_sequence():
	is_open = false
	if anim.sprite_frames.has_animation("close"):
		anim.play("close")
		await anim.animation_finished
	
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

# --- 이동 로직 ---
func perform_teleport(target_player):
	is_teleporting = true
	
	# 1. 플레이어 조작 멈춤 & 물리 끄기
	if "can_move" in target_player:
		target_player.can_move = false
	target_player.set_physics_process(false) 
	target_player.visible = false
	
	# --- [분기점] 경로가 있나요? ---
	if camera_path != null:
		await move_player_along_path(target_player)
	else:
		if travel_time > 0:
			await get_tree().create_timer(travel_time).timeout
	
	# -------------------------------------
	
	# 2. 확실하게 목적지 좌표로 고정
	target_player.global_position = destination.global_position
	
	# [도착 대기] 문이 없을 때만 대기
	if linked_tp == null and arrival_delay > 0:
		await get_tree().create_timer(arrival_delay).timeout

	# 3. 도착지 처리 (문 열기 + 등장)
	if linked_tp != null:
		# 여기서 문 열림과 동시에 플레이어가 등장합니다.
		await linked_tp.process_arrival_open(target_player)
	else:
		# 문이 없으면 여기서 등장
		target_player.visible = true
	
	# 4. 마무리 (문 닫기)
	if linked_tp != null:
		linked_tp.process_arrival_close()
	
	target_player.set_physics_process(true)
	if "can_move" in target_player:
		target_player.can_move = true
		
	is_teleporting = false

# --- [양방향] 플레이어 경로 이동 함수 ---
func move_player_along_path(target_player):
	var follower = PathFollow2D.new()
	follower.loop = false 
	follower.rotates = false 
	
	var remote = RemoteTransform2D.new()
	remote.remote_path = target_player.get_path()
	remote.update_rotation = false
	remote.update_scale = false
	
	camera_path.add_child(follower)
	follower.add_child(remote)
	
	# 방향 결정 (체크박스 기준)
	var start_ratio = 0.0
	var target_ratio = 1.0
	
	if is_reverse_path:
		start_ratio = 1.0
		target_ratio = 0.0
	else:
		start_ratio = 0.0
		target_ratio = 1.0
	
	follower.progress_ratio = start_ratio
	
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE) 
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(follower, "progress_ratio", target_ratio, travel_time)
	
	await tween.finished
	
	follower.queue_free()

# --- 도착지 함수들 ---
func process_arrival_open(target_player = null):
	if tp_type == TpType.DOOR:
		if anim.sprite_frames.has_animation("open"):
			anim.play("open")
			
			# [수정됨] 대기 시간 삭제! 문 열림 시작과 동시에 바로 보여줌
			if target_player: 
				target_player.visible = true
			
			await anim.animation_finished 
		else:
			if target_player: target_player.visible = true
			
	else: 
		await get_tree().create_timer(0.3).timeout
		if target_player: target_player.visible = true

func process_arrival_close():
	if tp_type == TpType.DOOR:
		# 문 닫기 전 잠깐 대기
		await get_tree().create_timer(0.5).timeout
		
		if anim.sprite_frames.has_animation("close"):
			anim.play("close")
			await anim.animation_finished
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")

# --- 감지 ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
