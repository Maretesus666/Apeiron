extends Node2D

# Script para controlar la lógica del nivel

var objective_scene := preload("res://scenes/mission_objective.tscn")
var objective_instance: Node2D = null

func _ready() -> void:
	# Esperar un frame para que todo esté inicializado
	await get_tree().process_frame
	
	# Si hay una misión activa, spawnear el objetivo
	if UpgradeManager.is_mission_active:
		print("Misión activa detectada - spawneando objetivo")
		_spawn_objective()
	else:
		print("No hay misión activa")

func _spawn_objective() -> void:
	if not objective_scene:
		push_error("No se encontró la escena del objetivo")
		return
	
	print("Instanciando objetivo...")
	objective_instance = objective_scene.instantiate()
	add_child(objective_instance)
	print("Objetivo spawneado en: ", objective_instance.global_position)
	
	if objective_instance.has_signal("objective_reached"):
		objective_instance.objective_reached.connect(_on_objective_reached)
		print("Señal conectada")

func _on_objective_reached() -> void:
	print("¡Objetivo alcanzado!")
	# El mission_objective.gd ya maneja la lógica de completar la misión
