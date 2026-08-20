import SwiftUI

/// Custom Shape rendering a radial circular wedge segment.
public struct RadialWedgeShape: Shape {
    public var startAngle: Angle
    public var endAngle: Angle
    public var innerRadius: CGFloat
    public var outerRadius: CGFloat
    
    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.radians, endAngle.radians) }
        set {
            startAngle = Angle(radians: newValue.first)
            endAngle = Angle(radians: newValue.second)
        }
    }
    
    public init(startAngle: Angle, endAngle: Angle, innerRadius: CGFloat, outerRadius: CGFloat) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        
        // Outer arc clockwise
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Inner arc counter-clockwise back to start
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        return path
    }
}
