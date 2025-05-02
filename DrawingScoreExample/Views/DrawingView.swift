import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var score: Double
    @Binding var isDrawing: Bool
    @Binding var brushWidth: CGFloat
    @Binding var lastStrokeIndex: Int?
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    var onStrokeAdded: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: brushWidth)
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.backgroundColor = .clear
        uiView.isOpaque = false
        uiView.tool = PKInkingTool(.pen, color: .black, width: brushWidth)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        
        init(_ parent: DrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.isDrawing = true
            parent.lastStrokeIndex = canvasView.drawing.strokes.count - 1
            parent.canUndo = !canvasView.drawing.strokes.isEmpty
            parent.canRedo = false
            parent.onStrokeAdded()
        }
    }
} 