extends Area2D
## 방울 1개. 화면 사방(상/하/좌/우) 바깥에서 나타나 반대편으로 가로지르며,
## 진행 방향에 수직으로 살랑이고, 터치하면 팡 사라진다.
## 설계서 2장의 Bubble.tscn 노드 구조(BubbleSprite / CharacterSprite /
## CollisionShape2D / PopSound)를 전제로 한다.

## 방울이 터졌을 때 Main에게 알리는 커스텀 시그널.
## pos = 터진 위치(파티클 생성용), character_type = "" (일반) / "rui" / "toto"
signal popped(pos: Vector2, character_type: String)

const BBOK_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")
const RUI_SOUND: AudioStream = preload("res://assets/audio/rui.wav")
const TOTO_SOUND: AudioStream = preload("res://assets/audio/toto.wav")

var speed: float = 0.0        # 진행 속도(px/초) - 두둥실 뜨는 느낌으로 저속
var sway_amp: float = 0.0     # 큰 살랑임 폭
var sway_period: float = 0.0  # 큰 살랑임 주기(ms)
var wobble_amp: float = 0.0   # 작은 떨림 폭(잔물결처럼 더해지는 2차 흔들림)
var wobble_period: float = 0.0
var time_offset: float = 0.0  # 방울마다 흔들림 위상을 다르게(전부 같이 흔들리지 않게)
var character_type: String = ""       # "" = 일반 방울, "rui" / "toto" = 캐릭터 방울
var is_popped: bool = false   # 중복 터치 방지 가드
var move_dir: Vector2 = Vector2.UP    # 진행 방향(단위 벡터). 스폰 시 Main이 지정
var base_pos: Vector2 = Vector2.ZERO  # 살랑임의 기준이 되는 중심 위치

func _ready() -> void:
	speed = randf_range(45.0, 85.0)          # 기존(120~200)보다 훨씬 느리게 → 두둥실
	sway_amp = randf_range(35.0, 60.0)       # 큰 흔들림은 더 넉넉하게
	sway_period = randf_range(900.0, 1400.0) # 느긋한 주기로 여유 있게 살랑
	wobble_amp = randf_range(8.0, 16.0)      # 작은 잔떨림(비눗방울 특유의 흔들림)
	wobble_period = randf_range(250.0, 400.0)
	time_offset = randf_range(0.0, 1000.0)
	base_pos = position
	# Area2D의 터치/클릭 이벤트를 아래 함수에 연결
	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	# 진행 방향으로 중심을 이동(저속 = 두둥실 뜨는 느낌)
	base_pos += move_dir * speed * delta
	# 진행 방향에 수직인 방향으로, 큰 흔들림 + 작은 잔떨림을 겹쳐서 자연스럽게
	var perp := Vector2(-move_dir.y, move_dir.x)
	var t := Time.get_ticks_msec() + time_offset
	var sway := sin(t / sway_period) * sway_amp
	var wobble := sin(t / wobble_period) * wobble_amp
	position = base_pos + perp * (sway + wobble)
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
	popped.emit(global_position, character_type)
	$BubbleSprite.hide()
	$CharacterSprite.hide()
	set_process(false)    # 팝 후에는 이동/살랑임 계산 중단
	# 방울 종류에 맞는 사운드 선택: 일반=bbok, 루이=rui, 토토=toto
	var sound := BBOK_SOUND
	if character_type == "rui":
		sound = RUI_SOUND
	elif character_type == "toto":
		sound = TOTO_SOUND
	$PopSound.stream = sound
	$PopSound.play()
	# 사운드가 끝날 때까지 기다렸다가 정리(끊기지 않게)
	$PopSound.finished.connect(queue_free)

func setup_motion(dir: Vector2) -> void:
	# Main이 스폰할 때 진행 방향을 넘겨준다.
	move_dir = dir.normalized()

func setup_character(who: String) -> void:
	character_type = who
	if who == "rui":
		# 씬(Bubble.tscn)에 지정된 루이(Rui) 이미지를 버블 위에 표시
		$CharacterSprite.show()
	else:
		# 토토 아트는 아직 없어 임시로 버블을 노랗게 틴트해 구분
		# (토토 스프라이트가 생기면 루이처럼 CharacterSprite로 연결)
		$BubbleSprite.modulate = Color(1.0, 0.85, 0.2)
