extends MarginContainer


@onready var label: Label = $MarginContainer/TextLabel
@onready var timer: Timer = $LetterDisplayTimer # 한 글자씩 표시용 타이머
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


const MAX_WIDTH = 256

var text = ""
var letter_index = 0
var was_skipped: bool = false # 스킵 여부를 기억하는 플래그

var letter_time = 0.07
var space_time = 0.05
var punctuation_time = 0.2


signal finished_displaying()

# 텍스트가 한 글자씩 나올 때마다 재생할 사운드
@export var text_sound: AudioStream

func _ready():
	timer.timeout.connect(_on_letter_display_timer_timeout)


func display_text(text_to_display: String):
	was_skipped = false # 새 대사를 시작할 때 플래그를 리셋
	text = text_to_display
	label.text = text_to_display
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized #wait for x resize
		await resized #wait for y resize
		custom_minimum_size.y = size.y
	
	
	global_position.x -= size.x / 2
	global_position.y -= size.y + 16
	
	# 만약 'await' 중에 skip_to_end()가 호출되었다면 (플래그가 true라면)
	# 여기서 즉시 함수를 종료하고, 텍스트를 리셋하지 않습니다.
	if was_skipped:
		return
	
	label.text = ""
	letter_index = 0 # 대화 시작 시 인덱스 초기화
	_display_letter()
	

func _display_letter():
	# 간혹 인덱스가 길이를 초과한 상태로 호출될 수 있으므로 방어 코드 추가
	if letter_index >= text.length():
		finished_displaying.emit()
		return
		
	label.text += text[letter_index]
	
	letter_index += 1
	# 모든 글자를 표시했다면 시그널을 보내고 타이머를 중지합니다.
	if letter_index >= text.length():
		finished_displaying.emit()
		return

	# 다음 글자에 맞춰 타이머 시간 설정
	match text[letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func _on_letter_display_timer_timeout():
	_display_letter()


# DialogueManager가 호출할 '텍스트 즉시 완료(대화 스킵)' 함수입니다.
# (2단계에서 추가했던 '즉시 완료' 함수)
func skip_to_end():
	# 1. 'was_skipped' 플래그를 true로 설정합니다.
	#    (display_text 함수가 'await'에서 깨어났을 때 이 플래그를 보게 됩니다.)
	was_skipped = true
	# 2. 이미 텍스트 표시가 끝났는지 확인합니다. (끝났으면 아무것도 안 함)
	if letter_index >= text.length():
		return
	# 3. 텍스트를 한 글자씩 표시하던 타이머(LetterDisplayTimer)를 즉시 중지합니다.
	timer.stop()
	# 4. 레이블의 텍스트를 전체 텍스트로 즉시 설정합니다.
	label.text = text
	# 5. 글자 인덱스를 텍스트의 끝으로 강제 이동시킵니다.
	letter_index = text.length()
	# 6. 타이핑이 (강제로) 완료되었으므로, 'finished_displaying' 신호를 보냅니다.
	finished_displaying.emit()
