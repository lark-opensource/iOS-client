//
//  SensitiveApi.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/22.
//

import Foundation

/// 接口wrapper的统一协议
public protocol SensitiveApi: NSObject {
    /// 外部注册自定义api使用的key值
    static var tag: String { get }
}
