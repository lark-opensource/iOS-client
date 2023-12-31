//
//  ResizeImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct ResizeImageView: View {
    @State private var scale: Double = 1

    private var range = 0.1...5
    private static let defaultSize = 166.0

    private var size: CGSize {
        .init(width: Self.defaultSize * scale, height: Self.defaultSize * scale)
    }

    private var image = OperationTool(size: CGFloat(Self.defaultSize))

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.resizeNew(maxSize: size))
                .border(.red, width: 1)
                .clipped()

            Spacer()

            Text("Old")
            Image(uiImage: image.resizeNew(maxSize: size))
                .border(.red, width: 1)
                .clipped()

            Spacer()

            RSlider(title: "Scale", range: range, value: $scale)
        }
        .navigationTitle("Image resize with max size ")
    }
}

@available(iOS 14.0, *)
struct ResizeImageView_Previews: PreviewProvider {
    static var previews: some View {
        ResizeImageView()
    }
}
