extends Node2D
## 친구들 화면. 얼굴 아이템(face_item_1)이 비눗방울처럼 화면 사방에서 나타나
## 두둥실 떠다니고, 터치하면 face_item_2로 바뀐 뒤 사라진다.
## 노드 구조: FaceItemContainer / SpawnTimer / UILayer/MenuButton (FaceItem.tscn 인스턴싱).

var face_item_scene: PackedScene = preload("res://scenes/FaceItem.tscn")

## 종류(0=1/2번, 1=3/4번, 2=5/6번)마다 화면에 항상 이만큼씩 떠 있게 유지한다(총 6개).
const COUNT_PER_PAIR := 2

func _ready() -> void:
	$UILayer/MenuButton.pressed.connect(_on_menu_button_pressed)
	# 계속 쌓이지 않도록: 타이머로 무한히 추가 생성하는 대신 종류별로 개수를 고정해두고,
	# 하나가 터지면 같은 종류를 하나만 다시 채워 넣는다.
	for pair_idx in range(3):
		for i in range(COUNT_PER_PAIR):
			spawn_face_item(pair_idx)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func spawn_face_item(pair_idx: int) -> void:
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
	f.pair_index = pair_idx
	f.popped.connect(_on_face_item_popped)
	f.left_screen.connect(spawn_face_item)
	$FaceItemContainer.add_child(f)

func _on_face_item_popped(_pos: Vector2, pair_idx: int) -> void:
	# 터진 종류와 같은 종류를 하나 다시 채워 항상 종류별 2개(총 6개)를 유지한다.
	spawn_face_item(pair_idx)

func _unhandled_input(event: InputEvent) -> void:
	# 얼굴 아이템들이 겹쳐 있을 때 터치 지점의 아이템이 전부 동시에 사라지지 않도록,
	# 맨 위(가장 나중에 그려진) 아이템 하나만 터뜨린다.
	if event is InputEventScreenTouch and event.pressed:
		# 멀티터치: 각 손가락 이벤트의 좌표를 직접 월드 좌표로 변환해 사용한다.
		# get_global_mouse_position()은 포인터 1개만 반영해 두 번째 손가락부터 무시된다.
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_pop_topmost_face_item_at(world_pos)

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
