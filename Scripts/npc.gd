extends StaticBody3D

@export var npc_name: String = "Kanes"
@export var dialogue_key: String = "default"

@onready var interaction_area: Area3D = $InteractionArea

var player_in_range: bool = false

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	print("Entered body: ", body.name, " | In group Player? ", body.is_in_group("Player"))
	if body.is_in_group("Player"):
		player_in_range = true
		print("Player is now in range of ", npc_name)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		print("Player left range of ", npc_name)

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		print("Interact key pressed for ", npc_name)
		DialogueManager.play_dialogue(dialogue_key, get_tree().root)
