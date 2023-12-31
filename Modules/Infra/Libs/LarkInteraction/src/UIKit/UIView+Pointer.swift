//
//  UIView+Pointer.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/2.
//

import UIKit
import Foundation

extension UIView {
    /// 添加 iPad Pointer 效果 （文档链接：[Lark iPad Pointer 接入指南](https://bytedance.feishu.cn/wiki/wikcnwZuBCYDsyBw7oOI3oyIvVd)）
    public func addPointer(_ info: PointerInfo) {
        if #available(iOS 13.4, *) {
            let style = info.style
            let pointer = PointerInteraction(style: style)
            self.addLKInteraction(pointer)
        }
    }

    /// 移除所有存在的 Pointer 效果
    public func removeExistedPointers() {
        if #available(iOS 13.4, *) {
            for pointerInteraction in self.lkInteractions
            where type(of: pointerInteraction) == PointerInteraction.self {
                self.removeLKInteraction(pointerInteraction)
            }
        }
    }
}

extension UIButton {

    public func update(_ pointerInfo: PointerInfo?) {
        if #available(iOS 13.4, *) {
            self.update(pointerStyle: pointerInfo?.style)
        }
    }

    @available(iOS 13.4, *)
    func update(pointerStyle: PointerStyle?) {
        if #available(iOS 14.0, *) {
            if let style = pointerStyle {
                self.isPointerInteractionEnabled = true
                self.pointerStyleProvider = style.buttonProvider
            } else {
                self.isPointerInteractionEnabled = false
                self.pointerStyleProvider = nil
            }
        } else {
            // iOS 13 中，UIButton 没有设置 icon title 的时候会触发崩溃
            if let style = pointerStyle {
                let pointer = PointerInteraction(style: style)
                self.addLKInteraction(pointer)
            } else {
                if let pointer = self.lkInteractions.first(where: { (interaction) -> Bool in
                    return interaction is PointerInteraction
                }) as? PointerInteraction {
                    self.removeLKInteraction(pointer)
                }
            }
        }
    }
}
