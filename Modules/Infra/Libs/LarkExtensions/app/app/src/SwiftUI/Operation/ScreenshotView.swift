//
//  ScreenshotView.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
struct ScreenshotView: View {
    private let tool = ViewOperationTool()

    @State private var times: Int = 0

    @State private var new = UIImage()
    @State private var old = UIImage()

    var body: some View {
        VStack {
            Spacer()
            Text("New")
            Image(uiImage: new)
                .resizable()
                .scaledToFit()
                .border(.red, width: 1)
                .frame(width: 166)

            Spacer()

            Text("Old")
            Image(uiImage: old)
                .resizable()
                .scaledToFit()
                .border(.red, width: 1)
                .frame(width: 166)

            Spacer()

            HStack {
                Button("Shot") {
                    self.new = tool.screenshotNew()
                    self.old = tool.screenshotOld()!

                    times += 1
                }
                Spacer()

                Text("Times: \(times)").font(.title2)
            }
            .padding()
        }
        .navigationTitle("Screen")
    }
}

@available(iOS 14.0, *)
struct ScreenshotView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenshotView()
    }
}
