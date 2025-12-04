extends CharacterBody2D

var can_move: bool = true # 플레이어가 움직일 수 있는지 여부

const SPEED = 100.0
const JUMP_VELOCITY = -200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound

const LOAD_BUBBLE_SCENE = preload("res://ui/Load_box.tscn")

var is_loading_menu_open: bool = false

func _unhandled_input(event):
	# Z키(open_load_menu)를 눌렀고 + 메뉴가 안 열려있고 + 움직일 수 있는 상태라면
	if event.is_action_pressed("open_load_menu") and not is_loading_menu_open and can_move:
		open_load_bubble()

func open_load_bubble():
	is_loading_menu_open = true
	
	# 1. 플레이어 행동 정지 (메뉴 조작 중 이동 방지)
	can_move = false
	set_physics_process(false) 
	velocity = Vector2.ZERO # 미끄러짐 방지
	
	# 애니메이션을 멈추거나 Idle로 변경 (있다면)
	# if anim: anim.play("idle")
	
	# 2. 말풍선 생성 및 부착
	var bubble = LOAD_BUBBLE_SCENE.instantiate()
	add_child(bubble) # 플레이어의 자식으로 붙습니다.
	
	# 3. 말풍선이 닫힐 때(사라질 때)를 감지해서 플레이어 조작 복구
	bubble.tree_exiting.connect(_on_load_bubble_closed)

# 말풍선이 queue_free() 되어 사라질 때 자동으로 실행됨
func _on_load_bubble_closed():
	is_loading_menu_open = false
	can_move = true
	set_physics_process(true)

func _ready():
	# DialogueManager의 'dialog_started' 신호가 오면
	# 이 스크립트의 '_on_dialog_started' 함수를 실행합니다.
	DialogueManager.dialog_started.connect(_on_dialog_started)
		# 'dialog_ended' 신호가 오면 '_on_dialog_ended' 함수를 실행합니다.
	DialogueManager.dialog_ended.connect(_on_dialog_ended)
	# [추가] 저장된 체크포인트가 있다면 거기로 순간이동!
	if GameManager.has_checkpoint:
		global_position = GameManager.last_checkpoint_pos
		
		# (팁) 땅에 박히는 걸 방지하기 위해 y축을 살짝 위로 띄워주면 좋습니다.
		# global_position.y -= 10

func _physics_process(delta: float) -> void:
	# --- 1. 중력 (항상 적용) ---
	# 중력은 can_move와 상관없이 항상 적용됩니다.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- 2. 입력 처리 (can_move가 true일 때만) ---
	var direction := 0.0
	if can_move:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		# Get the input direction: -0. -. 1
		direction = Input.get_axis("move_left", "move_right")

	# --- 3. 속도 적용 (수정됨) ---
	# 'direction' (입력)이 있으면 속도를 설정하고,
	# 'direction'이 없거나 'can_move'가 false이면 관성에 의해 미끄러짐(move_toward)
	if direction:
		velocity.x = direction * SPEED
	else:
		# [수정] 대화 중(can_move=false)이면 direction이 0이므로
		# 자동으로 이 코드가 실행되어, 미끄러지다 멈춥니다. (요구사항 충족)
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- 4. 애니메이션 (수정됨) ---
	
	# Flip the Sprite (입력이 있을 때만)
	if can_move and direction != 0: # [수정] 대화 중에는 방향 전환 안 함
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
	
	# Play animations (입력이 아닌 '속도' 기준으로 변경)
	if is_on_floor():
		# direction(입력)이 아닌, 실제 속도(velocity.x)로 'Run' 판별
		# 이렇게 해야 미끄러질 때도 'Run' 애니메이션이 나옵니다.
		if abs(velocity.x) > 0.1: # 0.1은 미세한 떨림 방지
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")
	else:
		animated_sprite.play("Jump")

	# --- 5. 최종 이동 ---
	move_and_slide()


func set_movement_enabled(enabled: bool):
	"""
	NPC가 플레이어의 움직임 가능 여부를 설정하기 위해 호출하는 함수.
	false가 되면 'can_move'가 false가 되고, _physics_process에서 입력을 무시함.
	"""
	can_move = enabled



func _on_dialog_started():
	"""
	대화가 시작되었다는 신호를 받으면,
	플레이어의 움직임을 비활성화합니다.
	"""
	can_move = false

func _on_dialog_ended():
	"""
	대화가 끝났다는 신호를 받으면,
	플레이어의 움직임을 다시 활성화합니다.
	"""
	can_move = true
