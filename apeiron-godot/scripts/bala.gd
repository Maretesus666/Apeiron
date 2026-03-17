extends Area2D

@export var base_speed: float = 1000.0
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0
var damage: int = 1  # Daño base, puede ser modificado por upgrades

func _ready():
	add_to_group("player_bullet")
	
	# Leer el daño desde metadata si fue pasado
	if has_meta("damage"):
		damage = get_meta("damage")

func _physics_process(delta):
	position += velocity * delta
	
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()

func initialize(player_velocity: Vector2, bullet_rotation: float):
	var bullet_direction = Vector2.RIGHT.rotated(bullet_rotation)
	velocity = bullet_direction * base_speed + player_velocity
	rotation = bullet_rotation

# Función para obtener el daño (usada por los enemigos)
func get_damage() -> int:
	return damage
