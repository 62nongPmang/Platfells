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
	# [수정 1: 안전장치 추가]
	# 전달받은 대사(lines)가 비어있으면 함수를 즉시 종료합니다.
	# 이 코드가 없으면 빈 배열의 [0]번을 찾다가 게임이 튕깁니다.
	if lines.is_empty():
		print("오류: 대사 목록이 비어있습니다! start_dialog 호출을 확인하세요.")
		return

	dialog_started.emit()
	
	if is_dialog_active:
		return
		
	dialog_lines = lines
	text_box_position = position
	_show_text_box()
	is_dialog_active = true


func _show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)
	text_box.global_position = text_box_position
	
	can_advance_line = false
	

	text_box.display_text(dialog_lines[current_line_index])
	
	
func _on_text_box_finished_displaying():
	can_advance_line = true


func _unhandled_input(event):
	if (
		(event.is_action_pressed("advance_dialog", true) or event.is_action_pressed("jump")) and
		is_dialog_active
	):
		get_tree().root.set_input_as_handled()

		# 1. 텍스트가 다 표시되어서 다음 줄로 넘길 수 있을 때
		if can_advance_line:
			
			if is_instance_valid(text_box):
				text_box.queue_free()
			
			current_line_index += 1
			if current_line_index >= dialog_lines.size():
				is_dialog_active = false
				current_line_index = 0
				dialog_ended.emit()
				return
			
			_show_text_box()

		# 2. 텍스트가 타이핑되는 중일 때 (스킵)
		else:
			if is_instance_valid(text_box):
				text_box.skip_to_end()
