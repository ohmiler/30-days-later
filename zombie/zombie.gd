class_name Zombie
extends CharacterBody3D
## ซอมบี้: เดินเตร่ → ได้ยินเสียงก็ไปดู → เห็นผู้เล่นก็ไล่ → เข้าใกล้ก็กัด
##
## สมองของมันคือ "State Machine": ในแต่ละช่วงเวลาซอมบี้จะอยู่ใน "สถานะ" เดียว
## แต่ละสถานะมีพฤติกรรมของตัวเอง และมีเงื่อนไขว่าจะเปลี่ยนไปสถานะไหนต่อ
##
##   IDLE ──หมดเวลา──▶ WANDER ──ถึงที่หมาย──▶ IDLE
##     │ได้ยินเสียง         │ได้ยินเสียง
##     ▼                    ▼
##   INVESTIGATE ──ถึงจุดที่มีเสียง──▶ IDLE
##     (ทุกสถานะข้างบน ถ้า "เห็นผู้เล่น" ──▶ CHASE)
##   CHASE ──ใกล้พอ──▶ ATTACK ──กัดเสร็จ──▶ CHASE
##   CHASE ──ไปถึงจุดที่เห็นครั้งสุดท้ายแต่ไม่เจอ──▶ IDLE
##   โดนตี ──▶ STAGGER (เซ) ──▶ CHASE        เลือดหมด ──▶ DEAD

enum State { IDLE, WANDER, INVESTIGATE, CHASE, ATTACK, STAGGER, DEAD }

const WORLD_LAYER := 1          # physics layer 1 = "world" (กำแพง ของที่บังสายตา)
const ACCELERATION := 8.0
const REPATH_INTERVAL := 0.25   # ตอนไล่ จะคำนวณเส้นทางใหม่ทุกๆ กี่วินาที (ไม่ต้องทุกเฟรม)
const STAGGER_TIME := 0.5

@export_group("Movement")
@export var wander_speed := 0.8
@export var investigate_speed := 1.4
## ช้ากว่าผู้เล่นเดิน (3.0) นิดหน่อย: เดินหนีได้ แต่ห้ามประมาท
@export var chase_speed := 2.2
@export var turn_speed := 5.0
## เดินเตร่ห่างจากจุด "บ้าน" ได้ไกลแค่ไหน
@export var wander_radius := 6.0

@export_group("Senses")
@export var sight_range := 12.0
## มุมกรวยสายตาทั้งหมด (องศา) ผู้เล่นที่อยู่ข้างหลังจะไม่ถูกเห็น
@export var sight_angle := 120.0

@export_group("Attack")
@export var attack_range := 1.2
@export var attack_damage := 15.0
## เวลาง้างก่อนกัด ถ้าผู้เล่นถอยออกทันจะกัดพลาด
@export var attack_windup := 0.6
@export var attack_recovery := 0.6

var state := State.IDLE
var player: Player
## จุดศูนย์กลางที่ซอมบี้เดินเตร่รอบๆ (ย้ายตามไปเรื่อยๆ เมื่อมันไปตามเสียง)
var home := Vector3.ZERO
var last_seen_position := Vector3.ZERO

var _state_time := 0.0          # อยู่ในสถานะปัจจุบันมากี่วินาทีแล้ว
var _idle_duration := 0.0
var _repath_left := 0.0
var _attack_landed := false
var _base_color := Color.WHITE
var _seen := false
var _fade := 0.0                # 0 = มองไม่เห็นเลย, 1 = เห็นชัด
var _meshes: Array[Node] = []

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var model: Node3D = $Model
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var state_label: Label3D = $StateLabel


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	home = global_position
	rotation.y = randf() * TAU
	_base_color = (body_mesh.material_override as StandardMaterial3D).albedo_color
	_meshes = model.find_children("*", "MeshInstance3D")
	_apply_fade()  # เริ่มเกมมาแบบมองไม่เห็น จนกว่าผู้เล่นจะมองมาเจอ
	health.died.connect(_die)
	NoiseBus.noise_made.connect(_on_noise)
	_enter_state(State.IDLE)


## PlayerVision เรียกทุกเฟรมเพื่อบอกว่าผู้เล่นมองเห็นซอมบี้ตัวนี้ไหม
func set_seen(seen: bool) -> void:
	_seen = seen


func _process(delta: float) -> void:
	# ค่อยๆ ปรากฏ/จางหาย แทนการโผล่ทันที (ศพเห็นตลอด)
	var target := 1.0 if _seen or state == State.DEAD else 0.0
	if _fade != target:
		_fade = move_toward(_fade, target, delta * 4.0)
		_apply_fade()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_state_time += delta

	var sees_player := _can_see_player()
	if sees_player:
		last_seen_position = player.global_position

	match state:
		State.IDLE:
			_slow_to(Vector3.ZERO, delta)
			if sees_player:
				_enter_state(State.CHASE)
			elif _state_time > _idle_duration:
				_enter_state(State.WANDER)

		State.WANDER, State.INVESTIGATE:
			_follow_path(wander_speed if state == State.WANDER else investigate_speed, delta)
			if sees_player:
				_enter_state(State.CHASE)
			elif agent.is_navigation_finished():
				_enter_state(State.IDLE)

		State.CHASE:
			_repath_left -= delta
			if _repath_left <= 0.0:
				_repath_left = REPATH_INTERVAL
				agent.target_position = last_seen_position
			_follow_path(chase_speed, delta)
			if sees_player and _distance_to_player() <= attack_range:
				_enter_state(State.ATTACK)
			elif not sees_player and agent.is_navigation_finished():
				# ไปถึงจุดที่เห็นครั้งสุดท้ายแล้วแต่ไม่เจอ: เลิกไล่ แล้วเดินเตร่แถวนี้แทน
				home = global_position
				_enter_state(State.IDLE)

		State.ATTACK:
			_slow_to(Vector3.ZERO, delta)
			_face(player.global_position - global_position, delta)
			if not _attack_landed and _state_time >= attack_windup:
				_attack_landed = true
				if not player.is_dead and _distance_to_player() <= attack_range + 0.4:
					player.take_damage(attack_damage)
			if _state_time >= attack_windup + attack_recovery:
				_enter_state(State.CHASE)

		State.STAGGER:
			_slow_to(Vector3.ZERO, delta)  # แรงผลักค่อยๆ หมดไป
			if _state_time >= STAGGER_TIME:
				_enter_state(State.CHASE)

	move_and_slide()


## ผู้เล่นตีโดน: ลดเลือด กระเด็นถอยหลัง และหันมาไล่คนตี
func take_hit(damage: float, push: Vector3) -> void:
	if state == State.DEAD:
		return
	_flash()
	health.take_damage(damage)
	if state == State.DEAD:
		return
	velocity.x = push.x
	velocity.z = push.z
	last_seen_position = player.global_position
	_enter_state(State.STAGGER)


func _enter_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	match new_state:
		State.IDLE:
			_idle_duration = randf_range(2.0, 5.0)
		State.WANDER:
			var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * wander_radius
			agent.target_position = home + offset
		State.CHASE:
			_repath_left = 0.0
		State.ATTACK:
			_attack_landed = false
	_update_label()


func _on_noise(origin: Vector3, radius: float) -> void:
	if state in [State.CHASE, State.ATTACK, State.STAGGER, State.DEAD]:
		return
	if global_position.distance_to(origin) <= radius:
		home = origin
		agent.target_position = origin
		_enter_state(State.INVESTIGATE)


## ผู้เล่นต้อง (1) อยู่ในระยะ (2) อยู่ในกรวยสายตา (3) ไม่มีกำแพงบัง
func _can_see_player() -> bool:
	if player == null or player.is_dead:
		return false
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	# กลางคืนซอมบี้ก็มองเห็นได้ใกล้ลงครึ่งหนึ่ง
	if distance > sight_range * lerpf(0.5, 1.0, GameClock.get_daylight()):
		return false
	# ถ้าอยู่ใกล้มากๆ ซอมบี้รู้ตัวแม้ผู้เล่นอยู่ข้างหลัง
	if distance > 1.5:
		var forward := -global_basis.z
		if rad_to_deg(forward.angle_to(to_player)) > sight_angle * 0.5:
			return false
	# ยิงเส้นตรง (raycast) จากตาซอมบี้ไปที่ตัวผู้เล่น ถ้าชนกำแพงก่อนแปลว่ามองไม่เห็น
	var eyes := global_position + Vector3.UP * 1.5
	var target := player.global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(eyes, target, WORLD_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## เดินตามเส้นทางที่ NavigationAgent3D คำนวณให้ (อ้อมกำแพง หาประตูเอง)
func _follow_path(speed: float, delta: float) -> void:
	var direction := Vector3.ZERO
	if not agent.is_navigation_finished():
		direction = agent.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
	_slow_to(direction * speed, delta)
	if direction != Vector3.ZERO:
		_face(direction, delta)


func _slow_to(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, ACCELERATION * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, minf(turn_speed * delta, 1.0))


func _distance_to_player() -> float:
	return global_position.distance_to(player.global_position)


## สัญลักษณ์บนหัว: "?" = ได้ยินอะไรบางอย่าง, "!" = เห็นผู้เล่นแล้ว
func _update_label() -> void:
	match state:
		State.INVESTIGATE:
			state_label.text = "?"
			state_label.modulate = Color(1.0, 0.85, 0.2)
		State.CHASE, State.STAGGER:
			state_label.text = "!"
			state_label.modulate = Color(1.0, 0.25, 0.2)
		State.ATTACK:
			state_label.text = "!!"
			state_label.modulate = Color(1.0, 0.25, 0.2)
		_:
			state_label.text = ""


func _apply_fade() -> void:
	model.visible = _fade > 0.0
	state_label.visible = _fade > 0.5
	for mesh: MeshInstance3D in _meshes:
		mesh.transparency = 1.0 - _fade


func _flash() -> void:
	var material := body_mesh.material_override as StandardMaterial3D
	material.albedo_color = Color(0.9, 0.1, 0.1)
	create_tween().tween_property(material, "albedo_color", _base_color, 0.25)


func _die() -> void:
	_enter_state(State.DEAD)
	remove_from_group("zombies")
	$CollisionShape3D.set_deferred("disabled", true)  # ศพไม่ขวางทาง
	set_physics_process(false)
	# ล้มคว่ำหน้าลงพื้น
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "rotation:x", -PI * 0.5, 0.4)
	tween.tween_property(model, "position:y", 0.3, 0.4)
