//
//  ReturnInputHandler.swift
//  Lark
//
//  Created by lichen on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView
import LKCommonsLogging

/// 处理 TextView 中回车操作
public final class ReturnInputHandler: TextViewInputProtocol {
    static let logger = Logger.log(ReturnInputHandler.self, category: "ReturnInputHandler")

    public let returnFunc: (UITextView) -> Bool
    public var newlineFunc: ((UITextView) -> Bool)? // 匹配 \r\r 搜狗换行

    public init(returnFunc: @escaping (UITextView) -> Bool) {
        self.returnFunc = returnFunc
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return self.returnFunc(textView)
        } else if text == "\r\r", let newlineFunc = self.newlineFunc {
            return newlineFunc(textView)
        } else if text == "r" || text == "\r\n" {
            /// 不用担心打印频繁 正常不会走到
            Self.logger.warn("Abnormal line breaks \(text)")
        }
        return true
    }
}
