//
//  AlphaImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct AlphaImageView: View {
    @State private var scale: Double = 1
    private var range = 0...1.0
    private static let defaultSize = 206.0

    private var size: CGSize {
        .init(width: Self.defaultSize, height: Self.defaultSize )
    }

    private var image = OperationTool(size: Self.defaultSize)

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.alphaNew(scale))
                .border(.red, width: 1)

            Spacer()

            Text("Old")
            Image(uiImage: image.alphaOld(scale))
                .border(.red, width: 1)

            Spacer()

            RSlider(title: "Alpha", range: range, value: $scale)
        }
        .navigationTitle("Image Alpha")
    }
}

@available(iOS 14.0, *)
struct AlphaImageView_Previews: PreviewProvider {
    static var previews: some View {
        AlphaImageView()
    }
}
