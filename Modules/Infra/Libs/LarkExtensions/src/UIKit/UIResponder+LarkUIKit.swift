//
//  UIResponder+LarkUIKit.swift
//  LarkUIKitDemo
//
//  Created by lichen on 2018/10/28.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit

extension UIResponder: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType: UIResponder {
    /// 结束整条 responder chain 的 focus 状态
    /// 当调用 resignFirstResponder 之后 first reponder 会传递给 next
    func resignChainFirstResponder() {
        _ = self.base.resignFirstResponder()
        if let next = self.base.next {
            next.lu.resignChainFirstResponder()
        }
    }
}
