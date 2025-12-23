extends Node

var score: int = 0
var high_score: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 2.0

signal score_changed(new_score)
signal combo_changed(new_combo)
signal high_score_beaten(new_high_score)

func _ready():
	load_high_score()

func _process(delta):
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()

func add_score(points: int):
	var multiplied_points = points * (1 + combo)
	score += multiplied_points
	score_changed.emit(score)
	
	# También agregar puntos al UpgradeManager (para poder comprar mejoras de clicker)
	if UpgradeManager:
		UpgradeManager.add_game_points(multiplied_points)
	
	# Actualizar combo
	combo += 1
	combo_timer = combo_timeout
	combo_changed.emit(combo)
	
	# Verificar high score
	if score > high_score:
		high_score = score
		save_high_score()
		high_score_beaten.emit(high_score)

func reset_combo():
	combo = 0
	combo_changed.emit(combo)

func reset_score():
	score = 0
	reset_combo()
	score_changed.emit(score)

func load_high_score():
	if FileAccess.file_exists("user://high_score.save"):
		var file = FileAccess.open("user://high_score.save", FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()

func save_high_score():
	var file = FileAccess.open("user://high_score.save", FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func get_score() -> int:
	return score

func get_high_score() -> int:
	return high_score

func get_combo() -> int:
	return combo
