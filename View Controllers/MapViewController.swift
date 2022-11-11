//
//  MapViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/06.
//

import UIKit
import CoreMotion
import MapKit
import FirebaseFirestore

var riskLocationCoordinates = [CLLocation]()

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var db: Firestore!
    
    var playState: Bool = false
    
    @IBOutlet weak var mapGuideLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    
    @IBAction func playStateBtnDidTap(_ sender: Any) {
        playState = !playState
        if playState {
            playBtn.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: largeConfiguration)?.withRenderingMode(.alwaysOriginal), for: .normal)
            mapGuideLabel.text = "정지버튼을 누르면 탐지가 종료됩니다"
            
        } else {
            playBtn.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: largeConfiguration)?.withRenderingMode(.alwaysOriginal), for: .normal)
            mapGuideLabel.text = "재생 버튼을 누르면 탐지가 실행됩니다"
            
        }
    }
    
    
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var locationInfo2: UILabel!
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let database = Firestore.firestore()
    let haptic = HapticsManager.shared
    var currentLoc: CLLocation!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationInfo2.text = ""
        locationManager.delegate = self
        // 정확도를 최고로 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 위치 데이터를 추적하기 위해 사용자에게 승인 요구
        locationManager.requestWhenInUseAuthorization()
        guard let userLocation = locationManager.location?.coordinate else {return }
        myMap.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        
        
        // 위치 업데이트를 시작
        locationManager.startUpdatingLocation()
        // 위치 보기 설정
        myMap.showsUserLocation = true
       
        
        
        
        db = Firestore.firestore()
        
        //MARK: accelerometer & gyroscope Data
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.01
        riskLocationData(database: db, mapToPin: myMap)
        downloadRiskLocation { isRiskLocationExist in
            print(isRiskLocationExist)
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
    
        mapGuideLabel.blink()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playState = false
    }
 
    var userLocationRecord = [CLLocation]()
    
  
    
    // 위치 정보에서 국가, 지역, 도로를 추출하여 레이블에 표시
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if playState == true {
            
            myMap.setRegion(MKCoordinateRegion(center: (locations.last?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)), animated: false)
            
            let pLocation = locations.last
            userLocationRecord.append(pLocation!)
            print(userLocationRecord.count)
            if userLocationRecord.count > 10 {
                userLocationRecord.removeAll()
                
            }
            
            CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {(placemarks, error) -> Void in
                let pm = placemarks?.first
                var address: String = ""
                if pm?.locality != nil {
                    address += " "
                    address += pm!.locality!
                }
                if pm?.thoroughfare != nil {
                    address += " "
                    address += pm!.thoroughfare!
                }
                self.locationInfo2.text = "현위치 \(address)"
            })
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
                guard let data = self.motionManager.accelerometerData else {return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let accelMagnitude = sqrt(x*x + y*y + z*z)
                
                //MARK: 가속도가 임계값 이상이면 지도에 마크 표시 & riskLocation 배열에 해당 좌표 추가
                if accelMagnitude > 2 {
//                    self.haptic.vibrate(for: .success)
                    UIDevice.vibrate()
                    let digit: Double = pow(10, 3) // 10의 4제곱
                    self.currentLoc = self.locationManager.location
                    let liveLatitude = round(self.currentLoc.coordinate.latitude * digit) / digit
                    let liveLongitude = round(self.currentLoc.coordinate.longitude * digit) / digit
                    
                    if checkRiskLocationAleadyExist(database: db, latitude: liveLatitude, longitude: liveLongitude) == false {
                        setAnnotation(latitudeValue: liveLatitude, longitudeValue: liveLongitude, delta: 0.1, title: "충격 감지", subtitle: self.locationInfo2.text!, map: self.myMap)
                        var ref: DocumentReference? = nil
                        ref = self.db.collection("saferoad").addDocument(data: [
                            "latitude" : liveLatitude,
                            "longitude" : liveLongitude
                        ]) { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            } else {
                                print("Document added with ID: \(ref!.documentID)")
                            }
                        }
                    }
                    sleep(1)
                }
                
                //MARK: - riskLocation과 유저의 위치가 특정값 이하면 진동
                //만약 위험 좌표와 거리가 20m 안쪽이고, 그 물체에 직진(헤딩) 중이면 알림주기
                //    20 km/h -> 5.6m/s      20m 전에 미리 알림 줘야함
                for i in 0..<riskLocationCoordinates.count {
                    
                    let lastTwoRecordedLocationOfUser = self.userLocationRecord.suffix(2)
                    
                    if lastTwoRecordedLocationOfUser.first != nil {
                        let velocityRushingToRisk = lastTwoRecordedLocationOfUser.first!.distance(from: riskLocationCoordinates[i]) - lastTwoRecordedLocationOfUser.last!.distance(from: riskLocationCoordinates[i])
                        
                        let userCurrentSpeedToDouble = Double(String(describing: locations.last!.speed))
                        if locations.last!.distance(from: riskLocationCoordinates[i]) < 20 && abs(userCurrentSpeedToDouble!-velocityRushingToRisk)<0.1 && userCurrentSpeedToDouble ?? 0  > 5 {
                            self.haptic.vibrate(for: .warning)
                        }
                    }
                    
                }
                
            }
        }
    }
    
  
    func downloadRiskLocation(completion: @escaping (Bool) -> Void) {
        var isRiskLocationExist:Bool = false
        let query = db.collection("saferoad")
            .whereField("latitude", isEqualTo: 37.311)
        query.getDocuments { snapshot, error in
          if let error = error {
            print(error)
            completion(isRiskLocationExist)
            return
          }
            for _ in snapshot!.documents {
//            let cat = doc
//            catArray.append(cat)
              isRiskLocationExist = (snapshot?.documents.isEmpty)!
                isRiskLocationExist = true
            
              
          }
          completion(isRiskLocationExist)
        }
      }
    
    
    
    //    func checkUserNameAlreadyExist(newUserName: String, completion: @escaping(Bool) -> Void) {
    
}


