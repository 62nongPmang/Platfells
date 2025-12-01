class_name UniversalTP
extends Node2D

# [설정 1] 타입 선택
enum TpType { DOOR, CAVE, HOLE, EMPTY }
@export var tp_type: TpType = TpType.DOOR

# [설정 2] 이동 관련
@export var destination: Marker2D
@export var linked_tp: UniversalTP

# [설정 3] 타이밍 및 경로
@export_group("Teleport Timing")
@export var travel_time: float = 1.0
@export var arrival_delay: float = 0.3
@export var camera_path: Path2D 
# [추가] 경로 역주행 여부 (체크하면 거꾸로 1.0 -> 0.0 이동)
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

# 비주얼 업데이트
func update_visual():
	if tp_type == TpType.EMPTY:
		anim.visible = false
		return
	
	anim.visible = true
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

# 키 입력 감지
func _unhandled_input(event):
	if destination == null:
		return

	if player_ref != null and not is_teleporting and event.is_action_pressed("interaction"):
		if tp_type == TpType.DOOR:
			if not is_open:
				start_sequence()
		else:
			perform_teleport()

# --- 시퀀스 ---
func start_sequence():
	is_open = true
	if anim.sprite_frames.has_animation("open"):
		anim.play("open")
		await anim.animation_finished
	
	perform_teleport()
	close_sequence()

func close_sequence():
	is_open = false
	if anim.sprite_frames.has_animation("close"):
		anim.play("close")
		await anim.animation_finished
	
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

# --- [이동 로직] 카메라 스무딩 제어 복구 ---
func perform_teleport():
	if destination == null:
		return

	is_teleporting = true
	var target_player = player_ref
	
	# 1. 플레이어 조작 멈춤 & 물리 끄기
	if "can_move" in target_player:
		target_player.can_move = false
	
	# 물리 꺼야 Tween이랑 안 싸움
	target_player.set_physics_process(false) 
	target_player.visible = false
	
	# --- [복구됨] 카메라 설정 저장 및 '화면(Idle) 모드'로 변경 ---
	var current_cam = get_viewport().get_camera_2d()
	var saved_cam_settings = {} 
	
	if current_cam:
		saved_cam_settings["smoothing"] = current_cam.position_smoothing_enabled
		saved_cam_settings["callback"] = current_cam.process_callback
		
		# 스무딩 끄기 (딱 붙어다니게)
		current_cam.position_smoothing_enabled = false 
		# 카메라 갱신을 화면 주사율에 맞춤 (부드러움)
		current_cam.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	# ---------------------------------------------------

	# --- [분기점] 경로가 있나요? ---
	if camera_path != null:
		await move_player_along_path(target_player)
	else:
		if travel_time > 0:
			await get_tree().create_timer(travel_time).timeout
	
	# -------------------------------------
	
	# 2. 확실하게 목적지 좌표로 고정
	target_player.global_position = destination.global_position
	
	# --- [복구됨] 카메라 및 물리 복원 ---
	if current_cam:
		current_cam.reset_smoothing() 
		# 원래 설정대로 복구
		current_cam.position_smoothing_enabled = saved_cam_settings["smoothing"]
		current_cam.process_callback = saved_cam_settings["callback"]
	
	target_player.set_physics_process(true) # 물리 다시 켜기
	# -------------------------------
	
	# 3. 도착지 처리
	if linked_tp != null:
		await linked_tp.process_arrival_open()
	else:
		if arrival_delay > 0:
			await get_tree().create_timer(arrival_delay).timeout
	
	# 4. 플레이어 등장
	target_player.visible = true
	if "can_move" in target_player:
		target_player.can_move = true
	
	# 5. 마무리
	if linked_tp != null:
		linked_tp.process_arrival_close()
	
	is_teleporting = false

# --- [수정됨] 이동 곡선 완만하게 변경 (SINE) ---
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
	
	# 방향 결정
	var path_start_pos = camera_path.to_global(camera_path.curve.get_point_position(0))
	var path_end_idx = camera_path.curve.get_point_count() - 1
	var path_end_pos = camera_path.to_global(camera_path.curve.get_point_position(path_end_idx))
	
	var dist_to_start = target_player.global_position.distance_to(path_start_pos)
	var dist_to_end = target_player.global_position.distance_to(path_end_pos)
	
	var start_ratio = 0.0
	var target_ratio = 1.0
	
	if dist_to_start < dist_to_end:
		start_ratio = 0.0
		target_ratio = 1.0
	else:
		start_ratio = 1.0
		target_ratio = 0.0
	
	follower.progress_ratio = start_ratio
	
	# [Tween 설정]
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE) 
	
	# [핵심 수정] TRANS_SINE: 가장 자연스럽고 완만한 가속/감속
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(follower, "progress_ratio", target_ratio, travel_time)
	
	await tween.finished
	
	follower.queue_free()
	
# --- 도착지 함수들 ---
func process_arrival_open():
	if tp_type == TpType.DOOR:
		if anim.sprite_frames.has_animation("open"):
			anim.play("open")
			await anim.animation_finished 

func process_arrival_close():
	if tp_type == TpType.DOOR:
		await get_tree().create_timer(0.1).timeout
		if anim.sprite_frames.has_animation("close"):
			anim.play("close")
			await anim.animation_finished
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")

# --- 감지 로직 ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
