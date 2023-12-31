//
//  RoundedCornerImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct RoundedCornerImageView: View {
    @State private var size: Double = Self.defaultSize
    @State private var radius: Double = 3.5

    private static let defaultSize = 166.0

    private var sizetoFit: CGSize {
        .init(width: size, height: size)
    }

    private var image: OperationTool {
        .init(
            size: CGFloat(Self.defaultSize),
            image: OperationTool.drawCheckerboardImage(size: sizetoFit, blockSize: 12)
        )
    }

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.drawRectWithRoundedCornerNew(radius: radius, sizetoFit: sizetoFit))
                .border(.red, width: 1)
                .clipped()
                .background(Color.orange)

            Spacer()

            Text("Old")
            Image(uiImage: image.drawRectWithRoundedCornerOld(radius: radius, sizetoFit: sizetoFit)!)
                .border(.red, width: 1)
                .clipped()
                .background(Color.orange)

            Spacer()

            RSlider(title: "Size", range: 101...202, value: $size)
            RSlider(title: "Radius", range: 0...55, value: $radius)
        }
        .navigationTitle("Round")
    }
}

@available(iOS 14.0, *)
struct RoundedCornerImageView_Previews: PreviewProvider {
    static var previews: some View {
        RoundedCornerImageView()
    }
}
