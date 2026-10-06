class_name PlayerVision
extends Node3D
## การมองเห็นของผู้เล่น (แบบ Project Zomboid)
## 1) ยิงเส้น (raycast) รอบตัว 360° หาว่าแต่ละทิศมองไปได้ไกลแค่ไหนก่อนชนกำแพง
## 2) ส่งข้อมูลให้ shader ที่ทับทั้งจอ (Overlay) ทำให้ส่วนที่มองไม่เห็นมืดลง
## 3) ซ่อนซอมบี้ที่ผู้เล่นมองไม่เห็น

const RAY_COUNT := 240  # ต้องตรงกับ RAY_COUNT ใน vision_overlay.gdshader
const WORLD_LAYER := 1

@export var player: Player
## ปิดเพื่อดีบัก: เห็นทั้งแมพและซอมบี้ทุกตัว
@export var enabled := true
## มุมกรวยสายตาด้านหน้า (องศา)
@export var fov_degrees := 150.0
## ระยะรอบตัวที่รู้สึกได้แม้อยู่ข้างหลัง (เมตร)
@export var near_radius := 2.0
@export var view_distance := 30.0
## ความสูงของสายตา ของที่เตี้ยกว่านี้ (โต๊ะ รั้ว) จะไม่บังสายตา แต่หน้าต่างมองลอดได้
@export var eye_height := 1.4

var _distances := PackedFloat32Array()
var _eye := Vector3.ZERO
var _facing_angle := 0.0
var _query := PhysicsRayQueryParameters3D.new()

@onready var overlay: MeshInstance3D = $Overlay
@onready var _material := overlay.material_override as ShaderMaterial


func _ready() -> void:
	_distances.resize(RAY_COUNT)
	_distances.fill(view_distance)
	_query.collision_mask = WORLD_LAYER
	_material.set_shader_parameter("half_fov", deg_to_rad(fov_degrees) * 0.5)
	_material.set_shader_parameter("near_radius", near_radius)
	_material.set_shader_parameter("view_distance", view_distance)


func _physics_process(_delta: float) -> void:
	overlay.visible = enabled
	if player == null:
		return
	_cast_rays(player.global_position + Vector3.UP * eye_height)
	_material.set_shader_parameter("ray_distances", _distances)
	for zombie: Zombie in get_tree().get_nodes_in_group("zombies"):
		zombie.set_seen(not enabled or can_see(zombie.global_position + Vector3.UP))


func _process(_delta: float) -> void:
	if player == null:
		return
	# ใช้ตำแหน่ง/ทิศแบบ interpolated ให้กรวยสายตาขยับลื่นตามตัวละคร
	var xform := player.get_global_transform_interpolated()
	var forward := -xform.basis.z
	_eye = xform.origin + Vector3.UP * eye_height
	_facing_angle = atan2(forward.z, forward.x)
	_material.set_shader_parameter("eye_position", _eye)
	_material.set_shader_parameter("facing_angle", _facing_angle)


## ผู้เล่นมองเห็นจุดนี้ไหม (ใช้กฎเดียวกับ shader: อยู่ในระยะ + ในกรวยหรือใกล้ตัว + ไม่มีกำแพงบัง)
func can_see(point: Vector3) -> bool:
	var to_point := Vector2(point.x - _eye.x, point.z - _eye.z)
	var distance := to_point.length()
	if distance > view_distance:
		return false
	var angle := atan2(to_point.y, to_point.x)
	if distance > near_radius and absf(angle_difference(_facing_angle, angle)) > deg_to_rad(fov_degrees) * 0.5:
		return false
	return distance <= _clear_distance(angle) + 0.3


func _cast_rays(eye: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	_query.from = eye
	for i in RAY_COUNT:
		var angle := TAU * i / RAY_COUNT
		_query.to = eye + Vector3(cos(angle), 0.0, sin(angle)) * view_distance
		var hit := space.intersect_ray(_query)
		_distances[i] = view_distance if hit.is_empty() else eye.distance_to(hit.position)


## ระยะที่มองไปได้ในทิศ angle (เกลี่ยระหว่างเส้นที่ยิงไว้ 2 เส้นที่ใกล้ที่สุด)
func _clear_distance(angle: float) -> float:
	var f := wrapf(angle, 0.0, TAU) / TAU * RAY_COUNT
	var i0 := int(f) % RAY_COUNT
	var i1 := (i0 + 1) % RAY_COUNT
	return lerpf(_distances[i0], _distances[i1], f - floorf(f))
