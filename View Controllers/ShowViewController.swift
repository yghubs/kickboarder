//
//  ShowViewController.swift
//  SafeRoad
//
//  Created by 유재호 on 2022/11/14.
//

import UIKit

let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

// NetworkViewController를 RootViewController로 보여주는 메소드
func showNetworkVCOnRoot() {
    DispatchQueue.main.async {
        let networkViewController = storyboard.instantiateViewController(withIdentifier: "NetworkViewController")
        networkViewController.modalPresentationStyle = .fullScreen
        UIApplication.shared.currentUIWindow()?.rootViewController?.show(networkViewController, sender: nil)
        
    }
}

public extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
        
        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }

        return window
        
    }
}
