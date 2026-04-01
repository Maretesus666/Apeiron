extends Area2D

signal objective_reached

@export var min_distance: float = 3000.0
@export var max_distance: float = 8000.0

func _ready() -> void:
	add_to_group("objective")
	_place_randomly()

func _place_randomly() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var angle := randf() * TAU
	var distance := randf_range(min_distance, max_distance)
	global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		objective_reached.emit()
		UpgradeManager.complete_mission()
		queue_free()
