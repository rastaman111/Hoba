import UIKit

extension UISegmentedControl {
    
    func ignoreCornerRadius() {
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        
        let normalImage = renderer.image { (context) in
            tintColor.setStroke()
            context.stroke(bounds)
        }
        let selectedImage = renderer.image { (context) in
            tintColor.setFill()
            context.fill(bounds)
        }
        
        setBackgroundImage(normalImage, for: .normal, barMetrics: .default)
        setBackgroundImage(selectedImage, for: .selected, barMetrics: .default)
    }
        
}
