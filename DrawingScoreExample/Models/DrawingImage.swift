import SwiftUI

struct DrawingImage: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGPoint
    let color: String
    let size: CGFloat
    let rotation: Double
    
    static let defaultImages: [DrawingImage] = [
//        DrawingImage(name: "plus", offset: CGPoint(x: -0.1, y: -0.1)),
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0.1, y: -0.1), color: "#FF0000", size: 50, rotation: 45),
        DrawingImage(name: "star.fill", offset: CGPoint(x: -0.1, y: 0.1), color: "#00FF00", size: 250, rotation: -30),
        DrawingImage(name: "arrow.right", offset: CGPoint(x: 0.1, y: 0.1), color: "#0000FF", size: 250, rotation: 90)
    ]
} 
