extends Area2D

# Configuración del enemigo
@export var speed = 150.0  # Velocidad de movimiento
@export var health = 3  # Vida del enemigo
@export var damage = 1  # Daño que causa al jugador

var player = null  # Referencia al jugador

func _ready():
	# Conectar señales
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Buscar al jugador en la escena
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player:
		# Calcular dirección hacia el jugador
		var direction = (player.global_position - global_position).normalized()
		
		# Mover hacia el jugador
		global_position += direction * speed * delta
		
		# Opcional: rotar el enemigo hacia el jugador
		rotation = direction.angle()

func take_damage(amount: int):
	health -= amount
	
	# Efecto visual opcional (parpadeo)
	flash_effect()
	
	if health <= 0:
		die()

func die():
	# Aquí puedes añadir efectos de muerte
	# Por ejemplo: explosión, sonido, partículas
	queue_free()  # Eliminar el enemigo

func flash_effect():
	# Efecto de parpadeo al recibir daño
	modulate = Color(1, 0, 0)  # Rojo
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)  # Volver a normal

func _on_body_entered(body):
	# Si choca con el jugador
	if body.is_in_group("player"):
		# Aquí puedes hacer daño al jugador
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()  # El enemigo muere al chocar

func _on_area_entered(area):
	# Si es una bala del jugador
	if area.is_in_group("player_bullet"):
		take_damage(1)
		area.queue_free()  # Destruir la bala
