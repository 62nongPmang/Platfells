extends Node

var score = 0

@onready var score_label: Label = $"../Map_03/NPC_Big_Mac/ScoreLabel"



func add_point():
	score += 1
	score_label.text = "오,지금까지: " + str(score) + "개의 코인을 모았구나."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
