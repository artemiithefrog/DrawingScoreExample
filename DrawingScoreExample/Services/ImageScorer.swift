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