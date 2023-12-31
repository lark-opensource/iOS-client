//
//  LarkVersionDependency.swift
//  LarkVersion
//
//  Created by 张威 on 2022/1/19.
//

import Foundation

public protocol LarkVersionDependency: AnyObject {
    /// 是否允许在当前页面弹窗 upgrade alert
    func enableShowUpgradeAlert() -> Bool
}
