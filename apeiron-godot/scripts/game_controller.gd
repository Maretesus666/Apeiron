extends Node2D

var objective_scene := preload("res://scenes/mission_objective.tscn")
var objective_instance: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	
	UpgradeManager.mission_completed.connect(_on_mission_completed)
	
	if UpgradeManager.is_mission_active:
		_spawn_objective()

func _spawn_objective() -> void:
	if not objective_scene:
		return
	objective_instance = objective_scene.instantiate()
	add_child(objective_instance)

func _on_mission_completed(reward: int) -> void:
	var pause_menu = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu:
		pause_menu.show_mission_complete(reward)
