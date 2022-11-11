//
//  HapticsManager.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/10/18.
//

import UIKit

final class HapticsManager {
    
    static let shared = HapticsManager()
    
    private init() {
        
    }
    
    public func selectionVibrate() {
        DispatchQueue.main.async {
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.prepare()
            selectionFeedbackGenerator.selectionChanged()
        }
    }
    
    public func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(type)
        }
    }
    
    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let vibrationGenerator = UIImpactFeedbackGenerator(style: style)
        vibrationGenerator.impactOccurred()
    }
    
}
