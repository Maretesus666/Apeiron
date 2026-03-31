extends Node2D

# Script para controlar la lógica del nivel

var objective_scene := preload("res://scenes/mission_objective.tscn")
var objective_instance: Node2D = null

func _ready() -> void:
	# Si hay una misión activa, spawnearel objetivo
	if UpgradeManager.is_mission_active:
		_spawn_objective()

func _spawn_objective() -> void:
	if not objective_scene:
		push_error("No se encontró la escena del objetivo")
		return
	
	objective_instance = objective_scene.instantiate()
	add_child(objective_instance)
	
	if objective_instance.has_signal("objective_reached"):
		objective_instance.objective_reached.connect(_on_objective_reached)

func _on_objective_reached() -> void:
	print("¡Objetivo alcanzado!")
