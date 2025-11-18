extends Node

signal dialog_started
signal dialog_ended

@onready var text_box_scene = preload("res://ui/text_box.tscn")


var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var is_dialog_active = false
var can_advance_line = false


func start_dialog(position: Vector2, lines: Array[String]):
	dialog_started.emit() # "대화 시작" 신호를 게임 전체에 보냅니다.
	
	if is_dialog_active:
		return # 이미 대화 중이면 아무것도 하지 않고 종료
		
	dialog_lines = lines
	text_box_position = position
	_show_text_box()
	is_dialog_active = true


func _show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)
	text_box.global_position = text_box_position
	
	# 새 텍스트 박스를 표시할 때, "다음 줄로 넘길 수 있음" 플래그를
	# 즉시 'false'로 리셋합니다. (핵심 버그 수정)
	can_advance_line = false
	
	text_box.display_text(dialog_lines[current_line_index])
	
	
func _on_text_box_finished_displaying():
		can_advance_line = true


func _unhandled_input(event):
	# 괄호 위치 중요! ((A or B) and C) 구조여야 합니다.
	# 안 그러면 대화 중이 아닐 때도 키만 누르면 코드가 실행될 수 있습니다.
	if (
		(event.is_action_pressed("advance_dialog", true) or event.is_action_pressed("jump")) and
		is_dialog_active
	):
		get_tree().root.set_input_as_handled()

		# 1. 텍스트가 다 표시되어서 다음 줄로 넘길 수 있을 때
		if can_advance_line:
			text_box.queue_free()
			
			if is_instance_valid(text_box):
				text_box.queue_free()
			
			current_line_index += 1
			if current_line_index >= dialog_lines.size():
				# 대화 종료
				is_dialog_active = false
				current_line_index = 0
				dialog_ended.emit() 
				return
			
			# 다음 줄 표시
			_show_text_box()

		# 2. 텍스트가 타이핑되는 중일 때 (스킵)
		else:
			if is_instance_valid(text_box):
				text_box.skip_to_end()
