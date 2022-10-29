//
//  FireStoreManager.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/29.
//

import UIKit
import FirebaseFirestore
import CoreLocation

final class FireStoreManager {
    
    static let shared = FireStoreManager()
    var db: Firestore!

    private init() {
        
    }
    
    public func riskLocationDataInFireStore() {
        db = Firestore.firestore()
        db.collection("saferoad").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
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
    
        
}

