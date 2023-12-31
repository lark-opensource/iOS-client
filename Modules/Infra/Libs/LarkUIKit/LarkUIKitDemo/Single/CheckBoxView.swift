//
//  CheckBoxView.swift
//  LarkUIKitDemo
//
//  Created by Crazy凡 on 2022/11/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import SwiftUI
import LarkUIKit
import Foundation

@available(iOS 13.0.0, *)
struct CheckBoxWrapper: UIViewRepresentable {
    typealias Handler = (_ isOn: Bool) -> Void

    var type: CheckboxType

    @Binding var isOn: Bool
    var didTapCheckbox: Handler?
    var animationDidStop: Handler?

    func makeUIView(context: Self.Context) -> Checkbox {
        let box = Checkbox()
        box.delegate = context.coordinator
        return box
    }

    func updateUIView(_ box: Checkbox, context: Context) {
        box.setOn(on: isOn)
        box.boxType = type
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: $isOn, didTapCheckbox: didTapCheckbox, animationDidStop: animationDidStop)
    }

    class Coordinator: NSObject, CheckboxDelegate {
        @Binding var isOn: Bool

        var didTapCheckbox: Handler?
        var animationDidStop: Handler?

        init(isOn: Binding<Bool>, didTapCheckbox: Handler?, animationDidStop: Handler?) {
            self._isOn = isOn
            self.didTapCheckbox = didTapCheckbox
            self.animationDidStop = animationDidStop

            super.init()
        }

        func didTapCheckbox(_ checkbox: LarkUIKit.Checkbox) {
            isOn = checkbox.on
            didTapCheckbox?(isOn)
        }

        func animationDidStopForCheckbox(_ checkbox: LarkUIKit.Checkbox) {
            isOn = checkbox.on
            animationDidStop?(isOn)
        }
    }
}

@available(iOS 14.0.0, *)
struct CheckBoxView: View {
    var body: some View {
        NavigationView { ScrollView {
            LazyVGrid(
                columns: (0..<CheckboxType.allCases.count).map {
                    _ in .init(.flexible(minimum: 24, maximum: 240), spacing: 10, alignment: .center)
                },
                alignment: .center,
                spacing: 10
            ) {
                ForEach(0..<2000) { index in
                    HStack {
                        Text("\(index + 1)")
                        CheckBoxWrapper(type: CheckboxType.allCases[index % CheckboxType.allCases.count], isOn: .constant(.random())) { isOn in
                            print("Taped: \(isOn)")
                        } animationDidStop: { isOn in
                            print("Animation Did Stop: \(isOn)")
                        }
                        .frame(width: 24, height: 24)
                    }
                }
            }
        }}
    }
}

@available(iOS 14.0.0, *)
struct CheckBoxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckBoxView()
    }
}
