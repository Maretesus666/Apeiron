extends Node2D

@export var enemy_scene = preload("res://scenes/enemigo.tscn")
@export var min_spawn_interval: float = 0.0   # Mínimo tiempo entre spawns
@export var max_spawn_interval: float = 5.0  # Máximo tiempo entre spawns
@export var min_distance: float = 10000.0
@export var max_distance: float = 35000.0
@export var max_enemies: int = 30 
@export var min_enemies_per_group: int = 3
@export var max_enemies_per_group: int = 6

enum SpawnPattern {
	RANDOM,      # Posiciones aleatorias
	WAVE,        # Oleadas desde un lado
	CORNERS,     # Desde las esquinas
	FORMATION    # Formación en V o línea
}

@export var spawn_pattern: SpawnPattern = SpawnPattern.RANDOM

var player = null
var spawn_timer: float = 0.0
var current_spawn_interval: float = 8.0
var current_enemies: int = 0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_set_next_spawn_interval()

func _process(delta):
	if not player:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= current_spawn_interval and current_enemies < max_enemies:
		spawn_wave()
		spawn_timer = 0.0
		_set_next_spawn_interval()

func _set_next_spawn_interval() -> void:
	# Tiempo aleatorio entre min y max
	current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)

func spawn_wave():
	# Determinar cuántos enemigos spawnear (3-5)
	var enemies_to_spawn := randi_range(min_enemies_per_group, max_enemies_per_group)
	
	# No exceder el máximo de enemigos
	enemies_to_spawn = mini(enemies_to_spawn, max_enemies - current_enemies)
	
	if enemies_to_spawn <= 0:
		return
	
	# Elegir patrón aleatorio ocasionalmente
	if randf() < 0.3:  # 30% de probabilidad de cambiar patrón
		spawn_pattern = SpawnPattern.values()[randi() % SpawnPattern.size()]
	
	match spawn_pattern:
		SpawnPattern.RANDOM:
			spawn_random_pattern(enemies_to_spawn)
		SpawnPattern.WAVE:
			spawn_wave_pattern(enemies_to_spawn)
		SpawnPattern.CORNERS:
			spawn_corners_pattern(enemies_to_spawn)
		SpawnPattern.FORMATION:
			spawn_formation_pattern(enemies_to_spawn)

func spawn_random_pattern(count: int):
	for i in range(count):
		if current_enemies >= max_enemies:
			break
		var angle = randf() * TAU
		var distance = randf_range(min_distance, max_distance)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		spawn_enemy_at(player.global_position + offset)

func spawn_circle_pattern(count: int):
	var angle_step = TAU / count
	var base_angle = randf() * TAU  # Ángulo inicial aleatorio
	var distance = (min_distance + max_distance) / 2
	
	for i in range(count):
		if current_enemies >= max_enemies:
			break
		var angle = base_angle + angle_step * i
		var offset = Vector2(cos(angle), sin(angle)) * distance
		spawn_enemy_at(player.global_position + offset)

func spawn_wave_pattern(count: int):
	# Spawna desde un lado aleatorio
	var side = randi() % 4  # 0=arriba, 1=derecha, 2=abajo, 3=izquierda
	var distance = (min_distance + max_distance) / 2
	
	# Espaciado entre enemigos
	var spacing = 200.0
	var total_width = spacing * (count - 1)
	var start_offset = -total_width / 2.0
	
	for i in range(count):
		if current_enemies >= max_enemies:
			break
		
		var pos = Vector2.ZERO
		var lateral_offset = start_offset + spacing * i
		
		match side:
			0:  # Arriba
				pos = player.global_position + Vector2(lateral_offset, -distance)
			1:  # Derecha
				pos = player.global_position + Vector2(distance, lateral_offset)
			2:  # Abajo
				pos = player.global_position + Vector2(lateral_offset, distance)
			3:  # Izquierda
				pos = player.global_position + Vector2(-distance, lateral_offset)
		
		spawn_enemy_at(pos)

func spawn_corners_pattern(count: int):
	var corners = [
		Vector2(1, 1),   # Abajo-derecha
		Vector2(-1, 1),  # Abajo-izquierda
		Vector2(1, -1),  # Arriba-derecha
		Vector2(-1, -1)  # Arriba-izquierda
	]
	
	var distance = (min_distance + max_distance) / 2
	
	# Distribuir enemigos en las esquinas
	for i in range(count):
		if current_enemies >= max_enemies:
			break
		var corner = corners[i % corners.size()]
		var pos = player.global_position + corner * distance
		
		# Añadir variación pequeña
		var variation = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		spawn_enemy_at(pos + variation)

func spawn_formation_pattern(count: int):
	# Formación en V o línea
	var is_v_formation = randf() > 0.5
	var angle = randf() * TAU  # Dirección de la formación
	var distance = (min_distance + max_distance) / 2
	
	var forward = Vector2(cos(angle), sin(angle))
	var right = Vector2(-sin(angle), cos(angle))
	
	if is_v_formation:
		# Formación en V
		var spacing = 120.0
		for i in range(count):
			if current_enemies >= max_enemies:
				break
			
			var depth_offset = abs(i - count / 2) * spacing * 0.5
			var lateral_offset = (i - count / 2) * spacing
			
			var pos = player.global_position + forward * (distance + depth_offset) + right * lateral_offset
			spawn_enemy_at(pos)
	else:
		# Línea horizontal
		var spacing = 150.0
		var total_width = spacing * (count - 1)
		var start_offset = -total_width / 2.0
		
		for i in range(count):
			if current_enemies >= max_enemies:
				break
			
			var lateral_offset = start_offset + spacing * i
			var pos = player.global_position + forward * distance + right * lateral_offset
			spawn_enemy_at(pos)

func spawn_enemy_at(pos: Vector2):
	if not enemy_scene:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	
	# Conectar señal de muerte para actualizar contador
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_died)
	
	get_parent().add_child(enemy)
	current_enemies += 1

func _on_enemy_died():
	current_enemies -= 1

# Función para aumentar dificultad progresivamente
func increase_difficulty():
	# Reducir tiempos mínimos y máximos
	min_spawn_interval = maxf(3.0, min_spawn_interval - 0.5)
	max_spawn_interval = maxf(6.0, max_spawn_interval - 0.5)
	
	# Aumentar tamaño de grupos gradualmente
	if max_enemies_per_group < 8:
		max_enemies_per_group += 1
	
	# Aumentar máximo de enemigos en pantalla
	if max_enemies < 30:
		max_enemies += 2

# Función para reducir dificultad (útil si el jugador está perdiendo mucho)
func decrease_difficulty():
	min_spawn_interval = minf(15.0, min_spawn_interval + 1.0)
	max_spawn_interval = minf(20.0, max_spawn_interval + 1.0)
	
	if max_enemies_per_group > 3:
		max_enemies_per_group -= 1
	
	if max_enemies > 12:
		max_enemies -= 2
