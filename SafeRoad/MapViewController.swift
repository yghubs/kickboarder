//
//  MapViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/06.
//

import UIKit
import MapKit
import CoreMotion
import FirebaseFirestore
var riskLocationCoordinates = [CLLocation]()



class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var db: Firestore!
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var locationInfo1: UILabel!
    @IBOutlet weak var locationInfo2: UILabel!
    //    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var accelLabel: UILabel!
    
    
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let database = Firestore.firestore()
    
    var currentLoc: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationInfo1.text = ""
        locationInfo2.text = ""
        locationManager.delegate = self
        // 정확도를 최고로 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 위치 데이터를 추적하기 위해 사용자에게 승인 요구
        locationManager.requestWhenInUseAuthorization()
        // 위치 업데이트를 시작
        locationManager.startUpdatingLocation()
        // 위치 보기 설정
        myMap.showsUserLocation = true
        
        //MARK: accelerometer & gyroscope Data
        //        motionManager.startGyroUpdates()
        
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.01
        db = Firestore.firestore()
        //MARK: firebase Database
        
        //        docRef.getDocument { snapshot , error in
        //            guard let data = snapshot?.data(), error == nil else {
        //                return
        //            }
        //
        //            print(data)
        //        }
        getRiskLocationData()
        //        markingKnownRiskLocation()
        
        
        
        
    }
    //
    //    func doubleToCLLocation() -> CLLocation {
    ////        var locationOfDouble = [data1, data2]
    //        var locationOfCLLocation = CLLocation(latitude: _, longitude: _)
    //        return locationOfCLLocation
    //    }
    
    
    func getRiskLocationData() {
        
        db.collection("saferoad").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    //                    setAnnotation(latitudeValue: document.get("latitude"), longitudeValue: document.get("longitude"), delta: 0.1, title: "충격감지", subtitle: "주의")
                    let latitudes = String(describing: document.get("latitude")!)
                    let longitudes = String(describing: document.get("longitude")!)
                    let doubleLatitudes = Double(latitudes)
                    let doubleLongitudes = Double(longitudes)
                    self.setAnnotation(latitudeValue: doubleLatitudes!, longitudeValue: doubleLongitudes!, delta: 0.1, title: "", subtitle: "")
                    riskLocationCoordinates.append(CLLocation(latitude: doubleLatitudes!, longitude: doubleLongitudes!))
                    
                }
                
                
            }
        }
    }
    
    
    
    
    // 위도와 경도, 스팬(영역 폭)을 입력받아 지도에 표시
    func goLocation(latitudeValue: CLLocationDegrees,
                    longtudeValue: CLLocationDegrees,
                    delta span: Double) -> CLLocationCoordinate2D {
        let pLocation = CLLocationCoordinate2DMake(latitudeValue, longtudeValue)
        let spanValue = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        let pRegion = MKCoordinateRegion(center: pLocation, span: spanValue)
        myMap.setRegion(pRegion, animated: true)
        return pLocation
    }
    
    // 특정 위도와 경도에 핀 설치하고 핀에 타이틀과 서브 타이틀의 문자열 표시
    func setAnnotation(latitudeValue: CLLocationDegrees,
                       longitudeValue: CLLocationDegrees,
                       delta span :Double,
                       title strTitle: String,
                       subtitle strSubTitle:String){
        let annotation = MKPointAnnotation()
        annotation.coordinate = goLocation(latitudeValue: latitudeValue, longtudeValue: longitudeValue, delta: span)
        annotation.title = strTitle
        annotation.subtitle = strSubTitle
        myMap.addAnnotation(annotation)
    }
    
    var userLocationRecord = [CLLocation]()
    
    // 위치 정보에서 국가, 지역, 도로를 추출하여 레이블에 표시
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let pLocation = locations.last
        userLocationRecord.append(pLocation!)
        print(userLocationRecord.count)
        if userLocationRecord.count > 10 {
            for i in 0...8{
                userLocationRecord.remove(at: 0)
            }
        }
        
        //        _ = goLocation(latitudeValue: (pLocation?.coordinate.latitude)!,
        //                       longtudeValue: (pLocation?.coordinate.longitude)!,
        //                       delta: 0.01)
        CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {(placemarks, error) -> Void in
            let pm = placemarks?.first
            let country = pm?.country
            var address: String = ""
            if country != nil {
                address = country!
            }
            
            
            if pm?.locality != nil {
                address += " "
                address += pm!.locality!
            }
            
            
            if pm?.thoroughfare != nil {
                address += " "
                address += pm!.thoroughfare!
            }
            self.locationInfo1.text = "현재 위치"
            self.locationInfo2.text = address
        })
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            
            guard let data = self.motionManager.accelerometerData else {return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let accelMagnitude = sqrt(x*x + y*y + z*z)
            
            self.accelLabel.text = "현재 가속도는 \(String(format: "%.2f",accelMagnitude)) 입니다"
            
            //            guard let gyroData = self.motionManager.gyroData else {return }
            //            gyroData.rotationRate.x
            //MARK: 가속도가 임계값 이상이면 지도에 마크 표시 & riskLocation 배열에 해당 좌표 추가
            if accelMagnitude > 1.5 {
                self.currentLoc = self.locationManager.location
                let liveLatitude = Double(self.currentLoc.coordinate.latitude)
                let liveLongitude = Double(self.currentLoc.coordinate.longitude)
                self.setAnnotation(latitudeValue: liveLatitude, longitudeValue: liveLongitude, delta: 0.1, title: "충격 감지", subtitle: self.locationInfo2.text!)
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
                
                sleep(1)
            }
            
            
            
            //MARK: - riskLocation과 유저의 위치가 특정값 이하면 진동
            //만약 위험 좌표와 거리가 20m 안쪽이고, 그 물체에 직진(헤딩) 중이면 알림주기
            //    20 km/h -> 5.6m/s      20m 전에 미리 알림 줘야함
            for i in 0..<riskLocationCoordinates.count {
                //
                let lastTwoRecordedLocationOfUser = self.userLocationRecord.suffix(2)
                let velocityRushingToRisk = lastTwoRecordedLocationOfUser.first!.distance(from: riskLocationCoordinates[i]) - lastTwoRecordedLocationOfUser.last!.distance(from: riskLocationCoordinates[i])
                let userCurrentSpeedToDouble = Double(String(describing: locations.last!.speed))
                if locations.last!.distance(from: riskLocationCoordinates[i]) < 20 && abs(userCurrentSpeedToDouble!-velocityRushingToRisk)>0.1  {
                    print("경고! 전방에 위험요소가 있습니다")
                }
            }
            
        }
    }
    
    //    func clLocationToAddress ([CLLocation] -> [CLGeocoder])
    
    func pushNotification() {
        
        
        
    }
    
   
    
}


