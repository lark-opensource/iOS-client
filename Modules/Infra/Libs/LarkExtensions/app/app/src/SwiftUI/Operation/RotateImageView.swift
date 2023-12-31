//
//  RotateImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct RotateImageView: View {
    @State private var rotate: Double = 0

    private var range = 0...(Double.pi * 2)
    private static let defaultSize = 166.0

    private var size: CGSize {
        .init(width: Self.defaultSize, height: Self.defaultSize)
    }

    private var image = OperationTool(size: CGFloat(Self.defaultSize))

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.rotateNew(by: rotate))
                .border(.red, width: 1)
                .clipped()

            Spacer()

            Text("Old")
            Image(uiImage: image.rotateOld(by: rotate))
                .border(.red, width: 1)
                .clipped()

            Spacer()

            RSlider(title: "Rotate", range: range, value: $rotate)
        }
        .navigationTitle("Image resize with macSize ")
    }
}

@available(iOS 14.0, *)
struct RotateImageView_Previews: PreviewProvider {
    static var previews: some View {
        RotateImageView()
    }
}
