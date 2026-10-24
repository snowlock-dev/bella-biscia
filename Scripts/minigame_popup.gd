extends Control

var mission_node: Node = null
var act_number: int = 1
var failure_count: int = 0

@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var desc_label = $Panel/VBoxContainer/DescLabel
@onready var evidence_box = $Panel/VBoxContainer/EvidenceBox
@onready var cipher_box = $Panel/VBoxContainer/CipherBox
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel
@onready var submit_button = $Panel/VBoxContainer/ButtonBox/SubmitButton
@onready var abort_button = $Panel/VBoxContainer/ButtonBox/AbortButton

var current_evidence_items: Array = [] 
var checkbox_nodes: Array = []
var dial_values: Array = [0, 0, 0]
var target_combination: Array = [3, 8, 5]
var dial_label_nodes: Array = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hide()
	call_deferred("setup_puzzle")

func setup_puzzle() -> void:
	show()
	
	if act_number == 1:
		title_label.text = "ACT I: MORNING PATIO PUZZLE"
		desc_label.text = "Select the 2 true clues from the patio and enter the 3-digit rattle combination."
		target_combination = [3, 8, 5]
		current_evidence_items = [
			{"text": "Tail-drag threading through every puddle", "is_true": true},
			{"text": "Cat slept peacefully through the silent stabbing", "is_true": true},
			{"text": "Fresh hot coffee left on the table", "is_true": false},
			{"text": "A broken wine glass inside the diner", "is_true": false}
		]
	elif act_number == 2:
		title_label.text = "ACT II: AFTERNOON KITCHEN ALIBI"
		desc_label.text = "Inspect Kanes's alibi, select the 2 true clues, and enter the cipher."
		target_combination = [7, 2, 4]
		current_evidence_items = [
			{"text": "Ashtray was bone dry during the heavy rainstorm", "is_true": true},
			{"text": "Fear-molt snake skin shed behind flour sacks", "is_true": true},
			{"text": "Freshly baked sourdough bread on the counter", "is_true": false},
			{"text": "Open cellar door with no footprints", "is_true": false}
		]
	else:
		title_label.text = "ACT III: EVENING ALLEY VAULT"
		desc_label.text = "Examine the alley, find the 2 true clues, and unlock the Emerald Fang vault."
		target_combination = [9, 1, 6]
		current_evidence_items = [
			{"text": "Flagstone wobbles by fence concealing oilskin packet", "is_true": true},
			{"text": "Tail rattled like a watch winding down before the strike", "is_true": true},
			{"text": "A stray dog barking at the autumn moon", "is_true": false},
			{"text": "A rusted iron skeleton key on the barrel", "is_true": false}
		]
	
	current_evidence_items.shuffle()
	
	for child in evidence_box.get_children():
		child.queue_free()
	checkbox_nodes.clear()
	
	for item in current_evidence_items:
		var cb = CheckBox.new()
		cb.text = item["text"]
		evidence_box.add_child(cb)
		checkbox_nodes.append({"node": cb, "is_true": item["is_true"]})
	
	for child in cipher_box.get_children():
		child.queue_free()
	dial_label_nodes.clear()
	
	for i in range(3):
		var dial_container = VBoxContainer.new()
		dial_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var up_btn = Button.new()
		up_btn.text = "▲"
		up_btn.custom_minimum_size = Vector2(40, 30)
		var index = i
		up_btn.pressed.connect(func(): adjust_dial(index, 1))
		dial_container.add_child(up_btn)
		
		var lbl = Label.new()
		lbl.text = str(dial_values[i])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		dial_container.add_child(lbl)
		dial_label_nodes.append(lbl)
		
		var down_btn = Button.new()
		down_btn.text = "▼"
		down_btn.custom_minimum_size = Vector2(40, 30)
		down_btn.pressed.connect(func(): adjust_dial(index, -1))
		dial_container.add_child(down_btn)
		
		cipher_box.add_child(dial_container)
	
	if submit_button and not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	if abort_button and not abort_button.pressed.is_connected(_on_abort_pressed):
		abort_button.pressed.connect(_on_abort_pressed)

func adjust_dial(dial_index: int, delta: int) -> void:
	dial_values[dial_index] = wrapi(dial_values[dial_index] + delta, 0, 10)
	if dial_index < dial_label_nodes.size():
		dial_label_nodes[dial_index].text = str(dial_values[dial_index])

func _on_submit_pressed() -> void:
	var evidence_correct = true
	var selected_true_count = 0
	var selected_false_count = 0
	
	for entry in checkbox_nodes:
		var cb = entry["node"] as CheckBox
		var is_true = entry["is_true"] as bool
		if cb.button_pressed:
			if is_true:
				selected_true_count += 1
			else:
				selected_false_count += 1
	
	if selected_true_count != 2 or selected_false_count > 0:
		evidence_correct = false
	
	var combination_correct = (dial_values == target_combination)
	
	if evidence_correct and combination_correct:
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1))
		feedback_label.text = "✅ Rattle Click! Case Solved Successfully!"
		
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_callback(complete_mission_success)
	else:
		failure_count += 1
		feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
		feedback_label.text = "❌ Incorrect evidence or cipher combination! (-5 minutes penalty)"
		
		DialogueManager.play_dialogue("time_penalty_warning", get_tree().root)
		
		if failure_count >= 3:
			DialogueManager.play_dialogue("time_expired", get_tree().root)
			queue_free()

func _on_abort_pressed() -> void:
	if mission_node:
		mission_node.triggered = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func complete_mission_success() -> void:
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			var current_time = sky_mat.get_shader_parameter("time_of_day")
			if current_time == null:
				current_time = 12.0
			var new_time = fposmod(current_time + 6.0, 24.0)
			sky_mat.set_shader_parameter("time_of_day", new_time)
	
	if act_number < 3:
		DialogueManager.current_act = act_number + 1
		if mission_node:
			mission_node.triggered = false 
	else:
		DialogueManager.play_dialogue("ending_1_true", get_tree().root)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
