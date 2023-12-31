//
//  UIButton+PointerStyle.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/9.
//

import Foundation
import UIKit
import LarkInteraction

public extension UIButton {
    func addPointerStyle() {
        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let view = interaction.view else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: view.bounds.width + 20, height: 36), 8)
                }))
        }
    }
}

public extension UIView {
    func addDefaultPointer() {
        if #available(iOS 13.4, *) {
            self.addPointer(.highlight(shape: { origin in
                return (CGSize(width: origin.width + 20, height: 36), 8)
            }))
        }
    }
}
