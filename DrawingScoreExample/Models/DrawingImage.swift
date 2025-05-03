import SwiftUI

struct DrawingImage: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGPoint
    
    static let defaultImages: [DrawingImage] = [
//        DrawingImage(name: "plus", offset: CGPoint(x: -0.1, y: -0.1)),
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0.1, y: -0.1)),
        DrawingImage(name: "star.fill", offset: CGPoint(x: -0.1, y: 0.1)),
        DrawingImage(name: "arrow.right", offset: CGPoint(x: 0.1, y: 0.1))
    ]
} 
