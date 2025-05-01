//
//  ContentView.swift
//  DrawingScoreExample
//
//  Created by artemiithefrog . on 30.04.2025.
//

import SwiftUI
import PencilKit
import UIKit

struct ContentView: View {
    @State private var canvasView = PKCanvasView()
    @State private var score: Double = 0.0
    @State private var isDrawing = false
    @State private var timer: Timer?
    @State private var brushWidth: CGFloat = 10.0
    @State private var canvasSize: CGSize = .zero
    @State private var progressValue: Double = 0.0
    @State private var lastUpdateTime: Date = Date()
    @State private var outsideProgressValue: Double = 0.0
    @State private var lastStrokeIndex: Int?
    @State private var isShaking: Bool = false
    @State private var isFlashing: Bool = false
    @State private var showCompletionAlert: Bool = false
    @State private var showCompletionButton: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let safeWidth = geometry.size.width
            let safeHeight = geometry.size.height
            let canvasWidth = safeWidth * 0.75
            let horizontalPadding: CGFloat = 20

            ZStack {
                Color.gray.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)

                HStack(spacing: 20) {
                    VStack {
                        Slider(value: $brushWidth, in: 1...20, step: 1)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 200)
                            .padding(.top, 100)
                    }
                    .frame(width: 50)

                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: canvasWidth, height: safeHeight)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                        VStack {
                            VStack(spacing: 8) {
                                CustomProgressBar(insideProgress: progressValue, 
                                                outsideProgress: outsideProgressValue,
                                                isShaking: isShaking,
                                                isFlashing: isFlashing)
                                    .frame(width: canvasWidth - horizontalPadding * 2, height: 8)
                                
                                Text("Coverage: \(Int(score))%")
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 20)
                            
                            Spacer()
                        }

                        Image(systemName: "star.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                            .foregroundColor(.blue)

                        DrawingView(canvasView: $canvasView,
                                  score: $score,
                                  isDrawing: $isDrawing,
                                  brushWidth: $brushWidth,
                                  lastStrokeIndex: $lastStrokeIndex)
                            .frame(width: canvasWidth, height: safeHeight)
                            .onAppear {
                                self.canvasSize = CGSize(width: canvasWidth, height: safeHeight)
                            }
                            .onChange(of: isDrawing) { newValue in
                                if newValue {
                                    timer?.invalidate()
                                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                        let now = Date()
                                        if now.timeIntervalSince(lastUpdateTime) >= 0.5 {
                                            DispatchQueue.main.async {
                                                calculateScore()
                                                lastUpdateTime = now
                                            }
                                        }
                                    }
                                } else {
                                    timer?.invalidate()
                                    timer = nil
                                    calculateScore()
                                }
                            }
                    }
                }
                
                if showCompletionButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showCompletionAlert = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                            .buttonStyle(PlainButtonStyle())
                            .allowsHitTesting(true)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    .frame(width: safeWidth)
                    .padding(.top, 20)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .alert("Drawing Complete!", isPresented: $showCompletionAlert) {
                Button("Start Over") {
                    // Reset everything
                    canvasView.drawing = PKDrawing()
                    score = 0
                    progressValue = 0
                    outsideProgressValue = 0
                    lastStrokeIndex = nil
                    showCompletionButton = false
                    isDrawing = false
                    timer?.invalidate()
                    timer = nil
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("You have completed the test drawing!")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func calculateScore() {
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
                if canvasView.drawing.strokes.count == 1 {
                    if let firstStroke = canvasView.drawing.strokes.first {
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
                    
                    if outsideScore > 50, let index = lastStrokeIndex {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isShaking = true
                            isFlashing = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            var strokes = canvasView.drawing.strokes
                            if index < strokes.count {
                                strokes.remove(at: index)
                                canvasView.drawing = PKDrawing(strokes: strokes)
                                lastStrokeIndex = nil
                                
                                withAnimation(nil) {
                                    isShaking = false
                                    isFlashing = false
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
                    showCompletionButton = insideScore >= 95
                }
            }
        }
    }
}

struct CustomProgressBar: View {
    let insideProgress: Double
    let outsideProgress: Double
    let isShaking: Bool
    let isFlashing: Bool
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(4)
                
                if isFlashing {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width)
                        .cornerRadius(4)
                } else {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: min(
                                geometry.size.width * CGFloat(insideProgress) * (1 - CGFloat(outsideProgress)),
                                geometry.size.width * (1 - CGFloat(outsideProgress))
                            ))
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: min(
                                geometry.size.width * CGFloat(outsideProgress),
                                geometry.size.width
                            ))
                    }
                    .cornerRadius(4)
                }
            }
            .offset(x: shakeOffset)
            .shadow(color: isFlashing ? .red.opacity(0.5) : .clear, radius: 4, x: 0, y: 2)
            .onChange(of: isShaking) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3).repeatCount(3)) {
                        shakeOffset = 10
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3).repeatCount(3)) {
                            shakeOffset = -10
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3).repeatCount(3)) {
                            shakeOffset = 0
                        }
                    }
                } else {
                    shakeOffset = 0
                }
            }
        }
    }
}

struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var score: Double
    @Binding var isDrawing: Bool
    @Binding var brushWidth: CGFloat
    @Binding var lastStrokeIndex: Int?
    
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
        }
    }
}

class ImageScorer {
    
    static func generateReferenceImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))

            let image = UIImage(systemName: "star.fill")!
                .withTintColor(.black, renderingMode: .alwaysOriginal)

            let starSize: CGFloat = 250
            let originX = (size.width - starSize) / 2
            let originY = (size.height - starSize) / 2

            image.draw(in: CGRect(x: originX, y: originY, width: starSize, height: starSize))
        }
    }

    static func calculateCoverage(drawing: UIImage, reference: UIImage) -> (Double, Double) {
        guard let drawingMask = createBinaryMask(from: drawing),
              let referenceMask = createBinaryMask(from: reference),
              drawing.size == reference.size else {
            return (0, 0)
        }

        let totalPixels = referenceMask.count
        var shapePixelCount = 0
        var coveredPixels = 0
        var outsidePixels = 0

        for i in 0..<totalPixels {
            if referenceMask[i] {
                shapePixelCount += 1
                if drawingMask[i] {
                    coveredPixels += 1
                }
            } else if drawingMask[i] {
                outsidePixels += 1
            }
        }

        guard shapePixelCount > 0 else { return (0, 0) }

        let insideCoverage = Double(coveredPixels) / Double(shapePixelCount) * 100

        let outsideCoverage = Double(outsidePixels) / Double(shapePixelCount) * 100

        return (min(insideCoverage, 100), min(outsideCoverage, 100))
    }

    private static func createBinaryMask(from image: UIImage) -> [Bool]? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        
        var mask = [Bool](repeating: false, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = data[pixelIndex]
                let g = data[pixelIndex + 1]
                let b = data[pixelIndex + 2]
                
                let threshold: UInt8 = 200
                let isBlack = r < threshold || g < threshold || b < threshold
                
                if isBlack {
                    mask[y * width + x] = true
                }
            }
        }

        return mask
    }
}
