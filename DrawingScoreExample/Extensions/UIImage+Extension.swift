//
//  UIImage+Extensions.swift
//  DrawingScoreExample
//
//  Created by artemiithefrog . on 01.05.2025.
//

import Foundation
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
