extends Area3D

@export var mission_name: String = "Stub Mission"

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not triggered and body.is_in_group("Player"):
		triggered = true
		print("Player entered mission area: ", mission_name)
		
		var popup_scene = load("res://Scenes/stub_popup.tscn")
		if popup_scene:
			var instance = popup_scene.instantiate()
			instance.mission_node = self
			get_tree().root.add_child(instance)
