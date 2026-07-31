extends Area2D
## 방울 1개(버블 게임 전용). 화면 사방(상/하/좌/우) 바깥에서 나타나 반대편으로
## 두둥실 가로지르며, 터치하면 팡 사라진다.
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

var pop_progress: float = 0.0   # 팝 연출 진행도(0=시작 ~ 1=완전히 사라짐)
var pop_radius: float = 0.0     # 스프라이트 크기에 맞춘 팝 연출 기준 반지름
var pop_seed: float = 0.0       # 물방울 조각 배치를 방울마다 다르게

func _ready() -> void:
	speed = randf_range(45.0, 85.0)
	sway_amp = randf_range(35.0, 60.0)
	sway_period = randf_range(900.0, 1400.0)
	wobble_amp = randf_range(8.0, 16.0)
	wobble_period = randf_range(250.0, 400.0)
	time_offset = randf_range(0.0, 1000.0)
	base_pos = position
	pop_seed = randf_range(0.0, TAU)
	# 실제 표시되는 스프라이트 크기 기준으로 팝 연출 반지름 산출
	pop_radius = $BubbleSprite.texture.get_size().x * $BubbleSprite.scale.x * 0.5

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
	# 사운드는 클릭과 동시에 바로 들리도록 다른 처리보다 맨 먼저 재생한다
	# (아래 tween 생성/시그널 emit 등을 먼저 하면 그만큼 재생이 밀려서 늦게 들린다)
	var sound := BBOK_SOUND
	if character_type == "rui":
		sound = RUI_SOUND
	elif character_type == "toto":
		sound = TOTO_SOUND
	$PopSound.stream = sound
	$PopSound.play()
	# 물리 처리 중 충돌을 즉시 끄면 오류가 나므로 안전한 타이밍에 끈다
	$CollisionShape2D.set_deferred("disabled", true)
	popped.emit(global_position, character_type)
	set_process(false)    # 팝 후에는 이동/살랑임 계산 중단
	# 비눗방울 스프라이트는 즉시 숨기고, 터지는 연출은 _draw()로 직접 그린다
	$BubbleSprite.hide()
	var pop_tw := create_tween()
	pop_tw.tween_method(_set_pop_progress, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# 루이/토토 인형은 방울이 터진 후에도 잠깐 남아, 살짝 커지며 사라진다
	var char_tw: Tween = null
	if character_type == "rui":
		char_tw = _play_character_pop($CharacterSprite)
	elif character_type == "toto":
		char_tw = _play_character_pop($TotoSprite)
	else:
		$CharacterSprite.hide()
		$TotoSprite.hide()
	# 사운드/인형 연출 중 더 오래 걸리는 쪽이 끝날 때까지 기다렸다가 정리(끊기지 않게)
	if char_tw != null:
		char_tw.finished.connect(queue_free)
	else:
		$PopSound.finished.connect(queue_free)

func setup_motion(dir: Vector2) -> void:
	# Main이 스폰할 때 진행 방향을 넘겨준다.
	move_dir = dir.normalized()

func setup_character(who: String) -> void:
	character_type = who
	if who == "rui":
		# 씬(Bubble.tscn)에 지정된 루이(Rui) 이미지를 버블 위에 표시
		$CharacterSprite.show()
	elif who == "toto":
		# 씬(Bubble.tscn)에 지정된 토토(Toto) 이미지를 버블 위에 표시
		$TotoSprite.show()

func _play_character_pop(sprite: Sprite2D) -> Tween:
	var start_scale := sprite.scale
	var tw := create_tween()
	# set_parallel(true)는 "바로 앞에 추가된 tweener"와 동시에 시작하게 만들 뿐이라,
	# tween_interval() 뒤에 바로 붙이면 대기 시간과 "동시에" 실행돼 버려 홀드가 무시된다.
	# 그래서 interval 대신 각 tween_property에 set_delay()로 0.8초 지연을 직접 지정한다.
	tw.set_parallel(true)
	var hold := 0.8
	tw.tween_property(sprite, "scale", start_scale * 1.3, 0.3).set_delay(hold).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3).set_delay(hold + 0.05)
	tw.chain().tween_callback(sprite.hide)
	return tw

func _set_pop_progress(v: float) -> void:
	pop_progress = v
	queue_redraw()

func _draw() -> void:
	# 스프라이트 없이 비눗방울이 "팡" 터지는 순간을 직접 그린다:
	# 테두리 링이 확 커지며 옅어지고, 물방울 조각들이 사방으로 튀며 작아진다.
	if not is_popped:
		return
	var t := pop_progress
	var fade := 1.0 - t
	var ring_radius := pop_radius * (0.85 + t * 0.9)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, fade * 0.8), 4.0, true)
	var droplet_count := 8
	for i in range(droplet_count):
		var angle := pop_seed + i * TAU / droplet_count
		var dist := pop_radius * (0.3 + t * 0.9)
		var pos := Vector2(cos(angle), sin(angle)) * dist
		var r := pop_radius * 0.14 * fade
		if r > 0.5:
			draw_circle(pos, r, Color(0.85, 0.95, 1.0, fade * 0.9))
