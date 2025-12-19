extends Camera2D


@export_category("Follow Character")
@export var jugador : CharacterBody2D

@export_category("Follow Character")
@export var smoothing_enabled : bool
@export_range(1, 10) var smoothing_distance: int =8
 
