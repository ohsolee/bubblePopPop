extends Area2D
class_name Vehicle
## 빠방 화면에 등장하는 탈것 1개. 경찰차/구급차/불도저/트럭 및
## 꼬마버스 타요 친구들(타요/로기/가니/라니/씨투)이 화면을 가로지르며,
## 터치하면 사라진다.
##
## 실제 그림이 아직 없을 때는 종류별 색상을 입힌 임시 아이콘으로 표시된다.
## assets/sprites/ 에 아래 TEXTURE_PATHS의 파일명으로 이미지를 넣으면
## 코드 수정 없이 자동으로 실제 그림으로 교체된다.

signal popped(pos: Vector2, vehicle_type: VehicleType)

enum VehicleType {
	POLICE_CAR,
	AMBULANCE,
	BULLDOZER,
	TRUCK,
	TAYO,
	ROGI,
	GANI,
	LANI,
	CITU,
}

## 실제 이미지 경로(디자이너가 이 이름 그대로 assets/sprites/에 넣으면 자동 적용)
const TEXTURE_PATHS := {
	VehicleType.POLICE_CAR: "res://assets/sprites/spr_police_car.png",
	VehicleType.AMBULANCE: "res://assets/sprites/spr_ambulance.png",
	VehicleType.BULLDOZER: "res://assets/sprites/spr_bulldozer.png",
	VehicleType.TRUCK: "res://assets/sprites/spr_truck.png",
	VehicleType.TAYO: "res://assets/sprites/spr_tayo.png",
	VehicleType.ROGI: "res://assets/sprites/spr_rogi.png",
	VehicleType.GANI: "res://assets/sprites/spr_gani.png",
	VehicleType.LANI: "res://assets/sprites/spr_lani.png",
	VehicleType.CITU: "res://assets/sprites/spr_citu.png",
}

## 실제 이미지가 없을 때 종류를 구분하기 위한 임시 색(icon.svg에 틴트)
const PLACEHOLDER_COLORS := {
	VehicleType.POLICE_CAR: Color(0.2, 0.35, 0.9),
	VehicleType.AMBULANCE: Color(0.95, 0.15, 0.15),
	VehicleType.BULLDOZER: Color(0.85, 0.6, 0.1),
	VehicleType.TRUCK: Color(0.45, 0.45, 0.45),
	VehicleType.TAYO: Color(0.1, 0.65, 0.9),
	VehicleType.ROGI: Color(0.2, 0.7, 0.3),
	VehicleType.GANI: Color(0.85, 0.2, 0.2),
	VehicleType.LANI: Color(0.95, 0.8, 0.1),
	VehicleType.CITU: Color(0.7, 0.1, 0.1),
}

const PLACEHOLDER_TEX: Texture2D = preload("res://icon.svg")
const POP_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

var vehicle_type: VehicleType = VehicleType.TAYO
var speed: float = 0.0
var move_dir: Vector2 = Vector2.RIGHT
var is_popped: bool = false

func _ready() -> void:
	speed = randf_range(100.0, 150.0)
	var path: String = TEXTURE_PATHS[vehicle_type]
	if ResourceLoader.exists(path):
		# 실제 그림이 준비되어 있으면 그대로 사용
		$VehicleSprite.texture = load(path)
		$VehicleSprite.modulate = Color(1, 1, 1)
	else:
		# 아직 그림이 없으므로 종류별 색으로 임시 구분
		$VehicleSprite.texture = PLACEHOLDER_TEX
		$VehicleSprite.modulate = PLACEHOLDER_COLORS[vehicle_type]
	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	position += move_dir * speed * delta
	# 화면(720x1280) 밖으로 충분히 나가면 메모리 정리(사방 어디로든)
	if position.x < -200.0 or position.x > 920.0 or position.y < -200.0 or position.y > 1480.0:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		pop()

func pop() -> void:
	if is_popped:
		return
	is_popped = true
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position, vehicle_type)
	set_process(false)
	$VehicleSprite.hide()
	$PopSound.stream = POP_SOUND
	$PopSound.play()
	$PopSound.finished.connect(queue_free)

func setup(type: VehicleType, dir: Vector2) -> void:
	# Bbang이 스폰할 때 종류와 진행 방향을 넘겨준다.
	vehicle_type = type
	move_dir = dir.normalized()
