extends Control
## 메인 메뉴 화면. 버튼을 눌러 각 게임으로 이동한다.
## 게임이 늘어나면 여기에 버튼을 추가하고 아래처럼 전환 함수를 연결하면 된다.

func _ready() -> void:
	$CenterContainer/VBoxContainer/BubbleButton.pressed.connect(_on_bubble_button_pressed)
	$CenterContainer/VBoxContainer/BbangButton.pressed.connect(_on_bbang_button_pressed)

func _on_bubble_button_pressed() -> void:
	# 버블 게임 화면(Main.tscn)으로 전환
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_bbang_button_pressed() -> void:
	# 빠방 화면(Bbang.tscn)으로 전환
	get_tree().change_scene_to_file("res://scenes/Bbang.tscn")
