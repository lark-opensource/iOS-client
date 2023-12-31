//
//  RecoveryAction.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation

/// 定义用于错误恢复的一个原子化操作
public protocol RecoveryAction {

    /// 执行原子化操作
    func executeAction(with context: RecoveryContext)

}
