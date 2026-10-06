extends Node3D
## บ้าน 1 หลัง: ซ่อนหลังคาเมื่อผู้เล่นเดินเข้าไปข้างใน จะได้มองเห็นภายในบ้าน (แบบ Project Zomboid)
## ต้องมีลูกชื่อ "Roof" (หลังคา) และ "Interior" (Area3D ครอบพื้นที่ในบ้าน)

@export var fade_time := 0.3

var _tween: Tween

@onready var roof: GeometryInstance3D = $Roof
@onready var interior: Area3D = $Interior


func _ready() -> void:
	interior.body_entered.connect(_on_body_entered)
	interior.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_fade_roof(false)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_fade_roof(true)


func _fade_roof(show_roof: bool) -> void:
	if _tween:
		_tween.kill()
	roof.visible = true
	_tween = create_tween()
	_tween.tween_property(roof, "transparency", 0.0 if show_roof else 1.0, fade_time)
	if not show_roof:
		_tween.tween_callback(roof.hide)
