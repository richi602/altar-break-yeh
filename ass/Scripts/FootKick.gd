class_name FootKick extends Node3D

@export var anim: AnimationPlayer

signal finish_anim


func _kick(rot: float) -> bool:
	if anim.is_playing():
		return false
	else:
		show()
		rotation_degrees.x = rot + 90
		anim.play("Kick")
		return true


func _on_animation_finished(anim: StringName) -> void:
	hide()
	finish_anim.emit()
