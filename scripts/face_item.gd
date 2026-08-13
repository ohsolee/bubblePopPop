extends Area2D
## 어린이집 화면에 등장하는 얼굴 아이템 1개. 비눗방울처럼 화면 사방에서 나타나
## 두둥실 가로지르며, 터치하면 face_item_2 그림으로 바뀐 뒤 사라진다.

signal popped(pos: Vector2)

const FACE_TEX_1: Texture2D = preload("res://assets/sprites/face_item_1.png")
const FACE_TEX_2: Texture2D = preload("res://assets/sprites/face_item_2.png")
const POP_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

var speed: float = 0.0        # 진행 속도(px/초) - 두둥실 뜨는 느낌으로 저속
var sway_amp: float = 0.0     # 큰 살랑임 폭
var sway_period: float = 0.0  # 큰 살랑임 주기(ms)
var wobble_amp: float = 0.0   # 작은 떨림 폭
var wobble_period: float = 0.0
var time_offset: float = 0.0  # 아이템마다 흔들림 위상을 다르게
var is_popped: bool = false   # 중복 터치 방지 가드
var move_dir: Vector2 = Vector2.UP
var base_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	speed = randf_range(45.0, 85.0)
	sway_amp = randf_range(35.0, 60.0)
	sway_period = randf_range(900.0, 1400.0)
	wobble_amp = randf_range(8.0, 16.0)
	wobble_period = randf_range(250.0, 400.0)
	time_offset = randf_range(0.0, 1000.0)
	base_pos = position

func _process(delta: float) -> void:
	base_pos += move_dir * speed * delta
	var perp := Vector2(-move_dir.y, move_dir.x)
	var t := Time.get_ticks_msec() + time_offset
	var sway := sin(t / sway_period) * sway_amp
	var wobble := sin(t / wobble_period) * wobble_amp
	position = base_pos + perp * (sway + wobble)
	# 화면(720x1280) 밖으로 충분히 나가면 메모리 정리(사방 어디로든)
	if position.x < -200.0 or position.x > 920.0 or position.y < -200.0 or position.y > 1480.0:
		queue_free()

func pop() -> void:
	if is_popped:
		return
	is_popped = true
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position)
	set_process(false)
	# face_item_2 그림으로 바꿔 보여준 뒤 사라진다
	$FaceSprite.texture = FACE_TEX_2
	$PopSound.stream = POP_SOUND
	$PopSound.play()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

func setup_motion(dir: Vector2) -> void:
	move_dir = dir.normalized()
