//
//  Scope.swift
//  RunloopTools
//
//  Created by KT on 2020/2/11.
//

import Foundation

/// 任务级别
public enum Scope {
    case user      // 用户级别，登出不执行
    case container // 容器级别，确保执行
}
