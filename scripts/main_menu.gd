extends Control
## 메인 메뉴 화면. 버튼을 눌러 각 게임으로 이동한다.
## 게임이 늘어나면 여기에 버튼을 추가하고 아래처럼 전환 함수를 연결하면 된다.

const BUBBLE_SOUND: AudioStream = preload("res://assets/audio/bubble.wav")
const BABBANG_SOUND: AudioStream = preload("res://assets/audio/babbang.wav")
const NUM_SOUND: AudioStream = preload("res://assets/audio/snd_spr_menu.wav")
const FRIENDS_SOUND: AudioStream = preload("res://assets/audio/bbok.wav")

## 친구들 메뉴 입장 비밀번호(4자리)
const FRIENDS_PIN := "2024"

# 전환이 이미 시작됐는지 표시. 두 번째 이후 입력을 무시해 사운드 재시작/중복 씬 전환을 막는다.
var _transitioning: bool = false
var _pin_entered: String = ""

func _ready() -> void:
	$CenterContainer/VBoxContainer/BubbleButton.pressed.connect(_on_bubble_button_pressed)
	$CenterContainer/VBoxContainer/BbangButton.pressed.connect(_on_bbang_button_pressed)
	$CenterContainer/VBoxContainer/NumButton.pressed.connect(_on_num_button_pressed)
	$CenterContainer/VBoxContainer/FriendsButton.pressed.connect(_on_friends_button_pressed)

	var grid := $PinLayer/PinPopup/CenterContainer/Panel/VBoxContainer/GridContainer
	for i in range(10):
		grid.get_node("Digit%d" % i).pressed.connect(_on_pin_digit_pressed.bind(str(i)))
	grid.get_node("ClearButton").pressed.connect(_on_pin_clear_pressed)
	grid.get_node("CancelButton").pressed.connect(_on_pin_cancel_pressed)
	$PinLayer/PinPopup/Dimmer.gui_input.connect(_on_pin_dimmer_input)

func _on_bubble_button_pressed() -> void:
	_play_and_change_scene(BUBBLE_SOUND, "res://scenes/Main.tscn")

func _on_bbang_button_pressed() -> void:
	_play_and_change_scene(BABBANG_SOUND, "res://scenes/Bbang.tscn")

func _on_num_button_pressed() -> void:
	_play_and_change_scene(NUM_SOUND, "res://scenes/Num.tscn")

func _on_friends_button_pressed() -> void:
	# 친구들 메뉴는 바로 들어가지 않고, 먼저 비밀번호 입력창을 띄운다.
	_pin_entered = ""
	_update_pin_dots()
	$PinLayer/PinPopup.visible = true

func _on_pin_digit_pressed(digit: String) -> void:
	if _pin_entered.length() >= 4:
		return
	_pin_entered += digit
	_update_pin_dots()
	if _pin_entered.length() == 4:
		if _pin_entered == FRIENDS_PIN:
			$PinLayer/PinPopup.visible = false
			_play_and_change_scene(FRIENDS_SOUND, "res://scenes/Friends.tscn")
		else:
			# 틀리면 잠깐 보여준 뒤 초기화(입력한 걸 바로 지우면 뭘 눌렀는지 확인이 안 되므로)
			await get_tree().create_timer(0.3).timeout
			_pin_entered = ""
			_update_pin_dots()

func _on_pin_clear_pressed() -> void:
	_pin_entered = ""
	_update_pin_dots()

func _on_pin_cancel_pressed() -> void:
	_pin_entered = ""
	$PinLayer/PinPopup.visible = false

func _on_pin_dimmer_input(event: InputEvent) -> void:
	# 바깥(어두운 배경) 터치/클릭 시 팝업 닫기
	if event is InputEventScreenTouch and event.pressed:
		_on_pin_cancel_pressed()

func _update_pin_dots() -> void:
	var dots := ""
	for i in range(4):
		dots += "● " if i < _pin_entered.length() else "○ "
	$PinLayer/PinPopup/CenterContainer/Panel/VBoxContainer/DotsLabel.text = dots.strip_edges()

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
