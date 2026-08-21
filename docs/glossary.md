루이 - rui
토토 - toto
버블 - baubble

# 버블 화면 이미지 변수명 (Bubble.tscn)
방울 이미지(노드명) - BubbleSprite (파일: spr_bubble.png)
캐릭터 이미지(노드명) - CharacterSprite (파일: spr_rui_idle.png, 루이일 때만 표시)

# 빠방 화면 변수명 (vehicle.gd, VehicleType enum)
경찰차 - POLICE_CAR (파일: spr_police_car.png)
구급차 - AMBULANCE (파일: spr_ambulance.png)
불도저 - BULLDOZER (파일: spr_bulldozer.png)
트럭 - TRUCK (파일: spr_truck.png)
타요 - BLUEBUS (파일: spr_bluebus.png)
로기 - GREENBUS (파일: spr_greenbus.png)
가니 - REDBUS (파일: spr_redbus.png)
라니 - YELLOWBUS (파일: spr_yellowbus.png)
씨투 - CITU (파일: spr_citu.png)
탈것 이미지(노드명) - VehicleSprite (파일 없으면 종류별 색으로 임시 표6시)

# 친구들 화면 변수명 (Friends.tscn, face_item.gd, FACE_PAIRS)
얼굴 이미지(노드명) - FaceSprite (터지기 전/후 그림이 짝을 이룸)
짝1 터지기 전 - face_item_1.png / 터진 후 - face_item_2.png
짝2 터지기 전 - face_item_3.png / 터진 후 - face_item_4.png
친구들 메뉴 버튼 - FriendsButton (파일: btn_frd.png)
친구들 진입 소리 - FRIENDS_SOUND (파일: bbok.wav, main_menu.gd)

# 친구들 진입 비밀번호 팝업 (MainMenu.tscn/PinLayer, main_menu.gd)
비밀번호 상수 - FRIENDS_PIN ("2024", main_menu.gd)
팝업 루트(노드명) - PinLayer/PinPopup
바깥 어둡게 처리(노드명) - Dimmer (터치 시 팝업 닫힘)
입력 자리 표시(노드명) - DotsLabel (● ○로 입력 개수 표시)
숫자 버튼(노드명) - GridContainer/Digit0~Digit9
지우기 버튼(노드명) - ClearButton
취소 버튼(노드명) - CancelButton

# 하나둘셋(숫자) 화면 변수명 (Num.tscn, number.gd, NumberPiece)
숫자 화면 씬 - Num.tscn / number.gd
숫자 조각(노드명) - NumberPiece (Number.tscn)
숫자 이미지(노드명) - NumberSprite
0 - spr_0.png
1 - spr_1.png
2 - spr_2.png
3 - spr_3.png
4 - spr_4.png
5 - spr_5.png
6 - spr_6.png
7 - spr_7.png
8 - spr_8.png
9 - spr_9.png
하나둘셋 메뉴 버튼 - NumButton (파일: btn_num.png)
