extends Control

const OpcionesScene := preload("res://scripts/opciones.gd")

func _ready() -> void:
	pass

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_opciones_pressed() -> void:
	var opciones := Control.new()
	opciones.set_script(OpcionesScene)
	opciones.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opciones)
	opciones.closed.connect(func(): pass)  # ya se libera solo

func _on_salir_pressed() -> void:
	get_tree().quit()
