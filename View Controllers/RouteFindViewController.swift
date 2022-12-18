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
    
    var currentLoc: CLLocation!
    var destinationCoordinate = CLLocationCoordinate2D()
    var dbInRouteFind: Firestore!
    var routeFindPlayState: Bool = false
    
    
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeFindPlayBtn: UIButton!
    
    @IBOutlet weak var nearestLabelRouteFind: UILabel!
    
    
    @IBAction func findBtnDidTap(_ sender: Any) {
        
        let userCurrentCoordinate = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)
        
        if Reachability.isConnectedToNetwork() { // 네트워크 연결 성공하면
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
        for i in riskLocationCoordinates {
            setAnnotation(latitudeValue: i.coordinate.latitude, longitudeValue: i.coordinate.longitude, delta: 0.1, title: "basic", subtitle: "", map: mapView)
        }
        
        
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
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if routeFindPlayState == true {

            let pLocation = locations.last
          
            var distanceArrayInRouteFind = [Double]()

            for i in 0..<riskLocationCoordinates.count {
                
                distanceArrayInRouteFind.append(pLocation?.distance(from: riskLocationCoordinates[i]) ?? 0)
                
            }
                
            for i in 0..<riskLocationCoordinates.count {
                
                
                if distanceArrayInRouteFind[i] < 10 && !visited[i]{
                    UIDevice.vibrate()
                    visited[i] = true
                    print(visited)
                }
            }
            nearestDistance = distanceArrayInRouteFind.min() ?? 0
            let cutOffdecimalPointInRouteFind = String(format: "%.2f", nearestDistance)
            nearestLabelRouteFind.text = "\(cutOffdecimalPointInRouteFind) m"
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                guard let data = self.motionManager.accelerometerData else {return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let accelMagnitude = sqrt(x*x + y*y + z*z)
           
            }
        }
    }
    
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
    

    
}
