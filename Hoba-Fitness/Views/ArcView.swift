import UIKit

final class ArcView: UIView {
    var color: UIColor = .blue
    var trackColor: UIColor = .clear
    var trackWidth: CGFloat = 8
    
    var startPercentage: CGFloat = 0
    var fillPercentage: CGFloat = 0 //10.8
    
    var storedFrame: CGRect = CGRect()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.storedFrame = frame
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundColor = UIColor.clear
    }
    
    private func getGraphStartAndEndPointsInRadians() -> (graphStartingPoint: CGFloat, graphEndingPoint: CGFloat) {
        // make sure our starting point is at least 0 and less than 100
        if ( 0 > self.startPercentage ) {
            self.startPercentage = 0
        } else if ( 100 < self.startPercentage ) {
            self.startPercentage = 100
        } // if
        
        // make sure our fill percentage is at least 0 and less than 100
        if ( 0 > self.fillPercentage ) {
            self.fillPercentage = 0
        } else if ( 100 < self.fillPercentage ) {
            self.fillPercentage = 100
        } // if
        
        // we take 25% off the starting point, so that a zero starting point
        // begins at the top of the circle instead of the right side...
        self.startPercentage = self.startPercentage - 25
        
        // we calculate a true fill percentage as we need to account
        // for the potential difference in starting points
        let trueFillPercentage = self.fillPercentage + self.startPercentage
        
        let π: CGFloat = .pi
        
        // now we can calculate our start and end points in radians
        let startPoint: CGFloat = ((2 * π) / 100) * (CGFloat(self.startPercentage))
        let endPoint: CGFloat = ((2 * π) / 100) * (CGFloat(trueFillPercentage))
        
        return(startPoint, endPoint)
        
    } // func
    
    func reDraw() {
        draw(storedFrame)
    }
    
    override func draw(_ rect: CGRect) {
        // first we want to find the centerpoint and the radius of our rect
        
        let center: CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = rect.width / 2
        
        // make sure our track width is at least 1
        if ( 1 > self.trackWidth) {
            self.trackWidth = 1
        } // if
        
        // and our track width cannot be greater than the radius of our circle
        if ( radius < self.trackWidth ) {
            self.trackWidth = radius
        } // if
        
        // we need our graph starting and ending points
        let (graphStartingPoint, graphEndingPoint) = self.getGraphStartAndEndPointsInRadians()
        
        // now we need to first draw the track...
        let trackPath = UIBezierPath(arcCenter: center, radius: radius - (trackWidth / 2), startAngle: graphStartingPoint, endAngle: 2.0 * .pi, clockwise: true)
        trackPath.lineWidth = trackWidth
        self.trackColor.setStroke()
        trackPath.stroke()
        
        // now we can draw the progress arc
        let percentagePath = UIBezierPath(arcCenter: center, radius: radius - (trackWidth / 2), startAngle: graphStartingPoint, endAngle: graphEndingPoint, clockwise: true)
        percentagePath.lineWidth = trackWidth
        percentagePath.lineCapStyle = .square
        self.color.setStroke()
        percentagePath.stroke()
        return
    }
}
