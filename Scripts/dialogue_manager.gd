extends Node

var dialogue_data: Dictionary = {}
var dialogue_scene = preload("res://Scenes/dialogue_box.tscn")
var active_dialogue_instance = null

func _ready() -> void:
	load_dialogue_file()

func load_dialogue_file() -> void:
	var file = FileAccess.open("res://dialogue_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			dialogue_data = json.get_data()
	else:
		push_error("Could not open dialogue file at res://dialogue_data.json")

func play_dialogue(key: String, parent_node: Node) -> void:
	if not dialogue_data.has(key):
		push_warning("Dialogue key not found: " + key)
		return
	
	# 1. FREE THE MOUSE FOR UI INTERACTION
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if active_dialogue_instance == null:
		active_dialogue_instance = dialogue_scene.instantiate()
		# Connect to cleanup when dialogue finishes
		if not active_dialogue_instance.dialogue_finished.is_connected(_on_dialogue_finished):
			active_dialogue_instance.dialogue_finished.connect(_on_dialogue_finished)
		parent_node.add_child(active_dialogue_instance)
	
	active_dialogue_instance.start_dialogue(dialogue_data[key])

func _on_dialogue_finished() -> void:
	# 2. RE-CAPTURE THE MOUSE WHEN DIALOGUE ENDS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
