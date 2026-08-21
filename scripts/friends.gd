extends Node2D
## 친구들 화면. 얼굴 아이템(face_item_1)이 비눗방울처럼 화면 사방에서 나타나
## 두둥실 떠다니고, 터치하면 face_item_2로 바뀐 뒤 사라진다.
## 노드 구조: FaceItemContainer / SpawnTimer / UILayer/MenuButton (FaceItem.tscn 인스턴싱).

var face_item_scene: PackedScene = preload("res://scenes/FaceItem.tscn")

## 3가지 짝(0,1,2)이 똑같은 빈도로 나오도록 섞은 뒤 하나씩 뽑아 쓰는 주머니.
## 다 뽑으면 다시 채우고 섞어서, 3번 스폰마다 세 종류가 정확히 한 번씩 나온다.
var _pair_bag: Array = []

func _next_pair_index() -> int:
	if _pair_bag.is_empty():
		_pair_bag = [0, 1, 2]
		_pair_bag.shuffle()
	return _pair_bag.pop_back()

func _ready() -> void:
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	$UILayer/MenuButton.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_spawn_timer_timeout() -> void:
	spawn_face_item()

func spawn_face_item() -> void:
	var f := face_item_scene.instantiate()
	# 사방(0=아래,1=위,2=왼쪽,3=오른쪽) 중 랜덤한 변 바깥에서 스폰 → 반대편으로 가로지른다
	var edge := randi_range(0, 3)
	var spawn_pos: Vector2
	var dir: Vector2
	match edge:
		0:
			spawn_pos = Vector2(randf_range(80.0, 640.0), 1360.0)
			dir = Vector2.UP
		1:
			spawn_pos = Vector2(randf_range(80.0, 640.0), -80.0)
			dir = Vector2.DOWN
		2:
			spawn_pos = Vector2(-80.0, randf_range(120.0, 1160.0))
			dir = Vector2.RIGHT
		_:
			spawn_pos = Vector2(800.0, randf_range(120.0, 1160.0))
			dir = Vector2.LEFT
	dir = dir.rotated(randf_range(-0.3, 0.3))
	dir = (dir + Vector2.UP * 0.35).normalized()
	f.position = spawn_pos
	f.setup_motion(dir)
	f.pair_index = _next_pair_index()
	$FaceItemContainer.add_child(f)

func _unhandled_input(event: InputEvent) -> void:
	# 얼굴 아이템들이 겹쳐 있을 때 터치 지점의 아이템이 전부 동시에 사라지지 않도록,
	# 맨 위(가장 나중에 그려진) 아이템 하나만 터뜨린다.
	if event is InputEventScreenTouch and event.pressed:
		_pop_topmost_face_item_at(get_global_mouse_position())

func _pop_topmost_face_item_at(world_pos: Vector2) -> void:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var results := get_world_2d().direct_space_state.intersect_point(params)
	var topmost: Node2D = null
	for r in results:
		var collider: Node = r["collider"]
		if collider.get_parent() == $FaceItemContainer and not collider.is_popped:
			if topmost == null or collider.get_index() > topmost.get_index():
				topmost = collider
	if topmost:
		topmost.pop()
