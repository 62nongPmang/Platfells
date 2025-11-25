extends Node

var score = 0

func add_point():
	score += 1
	print("현재 점수: " + str(score)) # 디버깅용 로그
