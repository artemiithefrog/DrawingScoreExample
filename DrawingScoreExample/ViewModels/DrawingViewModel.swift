import SwiftUI
import PencilKit
import UIKit

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
    @Published var currentImageIndex: Int = 0
    @Published var completedDrawings: [PKDrawing] = []
    @Published var currentDrawingStrokes: [PKStroke] = []

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    private var undoStack: [PKStroke] = []
    
    private var timer: Timer?
    private var lastUpdateTime: Date = Date()
    
    let images = DrawingImage.defaultImages
    
    var currentImage: DrawingImage {
        images[currentImageIndex]
    }
    
    var isLastImage: Bool {
        currentImageIndex == images.count - 1
    }
    
    func moveToNextImage() {
        if !isLastImage {
            completedDrawings.append(PKDrawing(strokes: currentDrawingStrokes))
            
            var combinedDrawing = PKDrawing()
            for drawing in completedDrawings {
                combinedDrawing.append(drawing)
            }
            
            currentImageIndex += 1
            canvasView.drawing = combinedDrawing
            currentDrawingStrokes = []
            
            score = 0
            progressValue = 0
            outsideProgressValue = 0
            lastStrokeIndex = nil
            showCompletionButton = false
            isDrawing = false
            timer?.invalidate()
            timer = nil
            
            undoStack.removeAll()
            updateButtonStates()
        }
    }
    
    func calculateScore() {
        guard !currentDrawingStrokes.isEmpty else {
            DispatchQueue.main.async {
                self.score = 0
                self.progressValue = 0
                self.outsideProgressValue = 0
            }
            return
        }

        let targetSize = canvasSize
        let scale = UIScreen.main.scale

        let currentDrawing = PKDrawing(strokes: currentDrawingStrokes)
        let drawingImage = currentDrawing.image(from: CGRect(origin: .zero, size: targetSize), scale: scale)

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

            for stroke in currentDrawingStrokes {
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

        let referenceImage = ImageScorer.generateReferenceImage(
            size: targetSize,
            imageName: currentImage.name,
            offset: currentImage.offset
        )

        let (insideScore, outsideScore) = ImageScorer.calculateCoverage(
            drawing: processedDrawingImage,
            reference: referenceImage
        )

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                var hasInsideStroke = false
                let imageSize: CGFloat = 250
                let originX = (targetSize.width - imageSize) / 2 + targetSize.width * self.currentImage.offset.x
                let originY = (targetSize.height - imageSize) / 2 + targetSize.height * self.currentImage.offset.y
                let targetRect = CGRect(x: originX, y: originY, width: imageSize, height: imageSize)
                
                for stroke in self.currentDrawingStrokes {
                    let points = stroke.path
                    for point in points {
                        if targetRect.contains(point.location) {
                            hasInsideStroke = true
                            break
                        }
                    }
                    if hasInsideStroke { break }
                }
                
                if hasInsideStroke {
                    self.score = insideScore
                    self.progressValue = insideScore / 100.0
                } else {
                    self.score = 0
                    self.progressValue = 0
                }
                
                if outsideScore > 30, let index = self.lastStrokeIndex {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.isShaking = true
                        self.isFlashing = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if index < self.currentDrawingStrokes.count {
                            self.currentDrawingStrokes.remove(at: index)
                            var allStrokes = self.completedDrawings.flatMap { $0.strokes }
                            allStrokes.append(contentsOf: self.currentDrawingStrokes)
                            self.canvasView.drawing = PKDrawing(strokes: allStrokes)
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
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.showCompletionButton = insideScore >= 15
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
        guard let lastStroke = currentDrawingStrokes.last else { return }

        currentDrawingStrokes.removeLast()
        var allStrokes = completedDrawings.flatMap { $0.strokes }
        allStrokes.append(contentsOf: currentDrawingStrokes)
        canvasView.drawing = PKDrawing(strokes: allStrokes)

        undoStack.append(lastStroke)

        updateButtonStates()
        calculateScore()
    }
    
    func redo() {
        guard !undoStack.isEmpty else {
            updateButtonStates()
            return
        }

        let stroke = undoStack.removeLast()
        currentDrawingStrokes.append(stroke)
        var allStrokes = completedDrawings.flatMap { $0.strokes }
        allStrokes.append(contentsOf: currentDrawingStrokes)
        canvasView.drawing = PKDrawing(strokes: allStrokes)

        updateButtonStates()
        calculateScore()
    }
    
    func clearUndoStack() {
        undoStack.removeAll()
        updateButtonStates()
    }
    
    func resetDrawing() {
        completedDrawings.removeAll()
        currentDrawingStrokes.removeAll()
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
        updateButtonStates()
    }

    private func updateButtonStates() {
        DispatchQueue.main.async {
            self.canUndo = !self.currentDrawingStrokes.isEmpty
            self.canRedo = !self.undoStack.isEmpty
        }
    }
} 
