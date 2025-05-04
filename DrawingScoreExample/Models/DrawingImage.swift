import SwiftUI

struct DrawingImage: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGPoint
    let color: String
    let size: CGFloat
    let rotation: Double

    static let defaultImages: [DrawingImage] = [
        // Мордочка кота
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0, y: 0), color: "#F4A460", size: 200, rotation: 0),

        // Ушки — треугольники, прижатые по бокам сверху
        DrawingImage(name: "triangle.fill", offset: CGPoint(x: -0.18, y: -0.2), color: "#F4A460", size: 60, rotation: -45),
        DrawingImage(name: "triangle.fill", offset: CGPoint(x: 0.18, y: -0.2), color: "#F4A460", size: 60, rotation: 45),

        // Глаза — два круга
        DrawingImage(name: "circle.fill", offset: CGPoint(x: -0.07, y: -0.03), color: "#000000", size: 20, rotation: 0),
        DrawingImage(name: "circle.fill", offset: CGPoint(x: 0.07, y: -0.03), color: "#000000", size: 20, rotation: 0)
    ]
}
