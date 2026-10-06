class_name Player
extends CharacterBody3D
## ตัวละครผู้เล่น: เดิน วิ่ง เล็ง (คลิกขวาค้าง = หันตามเมาส์ เหมือน Project Zomboid) และฟัน (คลิกซ้าย)

@export_group("Movement")
## ความเร็วเดิน (เมตร/วินาที)
@export var walk_speed := 3.0
## ความเร็ววิ่ง (กด Shift)
@export var run_speed := 6.0
## ตอนเล็งจะเดินช้าลง
@export var aim_speed := 1.8
## เร่ง/ชะลอเร็วแค่ไหน ยิ่งมากยิ่งหยุดและออกตัวไว
@export var acceleration := 30.0
## ความเร็วในการหันตัว
@export var turn_speed := 12.0

@export_group("Combat")
@export var attack_damage := 34.0
## ต้องรอกี่วินาทีถึงจะฟันครั้งต่อไปได้
@export var attack_cooldown := 0.6
## ฟันโดนหลังจากกดไปกี่วินาที (ตรงกลางท่าเหวี่ยง)
@export var attack_windup := 0.1
## แรงผลักซอมบี้ให้ถอยหลังเมื่อโดนตี
@export var knockback := 4.0

@export_group("Noise")
## รัศมีเสียงฝีเท้าตอนเดิน (เมตร) ซอมบี้ในรัศมีนี้จะได้ยิน
@export var walk_noise := 3.0
## วิ่งเสียงดังกว่ามาก ระวังซอมบี้ทั้งละแวก!
@export var run_noise := 10.0
@export var attack_noise := 6.0

const FOOTSTEP_INTERVAL := 0.4
const SWING_TIME := 0.3
const WEAPON_REST := Vector3(-0.5, 0.3, 0.0)

var is_running := false
var is_aiming := false
var is_dead := false

var _cooldown_left := 0.0
var _swing_left := 0.0       # ระหว่างท่าฟัน จะไม่หันตัวตามทิศเดิน
var _footstep_left := 0.0

@onready var health: Health = $Health
@onready var model: Node3D = $Model
@onready var weapon_pivot: Node3D = $Model/WeaponPivot
@onready var attack_area: Area3D = $AttackArea


func _ready() -> void:
	health.died.connect(_on_died)
	weapon_pivot.rotation = WEAPON_REST


func _physics_process(delta: float) -> void:
	# แรงโน้มถ่วง: ถ้าไม่ได้ยืนบนพื้นให้ตกลง
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# อ่านปุ่ม WASD เป็น Vector2 แล้วแปลงเป็นทิศในโลก 3D ตามมุมกล้อง
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := _camera_relative(input)

	is_aiming = Input.is_action_pressed("aim")
	is_running = Input.is_action_pressed("run") and not is_aiming and direction != Vector3.ZERO

	var speed := walk_speed
	if is_aiming:
		speed = aim_speed
	elif is_running:
		speed = run_speed

	# ค่อยๆ เปลี่ยนความเร็วไปหาความเร็วเป้าหมาย ตัวละครจะไม่หยุดหรือออกตัวแบบกระตุก
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	_update_footsteps(delta)
	_update_attack(delta)

	# ตอนเล็งให้หันตามเมาส์ ถ้าไม่เล็งให้หันไปทางที่เดิน (ระหว่างฟันไม่หัน)
	var look_direction: Vector3 = _mouse_direction() if is_aiming else direction
	if look_direction != Vector3.ZERO and _swing_left <= 0.0:
		# ใน Godot "ด้านหน้า" ของ Node คือแกน -Z
		var target_angle := atan2(-look_direction.x, -look_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(turn_speed * delta, 1.0))


func _process(_delta: float) -> void:
	# ส่งตำแหน่งผู้เล่น (ระดับอก) ให้ shader ของกำแพง เพื่อเจาะกำแพงที่บังตัวละคร
	var chest := get_global_transform_interpolated().origin + Vector3.UP * 0.9
	RenderingServer.global_shader_parameter_set("player_position", chest)


func take_damage(amount: float) -> void:
	health.take_damage(amount)


## ทุกๆ 0.4 วินาทีที่ขยับ จะปล่อยเสียงฝีเท้าออกไป (วิ่ง = ดังกว่า)
func _update_footsteps(delta: float) -> void:
	_footstep_left -= delta
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	if moving and _footstep_left <= 0.0:
		_footstep_left = FOOTSTEP_INTERVAL
		NoiseBus.make_noise(global_position, run_noise if is_running else walk_noise)


func _update_attack(delta: float) -> void:
	_cooldown_left -= delta
	_swing_left -= delta
	if Input.is_action_just_pressed("attack") and _cooldown_left <= 0.0:
		_start_attack()


func _start_attack() -> void:
	_cooldown_left = attack_cooldown
	_swing_left = SWING_TIME
	# หันไปทางเมาส์ทันที แล้วเหวี่ยงอาวุธจากขวาไปซ้าย
	var direction := _mouse_direction()
	if direction != Vector3.ZERO:
		rotation.y = atan2(-direction.x, -direction.z)
	weapon_pivot.rotation = Vector3(0.0, -1.3, 0.0)
	var tween := create_tween()
	tween.tween_property(weapon_pivot, "rotation", Vector3(0.0, 1.1, 0.0), 0.15)
	tween.tween_property(weapon_pivot, "rotation", WEAPON_REST, 0.2)
	NoiseBus.make_noise(global_position, attack_noise)
	# รอจังหวะกลางท่าเหวี่ยง แล้วค่อยเช็กว่าโดนใคร
	get_tree().create_timer(attack_windup, false, true).timeout.connect(_land_attack)


## ซอมบี้ทุกตัวที่อยู่ในกล่อง AttackArea (ด้านหน้าตัวละคร) จะโดนตี
func _land_attack() -> void:
	if is_dead:
		return
	var push := -global_basis.z * knockback
	for body in attack_area.get_overlapping_bodies():
		if body is Zombie:
			body.take_hit(attack_damage, push)


func _on_died() -> void:
	is_dead = true
	# ล้มลงไปนอนกับพื้น
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "rotation:x", PI * 0.5, 0.5)
	tween.tween_property(model, "position:y", 0.3, 0.5)


## แปลงปุ่มกดให้ "ขึ้น" = ขึ้นบนจอ ไม่ใช่แกน -Z ของโลก (เพราะกล้องหมุนอยู่ 45°)
func _camera_relative(input: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input.x, 0.0, input.y)
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	return right * input.x - forward * input.y


## ยิงเส้นจากกล้องผ่านเมาส์ แล้วคืนทิศจากผู้เล่นไปยังจุดที่เส้นนั้นชน
## ใช้ระนาบที่ความสูงระดับอก ไม่ใช่พื้น เพราะผู้เล่นจะคลิกที่ "ตัว" ซอมบี้ ไม่ใช่ที่เท้า
## (ถ้าใช้พื้น จุดที่ได้จะเลยไปด้านหลังซอมบี้เกือบ 2 เมตร เพราะกล้องมองเฉียง ทำให้ฟันพลาด)
func _mouse_direction() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var aim_plane := Plane(Vector3.UP, global_position.y + 1.0)
	var hit: Variant = aim_plane.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
	if hit == null:
		return Vector3.ZERO
	var to_mouse: Vector3 = hit - global_position
	to_mouse.y = 0.0
	if to_mouse.length() < 0.1:
		return Vector3.ZERO
	return to_mouse.normalized()
