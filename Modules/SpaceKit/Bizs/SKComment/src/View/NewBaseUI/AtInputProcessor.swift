//
//  AtInputProcessor.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/21.

import Foundation

class AtInputProcessor {

    /// 是否响应@内容
    ///
    /// - Parameters:
    ///   - content: 输入文本
    ///   - replaceRange: 被替换的 range
    /// - Returns: 是否响应
    public static func shouldRespondToAt(_ content: String, replaceRange: NSRange) -> Bool {
        // 1. 如果文本内容是空，则响应
        if content.isEmpty {
            return true
        }

        return true
    }
}
