extends Area2D
## 방울 1개. 화면 사방(상/하/좌/우) 바깥에서 나타나 반대편으로 가로지르며,
## 진행 방향에 수직으로 살랑이고, 터치하면 팡 사라진다.
## 설계서 2장의 Bubble.tscn 노드 구조(BubbleSprite / CharacterSprite /
## CollisionShape2D / PopSound)를 전제로 한다.

## 방울이 터졌을 때 Main에게 알리는 커스텀 시그널.
## pos = 터진 위치(파티클 생성용), is_character = 캐릭터 방울 여부(별 카운트용)
signal popped(pos: Vector2, is_character: bool)

var speed: float = 0.0        # 진행 속도(px/초)
var sway_amp: float = 0.0     # 살랑임 폭
var is_character: bool = false
var is_popped: bool = false   # 중복 터치 방지 가드
var move_dir: Vector2 = Vector2.UP    # 진행 방향(단위 벡터). 스폰 시 Main이 지정
var base_pos: Vector2 = Vector2.ZERO  # 살랑임의 기준이 되는 중심 위치

func _ready() -> void:
	speed = randf_range(120.0, 200.0)
	sway_amp = randf_range(20.0, 40.0)
	base_pos = position
	# Area2D의 터치/클릭 이벤트를 아래 함수에 연결
	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	# 진행 방향으로 중심을 이동
	base_pos += move_dir * speed * delta
	# 진행 방향에 수직인 방향으로 sin 살랑살랑
	var perp := Vector2(-move_dir.y, move_dir.x)
	position = base_pos + perp * sin(Time.get_ticks_msec() / 400.0) * sway_amp
	# 화면(720x1280) 밖으로 충분히 나가면 메모리 정리(사방 어디로든)
	if position.x < -200.0 or position.x > 920.0 or position.y < -200.0 or position.y > 1480.0:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 터치 에뮬레이션 ON이라 PC 마우스 클릭도 여기로 들어온다.
	if event is InputEventScreenTouch and event.pressed:
		pop()

func pop() -> void:
	if is_popped:
		return                 # 이미 터졌으면 무시(중복 가드)
	is_popped = true
	# 물리 처리 중 충돌을 즉시 끄면 오류가 나므로 안전한 타이밍에 끈다
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position, is_character)
	# 사운드/파티클/Tween 연출은 이후 B 단계(지용)에서 추가.
	# 지금은 최소 루프라 바로 정리한다.
	queue_free()

func setup_motion(dir: Vector2) -> void:
	# Main이 스폰할 때 진행 방향을 넘겨준다.
	move_dir = dir.normalized()

func setup_character(_who: String) -> void:
	is_character = true
	# 아직 캐릭터 아트가 없어서, 임시로 방울 색을 노랗게 바꿔 눈으로 구분한다.
	# (2단계에서 진짜 루이/토토 스프라이트로 교체)
	$BubbleSprite.modulate = Color(1.0, 0.85, 0.2)
