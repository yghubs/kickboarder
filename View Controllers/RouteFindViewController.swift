//
//  LogViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/23.
//

import UIKit
import MapKit



class RouteFindViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    let locationManager = CLLocationManager()
    var destinationCoordinate = CLLocationCoordinate2D()
   
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let sourceLocation = CLLocationCoordinate2D(latitude: 37.3219, longitude: 126.8308)
        
//        createPath(sourceLocation: sourceLocation, destinationLocation: destinationLocation)
//
        locationManager.startUpdatingLocation()
        
//        = CLLocation(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)
        // 위치 보기 설정
        mapView.showsUserLocation = true
        self.mapView.delegate = self
        self.initView()
        
    }
    
    @IBAction func findBtnDidTap(_ sender: Any) {
        var userCurrentCoordinate = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)

        createPath(sourceLocation: userCurrentCoordinate, destinationLocation: destinationCoordinate)
        
    }
    
    
    
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
       
        if let location = sourcePlaceMark.location {
            sourceAnotation.coordinate = location.coordinate
        }
        
        let destinationAnotation = MKPointAnnotation()
        if let location = destinationPlaceMark.location {
            destinationAnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnotation, destinationAnotation], animated: true)
        
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
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            
        }
    }

}

extension RouteFindViewController  {
    
    //제스처 조작
    @objc
    private func didTappedMapView(_ sender: UITapGestureRecognizer) {
        
        let location: CGPoint = sender.location(in: self.mapView)
        let mapPoint: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        removeAllAnnotations()
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = mapPoint
        self.mapView.addAnnotation(destinationAnnotation)
        
        destinationCoordinate = mapPoint
        print(destinationCoordinate)
        

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
    
    
    
    
}
