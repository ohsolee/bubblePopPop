# 비눗방울 팡팡 — Godot 합맞추기 프로젝트 설계서

> "루이, 어디있어?" 본편 전 워밍업 프로젝트
> 목표: 게임 완성 그 자체보다 **Godot 워크플로우 + 2인 협업 방식 검증**
>
> **문서 버전: v0.01**

### 변경 이력
- **v0.01** — 방울이 화면 **사방(상/하/좌/우)**에서 나와 반대편으로 가로지르는 방식으로 변경.
  (기존 v0.00은 각 항목에 `<!-- v0.00 ... -->` 주석으로 보존)
- **v0.00** — 최초 설계. 방울이 화면 아래에서 위로만 떠오름.

---

## 1. 게임 사양

| 항목 | 내용 |
|------|------|
| 장르 | 터치 팝 (실패 없음, 점수 압박 없음) |
| 화면 | 세로 720×1280 기준, 모바일/PC 웹 대응 |
| 엔진 | Godot 4.x 최신 stable (**Standard 빌드**, .NET 아님 — GDScript 사용) |
| 렌더러 | **Compatibility** (웹 익스포트 호환성 최우선) |
| 배포 | 웹 익스포트 → GitHub Pages |

### 플레이 루프

<!-- v0.00 (구버전) — 아래에서 위로만
```
비눗방울이 화면 아래에서 위로 둥둥 떠오름 (좌우로 살랑살랑)
→ 터치/클릭 → 팡! (파티클 + 효과음)
→ 가끔 루이 or 토토가 탄 방울 등장
→ 터치하면 캐릭터가 폴짝 좋아하는 리액션 후 사라짐
→ 화면 상단에 별 카운터만 조용히 증가 (게임오버 없음)
```
-->

**v0.01**
```
비눗방울이 화면 사방(상/하/좌/우) 바깥에서 나타나 반대편으로 둥둥 가로지름
 (진행 방향에 수직으로 살랑살랑)
→ 터치/클릭 → 팡! (파티클 + 효과음)
→ 가끔 루이 or 토토가 탄 방울 등장
→ 터치하면 캐릭터가 폴짝 좋아하는 리액션 후 사라짐
→ 화면 상단에 별 카운터만 조용히 증가 (게임오버 없음)
```

### 캐릭터 방울 등장 규칙
순수 랜덤이 아니라 **보장형 카운터** 사용:
일반 방울 6~8개마다 캐릭터 방울 1개 확정 등장 (루이/토토 번갈아).
유아에게 순수 랜덤은 "한참 안 나오는" 구간이 생겨서 지루해짐.

---

## 2. 씬 구조 (인터페이스 계약)

> ⚠️ 아래 노드 이름과 구조가 두 사람 사이의 **계약**입니다.
> 스크립트가 이 이름들을 참조하므로, 구조 변경 시 반드시 상대에게 공유.

### Main.tscn (루트 씬)
```
Main (Node2D)                      ← main.gd 부착
├── Background (Sprite2D)          ← 배경 이미지
├── BubbleContainer (Node2D)       ← 생성된 방울들이 붙는 부모
├── SpawnTimer (Timer)             ← wait_time 1.2초, autostart ON
└── UILayer (CanvasLayer)
	└── StarCounter (HBoxContainer)
		├── StarIcon (TextureRect)
		└── CountLabel (Label)
```

### Bubble.tscn (방울 1개 = 씬 1개, 코드로 인스턴싱)
```
Bubble (Area2D)                    ← bubble.gd 부착
├── BubbleSprite (Sprite2D)        ← 비눗방울 이미지
├── CharacterSprite (Sprite2D)     ← 루이/토토 (기본 hidden)
├── CollisionShape2D               ← CircleShape2D, 스프라이트보다 20% 크게 (유아 터치 판정 넉넉히)
└── PopSound (AudioStreamPlayer2D)
```

> 언리얼로 치면: Bubble.tscn = Blueprint 클래스, 인스턴싱 = SpawnActor,
> Area2D의 input_event = OnClicked 이벤트, 시그널 = Event Dispatcher

### PopEffect.tscn (터질 때 파티클)
```
PopEffect (CPUParticles2D)         ← one_shot ON, emitting ON
```
- GPUParticles 대신 **CPUParticles2D** 사용 (웹 Compatibility 렌더러에서 가장 안전)
- `finished` 시그널 → `queue_free()` 연결해서 자동 소멸

---

## 3. 로직 설계 (율미 담당 영역)

### main.gd

<!-- v0.00 (구버전) — 아래 바깥에서만 스폰
```
변수:
  bubble_scene = preload("res://scenes/Bubble.tscn")
  pop_effect_scene = preload("res://scenes/PopEffect.tscn")
  bubbles_since_character: int = 0   # 보장형 카운터
  star_count: int = 0

SpawnTimer.timeout 시그널 →
  spawn_bubble():
	var b = bubble_scene.instantiate()
	b.position = Vector2(randf_range(80, 640), 1360)   # 화면 아래 바깥
	bubbles_since_character += 1
	if bubbles_since_character >= randi_range(6, 8):
		b.setup_character("louie" 또는 "toto" 번갈아)
		bubbles_since_character = 0
	b.popped.connect(_on_bubble_popped)               # 커스텀 시그널 구독
	BubbleContainer.add_child(b)

_on_bubble_popped(pos: Vector2, is_character: bool):
	var fx = pop_effect_scene.instantiate()
	fx.position = pos
	add_child(fx)
	if is_character:
		star_count += 1
		CountLabel.text = str(star_count)
```
-->

**v0.01** — 사방 스폰: 스폰할 변에 따라 시작 위치와 진행 방향을 정해 방울에 넘겨줌
```
변수:
  bubble_scene = preload("res://scenes/Bubble.tscn")
  pop_effect_scene = preload("res://scenes/PopEffect.tscn")
  bubbles_since_character: int = 0   # 보장형 카운터
  character_threshold: int = randi_range(6, 8)  # 이번에 몇 개마다 캐릭터를 낼지
  star_count: int = 0

SpawnTimer.timeout 시그널 →
  spawn_bubble():
	var b = bubble_scene.instantiate()
	# 사방(0=아래,1=위,2=왼쪽,3=오른쪽) 중 랜덤한 변에서 스폰 → 반대편으로 가로지름
	edge = randi_range(0, 3)
	match edge:
	  0: spawn_pos = Vector2(randf_range(80,640), 1360),  dir = Vector2.UP     # 아래→위
	  1: spawn_pos = Vector2(randf_range(80,640), -80),   dir = Vector2.DOWN   # 위→아래
	  2: spawn_pos = Vector2(-80, randf_range(120,1160)), dir = Vector2.RIGHT  # 왼→오
	  3: spawn_pos = Vector2(800, randf_range(120,1160)), dir = Vector2.LEFT   # 오→왼
	dir = dir.rotated(randf_range(-0.3, 0.3))   # 진행 방향 살짝 랜덤(±약 17도)
	b.position = spawn_pos
	b.setup_motion(dir)                          # 진행 방향을 방울에 전달
	bubbles_since_character += 1
	if bubbles_since_character >= character_threshold:
		b.setup_character("louie" 또는 "toto" 번갈아)
		bubbles_since_character = 0
		character_threshold = randi_range(6, 8)  # 다음 임계치 새로 뽑기
	b.popped.connect(_on_bubble_popped)               # 커스텀 시그널 구독
	BubbleContainer.add_child(b)

_on_bubble_popped(pos: Vector2, is_character: bool):
	var fx = pop_effect_scene.instantiate()
	fx.position = pos
	add_child(fx)
	if is_character:
		star_count += 1
		CountLabel.text = str(star_count)
```

### bubble.gd

<!-- v0.00 (구버전) — 위로 상승 + 좌우 sin 흔들림
```
signal popped(pos: Vector2, is_character: bool)      # 커스텀 시그널 선언

변수:
  speed: float = randf_range(120, 200)   # 상승 속도
  sway_amp: float = randf_range(20, 40)  # 좌우 흔들림 폭
  is_character: bool = false
  is_popped: bool = false
  base_x: float

_ready():
  base_x = position.x
  input_event 시그널을 _on_input_event에 연결 (에디터에서 연결해도 됨)

_process(delta):
  position.y -= speed * delta
  position.x = base_x + sin(Time.get_ticks_msec() / 400.0) * sway_amp
  if position.y < -150: queue_free()    # 화면 위로 나가면 정리
```
-->

**v0.01** — 임의의 진행 방향(move_dir)으로 이동 + 진행 방향에 **수직**으로 살랑임
```
signal popped(pos: Vector2, is_character: bool)      # 커스텀 시그널 선언

변수:
  speed: float = randf_range(120, 200)   # 진행 속도
  sway_amp: float = randf_range(20, 40)  # 살랑임 폭
  is_character: bool = false
  is_popped: bool = false
  move_dir: Vector2 = Vector2.UP         # 진행 방향(단위 벡터). Main이 스폰 시 지정
  base_pos: Vector2                      # 살랑임의 기준이 되는 중심 위치

_ready():
  base_pos = position
  input_event 시그널을 _on_input_event에 연결 (에디터에서 연결해도 됨)

_process(delta):
  base_pos += move_dir * speed * delta                    # 진행 방향으로 중심 이동
  var perp = Vector2(-move_dir.y, move_dir.x)             # 진행 방향에 수직인 벡터
  position = base_pos + perp * sin(Time.get_ticks_msec() / 400.0) * sway_amp
  # 화면(720x1280) 밖으로 충분히 나가면 정리(사방 어디로든)
  if position.x < -200 or position.x > 920 or position.y < -200 or position.y > 1480:
	  queue_free()

setup_motion(dir: Vector2):     # Main이 스폰 시 진행 방향을 넘겨줌
  move_dir = dir.normalized()

_on_input_event(viewport, event, shape_idx):
  if event is InputEventScreenTouch and event.pressed:
	  pop()
  # 마우스 클릭은 프로젝트 설정의 터치 에뮬레이션으로 자동 처리됨

pop():
  if is_popped: return                  # 중복 터치 가드
  is_popped = true
  $CollisionShape2D.set_deferred("disabled", true)
  popped.emit(global_position, is_character)
  PopSound.play()
  if is_character:
	  캐릭터 리액션 재생 (아래 4장, 지용 담당) 후 queue_free()
  else:
	  $BubbleSprite.hide()
	  PopSound가 끝나면 queue_free()    # finished 시그널 활용

setup_character(who: String):
  is_character = true
  CharacterSprite에 해당 텍스처 지정 후 show()
```

### 프로젝트 설정 체크리스트 (환경 세팅)
- [ ] 프로젝트 설정 → Display → Window: 720×1280, Stretch Mode `canvas_items`, Aspect `expand`
- [ ] Input Devices → Pointing → **Emulate Touch From Mouse ON** (PC에서 마우스로 테스트 가능)
- [ ] 렌더러: Compatibility
- [ ] Git 초기화 + Godot용 `.gitignore` (`.godot/` 폴더 필수 제외)
- [ ] 폴더 구조: `scenes/` `scripts/` `assets/sprites/` `assets/audio/`

---

## 4. 연출 설계 (지용 담당 영역)

### 방울 팝 연출 (Tween)
```
pop() 안에서:
  var tw = create_tween()
  tw.tween_property(BubbleSprite, "scale", Vector2(1.3, 1.3), 0.08)  # 살짝 커졌다가
  tw.tween_callback(BubbleSprite.hide)                                # 사라짐 → 파티클이 이어받음
```

### 캐릭터 리액션 (Tween 체인)
```
캐릭터 방울 팝 시:
  1. BubbleSprite만 사라짐 (팝 연출)
  2. CharacterSprite 폴짝: scale 펀치 + position.y 바운스 2회
	 (TRANS_BOUNCE, EASE_OUT — 언리얼 커브 이징과 동일 개념)
  3. 기쁨 효과음 재생
  4. 0.8초 후 페이드아웃 → queue_free()
```

### CPUParticles2D 파라미터 시작값
| 파라미터 | 값 |
|----------|-----|
| amount | 12 |
| lifetime | 0.5 |
| one_shot | ON |
| spread | 180 |
| initial_velocity | 150~250 |
| scale_amount | 0.5 → 0 (curve) |
| texture | 작은 물방울/반짝이 PNG |

---

## 5. AI 에셋 리스트

| 에셋 | 스펙 | 생성 팁 |
|------|------|---------|
| 배경 | 720×1280, 파스텔 하늘/욕실 | 디테일 적게, 방울이 잘 보이는 밝은 단색 계열 |
| 비눗방울 | 512×512 투명 PNG | 림 하이라이트 있는 반투명, 흰 배경 생성 후 배경 제거 |
| 루이 in 방울 | 512×512 투명 PNG | 실제 인형 사진 → img2img로 일관성 확보 |
| 토토 in 방울 | 512×512 투명 PNG | 동일 |
| 루이/토토 기쁨 | 각 1장 (Tween으로 움직임 처리, 프레임 애니메이션 불필요) | |
| 별 아이콘 | 128×128 | |
| 팝 효과음 | 0.2~0.5초, 부드러운 "퐁" | 날카로운 소리 금지 (유아) |
| 캐릭터 등장음 | 1초 내외 까르르/딸랑 | |

> 프레임 애니메이션은 이번엔 안 씀. 스프라이트 1장 + Tween으로 전부 해결
> (제작 비용 최소화 — 본편에서 필요해지면 그때 AnimatedSprite2D 학습)

---

## 6. 협업 규칙 (이번 프로젝트의 진짜 검증 대상)

### 파일 소유권
| 파일 | 소유자 | 상대방은 |
|------|--------|---------|
| *.tscn (씬 파일) | 지용 | 수정 금지, 요청만 |
| *.gd (스크립트) | 율미 | 수정 금지, 요청만 |
| assets/ | 지용 | 자유롭게 참조 |
| project.godot (설정) | 율미 | 변경 전 상의 |

- 씬↔스크립트를 잇는 **노드 이름 = API**. 바꾸려면 이 문서 먼저 수정 후 통보
- .tscn은 텍스트 파일이라 Git 머지가 되긴 하지만, 같은 씬 동시 수정은 충돌 지옥 → 소유권으로 원천 차단

### 브랜치
2인 규모라 단순하게: `main` 하나 + 작업 전 pull, 작업 후 push. 충돌 나면 그때 브랜치 도입 논의.

---

## 7. 기능 분해 (작업 단위)

> 각 기능은 독립적으로 테스트 가능한 단위. 번호는 작업 ID로 사용.

### A. 코어 로직 — 율미

| ID | 기능 | 내용 | 선행 조건 |
|----|------|------|----------|
| A1 | 스폰 시스템 | SpawnTimer → Bubble 인스턴싱, 랜덤 X, 보장형 카운터(6~8개마다 캐릭터) | C1 |
| A2 | 방울 이동 | <!--v0.00: 상승 + sin 좌우 흔들림--> **v0.01:** move_dir 방향 이동 + 진행 방향 수직 sin 살랑임, 화면 사방 이탈 시 queue_free | A1 |
| A3 | 터치 판정 | Area2D input_event, 터치/마우스 겸용, is_popped 중복 가드 | A2 |
| A4 | 팝 상태 처리 | 콜리전 비활성화, `popped` 시그널 발신, 일반/캐릭터 분기 | A3 |
| A5 | 별 카운터 | popped 구독 → 캐릭터일 때만 카운트, Label 갱신 | A4 |

### B. 연출/피드백 — 지용

| ID | 기능 | 내용 | 선행 조건 |
|----|------|------|----------|
| B1 | 팝 Tween | scale 펀치(1.3배, 0.08초) → hide | A3 |
| B2 | 파티클 | PopEffect 씬, one_shot, finished → queue_free | 없음 (독립 제작) |
| B3 | 캐릭터 리액션 | 방울만 팝 → 캐릭터 바운스 Tween → 페이드아웃 | A4 |
| B4 | 사운드 | 팝음 / 캐릭터 등장음, 로직에 play() 한 줄씩 | 파일만 준비되면 독립 |
| B5 | 에셋 제작 | 5장 스프라이트 + 효과음 2개 (5장 참조) | 없음 — A1~A3 진행 중 병렬 |

### C. 인프라 — 율미

| ID | 기능 | 내용 | 선행 조건 |
|----|------|------|----------|
| C1 | 프로젝트 셋업 | 해상도/스트레치, 터치 에뮬레이션, 렌더러, 폴더 구조 | 없음 — 최우선 |
| C2 | Git 협업 | .gitignore(.godot/ 제외), 소유권 규칙 적용 | C1과 동시 |
| C3 | 웹 익스포트/배포 | HTML5 프리셋, GitHub Pages | A3 직후 **조기 실행** |

> ⚠️ C3은 마지막이 아니라 **A3 직후에 미리 한 번** 실행.
> 배포 문제(경로, 로딩)는 늦게 발견할수록 원인 추적이 어려움.
> 도형만 움직이는 상태로 폰에서 열리는 것까지 확인해두면 이후 배포 리스크 소멸.

### 작업 순서 다이어그램

```
C1, C2 (셋업)
 → A1, A2, A3 (도형으로 최소 루프)    ‖  B5 (에셋 생성 — 병렬)
 → C3 (조기 배포 테스트)
 → A4 (시그널 규격 확정)              ← ★ 두 사람의 유일한 동기화 지점
 → B1, B2, B3, B4 (연출)  ‖  A5 (카운터)   ← 완전 병렬
```

### 인터페이스 지점 (A4)

두 사람의 작업이 만나는 곳은 **A4 하나뿐**. 아래만 합의되면 나머지는 전부 병렬:

- 시그널 규격: `popped(pos: Vector2, is_character: bool)`
- 분기 규칙: 캐릭터 방울은 BubbleSprite만 숨기고 **CharacterSprite는 남긴다** (B3이 이어받음)

---

## 8. 개발 단계

| 단계 | 내용 | 완료 기준 | 주 담당 |
|------|------|----------|---------|
| 0 | 환경 세팅 (Godot 설치, 프로젝트 설정, Git) | 둘 다 프로젝트 열고 실행 가능 | 율미 |
| 1 | 임시 에셋(원 도형)으로 방울 상승 + 터치 팝 | 클릭하면 사라짐 | 율미 |
| 2 | 실제 아트 교체 + Tween 팝 연출 + 파티클 | "게임처럼" 보임 | 지용 |
| 3 | 캐릭터 방울 + 리액션 + 사운드 | 아이 테스트 가능 | 공동 |
| 4 | 웹 익스포트 + GitHub Pages 배포 | 폰에서 링크로 플레이 | 율미 |

> 1단계는 **아트 없이** 시작하는 게 핵심. ColorRect나 기본 원으로 로직 먼저 검증하고,
> 지용은 그동안 에셋 생성 — 병렬 작업으로 서로 안 기다림.

---

## 9. 본편으로 가져갈 것들

이 프로젝트에서 검증되는 본편 필수 요소:
- 씬 인스턴싱 + 커스텀 시그널 패턴 (→ 본편의 오브젝트-발견 이벤트 구조)
- Area2D 터치 판정 (→ 본편의 오브젝트 터치)
- Tween 리액션 연출 (→ 본편의 까꿍/발견 연출)
- 웹 익스포트 파이프라인 (→ 그대로 재사용)
- 파일 소유권 협업 규칙 (→ 그대로 재사용)
