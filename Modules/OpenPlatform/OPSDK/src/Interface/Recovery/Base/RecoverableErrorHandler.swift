//
//  RecoverableErrorHandler.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkOPInterface

/// 接入错误恢复框架的业务方需要具体实现的协议
/// 提供特定的上下文信息到Actions的映射
public protocol RecoverableErrorHandler: AnyObject {
    func handle(with context: RecoveryContext) -> [RecoveryAction]?
}
