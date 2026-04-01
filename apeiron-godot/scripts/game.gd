extends Node2D

# Script principal del juego (reemplaza el GDScript inline)

var objective_scene := preload("res://scenes/mission_objective.tscn")
var objective_instance: Node2D = null

func _ready() -> void:
	# Resetear score cuando empieza el juego
	if ScoreManager:
		ScoreManager.reset_score()
	
	# Si hay una misión activa, spawnear el objetivo
	if UpgradeManager.is_mission_active:
		_spawn_objective()
	
	# Conectar señal de muerte del jugador
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

func _spawn_objective() -> void:
	if not objective_scene:
		push_error("No se encontró la escena del objetivo")
		return
	
	objective_instance = objective_scene.instantiate()
	add_child(objective_instance)
	
	if objective_instance.has_signal("objective_reached"):
		objective_instance.objective_reached.connect(_on_objective_reached)
	
	print("Objetivo spawneado en posición: ", objective_instance.global_position)

func _on_objective_reached() -> void:
	print(" ¡Objetivo alcanzado!")
	# La lógica de completar misión está en mission_objective.gd

func _on_player_died() -> void:
	print("Jugador murió")
	# El pause_menu maneja el game over
