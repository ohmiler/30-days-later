class_name IsoCamera
extends Node3D
## กล้องมุมมองไอโซเมตริก (orthographic) ที่ตามเป้าหมายอย่างนุ่มนวล
## โครงสร้าง: IsoCamera = จุดที่กล้องมอง (หมุนเอียงไว้)
##            └ Camera3D = ถอยหลังออกไปตามแกน Z แล้วมองกลับมาที่จุดนั้น

## สิ่งที่กล้องจะตาม (ปกติคือ Player)
@export var target: Node3D

@export_group("Angle")
## ก้มลง 30° ให้ได้มุมภาพแบบ 2:1 เหมือน Project Zomboid
@export var pitch_degrees := -30.0
@export var yaw_degrees := 45.0

@export_group("Follow")
## ยิ่งมากกล้องยิ่งตามติด ยิ่งน้อยกล้องยิ่งลอยตามช้าๆ
@export var follow_speed := 8.0

@export_group("Zoom")
## ความสูงของพื้นที่ที่เห็นบนจอ (เมตร) ยิ่งมากยิ่งเห็นกว้าง
@export var zoom := 14.0
@export var min_zoom := 6.0
@export var max_zoom := 30.0
@export var zoom_step := 2.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	camera.position = Vector3(0.0, 0.0, 50.0)
	camera.size = zoom
	if target:
		global_position = target.global_position
	# บอก shader ของกำแพงว่ากล้องมองไปทางไหน (กล้องไม่หมุน จึงตั้งครั้งเดียวพอ)
	RenderingServer.global_shader_parameter_set("camera_forward", -camera.global_basis.z)


func _process(delta: float) -> void:
	if target:
		# ใช้ตำแหน่งแบบ interpolated เพื่อให้ภาพลื่น แม้จอจะรีเฟรชเร็วกว่า physics (60 ครั้ง/วินาที)
		var goal := target.get_global_transform_interpolated().origin
		global_position = global_position.lerp(goal, minf(follow_speed * delta, 1.0))
	camera.size = lerpf(camera.size, zoom, minf(10.0 * delta, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		zoom = clampf(zoom - zoom_step, min_zoom, max_zoom)
	elif event.is_action_pressed("zoom_out"):
		zoom = clampf(zoom + zoom_step, min_zoom, max_zoom)
