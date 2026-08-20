import Foundation
import AppKit

public struct ScreenPositioner {
    
    /// Calculates the optimal window origin so the center of the radial wheel aligns with the mouse cursor,
    /// clamped within the visible frame of the active screen.
    public static func calculateFloatingOrigin(
        windowSize: CGSize,
        cursorLocation: NSPoint = NSEvent.mouseLocation,
        margin: CGFloat = 16.0
    ) -> NSPoint {
        // 1. Find active screen containing cursor
        let activeScreen = NSScreen.screens.first(where: { NSPointInRect(cursorLocation, $0.frame) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        
        guard let screen = activeScreen else {
            return cursorLocation
        }
        
        let visibleFrame = screen.visibleFrame
        
        // 2. Center the window around the mouse cursor
        var targetX = cursorLocation.x - (windowSize.width / 2.0)
        var targetY = cursorLocation.y - (windowSize.height / 2.0)
        
        // 3. Clamp X to stay fully within screen visible bounds
        let minX = visibleFrame.minX + margin
        let maxX = visibleFrame.maxX - windowSize.width - margin
        
        if maxX >= minX {
            targetX = max(minX, min(targetX, maxX))
        } else {
            targetX = visibleFrame.minX
        }
        
        // 4. Clamp Y to stay fully within screen visible bounds
        let minY = visibleFrame.minY + margin
        let maxY = visibleFrame.maxY - windowSize.height - margin
        
        if maxY >= minY {
            targetY = max(minY, min(targetY, maxY))
        } else {
            targetY = visibleFrame.minY
        }
        
        return NSPoint(x: round(targetX), y: round(targetY))
    }
}
