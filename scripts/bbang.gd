extends Node2D
## 빠방 화면. 경찰차/구급차/불도저/트럭과 꼬마버스 타요 친구들
## (타요/로기/가니/라니/씨투)이 화면 사방에서 나타나 가로질러 지나간다.
## 노드 구조: VehicleContainer / SpawnTimer / UILayer/MenuButton (Vehicle.tscn 인스턴싱).

var vehicle_scene: PackedScene = preload("res://scenes/Vehicle.tscn")

const VEHICLE_TYPES: Array = [
	Vehicle.VehicleType.POLICE_CAR,
	Vehicle.VehicleType.AMBULANCE,
	Vehicle.VehicleType.BULLDOZER,
	Vehicle.VehicleType.TRUCK,
	Vehicle.VehicleType.TAYO,
	Vehicle.VehicleType.ROGI,
	Vehicle.VehicleType.GANI,
	Vehicle.VehicleType.LANI,
	Vehicle.VehicleType.CITU,
]

func _ready() -> void:
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	$UILayer/MenuButton.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_spawn_timer_timeout() -> void:
	spawn_vehicle()

func spawn_vehicle() -> void:
	var v := vehicle_scene.instantiate()
	# 사방(0=아래,1=위,2=왼쪽,3=오른쪽) 중 랜덤한 변에서 스폰 → 반대편으로 가로지름
	var edge := randi_range(0, 3)
	var spawn_pos: Vector2
	var dir: Vector2
	match edge:
		0:
			spawn_pos = Vector2(randf_range(80.0, 640.0), 1360.0)
			dir = Vector2.UP
		1:
			spawn_pos = Vector2(randf_range(80.0, 640.0), -80.0)
			dir = Vector2.DOWN
		2:
			spawn_pos = Vector2(-80.0, randf_range(120.0, 1160.0))
			dir = Vector2.RIGHT
		_:
			spawn_pos = Vector2(800.0, randf_range(120.0, 1160.0))
			dir = Vector2.LEFT
	dir = dir.rotated(randf_range(-0.3, 0.3))
	v.position = spawn_pos
	var type: Vehicle.VehicleType = VEHICLE_TYPES[randi_range(0, VEHICLE_TYPES.size() - 1)]
	v.setup(type, dir)
	$VehicleContainer.add_child(v)
