extends Area3D

@export var mission_name: String = "Case Investigation"
@export var act_required: int = 1

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_body_entered(body: Node3D) -> void:
	if not triggered and body.is_in_group("Player"):
		if DialogueManager.current_act == act_required:
			triggered = true
			if act_required == 3:
				check_final_syndicate_vault()
			
			var popup_scene = load("res://Scenes/minigame_popup.tscn")
			if popup_scene:
				var instance = popup_scene.instantiate()
				instance.mission_node = self
				instance.act_number = act_required
				get_tree().root.add_child(instance)

func _on_dialogue_ended(key: String) -> void:
	if key == "time_expired" or key == "ending_2_fallback":
		DialogueManager.current_act = 1
		get_tree().reload_current_scene()
	elif key == "ending_1_true":
		DialogueManager.current_act = 1
		get_tree().reload_current_scene()

func check_final_syndicate_vault() -> void:
	pass
