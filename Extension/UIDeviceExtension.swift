//
//  VibrationViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/11/11.
//

import UIKit
import AVFoundation

extension UIDevice {

    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
}
