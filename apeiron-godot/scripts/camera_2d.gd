extends Camera2D

@export_category("Follow Character")
@export var jugador: CharacterBody2D

@export_category("Follow Character")
@export var smoothing_enabled: bool
@export_range(1, 10) var smoothing_distance: int = 8

@export_category("Dynamic Zoom")
@export var zoom_min: float = 0.5  # Zoom cuando va rápido (más alejado)
@export var zoom_max: float = 1.0  # Zoom cuando va lento (más cerca)
@export var zoom_speed: float = 1.2  # Velocidad de transición del zoom

var _target_zoom: float = 0.2
var _current_zoom_value: float = 0.2

func _ready() -> void:
	if not jugador:
		jugador = get_tree().get_first_node_in_group("player")
	
	zoom = Vector2(_current_zoom_value, _current_zoom_value)

func _process(delta: float) -> void:
	if not jugador or not is_instance_valid(jugador):
		return
	
	# Calcular zoom basado en velocidad
	var player_speed := jugador.velocity.length()
	var max_speed: float = maxf(jugador.max_speed, 0.001)

	var speed_factor := clampf(player_speed / max_speed, 0.0, 1.0)
	
	# Interpolar zoom: más velocidad = más zoom out (menor zoom value)
	_target_zoom = lerp(zoom_max, zoom_min, speed_factor)
	
	# Suavizar transición de zoom
	_current_zoom_value = lerp(_current_zoom_value, _target_zoom, zoom_speed * delta)
	zoom = Vector2(_current_zoom_value, _current_zoom_value)

# Función pública para que otros nodos puedan consultar el zoom actual
func get_current_zoom() -> float:
	return _current_zoom_value
