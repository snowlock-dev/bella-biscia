extends Control

signal dialogue_finished

@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $Panel/VBoxContainer/TextLabel
@onready var next_button: Button = $Panel/VBoxContainer/NextButton

var current_dialogue: Array = []
var index: int = 0
var tween: Tween
var default_speed: float = 0.03 

func _ready() -> void:
	hide()
	next_button.pressed.connect(_on_next_pressed)

func start_dialogue(dialogue_array: Array) -> void:
	current_dialogue = dialogue_array
	index = 0
	show()
	display_line()

func display_line() -> void:
	if index < current_dialogue.size():
		var line = current_dialogue[index]
		name_label.text = line["speaker"]
		text_label.text = line["text"]
		
		# Apply custom font if provided
		if line.has("font_path") and line["font_path"] != "":
			var custom_font = load(line["font_path"])
			if custom_font:
				text_label.add_theme_font_override("normal_font", custom_font)
		else:
			text_label.remove_theme_font_override("normal_font")
		
		# Typewriter effect
		var speed = line.get("text_speed", default_speed)
		run_typewriter_effect(line["text"], speed)
	else:
		hide()
		dialogue_finished.emit()

func run_typewriter_effect(full_text: String, speed: float) -> void:
	if tween and tween.is_running():
		tween.kill()
	
	text_label.text = full_text
	text_label.visible_characters = 0
	
	var total_chars = full_text.length()
	tween = create_tween()
	tween.tween_property(text_label, "visible_characters", total_chars, total_chars * speed)

func _on_next_pressed() -> void:
	if tween and tween.is_running():
		tween.kill()
		text_label.visible_characters = -1 # Skip to end of line
	else:
		index += 1
		display_line()
