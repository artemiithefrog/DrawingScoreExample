import SwiftUI

struct DrawingImage: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGPoint
    let color: String
    let size: CGFloat
    let rotation: Double

    static let defaultImages: [DrawingImage] = [
        DrawingImage(name: "eye.fill", offset: CGPoint(x: 0, y: 0), color: "#000000", size: 0, rotation: 0),

        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0, y: 0), color: "#A9A9A9", size: 200, rotation: 0),

        DrawingImage(name: "triangle.fill", offset: CGPoint(x: -0.13, y: -0.14), color: "#A9A9A9", size: 60, rotation: -45),
        DrawingImage(name: "triangle.fill", offset: CGPoint(x: 0.13, y: -0.14), color: "#A9A9A9", size: 60, rotation: 45),

        DrawingImage(name: "circle.fill", offset: CGPoint(x: -0.07, y: -0.03), color: "#000000", size: 20, rotation: 0),
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0.07, y: -0.03), color: "#000000", size: 20, rotation: 0),

        DrawingImage(name: "triangle.fill", offset: CGPoint(x: 0, y: 0.05), color: "#FF69B4", size: 15, rotation: 180),
    ]
}
