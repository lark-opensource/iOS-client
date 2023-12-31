//
//  TypeButtonPreview.swift
//  LarkButton
//
//  Created by Crazy凡 on 2020/11/4.
//

import UIKit
import Foundation
import SwiftUI
import LarkButton

@available(iOS 13.0.0, *)
fileprivate struct ButtonWrapper: UIViewRepresentable {
    typealias UIViewType = TypeButton

    var style: TypeButton.Style
    var title: String
    var isHighlighted: Bool = false
    var isEnabled: Bool = true

    func makeUIView(context: Context) -> TypeButton {
        setup(button: TypeButton())
    }

    func updateUIView(_ button: TypeButton, context: Context) {
        setup(button: button)
    }

    @discardableResult private func setup(button: TypeButton) -> TypeButton {
        button.style = style
        button.setTitle(title, for: .normal)
        button.isEnabled = isEnabled
        button.isHighlighted = isHighlighted
        return button
    }
}

@available(iOS 13.0.0, *)
struct TypeButtonPreview: View {
    private let styles: [TypeButton.Style] = [
        .largeA,
        .largeB,
        .largeC,
        .normalA,
        .normalB,
        .normalC,
        .normalD,
        .textA,
        .textB
    ]

    var body: some View {
        List {
            ForEach(styles, id: \.self) {
                ButtonWrapper(style: $0, title: "「 Nomarl - \($0) 」")
                ButtonWrapper(style: $0, title: "「 Highlighted - \($0) 」", isHighlighted: true)
                ButtonWrapper(style: $0, title: "「 Disable - \($0) 」", isEnabled:  false)
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct TypeButtonPreview_Previews: PreviewProvider {
    static var previews: some View {
        TypeButtonPreview()
    }
}
