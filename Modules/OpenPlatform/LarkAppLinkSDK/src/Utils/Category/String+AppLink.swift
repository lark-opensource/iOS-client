//
//  String+AppLink.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/29.
//

import Foundation

extension String {
    
    /// 去掉 path 首尾的一个 /
    func applink_trimed_path() -> String {
        return applink_trim("/")
    }
    
    /// 去掉首尾的一个特定的字符
    private func applink_trim(_ target: Character) -> String {
        var result = self
        if result.hasPrefix(String(target)), let firstIndex = result.firstIndex(of: target) {
            result = String(result[result.index(after: firstIndex)...])
        }
        
        if result.hasSuffix(String(target)), let lastIndex = result.lastIndex(of: target) {
            result = String(result[..<lastIndex])
        }
        return result
    }
}
