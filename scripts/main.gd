extends Node2D
## 루트 씬. SpawnTimer마다 방울을 만들고, 방울이 터지면 별을 센다.
## 설계서 2장의 Main.tscn 노드 구조(BubbleContainer / SpawnTimer /
## UILayer/StarCounter/CountLabel)를 전제로 한다.

var bubble_scene: PackedScene = preload("res://scenes/Bubble.tscn")
# 파티클 씬은 B 단계(지용)에서 만들면 아래 주석을 풀어 사용
# var pop_effect_scene: PackedScene = preload("res://scenes/PopEffect.tscn")

var bubbles_since_character: int = 0   # 마지막 캐릭터 방울 이후 생성한 일반 방울 수
var character_threshold: int = 0       # 이번에 몇 개마다 캐릭터를 낼지(6~8)
var star_count: int = 0
var use_rui: bool = true               # 루이/토토 번갈아 등장용

func _ready() -> void:
	_reset_character_threshold()
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	$UILayer/MenuButton.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed() -> void:
	# 메인 메뉴 화면(MainMenu.tscn)으로 돌아간다
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_spawn_timer_timeout() -> void:
	spawn_bubble()

func spawn_bubble() -> void:
	var b := bubble_scene.instantiate()
	# 사방(상/하/좌/우) 중 랜덤한 변 바깥에서 스폰 → 반대편으로 가로지른다
	var edge := randi_range(0, 3)
	var spawn_pos: Vector2
	var dir: Vector2
	match edge:
		0: # 아래 → 위
			spawn_pos = Vector2(randf_range(80.0, 640.0), 1360.0)
			dir = Vector2.UP
		1: # 위 → 아래
			spawn_pos = Vector2(randf_range(80.0, 640.0), -80.0)
			dir = Vector2.DOWN
		2: # 왼쪽 → 오른쪽
			spawn_pos = Vector2(-80.0, randf_range(120.0, 1160.0))
			dir = Vector2.RIGHT
		_: # 오른쪽 → 왼쪽
			spawn_pos = Vector2(800.0, randf_range(120.0, 1160.0))
			dir = Vector2.LEFT
	# 진행 방향을 살짝 랜덤하게 틀어 움직임을 다양하게(±약 17도)
	dir = dir.rotated(randf_range(-0.3, 0.3))
	b.position = spawn_pos
	b.setup_motion(dir)
	bubbles_since_character += 1
	# 보장형 카운터: 순수 랜덤이 아니라 6~8개마다 캐릭터 방울 1개 확정
	if bubbles_since_character >= character_threshold:
		var who := "rui" if use_rui else "toto"
		b.setup_character(who)
		use_rui = not use_rui
		bubbles_since_character = 0
		_reset_character_threshold()
	# 방울의 popped 시그널을 구독(A4 인터페이스 계약)
	b.popped.connect(_on_bubble_popped)
	$BubbleContainer.add_child(b)

func _on_bubble_popped(_pos: Vector2, is_character: bool) -> void:
	# 연출/파티클은 B 단계에서 _pos를 활용해 추가.
	# 지금은 캐릭터 방울일 때만 별 카운트(A5).
	if is_character:
		star_count += 1
		$UILayer/StarCounter/CountLabel.text = str(star_count)

func _reset_character_threshold() -> void:
	character_threshold = randi_range(6, 8)
