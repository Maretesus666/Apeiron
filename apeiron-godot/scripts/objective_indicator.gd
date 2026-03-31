extends Control

# Indicador que muestra la dirección del objetivo de misión

@export var arrow_distance: float = 100.0
@export var arrow_size: float = 30.0

var player: Node2D = null
var objective: Node2D = null
var arrow_color := Color(0.3, 1.0, 0.5)

func _ready() -> void:
	custom_minimum_size = Vector2(200, 200)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	_find_objective()

func _find_objective() -> void:
	var objectives := get_tree().get_nodes_in_group("objective")
	if objectives.size() > 0:
		objective = objectives[0]

func _draw() -> void:
	if not is_instance_valid(player) or not is_instance_valid(objective):
		return
	
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	
	# Dirección hacia el objetivo
	var dir := (objective.global_position - player.global_position).normalized()
	
	# Posición de la flecha en el borde
	var arrow_pos := center + dir * arrow_distance
	
	# Dibujar flecha
	var arrow_angle := dir.angle()
	var point1 := arrow_pos
	var point2 := arrow_pos + Vector2(cos(arrow_angle + 2.5), sin(arrow_angle + 2.5)) * arrow_size
	var point3 := arrow_pos + Vector2(cos(arrow_angle - 2.5), sin(arrow_angle - 2.5)) * arrow_size
	
	draw_polygon(PackedVector2Array([point1, point2, point3]), PackedColorArray([arrow_color]))
	draw_polyline(PackedVector2Array([point1, point2, point3, point1]), arrow_color, 2.0)
	
	# Distancia al objetivo
	var dist := player.global_position.distance_to(objective.global_position)
	var dist_text := "%.0fm" % (dist / 100.0)
	
	var font := load("res://assets/fonts/ultrakill.ttf")
	if font:
		draw_string(font, arrow_pos + Vector2(-30, 50), dist_text, 
			HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(0.3, 1.0, 0.5))

func _process(_delta: float) -> void:
	if not is_instance_valid(objective):
		_find_objective()
	queue_redraw()
