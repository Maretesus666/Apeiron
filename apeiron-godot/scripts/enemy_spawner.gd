extends Node2D

@export var enemy_scene = preload("res://scenes/enemigo.tscn")
@export var spawn_interval = 2.0
@export var min_distance = 1000.0
@export var max_distance = 15000.0
@export var max_enemies = 15

enum SpawnPattern {
	RANDOM,      # Posiciones aleatorias
	CIRCLE,      # Círculo alrededor del jugador
	WAVE,        # Oleadas desde un lado
	CORNERS      # Desde las esquinas
}

@export var spawn_pattern: SpawnPattern = SpawnPattern.RANDOM
@export var enemies_per_spawn = 3

var player = null
var spawn_timer = 0.0
var current_enemies = 0

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if not player:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemies < max_enemies:
		spawn_wave()
		spawn_timer = 0.0

func spawn_wave():
	match spawn_pattern:
		SpawnPattern.RANDOM:
			spawn_random_pattern()
		SpawnPattern.CIRCLE:
			spawn_circle_pattern()
		SpawnPattern.WAVE:
			spawn_wave_pattern()
		SpawnPattern.CORNERS:
			spawn_corners_pattern()

func spawn_random_pattern():
	for i in range(enemies_per_spawn):
		if current_enemies >= max_enemies:
			break
		var angle = randf() * TAU
		var distance = randf_range(min_distance, max_distance)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		spawn_enemy_at(player.global_position + offset)

func spawn_circle_pattern():
	var angle_step = TAU / enemies_per_spawn
	for i in range(enemies_per_spawn):
		if current_enemies >= max_enemies:
			break
		var angle = angle_step * i
		var distance = (min_distance + max_distance) / 2
		var offset = Vector2(cos(angle), sin(angle)) * distance
		spawn_enemy_at(player.global_position + offset)

func spawn_wave_pattern():
	# Spawna desde un lado aleatorio
	var side = randi() % 4  # 0=arriba, 1=derecha, 2=abajo, 3=izquierda
	
	for i in range(enemies_per_spawn):
		if current_enemies >= max_enemies:
			break
		
		var pos = Vector2.ZERO
		var spread = randf_range(-200, 200)
		
		match side:
			0:  # Arriba
				pos = player.global_position + Vector2(spread, -max_distance)
			1:  # Derecha
				pos = player.global_position + Vector2(max_distance, spread)
			2:  # Abajo
				pos = player.global_position + Vector2(spread, max_distance)
			3:  # Izquierda
				pos = player.global_position + Vector2(-max_distance, spread)
		
		spawn_enemy_at(pos)

func spawn_corners_pattern():
	var corners = [
		Vector2(1, 1),   # Abajo-derecha
		Vector2(-1, 1),  # Abajo-izquierda
		Vector2(1, -1),  # Arriba-derecha
		Vector2(-1, -1)  # Arriba-izquierda
	]
	
	var count = min(enemies_per_spawn, 4)
	for i in range(count):
		if current_enemies >= max_enemies:
			break
		var corner = corners[i]
		var distance = (min_distance + max_distance) / 2
		var pos = player.global_position + corner * distance
		spawn_enemy_at(pos)

func spawn_enemy_at(pos: Vector2):
	if not enemy_scene:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_died)
	
	get_parent().add_child(enemy)
	current_enemies += 1

func _on_enemy_died():
	current_enemies -= 1

# Función para cambiar dificultad
func increase_difficulty():
	spawn_interval = max(0.5, spawn_interval - 0.2)
	enemies_per_spawn = min(6, enemies_per_spawn + 1)
