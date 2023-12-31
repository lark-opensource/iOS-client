//
//  OPDiagnoseRunnerPermission.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation

/**
EMADiagnoseRunnerPermission用于描述Runner运行支持的权限环境，或者当前程序运行所在的权限环境
1. 当用于描述Runner运行支持的权限环境时：
 - none：代表该Runner在任意的情况下都是不可用的
 - debug：代表该Runner仅支持在debug环境下可用
 - release：代表该Runner在release与debug环境下都是可用的
2. 当用于描述当前程序运行所在的权限环境时：
 - none：在正确的逻辑下不会出现该值
 - debug：代表当前程序处于debug环境下，可以运行release或debug级别的Runner
 - release：代表当前程序处于release环境下，只可以运行release级别的Runner
*/
@objc public enum OPDiagnoseRunnerPermission: UInt {
    case none
    case debug
    case release
}

extension OPDiagnoseRunnerPermission {

    /// 该方法在权限判断时使用，判断level指定的权限等级是否是当前环境（self）对runner开放程度的子集
    /// - Parameter level: 指定权限等级
    /// - Returns: Bool
    public func include(level: OPDiagnoseRunnerPermission) -> Bool {
        switch (self, level) {
        // 正确代码中，当前环境（self）是不可能出现.none的
        case (.none, _):
            return false
        // level出现.none代表不属于任何一个权限环境，该runner暂时是不对外开放的
        case (_, .none):
            return false
        // debug环境下对于API的开放程度大于release，所以说release是debug的子集，debug是包含release的
        case (.debug, .release), (.debug, .debug), (.release, .release):
            return true
        case (.release, .debug):
            return false
        }
    }

}
