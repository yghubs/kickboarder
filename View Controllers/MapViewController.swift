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
var nearestDistance:Double = 0
class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var db: Firestore!
    var playState: Bool = false
    
    @IBOutlet weak var mapGuideLabel: UILabel!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBAction func playStateBtnDidTap(_ sender: Any) {
        if Reachability.isConnectedToNetwork() {
            playState = !playState
            if playState {
                playBtn.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: largeConfiguration)?.withRenderingMode(.alwaysOriginal), for: .normal)
                mapGuideLabel.text = "위험좌표에 접근하면 진동이 울립니다"
                
            } else {
                playBtn.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: largeConfiguration)?.withRenderingMode(.alwaysOriginal), for: .normal)
                mapGuideLabel.text = "재생 버튼을 누르면 탐지가 실행됩니다"
                
            }
        } else if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(
                title: "네트워크에 접속할 수 없습니다.",
                message: "네트워크 연결 상태를 확인해주세요.",
                preferredStyle: .alert
            )
            let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
                
            }
            alertController.addAction(confirmAction)
            present(alertController, animated: false, completion: nil)
            playState = false
        }
        
        
        
        
    }
    
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let database = Firestore.firestore()
    var currentLoc: CLLocation!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        // 정확도를 최고로 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 위치 데이터를 추적하기 위해 사용자에게 승인 요구
        locationManager.requestWhenInUseAuthorization()
        // 위치 업데이트를 시작
        locationManager.startUpdatingLocation()
        // 위치 보기 설정
        myMap.showsUserLocation = true
        
        db = Firestore.firestore()
        
        //MARK: accelerometer & gyroscope Data
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.01
        riskLocationData(database: db, mapToPin: myMap)
        //        downloadRiskLocation { isRiskLocationExist in
        //            print(isRiskLocationExist)
        //        }
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
        
        mapGuideLabel.blink()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playState = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            guard let userLocation = locationManager.location?.coordinate else {return }
            myMap.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            break
        case .restricted, .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            let alert = UIAlertController(title: "위치권한 거부", message: "설정에서 위치권한을 허용으로 바꾸면 앱이 실행됩니다", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
                exit(-1)
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        @unknown default:
            return
        }
    }
    
    var userLocationRecord = [CLLocation]()
    
    //
    //    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    //
    
    //
    //    }
    
    // 위치 정보에서 국가, 지역, 도로를 추출하여 레이블에 표시
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
       
        
        if playState == true {
            
            myMap.setRegion(MKCoordinateRegion(center: (locations.last?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)), animated: true)
            
            let pLocation = locations.last
            userLocationRecord.append(pLocation!)
            print(userLocationRecord.count)
            
            for i in 0..<riskLocationCoordinates.count {
                
                var distanceArray = [Double]()
                distanceArray.append(pLocation?.distance(from: riskLocationCoordinates[i]) ?? 0)
                nearestDistance = distanceArray.min() ?? 0
                let cutOffdecimalPoint = String(format: "%.2f", nearestDistance)
                distanceLabel.text = "\(cutOffdecimalPoint) m"
            }
            if userLocationRecord.count > 10 {
                userLocationRecord.removeAll()
                
            }
            
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
                    let digit: Double = pow(10, 5) // 10의 5제곱
                    self.currentLoc = self.locationManager.location
                    let liveLatitude = round(self.currentLoc.coordinate.latitude * digit) / digit
                    let liveLongitude = round(self.currentLoc.coordinate.longitude * digit) / digit
                    
                    //MARK: 해당 좌표가 서버에 존재하면 좌표 추가안함
                    checkRiskLocationExist(latitude: liveLatitude, longitude: liveLongitude) { isRiskLocationExist in
                        if isRiskLocationExist == false {
                            print("해당 좌표 없음")
                            setAnnotation(latitudeValue: liveLatitude, longitudeValue: liveLongitude, delta: 0.1, title: "충격 감지", subtitle: "", map: self.myMap)
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
                        } else {
                            print("해당 좌표는 이미 존재합니다")
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
                            UIDevice.vibrate()
                        }
                    }
                    
                }
                
            }
        }
    }
    
    
    func checkRiskLocationExist(latitude: Double, longitude: Double, completion: @escaping (Bool) -> Void) {
        
        var isRiskLocationExist:Bool = false
        
        let query = db.collection("saferoad")
            .whereField("latitude", isEqualTo: latitude)
            .whereField("longitude", isEqualTo: longitude)
        query.getDocuments { snapshot, error in
            if let error = error {
                print(error)
                completion(isRiskLocationExist)
                return
            }
            for _ in snapshot!.documents {
                isRiskLocationExist = !((snapshot?.documents.isEmpty)!)
            }
            completion(isRiskLocationExist)
        }
    }
    
//    func getOnly5km(latitude: Double, longitude: Double, completion: @escaping (Bool) -> Void) {
//
//        let query = db.collection("saferoad")
//            .whereField("latitude", isLessThan: <#T##Any#>)
//
//    }
    
    
    
    
    
    //    func checkUserNameAlreadyExist(newUserName: String, completion: @escaping(Bool) -> Void) {
    
}


