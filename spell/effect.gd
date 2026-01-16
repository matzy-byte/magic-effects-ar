extends Node3D

func _ready() -> void:
    get_node("AnimationPlayer").play("init")