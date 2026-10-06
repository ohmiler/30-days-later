extends CanvasLayer
## HUD: แถบพลังชีวิต, จำนวนซอมบี้, จอแดงตอนโดนกัด และหน้าจอตอนตาย
## HUD ไม่ต้องเช็กเลือดผู้เล่นทุกเฟรม แค่ "ฟัง" signal จาก Health ของผู้เล่น

@export var player: Player

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_flash: ColorRect = $DamageFlash
@onready var zombie_count: Label = $ZombieCount
@onready var death_screen: Control = $DeathScreen


func _ready() -> void:
	damage_flash.modulate.a = 0.0
	death_screen.visible = false
	health_bar.max_value = player.health.max_health
	health_bar.value = player.health.current
	player.health.changed.connect(_on_player_health_changed)
	player.health.died.connect(_on_player_died)


func _process(_delta: float) -> void:
	zombie_count.text = "ซอมบี้: %d" % get_tree().get_nodes_in_group("zombies").size()


func _unhandled_input(event: InputEvent) -> void:
	if death_screen.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_health_changed(current: float, _maximum: float) -> void:
	if current < health_bar.value:
		damage_flash.modulate.a = 1.0
		create_tween().tween_property(damage_flash, "modulate:a", 0.0, 0.4)
	health_bar.value = current


func _on_player_died() -> void:
	death_screen.visible = true
