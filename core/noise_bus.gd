extends Node
## ระบบเสียง (Autoload: เรียกได้จากทุกที่ด้วยชื่อ NoiseBus ดูได้ที่ Project Settings > Globals)
## ใครทำเสียงก็เรียก NoiseBus.make_noise(ตำแหน่ง, รัศมี)
## ซอมบี้ทุกตัวฟัง signal "noise_made" อยู่ ถ้าอยู่ในรัศมีจะเดินมาดู

signal noise_made(origin: Vector3, radius: float)

## วาดวงแหวนให้เห็นว่าเสียงไปไกลแค่ไหน (ไว้ดีบัก เปลี่ยนเป็น false เพื่อปิด)
var show_rings := true

var _ring_material: StandardMaterial3D


func _ready() -> void:
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_color = Color(1.0, 0.9, 0.5, 0.5)


func make_noise(origin: Vector3, radius: float) -> void:
	noise_made.emit(origin, radius)
	if show_rings:
		_spawn_ring(origin, radius)


func _spawn_ring(origin: Vector3, radius: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.05
	mesh.outer_radius = radius
	mesh.rings = 48
	mesh.ring_segments = 4
	mesh.material = _ring_material

	var ring := MeshInstance3D.new()
	ring.mesh = mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(ring)
	ring.global_position = origin + Vector3.UP * 0.05

	# ค่อยๆ จางหายแล้วลบทิ้ง
	var tween := ring.create_tween()
	tween.tween_property(ring, "transparency", 1.0, 0.6)
	tween.tween_callback(ring.queue_free)
