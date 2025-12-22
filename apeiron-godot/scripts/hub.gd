extends Control

@onready var tab_container = $TabContainer
@onready var clicker_tab = $TabContainer/Clicker
@onready var game_info_tab = $TabContainer/Juego

func _ready():
	# El TabContainer maneja el cambio entre tabs automáticamente
	pass

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_click_button_pressed() -> void:
	pass # Replace with function body.


func _on_start_game_button_pressed() -> void:
	pass # Replace with function body.
