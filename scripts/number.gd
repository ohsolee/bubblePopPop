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

const POP_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

var digit: int = 0
var speed: float = 0.0
var move_dir: Vector2 = Vector2.RIGHT
var is_popped: bool = false

func _ready() -> void:
	speed = randf_range(60.0, 100.0)
	$NumberSprite.texture = load(TEXTURE_PATHS[digit])

func _process(delta: float) -> void:
	position += move_dir * speed * delta
	# 화면(720x1280) 밖으로 나가면 반대편으로 순환시킨다(눌러야만 사라지므로 임의 정리 금지)
	if position.x < -200.0:
		position.x = 920.0
	elif position.x > 920.0:
		position.x = -200.0
	if position.y < -200.0:
		position.y = 1480.0
	elif position.y > 1480.0:
		position.y = -200.0

func pop() -> void:
	if is_popped:
		return
	is_popped = true
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position, digit)
	set_process(false)
	$NumberSprite.hide()
	$PopSound.stream = POP_SOUND
	$PopSound.play()
	$PopSound.finished.connect(queue_free)

func setup(value: int, dir: Vector2) -> void:
	digit = value
	move_dir = dir.normalized()
