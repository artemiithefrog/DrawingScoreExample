import SwiftUI

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