# 킥보더
도로 위 장애물 탐지 및 진동 알림 앱

## 프로젝트 소개
한국의 도로, 특히 인도는 굉장히 불균일합니다.  
킥보드 사용자가 불균일한 도로나 요철을 밟게 되면 충격이 발생하고, 정도에 따라 크게 다칠 위험이 있습니다.  
특정 임계값 이상 충격이 가해지면 해당 좌표를 지도에 남기고 firebase에 업로드합니다.  
이 좌표를 모든 사용자가 공유하며, 해당 지역을 지날 때마다 스마트폰에 진동 알림이 울리도록 구성하였습니다.  

## 앱 구현
앱은 크게 지도탭과 길찾기 탭으로 구성됩니다

### 지도탭
- 지도탭은 모든 유저들이 기록한 위험 좌표가 공유되며, 가장 근접한 좌표가 몇 m 이내에 있는지 알려줍니다
- 위험 좌표가 10m 거리 이내이고, 1.5m/s 이상의 속력으로 주행 중이면 진동 알림을 줍니다
<img width="252" alt="image" src="https://user-images.githubusercontent.com/113229215/205490903-f1860409-6a55-429d-9eef-381496521382.png">  
- 만약 턱을 밟아 스마트폰의 가속도 크기가 2m/s^2이상이면 지도에 '충격감지' 마크를 남기고, 해당 좌표를 서버에 업로드 합니다.
 <img width="252" alt="스크린샷 2022-12-11 오후 9 07 38" src="https://user-images.githubusercontent.com/113229215/206902696-a37775be-5b28-4ac3-89f3-00cd42ef3edb.png">
 <img width="600" alt="스크린샷 2022-12-11 오후 9 45 15" src="https://user-images.githubusercontent.com/113229215/206904300-5ed1ce49-c7b7-4ab6-81ee-b5b2a3d154e6.png">  




### 길찾기 탭은 초행길을 떠나는 유저들을 위한 탭입니다.  
- 지도탭과 기능적으로 유사하고, 길찾기 기능이 추가 되었습니다.
- 사용자는 자신이 가는 길에 위험좌표가 어디에 있는지와 몇 개가 존재하는지 확인할 수 있습니다.
<img width="252" alt="image" src="https://user-images.githubusercontent.com/113229215/205490953-36e610f8-4845-405e-bb86-e1d04e48b665.png">



