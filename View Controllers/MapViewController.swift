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

var riskLocationCoordinatesByLatitudes = [CLLocation]()
var riskLocationCoordinatesByLongitudes = [CLLocation]()
var riskLocationCoordinates = Array(Set(riskLocationCoordinatesByLatitudes + riskLocationCoordinatesByLongitudes))
var nearestDistance:Double = 0
var visited = Array(repeating: false, count: riskLocationCoordinates.count)

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var db: Firestore!
    var playState: Bool = false
    
    @IBOutlet weak var mapGuideLabel: UILabel!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var sirenInMap: UIImageView!
    
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let database = Firestore.firestore()
    var currentLoc: CLLocation!
    
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
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
        getOnly5km(mapToPin: myMap)
        mapGuideLabel.blink()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(riskLocationCoordinatesByLatitudes)
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        sirenInMap.isHidden = true
        if playState == true {
            
            myMap.setRegion(MKCoordinateRegion(center: (locations.last?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)), animated: true)
            
            let pLocation = locations.last
            var distanceArray = [Double]()
            
            for i in 0..<riskLocationCoordinates.count {
                
                distanceArray.append(pLocation?.distance(from: riskLocationCoordinates[i]) ?? 0)
                
            }
                
            for i in 0..<riskLocationCoordinates.count {
                
                
                if distanceArray[i] < 10 && !visited[i]{
                    UIDevice.vibrate()
                    sirenInMap.isHidden = false
                    print(sirenInMap.isHidden)
                    visited[i] = true
                    print(visited)
                }
            }
            nearestDistance = distanceArray.min() ?? 0
            let cutOffdecimalPoint = String(format: "%.2f", nearestDistance)
            distanceLabel.text = "\(cutOffdecimalPoint) m"
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
                guard let data = self.motionManager.accelerometerData else {return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let accelMagnitude = sqrt(x*x + y*y + z*z)
                //MARK: 가속도의 크기가 2 이상이면 지도에 마크 표시 & riskLocation 배열에 해당 좌표 추가
                if accelMagnitude > 1.6 && playState == true{
                    
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
    
    
    //MARK: -  위도, 경도 +-0.04이내 데이터만 받아서 배열에 저장
    func getOnly5km(mapToPin: MKMapView) {
        
        getCurrectLocationInfo { userStartLatitude, userStartLongitude in
            let queryLatitude = self.db.collection("saferoad")
                .whereField("latitude", isLessThan: userStartLatitude+0.04)
                .whereField("latitude", isGreaterThan: userStartLatitude-0.04)
            
            let queryLongitude = self.db.collection("saferoad")
                .whereField("longitude", isLessThan: userStartLongitude+0.04)
                .whereField("longitude", isGreaterThan: userStartLongitude-0.04)
            riskLocationCoordinatesByLatitudes = [CLLocation]()
            riskLocationCoordinatesByLongitudes = [CLLocation]()
            queryLatitude.getDocuments { querySnapshot, error in
                if let error = error {
                    print(error)
                    
                } else {
                    for document in querySnapshot!.documents {
                        let latitudes = String(describing: document.get("latitude")!)
                        let longitudes = String(describing: document.get("longitude")!)
                        let doubleLatitudes = Double(latitudes)
                        let doubleLongitudes = Double(longitudes)
                        riskLocationCoordinatesByLatitudes.append(CLLocation(latitude: doubleLatitudes!, longitude: doubleLongitudes!))
                        setAnnotation(latitudeValue: doubleLatitudes!, longitudeValue: doubleLongitudes!, delta: 0.1, title: "basic", subtitle: "", map: mapToPin)
                    }
                }
            }
            
            queryLongitude.getDocuments { querySnapshot, error in
                if let error = error {
                    print(error)
                    
                } else {
                    for document in querySnapshot!.documents {
                        let latitudes = String(describing: document.get("latitude")!)
                        let longitudes = String(describing: document.get("longitude")!)
                        let doubleLatitudes = Double(latitudes)
                        let doubleLongitudes = Double(longitudes)
                        riskLocationCoordinatesByLongitudes.append(CLLocation(latitude: doubleLatitudes!, longitude: doubleLongitudes!))
                        setAnnotation(latitudeValue: doubleLatitudes!, longitudeValue: doubleLongitudes!, delta: 0.1, title: "basic", subtitle: "", map: mapToPin)
                    }
                }
            }
            
        }
        
        
    }
    func getCurrectLocationInfo(completion: @escaping (Double, Double) -> Void) {
        
        switch locationManager.authorizationStatus {
        case .restricted, .denied:
            print("restricted")
        default:
            var userStartLocation: CLLocation!
            userStartLocation = locationManager.location
            let userStartLatitude = round(userStartLocation.coordinate.latitude * 100000) / 100000
            let userStartLongitude = round(userStartLocation.coordinate.longitude * 100000) / 100000
            completion(userStartLatitude, userStartLongitude)
            print(userStartLongitude)
            
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}


