//
//  PanelButton.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/6.
//

import UIKit
import Foundation

final class PanelButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel?.sizeThatFits(.init(width: 100, height: 100)) ?? CGSize.zero
        return .init(width: max(titleSize.width, 24),
                     height: titleSize.height + 32)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return .init(x: 0, y: 32, width: contentRect.width, height: contentRect.height - 32)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return .init(x: (contentRect.width - 24) / 2, y: 0, width: 24, height: 24)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -15, dy: -15).contains(point)
    }
}
