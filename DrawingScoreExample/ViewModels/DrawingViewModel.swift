import SwiftUI
import PencilKit

class DrawingViewModel: ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published var score: Double = 0.0
    @Published var isDrawing = false
    @Published var brushWidth: CGFloat = 10.0
    @Published var canvasSize: CGSize = .zero
    @Published var progressValue: Double = 0.0
    @Published var outsideProgressValue: Double = 0.0
    @Published var lastStrokeIndex: Int?
    @Published var isShaking: Bool = false
    @Published var isFlashing: Bool = false
    @Published var showCompletionButton: Bool = false

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    private var undoStack: [PKStroke] = []
    private var hasUndoneStrokes: Bool = false
    
    private var timer: Timer?
    private var lastUpdateTime: Date = Date()
    
    func calculateScore() {
        guard !canvasView.drawing.strokes.isEmpty else {
            DispatchQueue.main.async {
                self.score = 0
                self.progressValue = 0
                self.outsideProgressValue = 0
            }
            return
        }

        let targetSize = canvasSize
        let scale = UIScreen.main.scale

        let drawingImage = canvasView.drawing.image(from: CGRect(origin: .zero, size: targetSize), scale: scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        let processedDrawingImage = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: targetSize))

            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(brushWidth)
            context.cgContext.setLineCap(.round)
            context.cgContext.setLineJoin(.round)

            for stroke in canvasView.drawing.strokes {
                let path = UIBezierPath()
                let points = stroke.path
                if points.count > 0 {
                    path.move(to: points[0].location)
                    for i in 1..<points.count {
                        path.addLine(to: points[i].location)
                    }
                }
                context.cgContext.addPath(path.cgPath)
            }
            context.cgContext.strokePath()
        }

        let referenceImage = ImageScorer.generateReferenceImage(size: targetSize)

        let (insideScore, outsideScore) = ImageScorer.calculateCoverage(
            drawing: processedDrawingImage,
            reference: referenceImage
        )

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                if self.canvasView.drawing.strokes.count == 1 {
                    if let firstStroke = self.canvasView.drawing.strokes.first {
                        let points = firstStroke.path
                        var isInsideTarget = false
                        
                        for point in points {
                            let location = point.location
                            let starSize: CGFloat = 250
                            let originX = (targetSize.width - starSize) / 2
                            let originY = (targetSize.height - starSize) / 2
                            let targetRect = CGRect(x: originX, y: originY, width: starSize, height: starSize)
                            
                            if targetRect.contains(location) {
                                isInsideTarget = true
                                break
                            }
                        }
                        
                        if isInsideTarget {
                            self.score = insideScore
                            self.progressValue = insideScore / 100.0
                            self.outsideProgressValue = 0
                        } else {
                            self.score = 0
                            self.progressValue = 0
                            self.outsideProgressValue = outsideScore / 100.0
                        }
                    }
                } else {
                    self.score = insideScore
                    self.progressValue = insideScore / 100.0
                    
                    if outsideScore > 50, let index = self.lastStrokeIndex {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isShaking = true
                            self.isFlashing = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            var strokes = self.canvasView.drawing.strokes
                            if index < strokes.count {
                                strokes.remove(at: index)
                                self.canvasView.drawing = PKDrawing(strokes: strokes)
                                self.lastStrokeIndex = nil
                                
                                withAnimation(nil) {
                                    self.isShaking = false
                                    self.isFlashing = false
                                    self.outsideProgressValue = 0
                                }
                            }
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.outsideProgressValue = outsideScore / 100.0
                        }
                    }
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.showCompletionButton = insideScore >= 95
                }
            }
        }
    }
    
    func startDrawing() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            if now.timeIntervalSince(self.lastUpdateTime) >= 0.5 {
                DispatchQueue.main.async {
                    self.calculateScore()
                    self.lastUpdateTime = now
                }
            }
        }
    }
    
    func stopDrawing() {
        timer?.invalidate()
        timer = nil
        calculateScore()
    }
    
    func undo() {
        guard let lastStroke = canvasView.drawing.strokes.last else { return }

        var strokes = canvasView.drawing.strokes
        strokes.removeLast()
        canvasView.drawing = PKDrawing(strokes: strokes)

        undoStack.append(lastStroke)
        hasUndoneStrokes = true

        updateButtonStates()

        calculateScore()
    }
    
    func redo() {
        guard !undoStack.isEmpty else {
            updateButtonStates()
            return
        }

        var strokes = canvasView.drawing.strokes
        strokes.append(undoStack.removeLast())
        canvasView.drawing = PKDrawing(strokes: strokes)

        updateButtonStates()

        calculateScore()
    }
    
    private func updateButtonStates() {
        canUndo = !canvasView.drawing.strokes.isEmpty
        canRedo = !undoStack.isEmpty
    }
    
    func clearUndoStack() {
        if hasUndoneStrokes {
            undoStack.removeAll()
            hasUndoneStrokes = false
            updateButtonStates()
        }
    }
    
    func resetDrawing() {
        canvasView.drawing = PKDrawing()
        score = 0
        progressValue = 0
        outsideProgressValue = 0
        lastStrokeIndex = nil
        showCompletionButton = false
        isDrawing = false
        timer?.invalidate()
        timer = nil
        
        undoStack.removeAll()
        hasUndoneStrokes = false
        updateButtonStates()
    }
} 