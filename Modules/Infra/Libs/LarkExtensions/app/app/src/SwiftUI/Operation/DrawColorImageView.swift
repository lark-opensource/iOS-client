//
//  DrawColorImageView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
struct DrawColorImageView: View {
    @State private var insert: Double = 3
    @State private var cornerRadius: Double = 3.5
    @State private var color: Color = .orange
    @State private var borderColor: Color = .green
    @State private var borderWidth: Float = 1.0

    private static let defaultSize = 166.0

    private var size: CGSize {
        .init(width: Self.defaultSize, height: Self.defaultSize)
    }

    private var image = OperationTool(size: Self.defaultSize)

    var body: some View {
        VStack {
            Spacer()

            Text("New")
            Image(uiImage: image.imageWithNew(
                inserts: .init(top: insert, left: insert, bottom: insert, right: insert),
                cornerRadius: Float(cornerRadius),
                fillColor: UIColor(color),
                borderColor: UIColor(borderColor),
                borderWidth: borderWidth
            )!)
            .border(.red, width: 1)
            .frame(width: Self.defaultSize, height: Self.defaultSize)

            Spacer()

            Text("Old")
            Image(uiImage: image.imageWithOld(
                inserts: .init(top: insert, left: insert, bottom: insert, right: insert),
                cornerRadius: Float(cornerRadius),
                fillColor: UIColor(color),
                borderColor: UIColor(borderColor),
                borderWidth: borderWidth
            )!)
            .border(.red, width: 1)
            .frame(width: Self.defaultSize, height: Self.defaultSize)

            HStack {
                ColorPicker("Fill Color", selection: $color)
                Spacer()
                ColorPicker("Border Color", selection: $borderColor)
            }
            RSlider(title: "Insert", range: 0...5, value: $insert)
            RSlider(title: "CornerRadius", range: 0...35, value: $cornerRadius)
            RSlider(title: "Border Width", range: 0...5, value: $borderWidth)
        }
        .navigationTitle("Draw Color Image")
    }
}

@available(iOS 14.0, *)
struct DrawColorImageView_Previews: PreviewProvider {
    static var previews: some View {
        DrawColorImageView()
    }
}
