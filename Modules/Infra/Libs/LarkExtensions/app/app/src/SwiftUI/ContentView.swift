//
//  ContentView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI
import UIKit

enum Operation: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case scale
    case resize
    case alpha
    case drawImage
    case rounded
    case rotate
    case screen
}

@available(iOS 14.0, *)
struct ContentView: View {
    @State private var method: Operation = .screen
    var body: some View {
        NavigationView {
            List(Operation.allCases) { method in
                switch method {
                case .scale:
                    NavigationLink(destination: ScaleImageView()) {
                        Text(Operation.scale.rawValue)
                    }.tag(Operation.scale)

                case .resize:
                    NavigationLink(destination: ResizeImageView()) {
                        Text(Operation.resize.rawValue)
                    }.tag(Operation.resize)

                case .alpha:
                    NavigationLink(destination: AlphaImageView()) {
                        Text(Operation.alpha.rawValue)
                    }.tag(Operation.alpha)

                case .drawImage:
                    NavigationLink(destination: DrawColorImageView()) {
                        Text(Operation.drawImage.rawValue)
                    }.tag(Operation.drawImage)

                case .rounded:
                    NavigationLink(destination: RoundedCornerImageView()) {
                        Text(Operation.rounded.rawValue)
                    }.tag(Operation.rounded)

                case .rotate:
                    NavigationLink(destination: RotateImageView()) {
                        Text(Operation.rotate.rawValue)
                    }.tag(Operation.rotate)

                case .screen:
                    NavigationLink(destination: ScreenshotView()) {
                        Text(Operation.screen.rawValue)

                    }.tag(Operation.screen)
                }
            }
            .navigationTitle("UIGraphicsImageRenderer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
