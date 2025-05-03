import UIKit

class ImageScorer {
    static func generateReferenceImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            //            let image = UIImage(systemName: "star.fill")!
            let image = UIImage(systemName: "arrow.right")!
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
        
        let width = Int(reference.size.width)
        let height = Int(reference.size.height)

        let dilatedReferenceMask = dilateMask(referenceMask, width: width, height: height, iterations: 3)
        
        var shapePixelCount = 0
        var coveredPixels = 0
        var outsidePixels = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                
                if dilatedReferenceMask[index] {
                    shapePixelCount += 1
                    if drawingMask[index] {
                        coveredPixels += 1
                    }
                } else if drawingMask[index] {
                    if !isNearShapeBoundary(x: x, y: y, referenceMask: referenceMask, width: width, height: height) {
                        outsidePixels += 1
                    }
                }
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
    
    private static func dilateMask(_ mask: [Bool], width: Int, height: Int, iterations: Int) -> [Bool] {
        var result = mask
        
        for _ in 0..<iterations {
            var newResult = result
            
            for y in 0..<height {
                for x in 0..<width {
                    if result[y * width + x] {
                        for dy in -2...2 {
                            for dx in -2...2 {
                                let nx = x + dx
                                let ny = y + dy
                                
                                if nx >= 0 && nx < width && ny >= 0 && ny < height {
                                    newResult[ny * width + nx] = true
                                }
                            }
                        }
                    }
                }
            }
            
            result = newResult
        }
        
        return result
    }
    
    private static func isNearShapeBoundary(x: Int, y: Int, referenceMask: [Bool], width: Int, height: Int) -> Bool {
        let searchRadius = 5
        
        for dy in -searchRadius...searchRadius {
            for dx in -searchRadius...searchRadius {
                let nx = x + dx
                let ny = y + dy
                
                if nx >= 0 && nx < width && ny >= 0 && ny < height {
                    if referenceMask[ny * width + nx] {
                        let isSignificant = checkSignificantPixel(x: nx, y: ny, referenceMask: referenceMask, width: width, height: height)
                        if isSignificant {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private static func checkSignificantPixel(x: Int, y: Int, referenceMask: [Bool], width: Int, height: Int) -> Bool {
        var connectedPixels = 0
        let minConnectedPixels = 3
        
        for dy in -1...1 {
            for dx in -1...1 {
                let nx = x + dx
                let ny = y + dy
                
                if nx >= 0 && nx < width && ny >= 0 && ny < height {
                    if referenceMask[ny * width + nx] {
                        connectedPixels += 1
                    }
                }
            }
        }
        
        return connectedPixels >= minConnectedPixels
    }
} 
