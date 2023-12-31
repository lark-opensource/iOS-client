//
//  DispatchQueue+Extension.swift
//  LarkFoundation
//
//  Created by kongkaikai on 2019/1/11.
//  Copyright © 2019 com.bytedance.lark. All rights reserved.
//

import Foundation
import LarkCompatible

extension DispatchQueue: LarkFoundationExtensionCompatible {}

extension LarkFoundationExtension where BaseType == DispatchQueue {
    public func uiAsync(block: @escaping () -> Void) {
        if self.base == .main || Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
