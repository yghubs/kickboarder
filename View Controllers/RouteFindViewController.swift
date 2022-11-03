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
    
    let mapVC = MapViewController.shared
    let locationManager = CLLocationManager()
    var destinationCoordinate = CLLocationCoordinate2D()
    var db: Firestore!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        createPath(sourceLocation: sourceLocation, destinationLocation: destinationLocation)
        locationManager.startUpdatingLocation()
        //        = CLLocation(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)
        // 위치 보기 설정
        mapView.showsUserLocation = true
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        db = Firestore.firestore()
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
        sourceAnotation.title = "start"
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
            riskLocationData(database: self.db, mapToPin: self.mapView)
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
        destinationAnnotation.title = "destination"
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
            let image = UIImage(named: "startPin")?.withRenderingMode(.alwaysTemplate)
            let resizedImage = image?.resized(to: CGSize(width: 50, height: 50))
            annotationView?.image = resizedImage
            
            
            
            
            
            
            
        default:
            break
        }
        
        return annotationView
    }
    
    
    
}

extension UIImage {
    func imageWithColor(color1: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color1.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

