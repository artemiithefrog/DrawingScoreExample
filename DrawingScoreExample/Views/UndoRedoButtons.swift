import SwiftUI

struct UndoRedoButtons: View {
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onUndo) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(canUndo ? .black : .gray.opacity(0.5))
                }
            }
            .disabled(!canUndo)
            
            Button(action: onRedo) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(canRedo ? .black : .gray.opacity(0.5))
                }
            }
            .disabled(!canRedo)
        }
    }
} 