//
//  UDIcon+Ext.swift
//  SKUIKit
//
//  Created by lijuyou on 2023/9/20.
//

import SKFoundation

// ud-design key 转换工具
public func getRealUDKey(_ string: String?) -> String? {
    guard let string = string else {
        return nil
    }
    var finalStr = ""
    var str = string.replacingOccurrences(of: "-", with: "_")
    if str.starts(with: "icon_") {
        str.removeFirst(5) // 移除icon_
    } else {
        DocsLogger.error("ud key not start with icon_")
    }
    var flag = false
    // 按照UD规则做映射
    for item in str {
        if item == "_" {
            flag = true
        } else {
            if flag {
                finalStr.append(item.uppercased())
            } else {
                finalStr.append(item)
            }
            flag = false
        }
    }
    DocsLogger.info("getRealUDKey from \(string) to \(finalStr)")
    return finalStr
}
