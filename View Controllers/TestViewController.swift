//
//  TestViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/24.
//

import UIKit
import MapKit

class TestViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initView()
    }
    
    private func initView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        self.mapView.addGestureRecognizer(tap)
    }
}

//
// MARK:- 맵을 터치 했을 때
//

extension TestViewController {
    
    /// 제스처 조작
    @objc
    private func didTappedMapView(_ sender: UITapGestureRecognizer) {
        let location: CGPoint = sender.location(in: self.mapView)
        let mapPoint: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        
        if sender.state == .ended {
            self.searchLocation(mapPoint)
        }
    }
    
    /// 하나만 출력하기 위하여 모든 포인트를 삭제
    private func removeAllAnnotations() {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
    }
    
    /// 해당 포인트의 주소를 검색
    private func searchLocation(_ point: CLLocationCoordinate2D) {
        let geocoder: CLGeocoder = CLGeocoder()
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        
        // 포인트 리셋
        self.removeAllAnnotations()
        
        geocoder.reverseGeocodeLocation(location) { (placeMarks, error) in
            if error == nil, let marks = placeMarks {
                marks.forEach { (placeMark) in
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                    
                    self.locationLabel.text =
                    """
                    \(placeMark.administrativeArea ?? "")
                    \(placeMark.locality ?? "")
                    \(placeMark.thoroughfare ?? "")
                    \(placeMark.subThoroughfare ?? "")
                    """
                    
                    self.mapView.addAnnotation(annotation)
                }
            } else {
                self.locationLabel.text = "검색 실패"
            }
        }
    }
}

