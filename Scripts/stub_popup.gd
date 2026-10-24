extends Control

var mission_node: Node = null

@onready var complete_button = $Panel/VBoxContainer/CompleteButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hide()
	call_deferred("setup_ui")

func setup_ui() -> void:
	show()
	if complete_button and not complete_button.pressed.is_connected(_on_complete_pressed):
		complete_button.pressed.connect(_on_complete_pressed)

func _on_complete_pressed() -> void:
	print("Stub mission completed successfully! Transitioning time...")
	
	# Time transition / jump ahead after successful mission completion
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			var current_time = sky_mat.get_shader_parameter("time_of_day")
			if current_time == null:
				current_time = 12.0
			var new_time = fposmod(current_time + 6.0, 24.0)
			sky_mat.set_shader_parameter("time_of_day", new_time)
			print("Time advanced from ", current_time, " to ", new_time)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
