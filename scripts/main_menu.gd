extends Control
## 메인 메뉴 화면. 버튼을 눌러 각 게임으로 이동한다.
## 게임이 늘어나면 여기에 버튼을 추가하고 아래처럼 전환 함수를 연결하면 된다.

const BUBBLE_SOUND: AudioStream = preload("res://assets/audio/bubble.wav")
const BABBANG_SOUND: AudioStream = preload("res://assets/audio/babbang.wav")

func _ready() -> void:
	$CenterContainer/VBoxContainer/BubbleButton.pressed.connect(_on_bubble_button_pressed)
	$CenterContainer/VBoxContainer/BbangButton.pressed.connect(_on_bbang_button_pressed)

func _on_bubble_button_pressed() -> void:
	_play_and_change_scene(BUBBLE_SOUND, "res://scenes/Main.tscn")

func _on_bbang_button_pressed() -> void:
	_play_and_change_scene(BABBANG_SOUND, "res://scenes/Bbang.tscn")

func _play_and_change_scene(sound: AudioStream, scene_path: String) -> void:
	# 사운드가 잘리지 않게 다 재생된 뒤 화면을 전환한다.
	$SelectSound.stream = sound
	$SelectSound.play()
	await $SelectSound.finished
	get_tree().change_scene_to_file(scene_path)
