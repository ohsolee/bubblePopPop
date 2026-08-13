extends Control
## 메인 메뉴 화면. 버튼을 눌러 각 게임으로 이동한다.
## 게임이 늘어나면 여기에 버튼을 추가하고 아래처럼 전환 함수를 연결하면 된다.

const BUBBLE_SOUND: AudioStream = preload("res://assets/audio/bubble.wav")
const BABBANG_SOUND: AudioStream = preload("res://assets/audio/babbang.wav")
const NUM_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")
const FRIENDS_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

# 전환이 이미 시작됐는지 표시. 두 번째 이후 입력을 무시해 사운드 재시작/중복 씬 전환을 막는다.
var _transitioning: bool = false

func _ready() -> void:
	$CenterContainer/VBoxContainer/BubbleButton.pressed.connect(_on_bubble_button_pressed)
	$CenterContainer/VBoxContainer/BbangButton.pressed.connect(_on_bbang_button_pressed)
	$CenterContainer/VBoxContainer/NumButton.pressed.connect(_on_num_button_pressed)
	$CenterContainer/VBoxContainer/FriendsButton.pressed.connect(_on_friends_button_pressed)

func _on_bubble_button_pressed() -> void:
	_play_and_change_scene(BUBBLE_SOUND, "res://scenes/Main.tscn")

func _on_bbang_button_pressed() -> void:
	_play_and_change_scene(BABBANG_SOUND, "res://scenes/Bbang.tscn")

func _on_num_button_pressed() -> void:
	_play_and_change_scene(NUM_SOUND, "res://scenes/Num.tscn")

func _on_friends_button_pressed() -> void:
	_play_and_change_scene(FRIENDS_SOUND, "res://scenes/Friends.tscn")

func _play_and_change_scene(sound: AudioStream, scene_path: String) -> void:
	# 이미 전환 중이면 중복 실행하지 않는다(두 번 눌러도 멈추지 않도록).
	if _transitioning:
		return
	_transitioning = true
	# 전환하는 동안 다른 버튼도 못 누르게 잠근다.
	$CenterContainer/VBoxContainer/BubbleButton.disabled = true
	$CenterContainer/VBoxContainer/BbangButton.disabled = true
	$CenterContainer/VBoxContainer/NumButton.disabled = true
	$CenterContainer/VBoxContainer/FriendsButton.disabled = true
	# 사운드가 잘리지 않게 다 재생된 뒤 화면을 전환한다.
	$SelectSound.stream = sound
	$SelectSound.play()
	await $SelectSound.finished
	get_tree().change_scene_to_file(scene_path)
