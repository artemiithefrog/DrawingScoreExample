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
    @StateObject private var viewModel = DrawingViewModel()
    @State private var showCompletionAlert: Bool = false
    
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
                        if viewModel.currentImageIndex != 0 {
                            UndoRedoButtons(
                                canUndo: viewModel.canUndo,
                                canRedo: viewModel.canRedo,
                                onUndo: { viewModel.undo() },
                                onRedo: { viewModel.redo() }
                            )
                            .padding(.top, 20)
                        }
                        
                        Spacer()
                        
                        Slider(value: $viewModel.brushWidth, in: 1...20, step: 1)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 200)
                            .opacity(viewModel.currentImageIndex == 0 ? 0 : 1)
                        
                        Spacer()
                    }
                    .frame(width: 50)

                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: canvasWidth, height: safeHeight)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                        if viewModel.currentImageIndex != 0 {
                            VStack {
                                VStack(spacing: 8) {
                                    CustomProgressBar(insideProgress: viewModel.progressValue, 
                                                    outsideProgress: viewModel.outsideProgressValue,
                                                    isShaking: viewModel.isShaking,
                                                    isFlashing: viewModel.isFlashing)
                                        .frame(width: canvasWidth - horizontalPadding * 2, height: 8)
                                }
                                .padding(.top, 20)
                                
                                Spacer()
                            }
                        }

                        if viewModel.currentImageIndex == 0 {
                            ForEach(Array(viewModel.images.enumerated().dropFirst()), id: \.offset) { index, image in
                                Image(systemName: image.name)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: image.size, height: image.size)
                                    .foregroundColor(Color(hex: image.color))
                                    .rotationEffect(.degrees(image.rotation))
                                    .offset(x: canvasWidth * image.offset.x,
                                           y: safeHeight * image.offset.y)
                            }
                        } else {
                            ForEach(Array(viewModel.completedCanvasViews.enumerated()), id: \.offset) { index, canvas in
                                DrawingView(canvasView: .constant(canvas),
                                          score: .constant(0),
                                          isDrawing: .constant(false),
                                          brushWidth: .constant(10),
                                          lastStrokeIndex: .constant(nil),
                                          canUndo: .constant(false),
                                          canRedo: .constant(false),
                                          currentDrawingStrokes: .constant([]),
                                          currentImage: viewModel.images[index + 1],
                                          onStrokeAdded: {})
                                    .frame(width: canvasWidth, height: safeHeight)
                                    .allowsHitTesting(false)
                            }

                            Image(systemName: viewModel.currentImage.name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: viewModel.currentImage.size, height: viewModel.currentImage.size)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(viewModel.currentImage.rotation))
                                .offset(x: canvasWidth * viewModel.currentImage.offset.x,
                                       y: safeHeight * viewModel.currentImage.offset.y)
                                .zIndex(1)

                            DrawingView(canvasView: $viewModel.canvasView,
                                      score: $viewModel.score,
                                      isDrawing: $viewModel.isDrawing,
                                      brushWidth: $viewModel.brushWidth,
                                      lastStrokeIndex: $viewModel.lastStrokeIndex,
                                      canUndo: $viewModel.canUndo,
                                      canRedo: $viewModel.canRedo,
                                      currentDrawingStrokes: $viewModel.currentDrawingStrokes,
                                      currentImage: viewModel.currentImage,
                                      onStrokeAdded: { viewModel.clearUndoStack() })
                                .frame(width: canvasWidth, height: safeHeight)
                                .onAppear {
                                    viewModel.canvasSize = CGSize(width: canvasWidth, height: safeHeight)
                                }
                                .onChange(of: viewModel.isDrawing) { newValue in
                                    if newValue {
                                        viewModel.startDrawing()
                                    } else {
                                        viewModel.stopDrawing()
                                    }
                                }
                                .zIndex(2)
                        }
                    }
                }
                
                if viewModel.currentImageIndex == 0 || viewModel.showCompletionButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                if viewModel.isLastImage {
                                    showCompletionAlert = true
                                } else {
                                    viewModel.moveToNextImage()
                                }
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
                    viewModel.resetDrawing()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("You have completed all the drawings!")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
