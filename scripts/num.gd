extends Node2D
## 숫자게임(Num) 화면. 0~9 숫자가 화면을 떠다니다 터치하면 사라진다.
## 한 라운드에 나온 숫자를 전부 눌러야만 다음 라운드가 랜덤으로 다시 나온다
## (예: 5, 7, 2가 남아있으면 그 셋을 다 눌러야 0~9가 다시 전부 나옴).
## 노드 구조: NumberContainer / UILayer/MenuButton (Number.tscn 인스턴싱).

var number_scene: PackedScene = preload("res://scenes/Number.tscn")

## 이번 라운드에서 아직 안 눌린 숫자들. 비어야 다음 라운드가 시작된다.
var remaining: Array = []

func _ready() -> void:
	$UILayer/MenuButton.pressed.connect(_on_menu_button_pressed)
	_start_round()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# 숫자들이 겹쳐 있을 때 터치 지점의 숫자가 전부 동시에 터지지 않도록,
	# 맨 위(가장 나중에 그려진) 숫자 하나만 터뜨린다.
	if event is InputEventScreenTouch and event.pressed:
		_pop_topmost_number_at(get_global_mouse_position())

func _pop_topmost_number_at(world_pos: Vector2) -> void:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var results := get_world_2d().direct_space_state.intersect_point(params)
	var topmost: Node2D = null
	for r in results:
		var collider: Node = r["collider"]
		if collider.get_parent() == $NumberContainer and not collider.is_popped:
			if topmost == null or collider.get_index() > topmost.get_index():
				topmost = collider
	if topmost:
		topmost.pop()

func _start_round() -> void:
	var digits: Array = range(10)
	digits.shuffle()
	remaining = digits.duplicate()
	for i in range(digits.size()):
		# 살짝 시차를 둬서 10개가 한 번에 겹쳐 나오지 않게
		get_tree().create_timer(i * 0.15).timeout.connect(_spawn_number.bind(digits[i]))

func _spawn_number(digit: int) -> void:
	var n := number_scene.instantiate()
	# 화면(720x1280) 안에서만 떠다니도록 화면 내부에서 스폰하고 랜덤한 방향으로 움직인다.
	var spawn_pos := Vector2(randf_range(80.0, 640.0), randf_range(120.0, 1160.0))
	var dir := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	n.position = spawn_pos
	n.setup(digit, dir)
	n.popped.connect(_on_number_popped)
	$NumberContainer.add_child(n)

func _on_number_popped(_pos: Vector2, digit: int) -> void:
	remaining.erase(digit)
	if remaining.is_empty():
		_start_round()
