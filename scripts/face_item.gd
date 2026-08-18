extends Area2D
## 어린이집 화면에 등장하는 얼굴 아이템 1개. 비눗방울처럼 화면 사방에서 나타나
## 두둥실 가로지르며, 터치하면 짝을 이루는 다음 그림으로 바뀐 뒤 사라진다.
## 짝(before → after)은 FACE_PAIRS에 하나씩 추가하면 스폰 시 랜덤으로 고른다.

signal popped(pos: Vector2)

## 얼굴 짝 목록: [터지기 전 그림, 터진 뒤 그림]
const FACE_PAIRS: Array = [
	["res://assets/sprites/face_item_1.png", "res://assets/sprites/face_item_2.png"],
	["res://assets/sprites/face_item_3.png", "res://assets/sprites/face_item_4.png"],
	["res://assets/sprites/face_item_5.png", "res://assets/sprites/face_item_6.png"],
]
const POP_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

## 1,2번 그림 기준 화면 표시 크기. 다른 짝의 그림은 원본 해상도/가로세로 비율이
## 달라도 가로·세로 중 더 긴 쪽을 이 값에 맞춰서 항상 같은 크기로 보이게 한다.
const REFERENCE_SCALE := 0.228
const TARGET_MAX_DIM: float = 1195.0 * REFERENCE_SCALE

var speed: float = 0.0        # 진행 속도(px/초) - 두둥실 뜨는 느낌으로 저속
var sway_amp: float = 0.0     # 큰 살랑임 폭
var sway_period: float = 0.0  # 큰 살랑임 주기(ms)
var wobble_amp: float = 0.0   # 작은 떨림 폭
var wobble_period: float = 0.0
var time_offset: float = 0.0  # 아이템마다 흔들림 위상을 다르게
var is_popped: bool = false   # 중복 터치 방지 가드
var move_dir: Vector2 = Vector2.UP
var base_pos: Vector2 = Vector2.ZERO
var after_tex: Texture2D       # 터졌을 때 바뀔 그림(스폰 시 짝에 맞춰 결정)

func _ready() -> void:
	speed = randf_range(45.0, 85.0)
	sway_amp = randf_range(35.0, 60.0)
	sway_period = randf_range(900.0, 1400.0)
	wobble_amp = randf_range(8.0, 16.0)
	wobble_period = randf_range(250.0, 400.0)
	time_offset = randf_range(0.0, 1000.0)
	base_pos = position
	var pair: Array = FACE_PAIRS[randi_range(0, FACE_PAIRS.size() - 1)]
	var before_tex: Texture2D = load(pair[0])
	after_tex = load(pair[1])
	$FaceSprite.texture = before_tex
	$FaceSprite.scale = _scale_for(before_tex)

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
	# 짝을 이루는 "터진 뒤" 그림으로 바꿔 보여준 뒤 사라진다(크기도 다시 맞춘다)
	$FaceSprite.texture = after_tex
	$FaceSprite.scale = _scale_for(after_tex)
	$PopSound.stream = POP_SOUND
	$PopSound.play()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

func setup_motion(dir: Vector2) -> void:
	move_dir = dir.normalized()

func _scale_for(tex: Texture2D) -> Vector2:
	var longer_side: float = max(tex.get_width(), tex.get_height())
	var s: float = TARGET_MAX_DIM / longer_side
	return Vector2(s, s)
