extends CanvasLayer

@export var indicator_distance: float = 50.0
@export var indicator_size: float = 10.0
@export var update_interval: float = 0.1

var indicators := {}
var update_timer := 0.0
var player: Node2D
func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
func _process(delta):
	if not is_instance_valid(player):
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_indicators()
func update_indicators():
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size
	var camera := viewport.get_camera_2d()
	
	if not camera:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var active_enemies := {}
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var screen_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * enemy.global_position

		var is_on_screen := (
		screen_pos.x >= 0 and screen_pos.x <= viewport_size.x and
		screen_pos.y >= 0 and screen_pos.y <= viewport_size.y
		)

		
		if not is_on_screen:
			active_enemies[enemy] = true
			
			if not indicators.has(enemy):
				create_indicator(enemy)
			
			update_indicator_position(enemy, screen_pos, viewport_size)
	
	var to_remove := []
	for enemy in indicators.keys():
		if not is_instance_valid(enemy) or not active_enemies.has(enemy):
			to_remove.append(enemy)

	for enemy in to_remove:
		var indicator_node = indicators[enemy]["node"]
		if is_instance_valid(indicator_node):
			indicator_node.queue_free()
		indicators.erase(enemy)

func create_indicator(enemy: Node2D):
	var indicator := Control.new()
	indicator.custom_minimum_size = Vector2(indicator_size, indicator_size)
	
	var arrow := ColorRect.new()
	arrow.color = Color(1, 0, 0, 0.85)
	arrow.size = Vector2(indicator_size, indicator_size)
	arrow.pivot_offset = arrow.size / 2
	indicator.add_child(arrow)
	
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(0, indicator_size + 4)
	indicator.add_child(label)
	
	indicators[enemy] = {
		"node": indicator,
		"arrow": arrow,
		"label": label
	}
	
	add_child(indicator)
func update_indicator_position(enemy: Node2D, screen_pos: Vector2, viewport_size: Vector2):
	if not indicators.has(enemy):
		return
	
	var data = indicators[enemy]
	var indicator: Control = data["node"]
	var arrow: Control = data["arrow"]
	var label: Label = data["label"]
	
	var center := viewport_size / 2
	var direction := (screen_pos - center).normalized()
	var margin := indicator_distance
	
	var edge_pos := Vector2.ZERO
	
	if abs(direction.x) > abs(direction.y):
		edge_pos.x = viewport_size.x - margin if direction.x > 0 else margin
		edge_pos.y = center.y + direction.y / abs(direction.x) * (edge_pos.x - center.x)
		edge_pos.y = clamp(edge_pos.y, margin, viewport_size.y - margin)
	else:
		edge_pos.y = viewport_size.y - margin if direction.y > 0 else margin
		edge_pos.x = center.x + direction.x / abs(direction.y) * (edge_pos.y - center.y)
		edge_pos.x = clamp(edge_pos.x, margin, viewport_size.x - margin)
	
	indicator.position = edge_pos - indicator.size / 2
	
	# Rotación hacia el enemigo
	arrow.rotation = direction.angle() + PI / 4
	
	# Distancia
	var distance := player.global_position.distance_to(enemy.global_position)
	label.text = str(int(distance))
func remove_indicator(enemy: Node2D):
	if indicators.has(enemy):
		indicators[enemy]["node"].queue_free()
		indicators.erase(enemy)
