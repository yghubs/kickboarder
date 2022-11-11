//
//  locationHelper.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/11/03.
//

import UIKit
import CoreLocation
import MapKit
import FirebaseFirestore


// 위도와 경도, 스팬(영역 폭)을 입력받아 지도에 표시
func goLocation(latitudeValue: CLLocationDegrees,
                longtudeValue: CLLocationDegrees,
                delta span: Double) -> CLLocationCoordinate2D {
    let pLocation = CLLocationCoordinate2DMake(latitudeValue, longtudeValue)
    //        let spanValue = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
    //        let pRegion = MKCoordinateRegion(center: pLocation, span: spanValue)
    return pLocation
}

// 특정 위도와 경도에 핀 설치하고 핀에 타이틀과 서브 타이틀의 문자열 표시
func setAnnotation(latitudeValue: CLLocationDegrees,
                   longitudeValue: CLLocationDegrees,
                   delta span :Double,
                   title strTitle: String,
                   subtitle strSubTitle:String,
                   map: MKMapView){
    let annotation = MKPointAnnotation()
    annotation.title = "basic"
    annotation.coordinate = goLocation(latitudeValue: latitudeValue, longtudeValue: longitudeValue, delta: span)
    annotation.title = strTitle
    annotation.subtitle = strSubTitle
    map.addAnnotation(annotation)
}

func riskLocationData(database: Firestore!, mapToPin: MKMapView) {
    riskLocationCoordinates.removeAll()
    database.collection("saferoad").getDocuments() { (querySnapshot, err) in
        if let err = err {
            print("Error getting documents: \(err)")
        } else {
            for document in querySnapshot!.documents {
                let latitudes = String(describing: document.get("latitude")!)
                let longitudes = String(describing: document.get("longitude")!)
                let doubleLatitudes = Double(latitudes)
                let doubleLongitudes = Double(longitudes)
                setAnnotation(latitudeValue: doubleLatitudes!, longitudeValue: doubleLongitudes!, delta: 0.1, title: "basic", subtitle: "", map: mapToPin)
                riskLocationCoordinates.append(CLLocation(latitude: doubleLatitudes!, longitude: doubleLongitudes!))
            }
        }
    }
}
var isRiskLocationExist: Bool = false
func checkRiskLocationAleadyExist(database: Firestore!, latitude: Double, longitude: Double) -> Bool {
    
    
    let docRef = database.collection("saferoad")
        .whereField("latitude", isEqualTo: latitude)
        .whereField("longitude", isEqualTo: longitude)
    docRef.getDocuments { (querysnapshot, error) in
        
        guard let data = querysnapshot?.documents else {return }
        
        isRiskLocationExist = data.isEmpty
    }
    
    
    return isRiskLocationExist
}





