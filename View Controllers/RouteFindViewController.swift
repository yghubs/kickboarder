//
//  LogViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/23.
//

import UIKit
import CoreMotion
import MapKit
import FirebaseFirestore


class RouteFindViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let haptic = HapticsManager.shared
    
    var currentLoc: CLLocation!
    var destinationCoordinate = CLLocationCoordinate2D()
    var dbInRouteFind: Firestore!
    var routeFindPlayState: Bool = false

    
    @IBOutlet weak var guideLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeFindPlayBtn: UIButton!
    @IBAction func findBtnDidTap(_ sender: Any) {
        
        var userCurrentCoordinate = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)

        routeFindPlayState = !routeFindPlayState
        
        if routeFindPlayState {
            routeFindPlayBtn.setImage(UIImage(systemName: "pause", withConfiguration: mediumConfiguration)?.withRenderingMode(.alwaysTemplate), for: .normal)
            routeFindPlayBtn.setTitle("", for: .normal)
            createPath(sourceLocation: userCurrentCoordinate, destinationLocation: destinationCoordinate)
            
        } else {
//            let largeConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold, scale: .large)
            routeFindPlayBtn.backgroundColor = .systemBlue
            routeFindPlayBtn.setTitle("시작", for: .normal)
            routeFindPlayBtn.setImage(UIImage(systemName: "scooter"), for: .normal)
            routeFindPlayBtn.tintColor = .white
            guideLabel.text = "목적지를 지도에서 탭하세요"
            removeAllOverlays()
            removeAllAnnotations()
            
        }
      }
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.mapView.delegate = self
        dbInRouteFind = Firestore.firestore()
        locationManager.delegate = self
        
        // 정확도를 최고로 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
       
        // 위치 업데이트를 시작
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        guard let userLocation = locationManager.location?.coordinate else {return }
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.01
        
        self.initView()
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guideLabel.blink()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        routeFindPlayState = false
    }
    
//    func removeEverythingIfPlayStateIsFalse() {
//        if routeFindPlayState == false {
//            removeAllOverlays()
//            removeAllAnnotations()
//            guideLabel.text = "목적지를 지도에서 탭하세요"
//        }
//    }
    
    private func initView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        self.mapView.addGestureRecognizer(tap)
       

    }
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        guard locations.last != nil else {return }
    //        let startLocationCoordinates = CLLocationCoordinate2D(latitude: (locations.last?.coordinate.latitude)!, longitude: (locations.last?.coordinate.longitude)!)
    //    }
    

    func createPath(sourceLocation : CLLocationCoordinate2D, destinationLocation : CLLocationCoordinate2D) {
        
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        let destinationItem = MKMapItem(placemark: destinationPlaceMark)
        
        
        let sourceAnotation = MKPointAnnotation()
        sourceAnotation.title = "start"
        self.mapView.addAnnotation(sourceAnotation)
        if let location = sourcePlaceMark.location {
            sourceAnotation.coordinate = location.coordinate
        }
        
        //riskLocation 핀꽂기
        riskLocationData(database: dbInRouteFind, mapToPin: mapView)
        
        
        let destinationAnotation = MKPointAnnotation()
        if let location = destinationPlaceMark.location {
            destinationAnotation.coordinate = location.coordinate
        }
        
//        self.mapView.showAnnotations([sourceAnotation, destinationAnotation], animated: true)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .walking
        
        let direction = MKDirections(request: directionRequest)
        
        direction.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("ERROR FOUND : \(error.localizedDescription)")
                }
                return
            }
            
            let route = response.routes[0]
            //            if routeFindP
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            //            let rect = route.polyline.boundingMapRect
            //            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            //            riskLocationData(database: self.db, mapToPin: self.mapView)

        }
//        riskLocationData(database: dbInRouteFind, mapToPin: mapView)


    }
    
    var routeFindUserLocatioRecord = [CLLocation]()

}

extension RouteFindViewController {

    
    //제스처 조작
    @objc
    private func didTappedMapView(_ sender: UITapGestureRecognizer) {
        
        let location: CGPoint = sender.location(in: self.mapView)
        let mapPoint: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        removeAllAnnotations()
        guideLabel.text = ""
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = mapPoint
        destinationAnnotation.title = "destination"
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.addAnnotation(destinationAnnotation)
        destinationCoordinate = mapPoint
        routeFindPlayState = false
        routeFindPlayBtn.backgroundColor = .systemBlue
        routeFindPlayBtn.setTitle("시작", for: .normal)
        routeFindPlayBtn.setImage(UIImage(systemName: "scooter"), for: .normal)
        routeFindPlayBtn.tintColor = .white

        
        
        //        if sender.state == .ended {
        //            self.searchLocation(mapPoint)
        //        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let rendere = MKPolylineRenderer(overlay: overlay)
        rendere.lineWidth = 5
        rendere.strokeColor = .systemBlue
        
        return rendere
    }
    
    private func removeAllAnnotations() {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
    }
    
    private func removeAllOverlays() {
        let allOverlays = self.mapView.overlays
        self.mapView.removeOverlays(allOverlays)

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "custom")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "custom")
        } else {
            annotationView?.annotation = annotation
            
        }
        
        switch annotation.title {
        case "destination":
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .large)
            annotationView?.image = UIImage(systemName: "mappin.and.ellipse", withConfiguration: largeConfig)?.withRenderingMode(.alwaysTemplate).imageWithColor(color1: UIColor.systemGreen)
            
        case "start":
            let image = UIImage(named: "startPin")
            let resizedImage = image?.resized(to: CGSize(width: 29.04, height: 40.23))
            annotationView?.image = resizedImage
        
        case "basic":
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .medium)
            annotationView?.image = UIImage(systemName: "mappin", withConfiguration: largeConfig)?.withRenderingMode(.alwaysTemplate).imageWithColor(color1: UIColor.red)
        
        default:
            break
        }
        
        return annotationView
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if routeFindPlayState == true {
//            mapView.setRegion(MKCoordinateRegion(center: (locations.last?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: false)
            let pLocation = locations.last
            routeFindUserLocatioRecord.append(pLocation!)
            print(routeFindUserLocatioRecord.count)
            if routeFindUserLocatioRecord.count > 10 {
                routeFindUserLocatioRecord.removeAll()
            }
            
//            CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {(placemarks, error) -> Void in
//                let pm = placemarks?.first
//                var address: String = ""
//                if pm?.locality != nil {
//                    address += " "
//                    address += pm!.locality!
//                }
//                if pm?.thoroughfare != nil {
//                    address += " "
//                    address += pm!.thoroughfare!
//                }
//                self.locationInfo2.text = "현위치 \(address)"
//            })
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                guard let data = self.motionManager.accelerometerData else {return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let accelMagnitude = sqrt(x*x + y*y + z*z)
                
                //MARK: 가속도가 임계값 이상이면 지도에 마크 표시 & riskLocation 배열에 해당 좌표 추가
                if accelMagnitude > 2.5 {
                    let digit: Double = pow(10, 3) // 10의 3제곱
                    self.currentLoc = self.locationManager.location
                    let liveLatitude = round(self.currentLoc.coordinate.latitude * digit) / digit
                    let liveLongitude = round(self.currentLoc.coordinate.longitude * digit) / digit
                    setAnnotation(latitudeValue: liveLatitude, longitudeValue: liveLongitude, delta: 0.1, title: "충격 감지", subtitle: "", map: self.mapView)
                    self.haptic.vibrate(for: .success)
                    var ref: DocumentReference? = nil
                    ref = self.dbInRouteFind.collection("saferoad").addDocument(data: [
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
                    
                    
                    let lastTwoRecordedLocationOfUser = self.routeFindUserLocatioRecord.suffix(2)
                    
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
    
}
