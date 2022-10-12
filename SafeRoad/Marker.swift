//
//  Marker.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/12.
//

import Foundation
import MapKit

class Marker: NSObject, MKAnnotation {
  let coordinate: CLLocationCoordinate2D

  init(
    coordinate: CLLocationCoordinate2D
  ) {
    self.coordinate = coordinate

    super.init()
  }

}
