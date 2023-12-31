//
//  RSlider.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import SwiftUI

@available(iOS 14.0, *)
struct RSlider<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {

    var title: String
    var range: ClosedRange<V>
    @Binding var value: V

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                Text("Min: " + display(range.lowerBound))
                Spacer()
                Text("Cur: " + display(value))
                Spacer()
                Text("Max: " + display(range.upperBound))
            }
            .font(.footnote)
            HStack {
                Slider(value: $value, in: range)
            }
        }.padding()
    }

    private func display(_ value: V) -> String {
        String(format: "%.2f", Double(value))
    }
}

@available(iOS 14.0, *)
struct RSlider_Previews: PreviewProvider {
    static var previews: some View {
        RSlider(title: "Test", range: 0...1, value: .constant(0.5))
    }
}
