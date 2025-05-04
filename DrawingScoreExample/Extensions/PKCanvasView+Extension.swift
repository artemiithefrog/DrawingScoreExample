import PencilKit

extension PKCanvasView {
    func clear() {
        drawing = PKDrawing()
    }
    
    func removeLastStroke() {
        var strokes = drawing.strokes
        if !strokes.isEmpty {
            strokes.removeLast()
            drawing = PKDrawing(strokes: strokes)
        }
    }
} 