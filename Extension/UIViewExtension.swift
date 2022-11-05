//
//  UIViewExtension.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/11/04.
//

import Foundation
import UIKit

extension UIView {
    func blink() {
        self.alpha = 0.0;
        UIView.animate(withDuration: 0.8, //Time duration you want,
            delay: 0.0,
            options: [.curveEaseInOut, .autoreverse, .repeat],
            animations: { [weak self] in self?.alpha = 1.0 },
            completion: { [weak self] _ in self?.alpha = 0.0 })
    }
}
