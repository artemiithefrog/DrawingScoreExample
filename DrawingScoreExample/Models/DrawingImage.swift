import SwiftUI

struct DrawingImage: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGPoint
    let color: String
    
    static let defaultImages: [DrawingImage] = [
//        DrawingImage(name: "plus", offset: CGPoint(x: -0.1, y: -0.1)),
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0.1, y: -0.1), color: "#FF0000"),
        DrawingImage(name: "star.fill", offset: CGPoint(x: -0.1, y: 0.1), color: "#00FF00"),
        DrawingImage(name: "arrow.right", offset: CGPoint(x: 0.1, y: 0.1), color: "#0000FF")
    ]
} 
