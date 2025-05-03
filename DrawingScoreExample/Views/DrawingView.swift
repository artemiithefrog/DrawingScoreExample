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
    @Binding var currentDrawingStrokes: [PKStroke]
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
        private var lastStrokeCount: Int = 0
        
        init(_ parent: DrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.isDrawing = true
            let currentStrokeCount = canvasView.drawing.strokes.count
  
            if currentStrokeCount > lastStrokeCount {
                parent.lastStrokeIndex = currentStrokeCount - 1
                parent.canUndo = true
                if let newStroke = canvasView.drawing.strokes.last {
                    parent.currentDrawingStrokes.append(newStroke)
                    parent.onStrokeAdded()
                }
            }
            
            lastStrokeCount = currentStrokeCount
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            parent.isDrawing = false
        }
    }
} 