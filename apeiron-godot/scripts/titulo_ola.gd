extends RichTextLabel

@export var amplitude: float = 8.0
@export var speed: float = 3.0
@export var delay: float = 0.15

var t: float = 0.0
var text_str: String = ""
var char_x_offsets: Array = []

func _ready():
	text_str = text
	visible_characters = -1
	bbcode_enabled = false

	var font := get_theme_font("normal_font")
	var x := 0.0

	char_x_offsets.clear()

	for i in text_str.length():
		var char_unicode := text_str.unicode_at(i)
		var advance := 1
		char_x_offsets.append(x)
		x += advance

func _process(delta: float) -> void:
	t += delta
	queue_redraw()  # reemplaza update()

func _draw() -> void:
	var font := get_theme_font("normal_font")
	var base_y := size.y * 0.5  # rect_size -> size

	for i in text_str.length():
		var char_unicode := text_str.unicode_at(i)
		var wave_time := t - i * delay

		var offset_y := 0.0
		if wave_time > 0:
			offset_y = sin(wave_time * speed) * amplitude

		draw_string(
			font,
			Vector2(char_x_offsets[i], base_y + offset_y),
			text_str.substr(i,1),HORIZONTAL_ALIGNMENT_CENTER
			
		)
