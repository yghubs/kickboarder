import Foundation
import UIKit

class CustomTabBarvc: UITabBarController, UITabBarControllerDelegate {
    
    var customTabBarView = UIView(frame: .zero)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.selectedIndex = 0
        self.setupTabBarUI()
        self.addCustomTabBarView()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
//
    private func addCustomTabBarView() {
        self.customTabBarView.frame = tabBar.frame
        self.tabBar.backgroundColor = .white
        self.tabBar.layer.cornerRadius = 30
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.tabBar.layer.masksToBounds = false
        self.tabBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.tabBar.layer.shadowOffset = CGSize(width: -4, height: -4)
        self.tabBar.layer.shadowOpacity = 0.9
        self.tabBar.layer.shadowRadius = 20
        self.view.bringSubviewToFront(self.tabBar)
    }
    
    private func setupTabBarUI() {
        // Setup your colors and corner radius
        self.tabBar.backgroundColor = .white
        self.tabBar.layer.cornerRadius = 30
        self.tabBar.layer.masksToBounds = true
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.tabBar.backgroundColor = .white
        self.tabBar.tintColor = .systemBlue
        self.tabBar.unselectedItemTintColor = .white

        // Remove the line
        if #available(iOS 13.0, *) {
            let appearance = self.tabBar.standardAppearance
            appearance.shadowImage = nil
            appearance.shadowColor = nil
            self.tabBar.standardAppearance = appearance
        } else {
            self.tabBar.shadowImage = UIImage()
            self.tabBar.backgroundImage = UIImage()
        }
    }
    private func setTabBarItemBadgeAppearance(_ itemAppearance: UITabBarItemAppearance) {
        //Adjust the badge position as well as set its color
        itemAppearance.normal.badgeBackgroundColor = .blue
        itemAppearance.normal.badgeTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        itemAppearance.normal.badgePositionAdjustment = UIOffset(horizontal: 10, vertical: -10)
    }
    
    
}
