//
//  ViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/06.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    let motionManager = CMMotionManager()
        var timer: Timer!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            motionManager.startAccelerometerUpdates()
            motionManager.startGyroUpdates()
            motionManager.startMagnetometerUpdates()
            motionManager.startDeviceMotionUpdates()
//            
//            timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        }

    //
    //    @IBAction func locationSegment(_ sender: UISegmentedControl) {
    //        if sender.selectedSegmentIndex == 0 {
    //            // "현재 위치" 선택 - 현재 위치 표시
    //            self.locationInfo1.text = ""
    //            self.locationInfo2.text = ""
    //            locationManager.startUpdatingLocation()
    //        } else if sender.selectedSegmentIndex == 1 {
    //            // "물왕저수지 정통밥집" 선택 - 핀을 설치하고 위치 정보 표시
    //            setAnnotation(latitudeValue: 37.5051, longitudeValue: 126.9571, delta: 0.1, title: "중앙대학교", subtitle: "서울특별시 동작구 흑석동")
    //            self.locationInfo1.text = "보고 계신 위치"
    //            self.locationInfo2.text = "중앙대학교"
    //        } else if sender.selectedSegmentIndex == 2 {
    //            // "이디야 북한산점" 선택 - 핀을 설치하고 위치 정보 표시
    //            setAnnotation(latitudeValue: 37.3219, longitudeValue: 126.8308, delta: 0.1, title: "안산시청", subtitle: "안산시 단원구")
    //            self.locationInfo1.text = "보고 계신 위치"
    //            self.locationInfo2.text = "안산시청"
    //        }
    //
    //    }
    //
    

}

