extends Control

var center_vp := Vector2.ZERO
var allow_redraw := false

func set_center(pos: Vector2) -> void:
    center_vp = pos
    queue_redraw()

func set_allow_redraw(in_effect: bool):
    allow_redraw = in_effect
    queue_redraw()

func _draw():
    if center_vp != Vector2.ZERO and allow_redraw:
        draw_circle(center_vp, 10, Color.RED)


