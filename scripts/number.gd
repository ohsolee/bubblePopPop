extends Area2D
class_name NumberPiece
## 숫자게임(Num)에 등장하는 숫자 1개(0~9). 화면 사방에서 나타나 흘러가며,
## 화면 밖으로 나가도 사라지지 않고 반대편에서 다시 나타난다 — 직접 눌러야만 사라지는
## 게임이라 임의로 없어지면 라운드가 영원히 안 끝날 수 있기 때문.

signal popped(pos: Vector2, digit: int)

const TEXTURE_PATHS := {
	0: "res://assets/sprites/spr_0.png",
	1: "res://assets/sprites/spr_1.png",
	2: "res://assets/sprites/spr_2.png",
	3: "res://assets/sprites/spr_3.png",
	4: "res://assets/sprites/spr_4.png",
	5: "res://assets/sprites/spr_5.png",
	6: "res://assets/sprites/spr_6.png",
	7: "res://assets/sprites/spr_7.png",
	8: "res://assets/sprites/spr_8.png",
	9: "res://assets/sprites/spr_9.png",
}

## 숫자별 음성 경로(이름이 같은 snd_spr_N.wav와 매칭, 없으면 POP_SOUND로 대체)
const SOUND_PATHS := {
	0: "res://assets/audio/snd_spr_0.wav",
	1: "res://assets/audio/snd_spr_1.wav",
	2: "res://assets/audio/snd_spr_2.wav",
	3: "res://assets/audio/snd_spr_3.wav",
	4: "res://assets/audio/snd_spr_4.wav",
	5: "res://assets/audio/snd_spr_5.wav",
	6: "res://assets/audio/snd_spr_6.wav",
	7: "res://assets/audio/snd_spr_7.wav",
	8: "res://assets/audio/snd_spr_8.wav",
	9: "res://assets/audio/snd_spr_9.wav",
}

const POP_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

var digit: int = 0
var speed: float = 0.0
var move_dir: Vector2 = Vector2.RIGHT
var is_popped: bool = false

## 화면(720x1280) 안에서만 떠다니도록 튕기는 경계(원 반지름 75만큼 여유를 둔다)
const MARGIN := 75.0
const SCREEN_WIDTH := 720.0
const SCREEN_HEIGHT := 1280.0

func _ready() -> void:
	speed = randf_range(60.0, 100.0)
	$NumberSprite.texture = load(TEXTURE_PATHS[digit])

func _process(delta: float) -> void:
	position += move_dir * speed * delta
	# 화면 밖으로 나가지 않도록 가장자리에서 튕겨 나오게 한다.
	if position.x < MARGIN:
		position.x = MARGIN
		move_dir.x = abs(move_dir.x)
	elif position.x > SCREEN_WIDTH - MARGIN:
		position.x = SCREEN_WIDTH - MARGIN
		move_dir.x = -abs(move_dir.x)
	if position.y < MARGIN:
		position.y = MARGIN
		move_dir.y = abs(move_dir.y)
	elif position.y > SCREEN_HEIGHT - MARGIN:
		position.y = SCREEN_HEIGHT - MARGIN
		move_dir.y = -abs(move_dir.y)

func pop() -> void:
	if is_popped:
		return
	is_popped = true
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position, digit)
	set_process(false)
	$NumberSprite.hide()
	var sound_path: String = SOUND_PATHS.get(digit, "")
	$PopSound.stream = load(sound_path) if sound_path != "" and ResourceLoader.exists(sound_path) else POP_SOUND
	$PopSound.play()
	$PopSound.finished.connect(queue_free)

func setup(value: int, dir: Vector2) -> void:
	digit = value
	move_dir = dir.normalized()
