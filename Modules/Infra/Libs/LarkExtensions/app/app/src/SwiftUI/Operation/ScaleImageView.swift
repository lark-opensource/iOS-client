//
//  ScaleImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct ScaleImageView: View {
    @State private var scale: Double = 1
    private var range = 0.5...5
    private static let defaultSize = 35.0

    private var size: CGSize {
        .init(width: Self.defaultSize * scale, height: Self.defaultSize * scale)
    }

    private var image = OperationTool(size: Self.defaultSize)

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.scaleNew(toSize: size)!)
                .border(.red, width: 1)

            Spacer()

            Text("Old")
            Image(uiImage: image.scaleOld(toSize: size)!)
                .border(.red, width: 1)

            Spacer()

            RSlider(title: "Scale", range: range, value: $scale)
        }
        .navigationTitle("Scale Image")
    }
}

@available(iOS 14.0, *)
struct ScaleImageView_Previews: PreviewProvider {
    static var previews: some View {
        ScaleImageView()
    }
}
