import UIKit

class ImageScorer {
    static func generateReferenceImage(size: CGSize, imageName: String = "star.fill", offset: CGPoint = .zero) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let image = UIImage(systemName: imageName)!
                .withTintColor(.black, renderingMode: .alwaysOriginal)
            
            let imageSize: CGFloat = 250
            let originX = (size.width - imageSize) / 2 + size.width * offset.x
            let originY = (size.height - imageSize) / 2 + size.height * offset.y

            image.draw(in: CGRect(x: originX, y: originY, width: imageSize, height: imageSize))
        }
    }

    static func calculateCoverage(drawing: UIImage, reference: UIImage) -> (Double, Double) {
        guard let drawingMask = createBinaryMask(from: drawing),
              let referenceMask = createBinaryMask(from: reference),
              drawing.size == reference.size else {
            return (0, 0)
        }
        
        let width = Int(reference.size.width)
        let height = Int(reference.size.height)

        let (shapeMask, boundaryMask) = createShapeAndBoundaryMasks(referenceMask, width: width, height: height)
        
        var shapePixelCount = 0
        var coveredPixels = 0
        var outsidePixels = 0
        var hasOutsideDrawing = false

        let chunkSize = 4
        for y in stride(from: 0, to: height, by: chunkSize) {
            for x in stride(from: 0, to: width, by: chunkSize) {
                let endY = min(y + chunkSize, height)
                let endX = min(x + chunkSize, width)
                
                for cy in y..<endY {
                    for cx in x..<endX {
                        let index = cy * width + cx
                        
                        if shapeMask[index] {
                            shapePixelCount += 1
                            if drawingMask[index] {
                                coveredPixels += 1
                            }
                        } else if drawingMask[index] {
                            if !boundaryMask[index] {
                                outsidePixels += 1
                                hasOutsideDrawing = true
                            }
                        }
                    }
                }
            }
        }

        guard shapePixelCount > 0 else { return (0, 0) }

        let insideCoverage = Double(coveredPixels) / Double(shapePixelCount) * 100
        let outsideCoverage = hasOutsideDrawing ? Double(outsidePixels) / Double(shapePixelCount) * 100 : 0

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
        
        let chunkSize = 4
        for y in stride(from: 0, to: height, by: chunkSize) {
            for x in stride(from: 0, to: width, by: chunkSize) {
                let endY = min(y + chunkSize, height)
                let endX = min(x + chunkSize, width)
                
                for cy in y..<endY {
                    for cx in x..<endX {
                        let pixelIndex = (cy * width + cx) * 4
                        let r = data[pixelIndex]
                        let g = data[pixelIndex + 1]
                        let b = data[pixelIndex + 2]
                        
                        let threshold: UInt8 = 180
                        let isBlack = r < threshold && g < threshold && b < threshold
                        
                        if isBlack {
                            mask[cy * width + cx] = true
                        }
                    }
                }
            }
        }

        return mask
    }
    
    private static func createShapeAndBoundaryMasks(_ mask: [Bool], width: Int, height: Int) -> ([Bool], [Bool]) {
        var shapeMask = mask
        var boundaryMask = [Bool](repeating: false, count: width * height)
        
        let chunkSize = 4
        for y in stride(from: 0, to: height, by: chunkSize) {
            for x in stride(from: 0, to: width, by: chunkSize) {
                let endY = min(y + chunkSize, height)
                let endX = min(x + chunkSize, width)
                
                for cy in y..<endY {
                    for cx in x..<endX {
                        let index = cy * width + cx
                        if mask[index] {
                            var isBoundary = false
                            for dy in -1...1 {
                                for dx in -1...1 {
                                    let nx = cx + dx
                                    let ny = cy + dy
                                    
                                    if nx >= 0 && nx < width && ny >= 0 && ny < height {
                                        if !mask[ny * width + nx] {
                                            isBoundary = true
                                            break
                                        }
                                    }
                                }
                                if isBoundary { break }
                            }
                            
                            if isBoundary {
                                boundaryMask[index] = true
                            }
                        }
                    }
                }
            }
        }

        for y in stride(from: 0, to: height, by: chunkSize) {
            for x in stride(from: 0, to: width, by: chunkSize) {
                let endY = min(y + chunkSize, height)
                let endX = min(x + chunkSize, width)
                
                for cy in y..<endY {
                    for cx in x..<endX {
                        let index = cy * width + cx
                        if boundaryMask[index] {
                            for dy in -2...2 {
                                for dx in -2...2 {
                                    let nx = cx + dx
                                    let ny = cy + dy
                                    
                                    if nx >= 0 && nx < width && ny >= 0 && ny < height {
                                        let neighborIndex = ny * width + nx
                                        if !shapeMask[neighborIndex] {
                                            shapeMask[neighborIndex] = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return (shapeMask, boundaryMask)
    }
} 
