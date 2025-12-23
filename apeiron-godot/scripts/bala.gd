extends Area2D

@export var base_speed: float = 1000.0
@export var lifetime: float = 5.0  # Segundos antes de destruirse

var velocity: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0

func _ready():
	add_to_group("player_bullet")

func _physics_process(delta):
	# Mover la bala
	position += velocity * delta
	
	# Contar tiempo de vida
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()

# Función para inicializar la bala con la velocidad del jugador
func initialize(player_velocity: Vector2, bullet_rotation: float):
	# Dirección base de la bala
	var bullet_direction = Vector2.RIGHT.rotated(bullet_rotation)
	
	# Velocidad de la bala = velocidad base + velocidad del jugador
	velocity = bullet_direction * base_speed + player_velocity
	
	rotation = bullet_rotation
